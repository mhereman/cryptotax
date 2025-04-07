delete from crypto.TransactionLinks;
delete from crypto.Transactions;

select * from crypto.Transactions;
select * from crypto.TransactionLinks;

--------------------------------------------------------

-- valuation after buy --> Should clear out amount open

call crypto.create_buy(
	'2024-12-01 12:20:00',		-- DateTime
	'BTC',						-- Asset
	1.5,						-- Amount excl fee
	(1.5 + 0.0001) * 100000,	-- Total payed
	0.0001 * 100000,			-- Fee in eur
	0.0001						-- Fee in asset
);
call crypto.create_valuation(
	'2024-12-02 00:00:00',		-- DateTime
	'BTC',						-- Asset
	1.5,						-- Amount
	162000,						-- Value
	'Valuation'
);
select 'amountopen previous' as field, amountopen = 0 as isok, 0 as expected, amountopen as value
from crypto.transactions
where datetime = '2024-12-01 12:20:00' and asset = 'BTC'
union 
select 'amountopen current' as field, amountopen = 1.5 as isok, 1.5 as expected, amountopen as value
from crypto.transactions
where datetime = '2024-12-02 00:00:00' and asset = 'BTC'
union 
select 'quotevalue', quotevalue = 100000, 100000, quotevalue
from crypto.transactions
where datetime = ' 2024-12-01 12:20:00' and asset = 'BTC'
;

--------------------------------------------------------

-- Buy (fee in native currency, fee in BTC, fee in BNB)

call crypto.create_valuation(
	'2024-12-03 00:00:00',		-- DateTime
	'BNB',						-- Asset
	10,							-- Amount
	10 * 620,					-- Value
	'Valuation BNB 2024-12-03'
);
call crypto.create_buy(
	'2024-12-03 10:00:00',		-- DateTime
	'BTC',						-- Asset
	0.5,						-- Amount excl fee
	50025,						-- Total payed
	25,							-- fee in eur
	null, null,					-- Fee in asset, Fee Asset
	'Buy (fee payed with euro)'
);
call crypto.create_buy(
	'2024-12-03 10:10:00',		-- DateTime
	'BTC',						-- Asset
	0.5,						-- Amount excl fee
	(0.5 + 0.00001) * 100000,	-- Total payed
	0.00001 * 100000,			-- Fee in eur
	0.00001,					-- Fee in asset
	null,						-- Fee asset
	'Buy (fee payed with BTC)'
);
call crypto.create_buy(
	'2024-12-03 10:20:00',		-- DateTime
	'BTC',						-- Asset
	0.5,						-- Amount excl fee
	500000 + (0.1 * 550),		-- Total payed
	0.1 * 550,					-- Fee in eur
	0.1,						-- Fee in asset
	'BNB',						-- Fee asset
	'Buy (fee payed with BNB)'
);
select 'grossvalue (native fee)' as field, grossvalue = 50025, 50025 as expected, grossvalue as value
from crypto.transactions
where datetime = '2024-12-03 10:00:00' and asset = 'BTC'
union
select 'transactioncost (native fee)', transactioncost = 25, 25, transactioncost
from crypto.transactions
where datetime = '2024-12-03 10:00:00' and asset = 'BTC'
union 
select 'netvalue (native fee)', netvalue = 50000, 50000, netvalue
from crypto.transactions
where datetime = '2024-12-03 10:00:00' and asset = 'BTC'
union 
select 'quotevalue (native fee)', quotevalue = ((50025 - 25) / 0.5)::numeric(16, 4), ((50025 - 25) / 0.5)::numeric(16, 4), quotevalue
from crypto.transactions
where datetime = '2024-12-03 10:00:00' and asset = 'BTC'
union 
select 'grossvalue (BTC fee)', grossvalue = ((0.5 + 0.00001) * 100000)::numeric(16, 4), ((0.5 + 0.00001) * 100000)::numeric(16, 4), grossvalue
from crypto.transactions
where datetime = '2024-12-03 10:10:00' and asset = 'BTC'
union 
select 'transactioncost (BTC fee)', transactioncost = (0.00001 * 100000)::numeric(16, 4), (0.00001 * 100000)::numeric(16, 4), transactioncost
from crypto.transactions
where datetime = '2024-12-03 10:10:00' and asset = 'BTC'
union 
select 'netvalue (BTC fee)', netvalue = (0.5 * 100000)::numeric(16, 4), (0.5 * 100000)::numeric(16, 4), netvalue
from crypto.transactions
where datetime = '2024-12-03 10:10:00' and asset = 'BTC'
union
select 'quotevalue (BTC fee)', quotevalue = 100000, 100000, quotevalue
from crypto.transactions
where datetime = '2024-12-03 10:10:00' and asset = 'BTC'
union
select 'grossvalue (BNB fee)', grossvalue = (500000 + (0.1 * 550))::numeric(16, 4), (500000 + (0.1 * 550))::numeric(16, 4), grossvalue
from crypto.transactions
where datetime = '2024-12-03 10:20:00' and asset = 'BTC'
union 
select 'transactioncost (BNB fee)', transactioncost = (0.1 * 550)::numeric(16, 4), (0.1 * 550)::numeric(16, 4), transactioncost
from crypto.transactions
where datetime = '2024-12-03 10:20:00' and asset = 'BTC'
union 
select 'netvalue (BNB fee)', netvalue = 500000, 500000, netvalue
from crypto.transactions
where datetime = '2024-12-03 10:20:00' and asset = 'BTC'
union 
select 'quotevalue (BNB fee)', quotevalue = 1000000, 1000000, quotevalue
from crypto.transactions
where datetime = '2024-12-03 10:20:00' and asset = 'BTC'
union 
select 'amount open (BNB)', amountopen = 9.9, 9.9, amountopen
from crypto.transactions
where datetime = '2024-12-03 00:00:00' and asset = 'BNB'
;

--------------------------------------------------------

-- simple valuation --> complete sell (fee in native currency)

call crypto.create_valuation(
	'2024-12-04 00:00:00',		-- DateTime
	'BTC',						-- Asset
	2.04993724,					-- Amount
	2.04993724 * 90167.3,		-- Value
	'Valuation BTC 2024-12-04'
);
call crypto.create_sell(
	'2024-12-04 12:00:00',		-- DateTime
	'BTC',						-- Asset
	2.04993724,					-- Amount Sold (incl fee)
	192603.7,					-- net value received
	100.0,						-- fee in native currency
	null, null,					-- fee in asset, fee asset
	'Sell all BTC'
);
select 'amountopen' as field, amountopen = 0 as isok, 0 as expected, amountopen as value
from crypto.Transactions
where datetime = '2024-12-04 00:00:00' and asset = 'BTC'
union
select 'TradeProfitLoss', TradeProfitLoss = (192603.7 - (2.04993724 * 90167.3))::numeric(16,4), (192603.7 - (2.04993724 * 90167.3))::numeric(16, 4), TradeProfitLoss
from crypto.Transactions
where datetime = '2024-12-04 12:00:00' and soldasset = 'BTC'
union
select 'grossvalue', grossvalue = (192603.7 + 100)::numeric(16, 4), (192603.7 + 100)::numeric(16, 4), grossvalue
from crypto.Transactions
where datetime = '2024-12-04 12:00:00' and soldasset = 'BTC'
union 
select 'transactioncost', transactioncost = (100)::numeric(16, 4), (100)::numeric(16, 4), transactioncost
from crypto.Transactions
where datetime = '2024-12-04 12:00:00' and soldasset = 'BTC'
union
select 'netvalue', netvalue = (192603.7)::numeric(16, 4), (192603.7)::numeric(16, 4), netvalue
from crypto.Transactions
where datetime = '2024-12-04 12:00:00' and soldasset = 'BTC'
union 
select 'quotevalue', quotevalue = ((192603.7 + 100) / 2.04993724)::numeric(16, 4), ((192603.7 + 100) / 2.04993724)::numeric(16, 4), quotevalue
from crypto.Transactions
where datetime = '2024-12-04 12:00:00' and soldasset = 'BTC'
;

--------------------------------------------------------

-- simple valuation --> complete sell (fee in crypto)

call crypto.create_valuation(
	'2024-12-05 00:00:00',		-- DateTime
	'BTC',						-- Asset
	2.04993724,					-- Amount
	2.04993724 * 90167.3,		-- Value
	'Valuation BTC 2024-12-05'
);
call crypto.create_sell(
	'2024-12-05 12:00:00',		-- DateTime
	'BTC',						-- Asset
	2.04993724,					-- Amount sold (incl fee)
	2.0499 * 94320.3,			-- Net value received
	0.00003724 * 94320.3,		-- fee in native currency
	0.00003724,					-- fee in asset
	'BTC',						-- fee asset
	'Sell all BTC'
);
select 'amountopen' as field, amountopen = 0 as isok, 0 as expected, amountopen as value
from crypto.Transactions
where datetime = '2024-12-05 00:00:00' and asset = 'BTC'
union
select 'TradeProfitLoss', TradeProfitLoss = ((2.0499 * 94320.3) - (2.04993724 * 90167.3))::numeric(16, 4), ((2.0499 * 94320.3) - (2.04993724 * 90167.3))::numeric(16, 4), TradeProfitLoss
from crypto.Transactions
where datetime = '2024-12-05 12:00:00' and soldasset = 'BTC'
union
select 'grossvalue', grossvalue = (2.04993724 * 94320.3)::numeric(16, 4), (2.04993724 * 94320.3)::numeric(16, 4), grossvalue
from crypto.Transactions
where datetime = '2024-12-05 12:00:00' and soldasset = 'BTC'
union 
select 'transactioncost', transactioncost = (0.00003724 * 94320.3)::numeric(16, 4), (0.00003724 * 94320.3)::numeric(16, 4), transactioncost
from crypto.Transactions
where datetime = '2024-12-05 12:00:00' and soldasset = 'BTC'
union
select 'netvalue', netvalue = (2.0499 * 94320.3)::numeric(16, 4), (2.0499 * 94320.3)::numeric(16, 4), netvalue
from crypto.Transactions
where datetime = '2024-12-05 12:00:00' and soldasset = 'BTC'
union 
select 'quotevalue', quotevalue = 94320.3, 94320.3, quotevalue
from crypto.Transactions
where datetime = '2024-12-05 12:00:00' and soldasset = 'BTC'
;

--------------------------------------------------------

-- simple valuation --> complete sell (fee in unrelated crypto)

call crypto.create_valuation(
	'2024-12-06 00:00:00',		-- DateTime
	'BTC',						-- Asset
	2.04993724,					-- Amount
	2.04993724 * 90167.3,		-- Value
	'Valuation BTC 2024-12-06'
);
call crypto.create_valuation(
	'2024-12-06 00:00:00',		-- DateTime
	'BNB',						-- Asset
	10,							-- Amount
	10 * 620,					-- Value
	'Valuation BNB 2024-12-06'
);
call crypto.create_sell(
	'2024-12-06 12:00:00',		-- DateTime
	'BTC',						-- Asset
	2.04993724,					-- Amount sold (incl fee)
	2.04993724 * 94320.3,		-- Net value received
	62.0,						-- fee in native currency
	0.1,						-- fee in asset
	'BNB',						-- fee asset
	'Sell all BTC'
);
select 'amountopen - BTC' as field, amountopen = 0 as isok, 0 as expected, amountopen as value
from crypto.Transactions
where datetime = '2024-12-06 00:00:00' and asset = 'BTC'
union
select 'amountopen - BNB' as field, amountopen = 9.9::NUMERIC(38, 18) as isok, 0 as expected, amountopen as value
from crypto.Transactions
where datetime = '2024-12-06 00:00:00' and asset = 'BNB'
union
select 'TradeProfitLoss', TradeProfitLoss = ((2.04993724 * 94320.3) - (2.04993724 * 90167.3) - 62.0)::numeric(16, 4), ((2.04993724 * 94320.3) - (2.04993724 * 90167.3) - 62.0)::numeric(16, 4), TradeProfitLoss
from crypto.Transactions
where datetime = '2024-12-06 12:00:00' and soldasset = 'BTC'
union
select 'grossvalue', grossvalue = ((2.04993724 * 94320.3) + 62.0)::numeric(16, 4), ((2.04993724 * 94320.3) + 62.0)::numeric(16, 4), grossvalue
from crypto.Transactions
where datetime = '2024-12-06 12:00:00' and soldasset = 'BTC'
union 
select 'transactioncost', transactioncost = 62.0::numeric(16, 4), 62.0::numeric(16, 4), transactioncost
from crypto.Transactions
where datetime = '2024-12-06 12:00:00' and soldasset = 'BTC'
union
select 'netvalue', netvalue = (2.04993724 * 94320.3)::numeric(16, 4), (2.04993724 * 94320.3)::numeric(16, 4), netvalue
from crypto.Transactions
where datetime = '2024-12-06 12:00:00' and soldasset = 'BTC'
union 
select 'quotevalue', quotevalue = 94320.3, 94320.3, quotevalue
from crypto.Transactions
where datetime = '2024-12-06 12:00:00' and soldasset = 'BTC'
;

-----------------------------------------------------------------

-- simple valuation --> sell in multiple parts (fee in native currency)

call crypto.create_valuation(
	'2024-12-07 00:00:00',		-- DateTime
	'BTC',						-- Asset
	2.04993724,					-- Amount
	2.04993724 * 90167.3,		-- Value
	'Valuation BTC 2024-12-07'
);
call crypto.create_sell(
	'2024-12-07 12:00:00',		-- DateTime
	'BTC',						-- Asset
	0.6,						-- Total amount sold (incl fee)
	0.6 * 95186.2,				-- Net value received
	15.5,						-- Fee in native currency
	null, null,					-- Fee in asset, fee asset
	'Sell 0.6 BTC'
);
call crypto.create_sell(
	'2024-12-07 12:10:00',		-- DateTime
	'BTC',						-- Asset
	1.0,						-- Total amount sold (incl fee)
	1.0 * 96841.13,				-- Net value received
	16.1,						-- Fee in native currency
	null, null,					-- Fee in asset, fee asset
	'Sell 1.0 BTC'
);
select 'amountopen' as field, amountopen = (2.04993724 - 0.6 - 1.0) as isok, (2.04993724 - 0.6 - 1.0) as expected, amountopen as value
from crypto.Transactions
where datetime = '2024-12-07 00:00:00' and asset = 'BTC'
union 
select 'TradeProfitLoss - Sell 1', TradeProfitLoss = ((0.6 * 95186.2) - (0.6 * 90167.3))::numeric(16, 4), ((0.6 * 95186.2) - (0.6 * 90167.3))::numeric(16, 4), TradeProfitLoss
from crypto.Transactions
where datetime = '2024-12-07 12:00:00' and soldasset = 'BTC'
union 
select 'quotevalue - Sell 1', quotevalue = (95186.2 + (15.5 / 0.6))::numeric(16, 4), (95186.2 + (15.5 / 0.6))::numeric(16, 4), quotevalue
from crypto.Transactions
where datetime = '2024-12-07 12:00:00' and soldasset = 'BTC'
union
select 'TradeProfitLoss- Sell 2', TradeProfitLoss = ((1.0 * 96841.13) - (1.0 * 90167.3))::numeric(16, 4), ((1.0 * 96841.13) - (1.0 * 90167.3))::numeric(16, 4), TradeProfitLoss
from crypto.Transactions
where datetime = '2024-12-07 12:10:00' and soldasset = 'BTC'
union 
select 'quotevalue - Sell 2', quotevalue = 96841.13 + 16.1, 96841.13 + 16.1, quotevalue
from crypto.Transactions
where datetime = '2024-12-07 12:10:00' and soldasset = 'BTC'
;

------------------------------------------------------------------

-- simple valuation --> sell in multiple parts (fee in asset)

call crypto.create_valuation(
	'2024-12-08 00:00:00',		-- DateTime
	'BTC',						-- Asset
	2.04993724,					-- Amount
	2.04993724 * 90167.3,		-- Value
	'Valuation BTC 2024-12-08'
);
call crypto.create_sell(
	'2024-12-08 12:00:00',		-- DateTime
	'BTC',						-- Asset
	0.6,						-- Total amount sold (incl fee)
	(0.6 - 0.0001) * 95186.2,	-- Net value received
	0.0001 * 95186.2,			-- Fee in native currency
	0.0001, null,				-- Fee in asset, fee asset
	'Sell 0.6 BTC'
);
call crypto.create_sell(
	'2024-12-08 12:10:00',		-- DateTime
	'BTC',						-- Asset
	1.0,						-- Total amount sold (incl fee)
	(1.0 - 0.00014) * 96841.13,	-- Net value received
	0.00014 * 96841.13,			-- Fee in native currency
	0.00014, null,					-- Fee in asset, fee asset
	'Sell 1.0 BTC'
);
select 'amountopen' as field, amountopen = (2.04993724 - 0.6 - 1.0) as isok, (2.04993724 - 0.6 - 1.0) as expected, amountopen as value
from crypto.Transactions
where datetime = '2024-12-08 00:00:00' and asset = 'BTC'
union 
select 'TradeProfitLoss - Sell 1', TradeProfitLoss = (((0.6 - 0.0001) * 95186.2) - (0.6 * 90167.3))::numeric(16, 4), (((0.6 - 0.0001) * 95186.2) - (0.6 * 90167.3))::numeric(16, 4), TradeProfitLoss
from crypto.Transactions
where datetime = '2024-12-08 12:00:00' and soldasset = 'BTC'
union
select 'quotevalue - Sell 1', quotevalue = 95186.2, 95186.2, quotevalue
from crypto.Transactions
where datetime = '2024-12-08 12:00:00' and soldasset = 'BTC'
union
select 'TradeProfitLoss- Sell 2', TradeProfitLoss = (((1.0 - 0.00014) * 96841.13) - (1.0 * 90167.3))::numeric(16, 4), (((1.0 - 0.00014) * 96841.13) - (1.0 * 90167.3))::numeric(16, 4), TradeProfitLoss
from crypto.Transactions
where datetime = '2024-12-08 12:10:00' and soldasset = 'BTC'
union
select 'quotevalue - Sell 2', quotevalue = 96841.13, 96841.13, quotevalue
from crypto.Transactions
where datetime = '2024-12-08 12:10:00' and soldasset = 'BTC'
;

-------------------------------------------------------------------

-- simple valuation --> sell in multiple parts (fee in other asset)

call crypto.create_valuation(
	'2024-12-09 00:00:00',		-- DateTime
	'BTC',						-- Asset
	2.04993724,					-- Amount
	2.04993724 * 90167.3,		-- Value
	'Valuation BTC 2024-12-09'
);
call crypto.create_valuation(
	'2024-12-09 00:00:00',		-- DateTime
	'BNB',						-- Asset
	10,							-- Amount
	10 * 620,					-- Value
	'Valuation BNB 2024-12-09'
);
call crypto.create_sell(
	'2024-12-09 12:00:00',		-- DateTime
	'BTC',						-- Asset
	0.6,						-- Total amount sold (incl fee)
	(0.6 * 95186.2),	-- Net value received
	0.8 * 532,					-- Fee in native currency
	0.8,						-- Fee in asset
	'BNB',						-- Fee asset
	'Sell 0.6 BTC'
);
call crypto.create_sell(
	'2024-12-09 12:10:00',		-- DateTime
	'BTC',						-- Asset
	1.0,						-- Total amount sold (incl fee)
	(1.0 * 96841.13),	-- Net value received
	1.13 * 533,					-- Fee in native currency
	1.13,						-- Fee in asset
	'BNB',						-- Fee asset
	'Sell 1.0 BTC'
);
select 'amountopen - BTC' as field, amountopen = (2.04993724 - 0.6 - 1.0) as isok, (2.04993724 - 0.6 - 1.0) as expected, amountopen as value
from crypto.Transactions
where datetime = '2024-12-09 00:00:00' and asset = 'BTC'
union 
select 'amountopen - BNB' as field, amountopen = (10 - 0.8 - 1.13) as isok, (10 - 0.8 - 1.13) as expected, amountopen as value
from crypto.Transactions
where datetime = '2024-12-09 00:00:00' and asset = 'BNB'
union 
select 'TradeProfitLoss - Sell 1', TradeProfitLoss = ((0.6 * 95186.2) - ((0.6 * 90167.3) + (0.8 * 532)))::numeric(16, 4), ((0.6 * 95186.2) - ((0.6 * 90167.3) + (0.8 * 532)))::numeric(16, 4), TradeProfitLoss
from crypto.Transactions
where datetime = '2024-12-09 12:00:00' and soldasset = 'BTC'
union
select 'quotevalue - Sell 1', quotevalue = 95186.2, 95186.2, quotevalue
from crypto.Transactions
where datetime = '2024-12-09 12:00:00' and soldasset = 'BTC'
union
select 'TradeProfitLoss - Sell 2', TradeProfitLoss = ((1.0 * 96841.13) - ((1.0 * 90167.3) + (1.13 * 533)))::numeric(16, 4), ((1.0 * 96841.13) - ((1.0 * 90167.3) + (1.13 * 533)))::numeric(16, 4), TradeProfitLoss
from crypto.Transactions
where datetime = '2024-12-09 12:10:00' and soldasset = 'BTC'
union 
select 'quotevalue - Sell 2', quotevalue = 96841.13, 96841.13, quotevalue
from crypto.Transactions
where datetime = '2024-12-09 12:10:00' and soldasset = 'BTC'
;

--------------------------------------------------------------------

-- simple valuation --> payments

call crypto.create_valuation(
	'2024-12-10 00:00:00',		-- DateTime
	'BTC',						-- Asset
	2.04993724,					-- Amount
	2.04993724 * 90167.3,		-- Value
	'Valuation BTC 2024-12-10'
);
call crypto.create_valuation(
	'2024-12-10 00:00:00',		-- DateTime
	'BNB',						-- Asset
	10,							-- Amount
	10 * 620,					-- Value
	'Valuation BNB 2024-12-09'
);
call crypto.create_payment(
	'2024-12-10 12:00:00',		-- DateTime
	'BTC',						-- Asset
	0.00025,					-- Amount
	(0.00025 * 102459.12) - 0.13,		-- Net payment value
	0.13,	-- Fee in currency
	null, null,
	'Payment (Fee in currency)'
);
call crypto.create_payment(
	'2024-12-10 12:10:00',		-- DateTime
	'BTC',						-- Asset
	0.00025 + 0.00001,			-- Amount
	0.00025 * 102459.12,		-- Net payment value
	0.00001 * 102459.12,		-- Fee in currency
	0.00001,					-- Fee in asset
	'BTC',						-- Fee asset
	'Payment (Fee in BTC)'
);
call crypto.create_payment(
	'2024-12-10 12:20:00',		-- DateTime
	'BTC',						-- Asset
	0.00025,					-- Amount
	0.00025 * 102459.12,		-- Net payment value
	0.001 * 584,				-- Fee in currency
	0.001,						-- Fee in asset
	'BNB',						-- Fee asset
	'Payment (Fee in BNB)' 
);
select 'amountopen - BTC' as field, amountopen = (2.04993724 - 0.00025 - 0.00025 - 0.00001 - 0.00025)::numeric(38, 18) as isok, (2.04993724 - 0.00025 - 0.00025 - 0.00001 - 0.00025)::numeric(38, 18) as excpected, amountopen as value
from crypto.Transactions
where DateTime = '2024-12-10 00:00:00' and asset = 'BTC'
union 
select 'amountopen - BNB' as field, amountopen = (10 - 0.001)::numeric(38, 18), (10 - 0.001)::numeric(38, 18), amountopen
from crypto.Transactions
where DateTime = '2024-12-10 00:00:00' and asset = 'BNB'
union 
select 'TradeProfitLoss - Sell 1', TradeProfitLoss = (((0.00025 * 102459.12) - 0.13) - (0.00025 * 90167.3))::numeric(16, 4), (((0.00025 * 102459.12) - 0.13) - (0.00025 * 90167.3))::numeric(16, 4), TradeProfitLoss
from crypto.Transactions
where DateTime = '2024-12-10 12:00:00' and soldasset = 'BTC'
union 
select 'quotevalue - Sell 1', quotevalue = 102459.12, 102459.12, quotevalue
from crypto.Transactions
where DateTime = '2024-12-10 12:00:00' and soldasset = 'BTC'
union 
select 'TradeProfitLoss - Sell 2', TradeProfitLoss = ((0.00025 * 102459.12) - ((0.00025 + 0.00001) * 90167.3))::numeric(16, 4), ((0.00025 * 102459.12) - ((0.00025 + 0.00001) * 90167.3))::numeric(16, 4), TradeProfitLoss
from crypto.Transactions
where DateTime = '2024-12-10 12:10:00' and soldasset = 'BTC'
union 
select 'quotevalue - Seel 2', quotevalue = 102459.12, 102459.12, quotevalue
from crypto.Transactions
where DateTime = '2024-12-10 12:10:00' and soldasset = 'BTC'
union 
select 'TradeProfitLoss - Sell 3', TradeProfitLoss = ((0.00025 * 102459.12) - (0.00025 * 90167.3) - (0.001 * 584))::numeric(16, 4), ((0.00025 * 102459.12) - (0.00025 * 90167.3) - (0.001 * 584))::numeric(16, 4), TradeProfitLoss
from crypto.Transactions
where DateTime = '2024-12-10 12:20:00' and soldasset = 'BTC'
union 
select 'quotevalue - Sell 3', quotevalue = 102459.12, 102459.12, quotevalue
from crypto.Transactions
where DateTime = '2024-12-10 12:20:00' and soldasset = 'BTC'
;


--------------------------------------------------------------------

-- simple valuation --> trade

call crypto.create_valuation(
	'2024-12-11 00:00:00',		-- DateTime
	'BTC',						-- Asset
	2.04993724,					-- Amount
	2.04993724 * 90167.3,		-- Value
	'Valuation BTC 2024-12-10'
);
call crypto.create_valuation(
	'2024-12-11 00:00:00',		-- DateTime
	'BNB',						-- Asset
	10,							-- Amount
	10 * 620,					-- Value
	'Valuation BNB 2024-12-09'
);
call crypto.create_trade(
	'2024-12-11 12:05:00',		-- DateTime
	'BTC',						-- Sold asset
	0.2,						-- Amount sold
	'ETH',						-- Bought asset
	32.36,						-- Amount bought
	19666.42,					-- Net value after trade
	1.34,						-- Fee in native currency
	null, null,					-- Fee in asset, Fee asset
	'Trade (Fee in native currency)'
);
call crypto.create_trade(
	'2024-12-11 12:10:00',		-- DateTime
	'BTC',						-- Sold asset
	0.2001,						-- Amount sould
	'ETH',						-- Bought asset
	32.36,						-- Amount bought
	19666.42,					-- Net value after trade
	0.0001 * 98332.08,			-- Fee in native currency
	0.0001,						-- Fee in asset
	'BTC',						-- Fee asset
	'Trade (fee in BTC)'
);
call crypto.create_trade(
	'2024-12-11 12:20:00',		-- DateTime
	'BTC',						-- Sold asset
	0.2,						-- Amount sold
	'ETH',						-- Bought asset
	32.36,						-- Amount bought
	19666.42,					-- Net value after trade
	1.2155,						-- Fee in native currency
	0.002,						-- Fee in asset
	'ETH',						-- Fee asset
	'Trade (fee in ETH)'
);
call crypto.create_trade(
	'2024-12-11 12:30:00',
	'BTC',
	0.2,
	'ETH',
	32.36,
	19666.42,
	0.001 * 584,
	0.001,
	'BNB',
	'Trade (fee in BNB)'
);
call crypto.create_sell(
	'2024-12-11 12:40:00',
	'ETH',
	50.00,
	50 * 2700.75,
	1.25,
	null, null,
	'Sell 50 ETH'
);
call crypto.create_sell(
	'2024-12-11 12:40:00',
	'ETH',
	79.4,
	79.4 * 2688.75,
	0.04 * 2688.75,
	0.04, 'ETH',
	'Sell remaining ETH (fee in ETH)'
);
select 'amountopen - BTC' as field, amountopen = (2.04993724 - 0.2 - 0.2001 - 0.2 - 0.2)::numeric(38, 18) as isok, (2.04993724 - 0.2 - 0.2001 - 0.2 - 0.2)::numeric(38, 18) as excpected, amountopen as value
from crypto.Transactions
where DateTime = '2024-12-11 00:00:00' and asset = 'BTC'
union 
select 'amountopen - BNB' as field, amountopen = (10 - 0.001)::numeric(38, 18), (10 - 0.001)::numeric(38, 18), amountopen
from crypto.Transactions
where DateTime = '2024-12-11 00:00:00' and asset = 'BNB'
union
select 'amountopen - ETH Buy 1', amountopen = 32.36, 32.36, amountopen
from crypto.Transactions
where DateTime = '2024-12-11 12:05:00' and asset = 'ETH'
union 
select 'TradeProfitLoss - ETH Buy 1', TradeProfitLoss = (19666.42 - (0.2 * 90167.3)), (19666.42 - (0.2 *90167.3)), TradeProfitLoss
from crypto.Transactions
where DateTime = '2024-12-11 12:05:00' and asset = 'ETH'
union 
select 'sold quote value - 1', soldquotevalue = ((19666.42 + 1.34) / 0.2), ((19666.42 + 1.34) / 0.2), soldquotevalue
from crypto.Transactions
where DateTime = '2024-12-11 12:05:00' and asset = 'ETH'
union
select 'bought quote value - 1', quotevalue = (19666.42 / 32.36)::numeric(16, 4), (19666.42 / 32.36)::numeric(16, 4), quotevalue
from crypto.Transactions
where DateTime = '2024-12-11 12:05:00' and asset = 'ETH'
union 
select 'amountopen - ETH Buy 2', amountopen = 32.36, 32.36, amountopen
from crypto.Transactions
where DateTime = '2024-12-11 12:10:00' and asset = 'ETH'
union 
select 'TradeProfitLoss - ETH Buy 2', TradeProfitLoss = (19666.42 - (0.2001 * 90167.3))::numeric(16, 4), (19666.42 - (0.2001 * 90167.3))::numeric(16, 4), TradeProfitLoss
from crypto.Transactions
where DateTime = '2024-12-11 12:10:00' and asset = 'ETH'
union 
select 'sold quote value - 2', soldquotevalue = (19666.42 / 0.2)::numeric(16, 4), (19666.42 / 0.2)::numeric(16, 4), soldquotevalue
from crypto.Transactions
where DateTime = '2024-12-11 12:10:00' and asset = 'ETH'
union 
select 'bought quote value - 2', quotevalue = (19666.42 / 32.36)::numeric(16, 4), (19666.42 / 32.36)::numeric(16, 4), quotevalue
from crypto.Transactions
where DateTime = '2024-12-11 12:10:00' and asset = 'ETH'
union 
select 'amountopen - ETH Buy 3', amountopen = 32.36, 32.36, amountopen
from crypto.Transactions
where DateTime = '2024-12-11 12:20:00' and asset = 'ETH'
union 
select 'TradeProfitLoss - ETH Buy 3', TradeProfitLoss = (19666.42 - (0.2 * 90167.3)), (19666.42 - (0.2 * 90167.3)), TradeProfitLoss
from crypto.Transactions
where DateTime = '2024-12-11 12:20:00' and asset = 'ETH'
union
select 'sold quote value - 3', soldquotevalue = ((19666.42 + 1.2155) / 0.2)::numeric(16, 4), ((19666.42 + 1.2155) / 0.2)::numeric(16, 4), soldquotevalue
from crypto.Transactions
where DateTime = '2024-12-11 12:20:00' and asset = 'ETH'
union
select 'bought quote value - 3', quotevalue = (19666.42 / 32.36)::numeric(16, 4), (19666.42 / 32.36)::numeric(16, 4), quotevalue
from crypto.Transactions
where DateTime = '2024-12-11 12:20:00' and asset = 'ETH'
union 
select 'amountopen - ETH Buy 4', amountopen = 32.36, 32.36, amountopen
from crypto.Transactions
where DateTime = '2024-12-11 12:30:00' and asset = 'ETH'
union 
select 'TradeProfitLoss - ETH Buy 4', TradeProfitLoss = (19666.42 - (0.2 *  90167.3) - (0.001 * 584))::numeric(16, 4), (19666.42 - (0.2 *  90167.3) - (0.001 * 584))::numeric(16, 4), TradeProfitLoss
from crypto.Transactions
where DateTime = '2024-12-11 12:30:00' and asset = 'ETH'
union
select 'sold quote value - 4', soldquotevalue = (19666.42 / 0.2)::numeric(16, 4), (19666.42 / 0.2)::numeric(16, 4), soldquotevalue
from crypto.Transactions
where DateTime = '2024-12-11 12:30:00' and asset = 'ETH'
union 
select 'bought quote value - 4', quotevalue = (19666.42 / 32.36)::numeric(16, 4), (19666.42 / 32.36)::numeric(16, 4), quotevalue
from crypto.Transactions
where DateTime = '2024-12-11 12:30:00' and asset = 'ETH'
;





select *
from crypto.Transactions
--where datetime >= '2024-12-11 00:00:00'
order by DateTime ASC





 ------- END ---------------