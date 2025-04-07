/**
 * Updates the holdings for a given non-fiat asset.
 *
 * This procedure updates the holdings of a specified asset by adding
 * the given amount to the current holdings. If the asset is a fiat asset,
 * an exception is raised since holdings are only tracked for non-fiat assets.
 * It also ensures that the holdings for years between the most recent existing
 * entry and the current year are populated with appropriate amounts.
 *
 * @param {timestamp} in_datetime The date and time of the operation.
 * @param {varchar(8)} in_asset The asset to update.
 * @param {numeric(38, 18)} in_amount The amount to add to the holdings.
 * @param {bool} in_overwrite Whether to overwrite the existing holdings if
 *     they exist. If true, the existing holdings are overwritten. If false,
 *     the new amount is added to the existing holdings.
 */
create or replace procedure crypto.UpdateHolding(
    in_datetime timestamp,
    in_asset VARCHAR(8),
    in_amount numeric(38, 18),
    in_overwrite bool default false
)
language plpgsql
as $$
declare
    -- the amount to update the holdings with, rounded to the precision of the asset
    asset_amount numeric(38, 18);
begin
    -- validate that in_datetime, in_asset and in_amount are not null
    if in_datetime is null or in_asset is null or in_amount is null then
        raise exception 'input parameters in_datetime, in_asset and in_amount cannot be null';
    end if;

    -- Check if the asset is a fiat currency
    if exists (
        select 1 from crypto.FiatAssets
        where Asset = in_asset
    ) then
        raise exception 'holdings are only tracked for non-fiat assets';
    end if;

    -- Convert the input amount to the asset's precision
    select crypto.ToAssetAmount(in_asset, in_amount) into asset_amount;

    -- Use a CTE to find the most recent available line for the asset
    -- before the year of in_datetime, and create entries for missing years
    with available_line as (
        select Amount, Year
        from crypto.Holdings
        where Asset = in_asset
        and Year < EXTRACT(year from in_datetime)
        order by Year desc
        limit 1
    )
    insert into crypto.Holdings (Asset, Year, Amount)
    select in_asset, y, (select Amount from available_line)
    from generate_series(
        (select Year from available_line) + 1,
        extract(year from in_datetime)
    ) as y
    left join crypto.Holdings h on h.Asset = in_asset and h.Year = y
    where h.Asset is null
    and exists(select 1 from available_line);

    -- Update the holdings for the specified asset and year
    if not in_overwrite then
        -- Add the new amount to the existing holdings
        update crypto.Holdings
        set Amount = Amount + asset_amount
        WHERE Asset = in_asset
        AND Year >= extract(year from in_datetime);

    else
        -- Overwrite the existing holdings if they exist
        update crypto.Holdings
        set Amount = asset_amount
        WHERE Asset = in_asset
        AND Year >= extract(year from in_datetime);
    end if;

    -- Insert a new holding if no existing entry was found
    if not FOUND then
        insert into crypto.Holdings (Asset, Year, Amount)
        values (in_asset, extract(year from in_datetime), asset_amount);
    end if;
end;
$$;

