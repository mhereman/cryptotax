create or replace procedure crypto.create_trade(
    in_datetime TIMESTAMP,								-- Date and time of the trade
    in_sold_asset VARCHAR(8),							-- Asset sold
    in_total_amount_sold NUMERIC(38, 18),				-- Total amount sold (incl. fee if payed in this asset)
    in_bought_asset VARCHAR(8),							-- Asset bought
    in_amount_bought_excl_fee NUMERIC(38, 18),			-- Amount bought (excl. fee if payed in this asset)
    in_net_value_after_trade NUMERIC(16, 4),  			-- Net value of the trade.
    in_fee_in_currency NUMERIC(16, 4),					-- Fee payed in the native currency (should always be provided, even if the fee is payed in another asset)
    in_fee_in_asset NUMERIC(38, 18) default null,		-- If the fee is not payed in the native currency, specify the amoun tof the fee expressed in the fee asset
    in_fee_asset VARCHAR(8) default null,				-- If the fee is not payed in the native currency, specify the asset used to pay the fee (if left null and in_fee_in_asset is set, the sold_asset is assumed)
    in_description text default null,					-- Description (optional)
    in_order_reference text default null,				-- Reference to the order (optional)
    in_link text default null							-- Weblink to the order (optional)
)
language plpgsql
as $$
declare
	amount_sold_excl_fee NUMERIC(38, 18);
	total_amount_bought numeric(38, 18);
	sold_quote_value NUMERIC(16, 4);
	bought_quote_value NUMERIC(16, 4);
	trade_transaction_id INTEGER;
	cost_basis_info crypto.cost_basis_info;
begin
	-- Validate inputs
    if in_fee_in_currency is null then
        raise exception 'in_fee_in_currency must always be provided.';
    end if;
   
   	-- Automatically set in_fee_asset to in_asset if in_fee_in_asset is provided but in_fee_asset is NULL
    if in_fee_in_asset is not null and in_fee_asset is null then
        in_fee_asset := in_sold_asset;
    end if;
   
    amount_sold_excl_fee := in_total_amount_sold;
    total_amount_bought := in_amount_bought_excl_fee;
    if in_fee_in_asset is not null then
    	if in_fee_asset = in_sold_asset then
    		amount_sold_excl_fee := in_total_amount_sold - in_fee_in_asset;
    		sold_quote_value := in_net_value_after_trade / amount_sold_excl_fee;
    		bought_quote_value := in_net_value_after_trade / total_amount_bought;
    	elsif in_fee_asset = in_bought_asset then
    		total_amount_bought := in_amount_bought_excl_fee + in_fee_in_asset;
    		sold_quote_value := (in_net_value_after_trade + in_fee_in_currency) / in_total_amount_sold;
    		bought_quote_value := in_net_value_after_trade / in_amount_bought_excl_fee;
		else
			sold_quote_value := in_net_value_after_trade / in_total_amount_sold;
			bought_quote_value := in_net_value_after_trade / total_amount_bought;
		end if;
	else
		sold_quote_value := (in_net_value_after_trade + in_fee_in_currency) / in_total_amount_sold;
		bought_quote_value := in_net_value_after_trade / total_amount_bought;
	end if;
	
	-- Insert the trade transaction
    insert into crypto.Transactions (
        DateTime,
        TransactionType,
        Asset,
        CostAsset,
        SoldAsset,
        Amount,
        Costs,
        SoldAmount,
        QuoteValue,
        SoldQuoteValue,
        GrossValue,
        TransactionCost,
        NetValue,
        InvestedValue,
        AmountOpen,
        Description,
        Reference,
        Link
    )
    values (
        in_datetime,											-- DateTime
        'Trade',												-- TransactionType
        in_bought_asset,										-- Asset
        in_fee_asset,											-- CostAsset
        in_sold_asset,											-- SoldAset
        in_amount_bought_excl_fee,								-- Amount
        in_fee_in_asset,										-- Costs
        amount_sold_excl_fee,									-- SoldAmount
        bought_quote_value,										-- QuoteValue
        sold_quote_value,										-- SoldQuoteValue
        in_net_value_after_trade + in_fee_in_currency,			-- GrossValue
        in_fee_in_currency,										-- TransactionCost
        in_net_value_after_trade,								-- NetValue
        in_net_value_after_trade + in_fee_in_currency,			-- InvestedValue
        in_amount_bought_excl_fee,								-- AmountOpen
        in_description,											-- Description
        in_order_reference,										-- Reference
        in_link													-- Link
    ) returning id into trade_transaction_id;
   
    -- Step 2: Handle fee
    if in_fee_in_asset is not null and in_fee_in_asset > 0 and in_fee_asset != in_sold_asset and in_fee_asset != in_bought_asset then
    	perform crypto.reduce_amount_open(
    		in_datetime,
    		in_fee_asset,
    		in_fee_in_asset,
    		trade_transaction_id
    	);
    end if;

    -- Step 3: Find transactions with AmountOpen > 0 in FIFO order and link them
	select cost_basis, trade_cost_basis 
	from crypto.reduce_amount_open(
		in_datetime,
		in_sold_asset,
		in_total_amount_sold,
		trade_transaction_id
	) into cost_basis_info.cost_basis, cost_basis_info.trade_cost_basis;
    
	-- If the fee is payed in a third party currency, we deduct it form the cost basis
	if in_fee_in_asset is not null and in_fee_asset != in_sold_asset and in_fee_asset != in_bought_asset then
		select cost_basis_info.cost_basis + in_fee_in_currency, cost_basis_info.trade_cost_basis + in_fee_in_currency
		into cost_basis_info.cost_basis, cost_basis_info.trade_cost_basis;
    end if;
    
    -- Step 4: Update the Profit/Loss of the trade transaction
    update crypto.Transactions
    set
    	TradeProfitLoss = in_net_value_after_trade - cost_basis_info.trade_cost_basis,
    	CostBasis = cost_basis_info.cost_basis
    where id = trade_transaction_id;
end;
$$;
	