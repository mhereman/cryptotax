drop materialized view if exists crypto.ViewTransactionList;

create materialized view crypto.ViewTransactionList As
select
     e.Id, e.DateTime, e.Type, e.IsFiatEvent, e.Description, e.Reference, e.Link,
     coalesce(TransactionPnL, 0)::numeric(16, 4) As TransactionPnL, coalesce(TaxablePnL, 0)::numeric(16, 4) As TaxablePnL,
     o1.Asset As ValuationAsset, o1.Value as ValuationValue, o1.FiatQuoteValue As ValuationFiatQuoteValue, o1.isfiateventoperation As ValuationIsFiat,
     o2.Asset As BuyAsset, o2.Value As BuyValue, o2.FiatQuoteValue As BuyFiatQuoteValue, o2.IsFiatEventOperation As BuyIsFiat,
     o3.Asset As SellAsset, o3.Value As SellValue, o3.FiatQuoteValue As SellFiatQuoteValue, o3.IsFiatEventOperation As SellIsFiat,
     o4.Asset As FeeAsset, o4.Value As FeeValue, o4.FiatQuoteValue As FeeFiatQuoteValue, o4.IsFiatEventOperation As FeeIsFiat
from crypto.Events e
left join crypto.CalcProfitLoss(e.Id, null) As TransactionPnL on true
left join crypto.CalcTaxableProfitLoss(e.Id, null, null) As TaxablePnL on true
left join crypto.eventoperations o1 on (o1.EventId = e.Id and o1.Type = 'Valuation')
left join crypto.eventoperations o2 on (o2.EventId = e.Id and o2.Type = 'Buy')
left join crypto.eventoperations o3 on (o3.EventId = e.Id and o3.Type = 'Sell')
left join crypto.eventoperations o4 on (o4.EventId = e.Id and o4.Type = 'Fee')
;

create index idx_crypto_view_transactionlist_datetime
on crypto.ViewTransactionList(DateTime);

create index idx_crypto_view_transactionlist_type
on crypto.ViewTransactionList(Type);

create index idx_crypto_view_transactionlist_isfiatevent
on crypto.ViewTransactionList(IsFiatEvent);

create index idx_crypto_view_transactionlist_description
on crypto.ViewTransactionList
using GIN (to_tsvector('simple', Description));

create index idx_crypto_view_transactionlist_reference
on crypto.ViewTransactionList(Reference);

create index idx_crypto_view_transactionlist_valuation_asset
on crypto.ViewTransactionList(ValuationAsset);

create index idx_crypto_view_transactionlist_buy_asset
on crypto.ViewTransactionList(BuyAsset);

create index idx_crypto_view_transactionlist_sell_asset
on crypto.ViewTransactionList(SellAsset);

create index idx_crypto_view_transactionlist_fee_asset
on crypto.ViewTransactionList(FeeAsset);

create index idx_crypto_view_transactionlist_txpnl
on crypto.ViewTransactionList(TransactionPnL);

create index idx_crypto_view_transactionlist_taxpnl
on crypto.ViewTransactionList(TaxablePnL);

--drop function crypto.RefreshViewTransactionList;

--create or replace function crypto.RefreshViewTransactionList()
--returns trigger as $$
--begin
  --   refresh materialized view crypto.ViewTransactionList;
   --  return null;
--end;
--$$ language plpgsql;

--drop trigger crypto_RefreshViewTransactionListTrigger on crypto.Events;
--drop trigger crypto_RefreshViewTransactionListTrigger on crypto.Fifo;
--drop trigger crypto_RefreshViewTransactionListTrigger on crypto.Lifo;

--create trigger crypto_RefreshViewTransactionListTrigger
--after insert or update or delete on crypto.Fifo
--for each statement
--execute procedure crypto.RefreshViewTransactionList();

--create trigger crypto_RefreshViewTransactionListTrigger
--after insert or update or delete on crypto.Lifo
--for each statement
--execute procedure crypto.RefreshViewTransactionList();


--select * from crypto.ViewTransactionList
--ORDER BY DateTime asc;

--select *
--from crypto.Events e
--join crypto.eventoperations o on (o.EventId = e.Id)
--where e.Id = 4;

--select * from crypto.ViewTransactionList
--where to_tsvector('simple', Description) @@ phraseto_tsquery('simple', '0.145 BTC');
