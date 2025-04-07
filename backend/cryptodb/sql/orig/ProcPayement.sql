create or replace procedure crypto.create_payment(
    in_datetime TIMESTAMP,							-- Date and time of the payment
    in_asset VARCHAR(8),							-- Asset used for the payment
    in_total_amount_payed NUMERIC(38, 18),			-- Total amount used for the payment (incl. fee if payed in this asset)
    in_net_payment_value NUMERIC(16, 4),			-- Net value payed (excl. fee if payed in native currency)
    in_fee_in_currency NUMERIC(16, 4),				-- Fee payed in the native currency (should alwas be provided, even if the fee is payed in another asset)
    in_fee_in_asset NUMERIC(38, 18) default null,	-- If the fee is not payed in the native currency, specify the amount of the fee expressed in the fee asset
    in_fee_asset VARCHAR(8) default null,			-- If the fee is not payed in the native currency, specify the asset used to pay the fee (if left null and in_fee_in_asset is set, the payment asset is assumed)
    in_description TEXT default null,				-- Description (optional)
    in_payment_reference TEXT default null,			-- Payment reference (optional)
    in_link TEXT default null						-- Weblink to the payment (optional)
)
language plpgsql
as $$
declare
	amount_payed_excl_fee NUMERIC(38, 18);
	quote_value NUMERIC(16, 4);
	payment_transaction_id INTEGER;
	cost_basis_info crypto.cost_basis_info;
begin
    -- Validate inputs
    if in_fee_in_currency is null then
        raise exception 'in_fee_in_currency must always be provided.';
    end if;

    -- If fee is provided in a different asset, assign it to the proper asset if not provided
    if in_fee_in_asset is not null and in_fee_asset is null then
        in_fee_asset := in_asset;
    end if;
   
    -- Calculate the amount of the payment excluding the fee
    amount_payed_excl_fee := in_total_amount_payed;
    if in_fee_in_asset is not null then
    	if in_fee_asset = in_asset then
    		amount_payed_excl_fee := in_total_amount_payed - in_fee_in_asset;
    		quote_value := in_net_payment_value / amount_payed_excl_fee;
	 	else
	 		quote_value := in_net_payment_value / in_total_amount_payed;
	 	end if;
	else
		quote_value := (in_net_payment_value + in_fee_in_currency) / in_total_amount_payed;
    end if;

    -- Insert the payment transaction
    insert into crypto.Transactions (
        DateTime,
        TransactionType,
        SoldAsset,
        SoldAmount,
        Costs,
        CostAsset,
        QuoteValue,
        GrossValue,
        TransactionCost,
        NetValue,
        Description,
        Reference,
        Link
    )
    values (
        in_datetime,									-- DateTime
        'Payment',										-- TransactionType
        in_asset,										-- SoldAsset
        amount_payed_excl_fee,							-- SoldAmount
        in_fee_in_asset,								-- Costs
        in_fee_asset,									-- CostAsset
        quote_value,									-- QuoteValue
        in_net_payment_value + in_fee_in_currency,		-- GrossValue
        in_fee_in_currency,								-- TransactionCost
        in_net_payment_value,							-- NetValue
        in_description,									-- Description
        in_payment_reference,							-- Reference
        in_link											-- Link
    ) returning id into payment_transaction_id;
   
    -- Handle fee if applicable (fee in asset)
    if in_fee_in_asset is not null and in_fee_in_asset > 0 and in_fee_asset != in_asset then
    	perform crypto.reduce_amount_open(
    		in_datetime,
    		in_fee_asset,
    		in_fee_in_asset,
    		payment_transaction_id
    	);
    end if;
   
   	-- Step 3: Find transactions with AmountOpen > 0 in FIFO order and link them
    select cost_basis, trade_cost_basis
    from crypto.reduce_amount_open(
    	in_datetime,
    	in_asset,
    	in_total_amount_payed,
    	payment_transaction_id
    ) into cost_basis_info.cost_basis, cost_basis_info.trade_cost_basis;

   	-- If the fee is payed in a third party currency, we deduct it form the cost basis
    if in_fee_in_asset is not null and in_fee_asset != in_asset then
    	select cost_basis_info.cost_basis + in_fee_in_currency, cost_basis_info.trade_cost_basis + in_fee_in_currency
    	into cost_basis_info.cost_basis, cost_basis_info.trade_cost_basis;
    end if;
    
    -- Step 4: Update the Profit/Loss of the sell transaction
    update crypto.Transactions
    set
    	TradeProfitLoss = in_net_payment_value - cost_basis_info.trade_cost_basis,
    	ProfitLoss = in_net_payment_value - cost_basis_info.cost_basis
    where Id = payment_transaction_id;
end;
$$;

