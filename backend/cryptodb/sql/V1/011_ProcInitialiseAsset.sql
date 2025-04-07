/**
 * Initialises the holdings of a given non-fiat asset by creating an event and
 * a valuation event operation.
 *
 * This procedure validates that the given asset is not a fiat asset and that
 * the given amount and quote value are not null. It then rounds the given
 * amount to the precision of the given asset, creates an event with the given
 * description, reference and link, and adds a valuation event operation with
 * the given quote value. Finally, it updates the holdings for the given asset
 * with the given amount.
 *
 * @param {timestamp} in_datetime The date and time of the event.
 * @param {varchar(8)} in_asset The asset to initialize.
 * @param {numeric(38, 18)} in_amount The amount to initialize with.
 * @param {numeric(16, 4)} in_quote_value The quote value of the asset in the
 *     configured fiat currency.
 * @param {text} in_description A description of the event.
 * @param {text} in_reference A reference of the event.
 * @param {text} in_link An external link to the event.
 */
create or replace procedure crypto.InitialiseAsset(
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
    -- the precision of the given asset
    precision integer;

    -- the amount to initialize with, rounded to the precision of the asset
    asset_amount numeric(38, 18);

    -- the configured fiat asset
    fiatAsset VARCHAR(8);

    -- the id of the created event
    eventId integer;
begin
    -- validate that in_datetime, in_asset, in_amount and in_quote_value are not null
    if in_datetime is null or in_asset is null or in_amount is null or in_quote_value is null then
        raise exception 'input parameters in_datetime, in_asset, in_amount and in_quote_value cannot be null';
    end if;

    -- check that the given asset is not a fiat asset
    if exists (
        select 1 from crypto.FiatAssets
        where Asset = in_asset
    ) then
        raise exception 'only non-fiat assets can be initialized';
    end if;

    -- round the given amount to the precision of the given asset
    select crypto.ToAssetAmount(in_asset, in_amount) into asset_amount;

    -- get the configured fiat asset
    select Value::varchar(8) into fiatAsset
    from crypto.Settings
    where Name = 'FiatAsset';

    -- create the event
    insert into crypto.Events (
        DateTime, Type, IsFiatEvent,
        BoughtAsset, SoldAsset,
        Description, Reference, Link
    ) values (
        in_datetime, 'Initialisation', true,
        in_asset, fiatAsset,
        in_description, in_reference, in_link
    ) returning id into eventId;

    -- create the valuation event operation
    insert into crypto.EventOperations (
        EventId, Type, Asset, Value,
        FiatQuoteValue, IsFiatEventOperation
    ) values
        (eventId, 'Valuation', in_asset, asset_amount, in_quote_value, false);

    -- update the holdings for the given asset
    call crypto.UpdateHolding(
        in_datetime,
        in_asset,
        asset_amount,
        true
    );

    -- Remove all Lifo and Fifo lines
    delete from crypto.Fifo;
    delete from crypto.Lifo;

    -- Refresh materialised view
    refresh materialized view crypto.ViewTransactionList;
end;
$$;

