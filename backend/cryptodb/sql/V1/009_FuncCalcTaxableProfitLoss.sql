create or replace function crypto.CalcTaxableProfitLoss(
    in_event_id integer,
    in_valuation_method text,
    in_taxation_method text,
    in_amount_override numeric(28, 18) default null
)
returns numeric(16, 4)
as $$
declare
    pnl numeric(16, 4);
    recs record;
    message text;
begin
    if in_valuation_method is null then
        select upper(Value) into in_valuation_method from crypto.Settings where Name = 'ValuationMethod';
    else
        select upper(in_valuation_method) into in_valuation_method;
    end if;

    if in_taxation_method is null THEN
        select upper(Value) into in_taxation_method from crypto.Settings where Name = 'TaxableProfitLoss';
    else
        select upper(in_taxation_method) into in_taxation_method;
    end if;

    if in_taxation_method = 'ALL' then
        return crypto.CalcProfitLoss(in_event_id, in_valuation_method, in_amount_override);
    end if;

    if exists (select 1 from crypto.Events where id = in_event_id and (IsFiatEvent = true or in_amount_override is not null)) then
        raise notice 'calcprofitloss';
        select crypto.CalcProfitLoss(in_event_id, in_valuation_method, in_amount_override) into pnl;

        if in_valuation_method = 'LIFO' and exists (select 1 from crypto.Lifo where OutEventId = in_event_id and InIsFiat = false) then
            for recs in
                select InEventId, SUM(InAmount) As InAmount
                from crypto.Lifo
                where OutEventId = in_event_id
                group by InEventId
            loop
                raise notice 'LIFO calcprofitloss';
                select crypto.CalcTaxableProfitLoss(recs.InEventId, in_valuation_method, in_taxation_method, recs.InAmount) + pnl into pnl;
            end loop;
        end if;
        
        if in_valuation_method = 'FIFO' and exists (select 1 from crypto.Fifo where OutEventId = in_event_id and InIsFiat = false) then
            for recs in
                select InEventId, SUM(InAmount) As InAmount
                from crypto.Lifo
                where OutEventId = in_event_id
                group by InEventId
            loop
                raise notice 'FIFO calcprofitloss';
                select crypto.CalcTaxableProfitLoss(recs.InEventId, in_valuation_method, in_taxation_method, recs.InAmount) + pnl into pnl;
            end loop;
        end if;

        return pnl;
    end if;

    return 0;
end;
$$ language plpgsql;