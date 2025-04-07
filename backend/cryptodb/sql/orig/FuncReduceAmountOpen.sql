create type crypto.cost_basis_info as (cost_basis numeric(16, 4), trade_cost_basis numeric(16, 4));

create or replace function crypto.reduce_amount_open(
	in_datetime TIMESTAMP,		-- Date and time of the transaction causing the amount reduction
	in_asset VARCHAR(8),		-- Asset to be reduced
	in_amount NUMERIC(38, 18),	-- Amount to be reduced
	in_transaction_id INTEGER	-- Id of the transaction causing the amount reduction
)
--returns NUMERIC(16, 4) as $$
returns crypto.cost_basis_info as $$
declare
	cost_basis NUMERIC(16, 4);
	trade_cost_basis NUMERIC(16, 4);
	cb crypto.cost_basis_info;
	remaining NUMERIC(38, 18);
	reduce_amount NUMERIC(38, 18);
	rec RECORD;
begin
	-- Loop over all transactions before in_datetime which have an AmountOpen > 0 for the transaction
	-- We loop in chronological order oldest first so that we apply the FIFO rule for valuation
	-- We then recuce the amount of the encountered transactions until we have allocated the 
	-- requested in_amount. While doing so we calculate the total cost_basis and return that value 
	-- in the end.
	
	cost_basis := 0;
	trade_cost_basis := 0;
	remaining := in_amount;
	for rec in
		select Id, Amount, AmountOpen, QuoteValue, CostBasis
		from crypto.Transactions
		where Asset = in_asset
		  and AmountOpen > 0
		  and DateTime < in_datetime
		order by DateTime asc
	loop
		if remaining <= rec.AmountOpen then
			reduce_amount := remaining;
			remaining := 0;
		else
			reduce_amount := rec.AmountOpen;
			remaining := remaining - reduce_amount;
		end if;
	
		-- Cost basis based on the original purchase
		cost_basis := cost_basis + ((reduce_amount / rec.Amount) * rec.CostBasis);
	
		-- Cost basis based on the cost basis of each trade
		trade_cost_basis := trade_cost_basis + (reduce_amount * rec.QuoteValue);
	
		update crypto.Transactions
		set AmountOpen = AmountOpen - reduce_amount
		where Id = rec.Id;
	
		insert into crypto.TransactionLinks (FromTransactionId, ToTransactionId, Amount)
		values (rec.Id, in_transaction_id, reduce_amount);
	
		exit when remaining = 0;
	end loop;

	if remaining > 0 then
		raise exception 'Not enough open transactions to fulfill the requested amount.';
	end if;

	select cost_basis, trade_cost_basis
	into cb.cost_basis, cb.trade_cost_basis;
	
	return cb;
end;
$$ language plpgsql;