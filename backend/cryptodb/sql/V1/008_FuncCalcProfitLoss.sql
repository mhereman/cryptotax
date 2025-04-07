create or replace function crypto.CalcProfitLoss(
    in_event_id integer,
    in_valuation_method text,
    in_amount_override numeric(38, 18) default null
)
returns numeric(16, 4)
as $$
declare
    fraction numeric(38, 18);
begin
    if in_valuation_method is null then
        select upper(Value) into in_valuation_method from crypto.Settings where Name = 'ValuationMethod';
    else
        select upper(in_valuation_method) into in_valuation_method;
    end if;

    fraction := 1;
    if in_valuation_method = 'LIFO' then
        if in_amount_override is not null then
            select in_amount_override / sum(OutAmount) into fraction
            from crypto.Lifo
            where OutEventId = in_event_id;
        end if;

        return (
            select ((sum(OutValue) - sum(InValue))::numeric(38, 18) * fraction)::numeric(16, 4)
            from crypto.Lifo
            where OutEventId = in_event_id); 
    else
        if in_amount_override is not null then
            select in_amount_override / sum(OutAmount) into fraction
            from crypto.Fifo
            where OutEventId = in_event_id;
        end if;

        return (
            select ((sum(OutValue) - sum(InValue))::numeric(38, 18) * fraction)::numeric(16, 4)
            from crypto.Fifo
            where OutEventId = in_event_id);
    end if;
end;
$$ language plpgsql;