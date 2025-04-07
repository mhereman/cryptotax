/**
 * Creates a new trade event, including its event operations and updates the
 * holdings of the involved assets.
 *
 * The trade event is created with the given date and time, type 'Trade',
 * whether the trade involves a fiat asset or not, the bought and sold assets,
 * the fee asset, a description, a reference and a link.
 *
 * The event operations are created as follows:
 *  - A 'Buy' event operation is created for the bought asset with the given
 *    amount and quote value. If the bought asset is a fiat asset, the
 *    IsFiatEventOperation flag is set.
 *  - A 'Sell' event operation is created for the sold asset with the given
 *    amount and quote value. If the sold asset is a fiat asset, the
 *    IsFiatEventOperation flag is set.
 *  - A 'Fee' event operation is created for the fee asset with the given
 *    amount and quote value. If the fee asset is a fiat asset, the
 *    IsFiatEventOperation flag is set.
 *
 * Finally, the holdings of the involved assets are updated by calling the
 * UpdateHolding procedure for each asset.
 *
 * @param {timestamp} in_datetime The date and time of the trade.
 * @param {varchar(8)} in_bought_asset The asset that is bought.
 * @param {numeric(38, 18)} in_bought_amount The amount of the bought asset.
 * @param {numeric(16, 4)} in_bought_quote_value The quote value of the bought
 *     asset in the configured fiat currency.
 * @param {varchar(8)} in_sold_asset The asset that is sold.
 * @param {numeric(38, 18)} in_sold_amount The amount of the sold asset.
 * @param {numeric(16, 4)} in_sold_quote_value The quote value of the sold
 *     asset in the configured fiat currency.
 * @param {varchar(8)} in_fee_asset The asset that is used to pay the fee's
 *     with.
 * @param {numeric(38, 18)} in_fee_amount The amount of the fee asset.
 * @param {numeric(16, 4)} in_fee_quote_value The quote value of the fee asset
 *     in the configured fiat currency.
 * @param {text} in_description A description of the trade.
 * @param {text} in_reference A reference of the trade.
 * @param {text} in_link An external link to the trade.
 */
create or replace procedure crypto.Trade(
    in_datetime timestamp,
    in_bought_asset varchar(8),
    in_bought_amount numeric(38, 18),
    in_bought_quote_value numeric(16, 4),
    in_sold_asset varchar(8),
    in_sold_amount numeric(38, 18),
    in_sold_quote_value numeric(16, 4),
    in_fee_asset varchar(8),
    in_fee_amount numeric(38, 18),
    in_fee_quote_value numeric(16, 4),
    in_description text default null,
    in_reference text default null,
    in_link text default null
)
language plpgsql
as $$
declare
    isBoughtFiat boolean;
    isSoldFiat boolean;
    isFeeFiat boolean;
    eventId integer;
begin
    -- validate that the following input parameters are not null:
    --  * in_datetime
    --  * in_bought_asset
    --  * in_bought_amount
    --  * in_bought_quote_value
    --  * in_sold_asset
    --  * in_sold_amount
    --  * in_sold_quote_value
    --  * in_fee_asset
    --  * in_fee_amount
    --  * in_fee_quote_value
    if in_datetime is null or
        in_bought_asset is null or in_bought_amount is null or in_bought_quote_value is null or
        in_sold_asset is null or in_sold_amount is null or in_sold_quote_value is null or
        in_fee_asset is null or in_fee_amount is null or in_fee_quote_value is null then
        raise exception 'input parameters in_datetime, in_bought_asset, in_bought_amount, in_bought_quote_value, in_sold_asset, in_sold_amount, in_sold_quote_value, in_fee_asset, in_fee_amount and in_fee_quote_value cannot be null';
    end if;

    -- Check which assets are fiat assets
    select exists (select 1 from crypto.FiatAssets where Asset = in_bought_asset) into isBoughtFiat;
    select exists (select 1 from crypto.FiatAssets where Asset = in_sold_asset) into isSoldFiat;
    select exists (select 1 from crypto.FiatAssets where Asset = in_fee_asset) into isFeeFiat;

    -- Create the event
    insert into crypto.Events (
        DateTime, Type, IsFiatEvent,
        BoughtAsset, SoldAsset, FeeAsset,
        Description, Reference, Link
    ) values (
        in_datetime, 'Trade', (isBoughtFiat or isSoldFiat),
        in_bought_asset, in_sold_asset, in_fee_asset,
        in_description, in_reference, in_link
    ) returning id into eventId;

    -- Create the event operations
    insert into crypto.EventOperations(
        EventId, Type, Asset, Value,
        FiatQuoteValue, IsFiatEventOperation
    ) values
        (eventId, 'Buy', in_bought_asset, in_bought_amount, in_bought_quote_value, isBoughtFiat),
        (eventId, 'Sell', in_sold_asset, in_sold_amount, in_sold_quote_value, isSoldFiat),
        (eventId, 'Fee', in_fee_asset, in_fee_amount, in_fee_quote_value, isFeeFiat);

    -- update the holdings
    if not isBoughtFiat then
        call crypto.UpdateHolding(in_datetime, in_bought_asset, in_bought_amount);
    end if;

    if not isSoldFiat then
        call crypto.UpdateHolding(in_datetime, in_sold_asset, -in_sold_amount);
    end if;

    if not isFeeFiat then
        call crypto.UpdateHolding(in_datetime, in_fee_asset, -in_fee_amount);
    end if;

    -- Create Lifo and Fifo links
    if not isSoldFiat then
        call crypto.LinkFifo(in_datetime, in_sold_asset);
        call crypto.LinkLifo(in_datetime, in_sold_asset);
    end if;

    if in_sold_asset != in_fee_asset and not isFeeFiat then
        call crypto.LinkFifo(in_datetime, in_fee_asset);
        call crypto.LinkLifo(in_datetime, in_fee_asset);
    end if;

    -- Refresh materialised view
    refresh materialized view crypto.ViewTransactionList;
end;
$$;


