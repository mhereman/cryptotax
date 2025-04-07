create or replace procedure crypto.create_buy(
    in_datetime TIMESTAMP,							-- Date and time of the buy
    in_asset VARCHAR(8),							-- Asset bought
    in_amount_excl_fee NUMERIC(38, 18),				-- Amount bought (excl. fee's payed if fee's are payed in the asset type)
    in_total_payed_value NUMERIC(16, 4),			-- Total amount payed in the native currency (including fee's - also when payed in native currency)
    in_fee_in_currency NUMERIC(16, 4),				-- Fee payed in the native currency (should always be provided, even if the fee is payed in another asset)
    in_fee_in_asset NUMERIC(38, 18) default null,	-- If the fee is not payed in the native currency, specify the amount of the fee expressed in the fee asset
    in_fee_asset VARCHAR(8) default null,			-- If the fee is not payed in the native currency, specify the asset used to pay the fee (if left null and in_fee_in_asset is set, the bought asset is assumed)
    in_description TEXT default null,				-- Description (optional)
    in_order_reference TEXT default null,			-- Reference to the order (optional)
    in_link TEXT default null						-- Weblink to the order (optional)
)
language plpgsql
as $$
declare
	quote_value NUMERIC(16, 4);
	buy_transaction_id INTEGER;
begin
    -- Validate inputs
    if in_fee_in_currency is null then
        raise exception 'in_fee_in_currency must always be provided.';
    end if;

    -- Automatically set in_fee_asset to in_asset if in_fee_in_asset is provided but in_fee_asset is NULL
    if in_fee_in_asset is not null and in_fee_asset is null then
        in_fee_asset := in_asset;
    end if;

    -- Calculate quote_value based on the type of fee and fee_asset
    if in_fee_in_asset is not null then
        if in_fee_asset = in_asset then
            -- Fee is in the same asset as the bought asset
            quote_value := (in_total_payed_value) / (in_amount_excl_fee + in_fee_in_asset);
        else
            -- Fee is in a different asset than the bought asset
            quote_value := (in_total_payed_value - in_fee_in_currency) / in_amount_excl_fee;
        end if;
    else
        -- No fee in asset; use standard calculation
        quote_value := (in_total_payed_value - in_fee_in_currency) / in_amount_excl_fee;
    end if;

    -- Insert the buy transaction
    insert into crypto.Transactions (
        DateTime,
        TransactionType,
        Asset,
        Amount,
        Costs,
        CostAsset,
        QuoteValue,
        GrossValue,
        TransactionCost,
        NetValue,
        InvestedValue,
        CostBasis,
        AmountOpen,
        Description,
        Reference,
        Link
    )
    values (
        in_datetime,								-- DateTime
        'Buy',										-- TransactionType
        in_asset,									-- Asset
        in_amount_excl_fee,							-- Amount
        in_fee_in_asset,          					-- Costs
        in_fee_asset,								-- CostAsset
        quote_value,              					-- QuoteValue
        in_total_payed_value,     					-- GrossValue
        in_fee_in_currency,       					-- TransactionCost
        in_total_payed_value - in_fee_in_currency,	-- NetValue
        in_total_payed_value,     					-- InvestedValue
        in_total_payed_value,						-- CostBasis
        in_amount_excl_fee,       					-- AmountOpen
        in_description,								-- Description
        in_order_reference,							-- Reference
        in_link										-- Link
    )
    returning Id into buy_transaction_id;

    -- Handle fee in another asset
    if in_fee_asset IS NOT NULL AND in_fee_asset != in_asset then
    	perform crypto.reduce_amount_open(
    		in_datetime,
    		in_fee_asset,
    		in_fee_in_asset,
    		buy_transaction_id
    	);
    end if;
end;
$$;
