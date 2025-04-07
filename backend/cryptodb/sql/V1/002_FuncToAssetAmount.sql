/**
 * Rounds a given amount to the precision of the given asset.
 *
 * If the given asset is not found in the crypto.Assets table, this function
 * will raise an exception.
 *
 * @param {varchar(8)} in_asset The asset to round for.
 * @param {numeric(38, 18)} in_amount The amount to round.
 * @returns {numeric(38, 18)} The rounded amount.
 */
create or replace function crypto.ToAssetAmount(
    in_asset varchar(8),
    in_amount numeric(38, 18)
)
returns numeric(38, 18)
as $$
begin
    -- validate that in_asset and in_amount are not null
    if in_asset is null or in_amount is null then
        raise exception 'input parameters in_asset and in_amount cannot be null';
    end if;

    -- Check if the asset is a fiat asset
    if exists (select 1 from crypto.FiatAssets where Asset = in_asset) then
        return round(in_amount, 4);
    end if;

    -- Check that the given asset exists in the crypto.Assets table.
    if not exists (
        select 1 from crypto.Assets
        where Asset = in_asset
    ) then
        raise exception 'crypto asset not recognised. Add the asset to the crypto.Assets table first.';
    end if;

    -- Round the given amount to the precision of the given asset.
    return round(in_amount, (select Precision FROM crypto.Assets where Asset = in_asset));
end;
$$ language plpgsql;

