create schema if not exists crypto;

create type crypto.TRANSACTIONTYPE as enum ('Valuation', 'Buy', 'Sell', 'Trade', 'Fee', 'Payment');

create table crypto.Transactions (
	Id SERIAL primary key,
	
	DateTime TIMESTAMP not null, 				-- Date and time of the transaction
	
	TransactionType crypto.TRANSACTIONTYPE not null, -- type of the transaction
												--	* Valuation: Valuation of the current state (Will be used then as a 0 point to calculate gains against)
												--  * Buy: Buy order from native currency to crypto
												--  * Sell: Sell order form crypto to native currency
												--  * Trade: Trade between 2 crypto's
												--  * Fee: Transaction fee on the blockchain (used to track fee's)
												--  * Payment: Direct crypto payment
	
	Asset VARCHAR(8) default null,					-- Asset of the trade (Crypto asset)
												--  * Valuation: The valued asset
												--  * Buy: The bouhgt asset
												--  * Sell: The sold asset
												--  * Trade: The assed bought
												--  * Fee: The assed transacted
												--  * Payment: The asset used for the payment
	
	CostAsset VARCHAR(8) default null,			-- Asset of the cost (Crypto asset).
												-- This asset can be totally unrelated to the Asset or SoldAsset field, as exchanges
												-- can use a specific asset to pay for fees.
												--  * Valuation: null
												--  * Buy: The asset used to pay the costs (null when in native currency)
												--  * Sell: The asset used to pay the costs (null when in native currency)
												--  * Trade: The asset used to pay the costs (null when in native currency)
												--  * Fee: null
												--  * PAyment: The aset used to pay the costs (null when in native currency)
	
	SoldAsset VARCHAR(8) default null,			-- only in case of Trade, The asset sold
	
	Amount NUMERIC(38,18) default null,			-- Amount expressed in the Asset type (Fee: amount of the fee)
	
	Costs NUMERIC(38,18) default 0,				-- Costs expressed in the Asset type
	
	SoldAmount NUMERIC(38,18) default null,		-- only in case of Trade, Amount expressed in the Soldasset type
	
	QuoteValue NUMERIC(16,4) default null,		-- quote value of the asset in native currency
	
	SoldQuoteValue NUMERIC(16, 4) default null,	-- only in case of trade.
												-- quote value of the sold asset
	
	GrossValue NUMERIC(16,4) default null,		-- Gross Value of the transaction in the native currency
												--  * Valuation: Value of the Base Asset
												--  * Buy: Value of the buy (native assets spent)
												--  * Sell: Value of the sold asset
												--  * Trade: Value of the sold asset (current valuation of the sold asset)
												--  * Fee: 0
												--  * Payment: Value of the asset used as payment
	
	TransactionCost NUMERIC(16, 4) default null,-- cost of the transaction in the native currency
												--  * Valuation: 0
												--  * Buy: Cost of the buy order
												--  * Sell: Cost of the sell order
												--  * Trade: Cost of the trade
												--  * Fee: 0
												--  * Payment: Payment costs
	
	NetValue NUMERIC(16, 4) default null,		-- Net Value of the transaction in the native currency
												--  * Valuation: Value of the Base Asset
												--  * Buy: Value of the bought asset
												--  * Sell: Value of the sell (native asset)
												--  * Trade: Value of the sell (bought asset)
												--  * Fee: 0
												--  * Payment: Value of payment after costs
	
	InvestedValue NUMERIC(16, 4) default 0,	    -- Value of the investment
												--  * Valuation: equals to NetValue
												--  * Buy: equals to GrossValue
												--  * Sell: 0
												--  * Trade: equals to the NetValue
												--  * Payment: 0
	
	CostBasis NUMERIC(16, 4) default 0,			-- Original cost basis of the investment (since the original Buy from native asset)
												--  * Valuation: equals to NetValue
												--  * Buy: equals to GrossValue
												--  * Sell: 0
												--  * Trade: The CostBasis of the previous record times the percentace traded of it + fee's if payed in native currency or third party currency.
												--  * Fee: 0
												--  * Payment: 0
	
	TradeProfitLoss NUMERIC(16,4) default 0,	-- Profit / Loss of the transaction in the native currency
												--  * Valuation: 0
												--  * Buy: 0
												--  * Sell: Profit / loss based on FIFO
												--  * Trade: Profit / loss based on FIFO
												--  * Fee: 0
												--  * Payment: Profit /loss baed on FIFO
	
	ProfitLoss NUMERIC(16, 4) default 0,		-- Profit / Loss of the transaction based original investment in native currency
												--  * Valuation: 0
												--  * Buy: 0
												--  * Sell: The CostBasis of the previous record times the percentage sold of it.
												--  * Trade: 0
												--  * Fee: 0
												--  * Payment: The CostBasis of the previous record times the percentage payed with.
	
	AmountOpen NUMERIC(38,18) default null,		-- Amount still open in this transaction
												-- Used to track how much of this transaction has been closed to calculate profit loss
												-- We will use FIFO for this
												--  * Valuation: Amount open of the valued assed (Asset)
												--  * Buy: ammount open of the bought asset (Asset)
												--  * Sell: null
												--  * Trade: amount open of the bought asset (Asset)
												--  * Fee: null
												--  * Payment: null
	
	Description text default null,				-- Description of the transaction
	
	Reference text default null,				-- Reference to the transaction
	
	Link text default null						-- Link to the transaction
);
create index idx_crypto_transactions_datetime ON crypto.Transactions (DateTime);
create index idx_crypto_transactions_asset ON crypto.Transactions (Asset);

-- Check constraints
alter table crypto.Transactions
add constraint chk_asset check (
	TransactionType not in ('Valuation', 'Buy', 'Trade') or Asset is not null
);
alter table crypto.Transactions
add constraint chk_amount check (
	TransactionType not in ('Valuation', 'Buy', 'Trade') or Amount is not null
);
alter table crypto.Transactions
add constraint chk_soldasset check (
    TransactionType not in ('Sell', 'Trade', 'Payment') or SoldAsset is not null
);
alter table crypto.Transactions
add constraint chk_soldamount check (
    TransactionType not in ('Sell', 'Trade', 'Payment') or SoldAmount is not null
);
alter table crypto.Transactions
add constraint chk_transactioncost check (
	TransactionType not in ('Valuation', 'Fee') or TransactionCost = 0
);
alter table crypto.Transactions
add constraint chk_profitloss check (
	TransactionType not in ('Valuation', 'Buy', 'Fee') or ProfitLoss = 0
);
alter table crypto.transactions 
add constraint chk_costasset check (
	TransactionType not in ('Valuation', 'Fee') or CostAsset is null
);

-- Automatically set amountopen and InvestedValue
create or replace function crypto.set_initial_amount_open_invested_value()
returns trigger as $$
begin
    if new.TransactionType in ('Valuation', 'Buy', 'Trade') then
        new.AmountOpen := new.Amount;
    else
        new.AmountOpen := null;
    end if;

    if new.TransactionType in ('Valuation', 'Trade') then
        new.InvestedValue :=  new.NetValue;
   	elsif new.TransactionType = 'Buy' then
        new.InvestedValue := new.GrossValue;
    end if;

    return new;
end;
$$ language plpgsql;


create trigger trigger_set_initial_amount_open_invested_value
before insert on crypto.Transactions
for each row
execute function crypto.set_initial_amount_open_invested_value();

create table crypto.TransactionLinks (
	Id SERIAL primary KEY,

	FromTransactionId INTEGER,					-- Links to initial transaction
												-- e.g. Valuation, Buy, Trade
	
	ToTransactionId INTEGER,					-- Links to matched transaction
												-- e.g. Sell, Trade, Fee
	
	Amount NUMERIC(38,18),						-- Amount of the initial transaction that is used by the linked transaction
	
	foreign key (FromTransactionId) references crypto.Transactions(id)
		on delete cascade
		on update cascade,
	foreign key (ToTransactionId) references crypto.Transactions(id)
		on delete cascade
		on update cascade
);

-- Check constraints
alter table crypto.TransactionLinks
add constraint chk_links_not_same check (
	FromTransactionId != ToTransactionId
);
alter table crypto.TransactionLinks
add constraint chk_amount_larger_zero check (
	Amount > 0
);

-- Validate that the ToTransaction is later in date as the FromTransaction
create or replace function crypto.validate_transaction_link_timing()
returns trigger as $$
declare
	from_datetime TIMESTAMP;
	to_datetime TIMESTAMP;
begin
	select DateTime into from_datetime
	from crypto.Transactions
	where Id = new.FromTransactionId;

	select datetime into to_datetime
	from crypto.Transactions
	where Id = new.ToTransactionId;

	if to_datetime <= from_datetime then
		raise exception 'ToTransaction (%s) must occur later than FromTransaction (%s)',
			new.ToTransactionId, new.FromTransactionId;
	end if;
	return new;
end;
$$ language plpgsql;

create trigger trigger_validate_transaction_link_timing
before insert or update on crypto.TransactionLinks
for each row 
execute function crypto.validate_transaction_link_timing();

create table crypto.Settings (
	Id SERIAL primary key,
	SettingsName VARCHAR(64) not null,
	SettingsValue text,
	constraint uq_settings_settings_name unique(SettingsName)
);

-- Default settings
insert into crypto.Settings (
	SettingsName, SettingsValue
) values (
	'ProfitLossType', 'EachTransaction'			-- Can be 'EachTransaction' or 'SellOnly'
);

update crypto.Settings
set
	settingsValue = 'SellOnly'
where SettingsName = 'ProfitLossType';

update crypto.Settings
set
	settingsValue = 'EachTransaction'
where SettingsName = 'ProfitLossType';

