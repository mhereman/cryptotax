delete from crypto.Events;
delete from crypto.EventOperations;
delete from crypto.Holdings;
delete from crypto.Fifo;
delete form crypto.Lifo;

-- TEST InitialiseAsset --

call crypto.InitialiseAsset(
    '2020-01-01 12:00:00',
    'BTC', 1.234, 16742.85,
    'Valuation BTC 2020-01-01',
    'abc-123',
    'https://www.mempool.space'
);

select * from (
    select 'Events' as table, 'Type' as field, Type = 'Initialisation' as isok, Type::text as have, 'Initialisation' as expected
    from crypto.events WHERE DateTime = '2020-01-01 12:00:00' AND BoughtAsset = 'BTC'
    union
    select 'Events', 'IsFiatEvent', IsFiatEvent = true, IsFiatEvent::text, 'true'
    from crypto.events WHERE DateTime = '2020-01-01 12:00:00' AND BoughtAsset = 'BTC'
    union
    select 'Events', 'SoldAsset', SoldAsset = (select Value from crypto.Settings where Name = 'FiatAsset'),
        SoldAsset, (select Value from crypto.Settings where Name = 'FiatAsset')
    from crypto.events WHERE DateTime = '2020-01-01 12:00:00' AND BoughtAsset = 'BTC'
    union
    select 'Events', 'FeeAsset', FeeAsset is null as isok, FeeAsset, null
    from crypto.events WHERE DateTime = '2020-01-01 12:00:00' AND BoughtAsset = 'BTC'
    union
    select 'Events', 'Description', Description = 'Valuation BTC 2020-01-01', Description, 'Valuation BTC 2020-01-01'
    from crypto.events WHERE DateTime = '2020-01-01 12:00:00' AND BoughtAsset = 'BTC'
    union
    select 'Events', 'Reference', Reference = 'abc-123', Reference, 'abc-123'
    from crypto.events WHERE DateTime = '2020-01-01 12:00:00' AND BoughtAsset = 'BTC'
    union
    select 'Events', 'Link', Link = 'https://www.mempool.space', Link, 'https://www.mempool.space'
    from crypto.events WHERE DateTime = '2020-01-01 12:00:00' AND BoughtAsset = 'BTC'
    union
    select 'EventOperations', 'Num operations',
        (
            select count(1) from crypto.EventOperations o
            join crypto.Events e on e.Id = o.eventid
            WHERE DateTime = '2020-01-01 12:00:00' AND BoughtAsset = 'BTC'
        ) = 1,
        (
            select count(1) from crypto.EventOperations o
            join crypto.Events e on e.Id = o.eventid
            WHERE DateTime = '2020-01-01 12:00:00' AND BoughtAsset = 'BTC'
        )::text,
        '1'
    union
    select 'EventOperations', 'Operation Type',
        (
            Select count(1) from crypto.EventOperations o
            join crypto.Events e on e.Id = o.eventid
            WHERE e.DateTime = '2020-01-01 12:00:00' AND e.BoughtAsset = 'BTC'
            and o.Type = 'Valuation'
        ) = 1,
        case when (
            Select count(1) from crypto.EventOperations o
            join crypto.Events e on e.Id = o.eventid
            WHERE e.DateTime = '2020-01-01 12:00:00' AND e.BoughtAsset = 'BTC'
            and o.Type = 'Valuation'
        ) = 1 then 'Valuation' else null end,
        'Valuation'
    union
    select 'EventOperations', 'Asset',
        (
            Select o.Asset from crypto.EventOperations o
            join crypto.Events e on e.Id = o.eventId
            WHERE e.DateTime = '2020-01-01 12:00:00' AND e.BoughtAsset = 'BTC'
            and o.Type = 'Valuation'
            limit 1
        ) = 'BTC',
        (
            Select o.Asset from crypto.EventOperations o
            join crypto.Events e on e.Id = o.eventId
            WHERE e.DateTime = '2020-01-01 12:00:00' AND e.BoughtAsset = 'BTC'
            and o.Type = 'Valuation'
            limit 1
        ),
        'BTC'
    union
    select 'EventOperations', 'Value',
        (
            Select o.Value from crypto.EventOperations o
            join crypto.Events e on e.Id = o.eventId
            WHERE e.DateTime = '2020-01-01 12:00:00' AND e.BoughtAsset = 'BTC'
            and o.Type = 'Valuation'
            limit 1
        ) = 1.234,
        (
            Select o.Value::text from crypto.EventOperations o
            join crypto.Events e on e.Id = o.eventId
            WHERE e.DateTime = '2020-01-01 12:00:00' AND e.BoughtAsset = 'BTC'
            and o.Type = 'Valuation'
            limit 1
        ),
        '1.234'
    union
    select 'EventOperations', 'FiatQuoteValue',
        (
            Select o.FiatQuoteValue from crypto.EventOperations o
            join crypto.Events e on e.Id = o.eventId
            WHERE e.DateTime = '2020-01-01 12:00:00' AND e.BoughtAsset = 'BTC'
            and o.Type = 'Valuation'
            limit 1
        ) = 16742.85,
        (
            Select o.FiatQuoteValue::text from crypto.EventOperations o
            join crypto.Events e on e.Id = o.eventId
            WHERE e.DateTime = '2020-01-01 12:00:00' AND e.BoughtAsset = 'BTC'
            and o.Type = 'Valuation'
            limit 1
        ),
        '16742.85'
    union
    select 'EventOperations', 'IsFiatEventOperation',
        (
            Select o.IsFiatEventOperation from crypto.EventOperations o
            join crypto.Events e on e.Id = o.eventId
            WHERE e.DateTime = '2020-01-01 12:00:00' AND e.BoughtAsset = 'BTC'
            and o.Type = 'Valuation'
            limit 1
        ) = false,
        (
            Select o.IsFiatEventOperation::text from crypto.EventOperations o
            join crypto.Events e on e.Id = o.eventId
            WHERE e.DateTime = '2020-01-01 12:00:00' AND e.BoughtAsset = 'BTC'
            and o.Type = 'Valuation'
            limit 1
        ),
        'false'
    union
    select 'Holdings', 'Exists',
        (
            select count(1) from crypto.Holdings
            where Year = 2020 and Asset = 'BTC'
        ) = 1,
        (
            select count(1)::text from crypto.Holdings
            where Year = 2020 and Asset = 'BTC'
        ),
        '1'
    union
    select 'Holdings', 'Amount', Amount = 1.234, Amount::text, '1.234'
    from crypto.holdings
    where Year = 2020 and Asset = 'BTC'
) order by "table" asc, field asc;

-- Test Trade Fiat -> BTC --

call crypto.Trade(
    '2020-01-02 12:00:00',
    'BTC', 0.145, 16112.33,
    'EUR', 0.145 * 16112.33, 1.0,
    'EUR', 12.15, 1.0,
    'Bought 0.145 BTC with EUR',
    'abc-124',
    'https://www.kraken.com'
);

select * from (
    select 'Events' as table, 'Type' as field, Type = 'Trade' as isok, Type::text as have, 'Trade' as expected
    from crypto.events WHERE DateTime = '2020-01-02 12:00:00' AND BoughtAsset = 'BTC'
    union
    select 'Events', 'IsFiatEvent', IsFiatEvent = true, IsFiatEvent::text, 'true'
    from crypto.events WHERE DateTime = '2020-01-02 12:00:00' AND BoughtAsset = 'BTC'
    union
    select 'Events', 'SoldAsset', SoldAsset = 'EUR', SoldAsset, 'EUR'
    from crypto.events WHERE DateTime = '2020-01-02 12:00:00' AND BoughtAsset = 'BTC'
    union
    select 'Events', 'FeeAsset', FeeAsset = 'EUR', FeeAsset, 'EUR' 
    from crypto.events WHERE DateTime = '2020-01-02 12:00:00' AND BoughtAsset = 'BTC'
    union
    select 'Events', 'Description', Description = 'Bought 0.145 BTC with EUR', Description, 'Bought 0.145 BTC with EUR'
    from crypto.events WHERE DateTime = '2020-01-02 12:00:00' AND BoughtAsset = 'BTC'
    union
    select 'Events', 'Reference', Reference = 'abc-124', Reference, 'abc-124'
    from crypto.events WHERE DateTime = '2020-01-02 12:00:00' AND BoughtAsset = 'BTC'
    union
    select 'Events', 'Link', Link = 'https://www.kraken.com', Link, 'https://www.kraken.com'
    from crypto.events WHERE DateTime = '2020-01-02 12:00:00' AND BoughtAsset = 'BTC'
    union
    select 'EventOperations', 'Num operations',
        (
            select count(1) from crypto.EventOperations o
            join crypto.Events e on e.Id = o.eventid
            WHERE DateTime = '2020-01-02 12:00:00' AND BoughtAsset = 'BTC'
        ) = 3,
        (
            select count(1) from crypto.EventOperations o
            join crypto.Events e on e.Id = o.eventid
            WHERE DateTime = '2020-01-02 12:00:00' AND BoughtAsset = 'BTC'
        )::text,
        '3'
    union
    select 'EventOperations', 'Operation Type Buy',
        (
            Select count(1) from crypto.EventOperations o
            join crypto.Events e on e.Id = o.eventid
            WHERE e.DateTime = '2020-01-02 12:00:00' AND e.BoughtAsset = 'BTC'
            and o.Type = 'Buy'
        ) = 1,
        case when (
            Select count(1) from crypto.EventOperations o
            join crypto.Events e on e.Id = o.eventid
            WHERE e.DateTime = '2020-01-02 12:00:00' AND e.BoughtAsset = 'BTC'
            and o.Type = 'Buy'
        ) = 1 then 'Buy' else null end,
        'Buy'
    union
    select 'EventOperations', 'Buy Asset',
        (
            Select o.Asset from crypto.EventOperations o
            join crypto.Events e on e.Id = o.eventId
            WHERE e.DateTime = '2020-01-02 12:00:00' AND e.BoughtAsset = 'BTC'
            and o.Type = 'Buy'
            limit 1
        ) = 'BTC',
        (
            Select o.Asset from crypto.EventOperations o
            join crypto.Events e on e.Id = o.eventId
            WHERE e.DateTime = '2020-01-02 12:00:00' AND e.BoughtAsset = 'BTC'
            and o.Type = 'Buy'
            limit 1
        ),
        'BTC'
    union
    select 'EventOperations', 'Buy Value',
        (
            Select o.Value from crypto.EventOperations o
            join crypto.Events e on e.Id = o.eventId
            WHERE e.DateTime = '2020-01-02 12:00:00' AND e.BoughtAsset = 'BTC'
            and o.Type = 'Buy'
            limit 1
        ) = 0.145,
        (
            Select o.Value::text from crypto.EventOperations o
            join crypto.Events e on e.Id = o.eventId
            WHERE e.DateTime = '2020-01-02 12:00:00' AND e.BoughtAsset = 'BTC'
            and o.Type = 'Buy'
            limit 1
        ),
        '0.145'
    union
    select 'EventOperations', 'Buy FiatQuoteValue',
        (
            Select o.FiatQuoteValue from crypto.EventOperations o
            join crypto.Events e on e.Id = o.eventId
            WHERE e.DateTime = '2020-01-02 12:00:00' AND e.BoughtAsset = 'BTC'
            and o.Type = 'Buy'
            limit 1
        ) = 16112.33,
        (
            Select o.FiatQuoteValue::text from crypto.EventOperations o
            join crypto.Events e on e.Id = o.eventId
            WHERE e.DateTime = '2020-01-02 12:00:00' AND e.BoughtAsset = 'BTC'
            and o.Type = 'Buy'
            limit 1
        ),
        '16112.33'
    union
    select 'EventOperations', 'Buy IsFiatEventOperation',
        (
            Select o.IsFiatEventOperation from crypto.EventOperations o
            join crypto.Events e on e.Id = o.eventId
            WHERE e.DateTime = '2020-01-02 12:00:00' AND e.BoughtAsset = 'BTC'
            and o.Type = 'Buy'
            limit 1
        ) = false,
        (
            Select o.IsFiatEventOperation::text from crypto.EventOperations o
            join crypto.Events e on e.Id = o.eventId
            WHERE e.DateTime = '2020-01-02 12:00:00' AND e.BoughtAsset = 'BTC'
            and o.Type = 'Buy'
            limit 1
        ),
        'false'
    union
    select 'EventOperations', 'Operation Type Sell',
        (
            Select count(1) from crypto.EventOperations o
            join crypto.Events e on e.Id = o.eventid
            WHERE e.DateTime = '2020-01-02 12:00:00' AND e.BoughtAsset = 'BTC'
            and o.Type = 'Sell'
        ) = 1,
        case when (
            Select count(1) from crypto.EventOperations o
            join crypto.Events e on e.Id = o.eventid
            WHERE e.DateTime = '2020-01-02 12:00:00' AND e.BoughtAsset = 'BTC'
            and o.Type = 'Sell'
        ) = 1 then 'Sell' else null end,
        'Sell'
    union
    select 'EventOperations', 'Sell Asset',
        (
            Select o.Asset from crypto.EventOperations o
            join crypto.Events e on e.Id = o.eventId
            WHERE e.DateTime = '2020-01-02 12:00:00' AND e.BoughtAsset = 'BTC'
            and o.Type = 'Sell'
            limit 1
        ) = 'EUR',
        (
            Select o.Asset from crypto.EventOperations o
            join crypto.Events e on e.Id = o.eventId
            WHERE e.DateTime = '2020-01-02 12:00:00' AND e.BoughtAsset = 'BTC'
            and o.Type = 'Sell'
            limit 1
        ),
        'EUR'
    union
    select 'EventOperations', 'Sell Value',
        (
            Select o.Value from crypto.EventOperations o
            join crypto.Events e on e.Id = o.eventId
            WHERE e.DateTime = '2020-01-02 12:00:00' AND e.BoughtAsset = 'BTC'
            and o.Type = 'Sell'
            limit 1
        ) = 0.145 * 16112.33,
        (
            Select o.Value::text from crypto.EventOperations o
            join crypto.Events e on e.Id = o.eventId
            WHERE e.DateTime = '2020-01-02 12:00:00' AND e.BoughtAsset = 'BTC'
            and o.Type = 'Sell'
            limit 1
        ),
        (0.145 * 16112.33)::text
    union
    select 'EventOperations', 'Sell FiatQuoteValue',
        (
            Select o.FiatQuoteValue from crypto.EventOperations o
            join crypto.Events e on e.Id = o.eventId
            WHERE e.DateTime = '2020-01-02 12:00:00' AND e.BoughtAsset = 'BTC'
            and o.Type = 'Sell'
            limit 1
        ) = 1.0,
        (
            Select o.FiatQuoteValue::text from crypto.EventOperations o
            join crypto.Events e on e.Id = o.eventId
            WHERE e.DateTime = '2020-01-02 12:00:00' AND e.BoughtAsset = 'BTC'
            and o.Type = 'Sell'
            limit 1
        ),
        '1.0'
    union
    select 'EventOperations', 'Sell IsFiatEventOperation',
        (
            Select o.IsFiatEventOperation from crypto.EventOperations o
            join crypto.Events e on e.Id = o.eventId
            WHERE e.DateTime = '2020-01-02 12:00:00' AND e.BoughtAsset = 'BTC'
            and o.Type = 'Sell'
            limit 1
        ) = true,
        (
            Select o.IsFiatEventOperation::text from crypto.EventOperations o
            join crypto.Events e on e.Id = o.eventId
            WHERE e.DateTime = '2020-01-02 12:00:00' AND e.BoughtAsset = 'BTC'
            and o.Type = 'Sell'
            limit 1
        ),
        'true'
    union
    select 'EventOperations', 'Operation Type Fee',
        (
            Select count(1) from crypto.EventOperations o
            join crypto.Events e on e.Id = o.eventid
            WHERE e.DateTime = '2020-01-02 12:00:00' AND e.BoughtAsset = 'BTC'
            and o.Type = 'Fee'
        ) = 1,
        case when (
            Select count(1) from crypto.EventOperations o
            join crypto.Events e on e.Id = o.eventid
            WHERE e.DateTime = '2020-01-02 12:00:00' AND e.BoughtAsset = 'BTC'
            and o.Type = 'Fee'
        ) = 1 then 'Fee' else null end,
        'Fee'
    union
    select 'EventOperations', 'Fee Asset',
        (
            Select o.Asset from crypto.EventOperations o
            join crypto.Events e on e.Id = o.eventId
            WHERE e.DateTime = '2020-01-02 12:00:00' AND e.BoughtAsset = 'BTC'
            and o.Type = 'Fee'
            limit 1
        ) = 'EUR',
        (
            Select o.Asset from crypto.EventOperations o
            join crypto.Events e on e.Id = o.eventId
            WHERE e.DateTime = '2020-01-02 12:00:00' AND e.BoughtAsset = 'BTC'
            and o.Type = 'Fee'
            limit 1
        ),
        'EUR'
    union
    select 'EventOperations', 'Fee Value',
        (
            Select o.Value from crypto.EventOperations o
            join crypto.Events e on e.Id = o.eventId
            WHERE e.DateTime = '2020-01-02 12:00:00' AND e.BoughtAsset = 'BTC'
            and o.Type = 'Fee'
            limit 1
        ) = 12.15,
        (
            Select o.Value::text from crypto.EventOperations o
            join crypto.Events e on e.Id = o.eventId
            WHERE e.DateTime = '2020-01-02 12:00:00' AND e.BoughtAsset = 'BTC'
            and o.Type = 'Fee'
            limit 1
        ),
        '12.15'
    union
    select 'EventOperations', 'Fee FiatQuoteValue',
        (
            Select o.FiatQuoteValue from crypto.EventOperations o
            join crypto.Events e on e.Id = o.eventId
            WHERE e.DateTime = '2020-01-02 12:00:00' AND e.BoughtAsset = 'BTC'
            and o.Type = 'Fee'
            limit 1
        ) = 1.0,
        (
            Select o.FiatQuoteValue::text from crypto.EventOperations o
            join crypto.Events e on e.Id = o.eventId
            WHERE e.DateTime = '2020-01-02 12:00:00' AND e.BoughtAsset = 'BTC'
            and o.Type = 'Fee'
            limit 1
        ),
        '1.0'
    union
    select 'EventOperations', 'Fee IsFiatEventOperation',
        (
            Select o.IsFiatEventOperation from crypto.EventOperations o
            join crypto.Events e on e.Id = o.eventId
            WHERE e.DateTime = '2020-01-02 12:00:00' AND e.BoughtAsset = 'BTC'
            and o.Type = 'Fee'
            limit 1
        ) = true,
        (
            Select o.IsFiatEventOperation::text from crypto.EventOperations o
            join crypto.Events e on e.Id = o.eventId
            WHERE e.DateTime = '2020-01-02 12:00:00' AND e.BoughtAsset = 'BTC'
            and o.Type = 'Fee'
            limit 1
        ),
        'true'
    union
    select 'Holdings', 'Exists',
        (
            select count(1) from crypto.Holdings
            where Year = 2020 and Asset = 'BTC'
        ) = 1,
        (
            select count(1)::text from crypto.Holdings
            where Year = 2020 and Asset = 'BTC'
        ),
        '1'
    union
    select 'Holdings', 'Amount', Amount = (1.234 + 0.145), Amount::text, '1.379'
    from crypto.holdings
    where Year = 2020 and Asset = 'BTC'
) order by "table" asc, field asc;

-- Trade BTC --> ETH --

call crypto.Trade(
    '2024-01-03 12:00:00',
    'ETH', 1.0, 845.35,
    'BTC', (845.35 / 16225.45)::numeric(38, 8), 16225.45,
    'BTC', 0.00052, 16225.45,
    'Trade BTC to ETH',
    'abd-125',
    'https://www.kraken.com'
);

call crypto.Trade(
    '2024-01-04 12:00:00',
    'EUR', 985.15, 1.0,
    'ETH', 0.99, 995.101,
    'ETH', 0.01, 995.101,
    'Trade ETH to EUR',
    'abc-145',
    'https://www.kraken.com'
);


select *
from crypto.Events e
join crypto.eventoperations o on o.eventid = e.id;

select *
from crypto.eventoperations;

select * from crypto.Holdings;

select sum(OutValue) - sum(InValue)
from crypto.Fifo
where OutEventId = 4;

select sum(OutValue) - sum(InValue)
from crypto.Lifo
where OutEventId = 4;

select *
from crypto.Fifo;

select *
from crypto.Lifo;

-- BTC 1 16742.85
-- BTC 2 16112.35
-- BTC 4 16225.445
-- ETH 4 845.35

select 0.00052 * 16742.85 + 0.05210025 * 16742.85, 1.0 * 845.35;
select 0.00052 * 16112.35 + 0.05210025 * 16112.35, 1.0 * 845.35;

select 'Individual Transactions', sum(PNL) from (
    select crypto.CalcProfitLoss(3, 'fifo') As PNL
    union
    select crypto.CalcProfitLoss(4, 'fifo') As OPL
)
union
select 'Taxable Transaction', crypto.CalcTaxableProfitLoss(4, 'fifo', 'FiatOnly')
union
select 'Invalid taxable', crypto.calctaxableprofitloss(3, 'fifo', 'fiatonly')
union
select 'all taxable', crypto.CalcTaxableProfitLoss(3, 'fifo', 'all');

select crypto.CalcProfitLoss(1, null);

SELECT
     e.Id, e.DateTime, e.Type, e.IsFiatEvent, e.Description, e.Reference, e.Link,
     coalesce(TransactionPnL, 0)::numeric(16, 4) As TransactionPnL, coalesce(TaxablePnL, 0)::numeric(16, 4) As TaxablePnL,
     o1.Asset As ValuationAsset, o1.Value as ValuationValue, o1.FiatQuoteValue As ValuationFiatQuoteValue, o1.isfiateventoperation As ValuationIsFiat,
     o2.Asset As BuyAsset, o2.Value As BuyValue, o2.FiatQuoteValue As BuyFiatQuoteValue, o2.IsFiatEventOperation As BuyIsFiat,
     o3.Asset As SellAsset, o3.Value As SellValue, o3.FiatQuoteValue As SellFiatQuoteValue, o3.IsFiatEventOperation As SellIsFiat,
     o4.Asset As FeeAsset, o3.Value As FeeValue, o3.FiatQuoteValue As FeeFiatQuoteValue, o3.IsFiatEventOperation As FeeIsFiat
FROM crypto.Events e
left join crypto.CalcProfitLoss(e.Id, null) As TransactionPnL on true
left join crypto.CalcTaxableProfitLoss(e.Id, null, null) As TaxablePnL on true
left JOIN crypto.eventoperations o1 on (o1.EventId = e.Id and o1.Type = 'Valuation')
left join crypto.eventoperations o2 on (o2.EventId = e.Id and o2.Type = 'Buy')
left join crypto.eventoperations o3 on (o3.EventId = e.Id and o3.Type = 'Sell')
left join crypto.eventoperations o4 on (o4.EventId = e.Id and o4.Type = 'Fee')
;

SELECT *
from crypto.Holdings;

SELECT *
FROM crypto.Holdings
WHERE Year = (SELECT MAX(Year) FROM crypto.Holdings WHERE Year <= 2000 AND Asset = 'BTC')
AND Asset = 'BTC';

SELECT *
FROM crypto.Holdings
WHERE Year = (SELECT MAX(Year) FROM crypto.Holdings WHERE Asset = 'BTC')
AND Asset = 'BTC';


SELECT *
FROM crypto.Holdings h
JOIN (
    SELECT MAX(Year) As Year, Asset As Asset
    FROM crypto.Holdings
    GROUP BY Asset
) hh ON (h.Year = hh.Year AND h.Asset = hh.Asset);

SELECT *
FROM crypto.FiatAssets;

select *
from crypto.FiatAssets
where Asset in (
    select Value
    from crypto.Settings
    where Name = 'FiatAsset'
) LIMIT 1;

select *
from crypto.ViewTransactionList;