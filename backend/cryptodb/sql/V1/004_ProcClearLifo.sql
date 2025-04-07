create or replace procedure crypto.ClearLifo(
    in_datetime timestamp,
    in_asset VARCHAR(8)
)
language plpgsql
as $$
begin
    -- validate that in_datetime and in_assset are not null
    if in_datetime is null or in_asset is null then
        raise exception 'input parameters in_datetime and in_asset cannot be null';
    end if;

    -- check if the given asset is not a fiat asset
    if exists (select 1 from crypto.FiatAssets where Asset = in_asset) then
        raise exception 'input asset cannot be a fiat asset';
    end if;

    delete from crypto.Lifo
    where OutEventId in (
        select Id
        from crypto.Events
        where Type = 'Trade'
        and (SoldAsset = in_asset or FeeAsset = in_asset)
        and DateTime > in_datetime
    )
    or OutEventId in (
        select Id
        from crypto.Events
        where Type = 'TransactionFee'
        and FeeAsset = in_asset
        and DateTime > in_datetime
    );
end;
$$;