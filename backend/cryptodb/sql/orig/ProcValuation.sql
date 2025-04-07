create or replace procedure crypto.create_valuation(
    in_datetime TIMESTAMP,					-- Date and time of the valuation
    in_asset VARCHAR(8),					-- Asset valued
    in_amount NUMERIC(38, 18),				-- Amount expressed in asset
    in_currentvalue NUMERIC(16, 4),			-- Value expressed in native currency
    in_description text default null,		-- Description (optional)
    in_walletaddress text default null,		-- Wallet address (optional)
    in_link text default null				-- Link to block explorer (optional)
)
language plpgsql
as $$
declare 
	num_transactions_after INTEGER;
begin
	select COUNT(id) into num_transactions_after
	from crypto.Transactions
	where Asset = in_asset
	  and DateTime > in_datetime;
	 
	if num_transactions_after > 0 then
		raise exception 'A valuation can not be performed if we have transactions after the valuation date.';
	end if;
	
    -- Step 1: Close all earlier transactions for this asset
    update crypto.Transactions
    set AmountOpen = 0
    where Asset = in_asset
      and AmountOpen > 0
      and DateTime < in_datetime;

    -- Step 2: Insert the valuation transaction
    insert into crypto.Transactions (
        DateTime,
        TransactionType,
        Asset,
        Amount,
        Costs,
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
        in_datetime,					-- DateTime
        'Valuation',					-- TransactionType
        in_asset,						-- Asset
        in_amount,						-- Amount
        0,                        		-- Costs
        in_currentvalue / in_amount, 	-- QuoteValue
        in_currentvalue,          		-- GrossValue
        0,                       	 	-- TransactionCost
        in_currentvalue,          		-- NetValue
        in_currentvalue,          		-- InvestedValue
        in_currentvalue,				-- CostBasis
        in_amount,                		-- AmountOpen
        in_description,					-- Description
        in_walletaddress,         		-- Reference
        in_link                   		-- Link
    );
end;
$$;
