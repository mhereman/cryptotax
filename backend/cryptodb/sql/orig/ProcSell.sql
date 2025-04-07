create or replace procedure crypto.create_sell(
    in_datetime TIMESTAMP,							-- Date and time of the sell
    in_asset VARCHAR(8),							-- Asset sold
    in_total_amount_sold NUMERIC(38, 18),			-- Total amount sold (incl. fee if payed in this asset)
    in_net_value_received NUMERIC(16, 4),			-- Net value received in the native currency
    in_fee_in_currency NUMERIC(16, 4),				-- Fee payed in the native currency (should always be provided, even if the fee is payed in another asset)
    in_fee_in_asset NUMERIC(38, 18) default null,	-- If the fee is not payed in the native currency, specify the amount of the fee expressed in the fee asset
    in_fee_asset VARCHAR(8) default null,			-- If the fee is not payed in the native currency, specify the asset used to pay the fee (if left null and in_fee_in_asset is set, the sold asset is assumed)
    in_description TEXT default null,				-- Description (optional)
    in_order_reference TEXT default null,			-- Reference to the order (optional)
    in_link TEXT default null						-- Weblink to the order (optional)
)
language plpgsql 
as $$
declare
	amount_excl_fee NUMERIC(38, 18);
	quote_value NUMERIC(16, 4);
	sell_transaction_id INTEGER;
	cost_basis_info crypto.cost_basis_info;
begin
	-- Validate inputs
    if in_fee_in_currency is null then
        raise exception 'in_fee_in_currency must always be provided.';
    end if;
   
   -- Automatically set in_fee_asset to in_asset if in_fee_in_asset is provided but in_fee_asset is NULL
    if in_fee_in_asset is not null and in_fee_asset is null then
        in_fee_asset := in_asset;
    end if;
   
    amount_excl_fee := in_total_amount_sold;
	if in_fee_in_asset is not null then
		if in_fee_asset = in_asset then
			amount_excl_fee := in_total_amount_sold - in_fee_in_asset;
			quote_value := in_net_value_received / amount_excl_fee;
		else
			quote_value := in_net_value_received / in_total_amount_sold;
		end if;
	else
		quote_value := (in_net_value_received + in_fee_in_currency) / in_total_amount_sold;
	end if;
   
    -- Step 1: Create the sell transaction
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
        in_datetime,								-- DateTime
        'Sell',										-- TrasactionType
        in_asset,									-- SoldAsset
        amount_excl_fee,							-- SoldAsset
        in_fee_in_asset,							-- Costs
        in_fee_asset,								-- CostAsset
        quote_value,								-- QuoteValue
        in_net_value_received + in_fee_in_currency,	-- GrossValue
        in_fee_in_currency,							-- TransactionCost
        in_net_value_received,						-- NetValue
        in_description,								-- Description
        in_order_reference,							-- Reference
        in_link										-- Link
    )
    returning Id into sell_transaction_id;
   
    -- Step 2: Handle fee if in an unrelated asset
    if in_fee_in_asset is not null and in_fee_in_asset > 0 and in_fee_asset != in_asset then
    	perform crypto.reduce_amount_open(
    		in_datetime,
    		in_fee_asset,
    		in_fee_in_asset,
    		sell_transaction_id
    	);
    end if;
    
    -- Step 3: Find transactions with AmountOpen > 0 in FIFO order
   	select cost_basis, trade_cost_basis
   	from crypto.reduce_amount_open(
   		in_datetime,
   		in_asset,
   		in_total_amount_sold,
   		sell_transaction_id
   	) into cost_basis_info.cost_basis, cost_basis_info.trade_cost_basis;
	
    -- If the fee is payed in a third party currency, we deduct it form the cost basis
    if in_fee_in_asset is not null and in_fee_asset != in_asset then
    	select cost_basis_info.cost_basis + in_fee_in_currency, cost_basis_info.trade_cost_basis + in_fee_in_currency
    	into cost_basis_info.cost_basis, cost_basis_info.trade_cost_basis;
    end if;
   	
    -- Step 3: Update the Profit/Loss of the sell transaction
    update crypto.Transactions
    set
    	TradeProfitLoss = in_net_value_received - cost_basis_info.trade_cost_basis,
    	ProfitLoss = in_net_value_received - cost_basis_info.cost_basis
    where Id = sell_transaction_id;
        
end;
$$;
