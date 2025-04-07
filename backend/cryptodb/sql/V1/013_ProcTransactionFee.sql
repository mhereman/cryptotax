/**
 * Creates a new transaction event, including its event operations and updates the
 * holdings of the involved asset.
 *
 * The transaction event is created with the given date and time, type 'TransactionFee',
 * and whether the transaction involves a fiat asset or not. The event is created
 * with the given asset, amount, quote value, description, reference and link.
 *
 * The event operations are created as follows:
 *  - A 'Fee' event operation is created for the given asset with the given
 *    amount and quote value. If the asset is a fiat asset, the
 *    IsFiatEventOperation flag is set.
 *
 * Finally, the holdings of the involved asset are updated by calling the
 * UpdateHolding procedure with the given date and time, asset and amount.
 *
 * @param {timestamp} in_datetime The date and time of the transaction.
 * @param {varchar(8)} in_asset The asset that is involved in the transaction.
 * @param {numeric(38, 18)} in_amount The amount of the asset that is involved in
 *     the transaction.
 * @param {numeric(16, 4)} in_quote_value The quote value of the asset expressed
 *     in the configured fiat currency.
 * @param {text} in_description A description of the transaction.
 * @param {text} in_reference A reference of the transaction.
 * @param {text} in_link An external link to the transaction.
 */
create or replace procedure crypto.TransactionFee(
    in_datetime timestamp,
    in_asset varchar(8),
    in_amount numeric(38, 18),
    in_quote_value numeric(16, 4),
    in_description text default null,
    in_reference text default null,
    in_link text default null
)
language plpgsql
as $$
declare
    isFiat boolean;
    eventId integer;
begin
    -- validate that in_datetime, in_asset, in_amount and in_quote_value are not null
    if in_datetime is null or in_asset is null or in_amount is null or in_quote_value is null then
        raise exception 'input parameters in_datetime, in_asset, in_amount and in_quote_value cannot be null';
    end if;

    -- check if the given asset is a fiat asset
    select exists (
        select 1 from crypto.FiatAssets
        where Asset = in_asset
    ) into isFiat;

    -- create the event
    insert into crypto.Events (
        DateTime, Type, IsFiatEvent,
        FeeAsset,
        Description, Reference, Link
    ) values (
        in_datetime, 'TransactionFee', false,
        in_asset,
        in_description, in_reference, in_link
    ) returning id into eventId;

    -- create the event operations
    insert into crypto.EventOperations(
        EventId, Type, Asset, Value,
        FiatQuoteValue, IsFiatEventOperation
    ) values
        (eventId, 'Fee', in_asset, in_amount, in_quote_value, isFiat);

    -- update the holdings
    if not isFiat then
        perform crypto.UpdateHolding(in_datetime, in_asset, -in_amount);
    end if;

    call crypto.LinkFifo(in_datetime, in_asset);
    call cyrpto.LinkLifo(in_datetime, in_asset);

    -- Refresh materialised view
    refresh materialized view crypto.ViewTransactionList;
end;
$$;

