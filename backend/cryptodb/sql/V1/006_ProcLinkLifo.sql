/**
 * Links the out_events of a given asset to the in_events that have not yet been consumed.
 *
 * The procedure takes two parameters: in_datetime and in_asset. The in_datetime parameter
 * is a timestamp that indicates the point in time until which we want to link the out_events.
 * The in_asset parameter is the asset for which we want to link the out_events.
 *
 * The procedure will link the out_events of the given asset that have not yet been linked to
 * the in_events that have not yet been consumed. The linking is done in a LIFO manner, meaning
 * that the newest in_events will be linked to the out_events first.
 */
create or replace procedure crypto.LinkLifo(
    in_datetime timestamp,
    in_asset VARCHAR(8)
)
language plpgsql
as $$
declare
    unlinked_event record;
    in_event record;
    fee_amount numeric(38, 18);
    original_sell_amount numeric(38, 18);
    sell_amount numeric(38, 18);
    buy_amount numeric(38, 18);
    buy_quote_value numeric(16, 4);
    buy_part numeric(38, 18);
    link_amount numeric(38, 18);
    remaining_amount numeric(38, 18);
    last_initialisation_date timestamp;
begin
    -- Validate that in_datetime and in_asset are not null
    if in_datetime is null or in_asset is null then
        raise exception 'input parameters in_datetime and in_asset cannot be null';
    end if;

    -- Perform a cleanup of the LIFO operations as we might insert transactions in random order
    call crypto.ClearLifo(in_datetime, in_asset);

    -- Find the date of the last Valorisation, we do not want to go before that
    select max(DateTime) into last_initialisation_date
    from crypto.events
    where Type = 'Initialisation';

    -- Gather all out_events that have not been linked
    -- We order them by oldest first
    for unlinked_event in
        select Id, DateTime, BoughtAsset, SoldAsset, FeeAsset, IsFiatEvent
        from crypto.Events
        where Type in ('TransactionFee', 'Trade')
        and (SoldAsset = in_asset or FeeAsset = in_asset)
        and DateTime <= in_datetime
        and Id not in (select OutEventId from crypto.Lifo)
        order by DateTime asc
    loop
        -- Fetch the fee operations for the current unlinked_event
        select coalesce(sum(Value), 0) into fee_amount
        from crypto.EventOperations
        where EventId = unlinked_event.Id
        and Type = 'Fee';

        -- Fetch the sell operations for the current unlinked_event
        select coalesce(sum(Value), 0) into sell_amount
        from crypto.EventOperations
        where EventId = unlinked_event.Id
        and Type = 'Sell';

        -- The the buy operations
        select coalesce(sum(Value), 0), coalesce(sum(FiatQuoteValue), 0) into buy_amount, buy_quote_value
        from crypto.EventOperations
        where EventId = unlinked_event.Id
        and Type = 'Buy';

        -- If both fee and sell amounts are zero, skip to the next unlinked_event
        if fee_amount = 0 and sell_amount = 0 then
            continue;
        end if;
        original_sell_amount := sell_amount;

        -- Gather all in_events that have amounts open to be consumed.
        -- We order them by newest first (LIFO)
        for in_event in
            select
                e.Id, e.DateTime, e.IsFiatEvent, o.Value,
                coalesce(sum(f.InAmount), 0) As UsedValue, coalesce(sum(o.FiatQuoteValue), 0) as FiatQuoteValue
            from crypto.Events e
            join crypto.EventOperations o on (o.EventId = e.Id and o.Type in ('Valuation', 'Buy'))
            left join crypto.Lifo f on (f.InEventId = e.Id)
            where e.Type in ('Initialisation', 'Trade')
            and BoughtAsset = in_asset
            and DateTime <= unlinked_event.DateTime
            and (last_initialisation_date is null or DateTime >= last_initialisation_date)
            group by (e.Id, e.DateTime, o.Value)
            having o.Value > coalesce(sum(f.InAmount), 0)
            order by e.DateTime desc
        loop
            -- Calculate the remaining amount that can be consumed from this in_event
            remaining_amount := in_event.Value - in_event.UsedValue;

            -- Handle the fee's
            if fee_amount > 0 then
                -- Calculate the amount to consume
                select least(fee_amount, remaining_amount) into link_amount;

                -- Consume the fee (or part of the fee)
                insert into crypto.Lifo (
                    InEventId, OutEventId, InAmount, InValue, InAsset, InIsFiat, Type)
                values (
                    in_event.Id, unlinked_event.Id,
                    link_amount, link_amount * in_event.FiatQuoteValue,
                    unlinked_event.FeeAsset, in_event.IsFiatEvent, 'Fee');

                -- Calculate remaining amount to be consumed and remaining fee to consume
                select remaining_amount - link_amount into remaining_amount;
                select fee_amount - link_amount into fee_amount;

                -- If the remaining amount is zero, move to the next in_event
                if remaining_amount = 0 then
                    continue;
                end if;
            end if;

            -- Handle the sold amount
            if sell_amount > 0 then
                -- Calculate the amount to consume
                select least(sell_amount, remaining_amount) into link_amount;

                select crypto.ToAssetAmount(
                    unlinked_event.BoughtAsset,
                    (link_amount / original_sell_amount) * buy_amount)
                into buy_part;

                -- Consume the sold amount (or part of the sold amount)
                insert into crypto.Lifo (
                    InEventId, OutEventId, InAmount, InValue, InAsset, InIsFiat,
                    OutAmount, OutValue, OutAsset, OutIsFiat, Type)
                values (
                    in_event.Id, unlinked_event.Id,
                    link_amount, link_amount * in_event.FiatQuoteValue,
                    unlinked_event.SoldAsset, in_event.IsFiatEvent,
                    buy_part, buy_part * buy_quote_value,
                    unlinked_event.BoughtAsset, unlinked_event.IsFiatEvent, 'Sell');

                -- Calculate remaining amount to be consumed and remaining sold amount to consume
                select remaining_amount - link_amount into remaining_amount;
                select sell_amount - link_amount into sell_amount;

                -- If the remaining amount is zero, move to the next in_event
                if remaining_amount = 0 then
                    continue;
                end if;
            end if;

            -- If both fee and sell amounts are depleted, exit the loop
            if fee_amount = 0 and sell_amount = 0 then
                exit;
            end if;
        end loop;

        -- If there are still open amounts after depleting all in_events, raise an error
        if fee_amount > 0 or sell_amount > 0 then
            raise exception 'Insufficient funds';
        end if;
    end loop;
end;
$$;

