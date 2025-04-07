create or replace procedure crypto.create_fee(
    in_datetime TIMESTAMP,							-- Date and time of the blockchain/exchange operation inducing a fee.
    in_asset VARCHAR(8),							-- Asset of the fee
    in_transaction_fee NUMERIC(38, 18),				-- Fee amount
    in_description TEXT default null,				-- Description (optional)
    in_transaction_reference TEXT default null,		-- Reference to the blockchain transaction or exchange operation (optional)
    in_link TEXT default null						-- Weblink to the blockchain transaction or exchang operation (optional)
)
language plpgsql
as $$
declare
	fee_transaction_id INTEGER;
begin
    -- Initial validation check before starting the transaction
    if in_transaction_fee <= 0 then
    	raise exception 'Transaction fee must be greater than zero.';
    end if;
   
    -- Insert the fee transaction line to link later
    insert into crypto.Transactions (
        DateTime,
        TransactionType,
        Asset,
        Amount,
        Description,
        Reference,
        Link
    )
    values (
        in_datetime,				-- DateTime
        'Fee',						-- TransactionType
        in_asset,					-- Asset
        in_transaction_fee, 		-- Amount
        in_description,				-- Description
        in_transaction_reference,	-- Reference
        in_link						-- Link
    ) returning id into fee_transaction_id;
   
	perform crypto.crypto.reduce_amount_open(
		in_datetime,
		in_asset,
		in_transaction_fee,
		fee_transaction_id
	);
end;
$$;
