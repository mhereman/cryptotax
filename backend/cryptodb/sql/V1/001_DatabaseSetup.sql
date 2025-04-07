-- Active: 1739787504888@@192.168.1.222@35432@priv_db
--drop schema if exists crypto cascade;
create schema crypto;

create extension if not exists pg_trgm with schema crypto;
create extension if not exists dict_xsyn with schema crypto;

create type crypto.EventType as enum (
    'Initialisation',
    'Trade',
    'TransactionFee'
);

create type crypto.EventOperationType as enum (
    'Buy',
    'Sell',
    'Fee',
    'Valuation'
);

create table crypto.Version(
    version int primary key
);

insert into crypto.Version(version) values (1);

create table crypto.Users(
    Id serial primary key,
    Email varchar(128),
    PasswordHash varchar(128),
    IsAdmin bool,
    constraint udx_crypto_users_email unique(Email)
);

create index idx_crypto_users_isadmin
on crypto.Users(IsAdmin);

create table crypto.UserDetails(
    UserId int primary key,
    FirstName varchar(64),
    LastName varchar(64),
    constraint fk_crypto_userdetails_userid foreign key (UserId)
        references crypto.Users(Id)
        on delete cascade
        on update cascade
);

create table crypto.Settings(
    Id serial primary key,
    Name varchar(64) not null,
    Value text,
    constraint udx_crypto_settings_name unique(Name)
);

insert into crypto.Settings(Name, Value)
values
    ('FiatAsset', 'EUR'),
    ('ValuationMethod', 'FIFO'),
    ('TaxableProfitLoss', 'FiatOnly');   -- 'All', 'FiatOnly'

-- select * from crypto.Settings;

--drop table crypto.FiatAssets;

create table crypto.FiatAssets(
    Asset varchar(8) primary key,
    Name text,
    Symbol varchar(8),
    SymbolBeforeValue bool,
    constraint udx_crypto_fiatassets_name unique(Name)
);

insert into crypto.FiatAssets(Asset, Name, Symbol, SymbolBeforeValue)
values
    ('EUR', 'Euro', '€', true),
    ('USD', 'US Dollar', '$', true),
    ('GBP', 'Brittish Pound','£', true),
    ('JPY', 'Japanese Yen', '¥', true);

create table crypto.Assets(
    Asset varchar(8) primary key,
    Name text,
    Precision integer,
    constraint udx_crypto_assets_name unique(Name)
);

insert into crypto.Assets(Asset, Name, Precision)
values
    ('BTC', 'Bitcoin', 8),
    ('ETH', 'Ethereum', 18),
    ('XRP', 'XRP', 6),
    ('SOL', 'Solana', 9),
    ('POL', 'Polygon', 18);


-- select * from crypto.FiatAssets;

create table crypto.Events (
    Id serial primary key,
    --
    -- Date and time of the transaction bundle
    DateTime timestamp not null,
    --
    -- Type of the event
    Type crypto.EventType not null,
    --
    -- Is a buy with or sell to fiat involved?
    IsFiatEvent boolean default false,
    --
    -- Asset bought
    BoughtAsset varchar(8) default null,
    --
    -- Asset sold
    SoldAsset varchar(8) default null,
    --
    -- Asset used to pay fee's with
    FeeAsset varchar(8) default null,
    --
    -- Description of the event
    Description text default null,
    --
    -- Reference of the event
    Reference text default null,
    --
    -- External link to the event
    Link text default null
);

create index idx_crypto_events_datetime
on crypto.Events(DateTime);

create index idx_crypto_events_isfiat
on crypto.Events(IsFiatEvent);

create table crypto.EventOperations (
    Id serial primary key,
    --
    -- Event this operation belongs to
    EventId int not null
        references crypto.Events(Id)
            on delete cascade
            on update cascade,
    --
    -- Type of event operation:
    --  * Buy:          Purchase of an asset.
    --                      If this is a purchase with fiat the field
    --                      IsFiatTransaction should be true
    --  * Sell          Sell of an asset.
    --                      If this is a sell to fiat the field
    --                      IsFiatTrasnaction should be true
    --  * Fee:          Fee payed (transaction fee, trade fee, ...)
    --  * Valuation:    Inventory of the current asset held.
    --                      The FiatValue should resemble the actual value
    --                      To be used for profit/loss calculation.
    --                      You can use this to fixate a certain value for
    --                      profit/loss calculation (e.g. when tax requirements
    --                      take effect from a specific date).
    --                      This will break LIFO and FIFO behaviour as this will
    --                      handle the current inventory as 1 single event.
    Type crypto.EventOperationType not null,
    --
    -- The asset purchased, sold, inventorised or used as a fee
    Asset varchar(8) default null,
    --
    -- The value expressed in the Asset
    Value numeric(38, 18) default 0,
    --
    --The quote value of the asset expressed in the configured fiat currency
    FiatQuoteValue numeric(16, 4) default 0,
    --
    -- True when the Buy or Sell transaction is from/to fiat
    -- This can also be a another fiat currency than the configurred
    -- fiat currency (e.g. configured = EUR, transation fiat currency = USD).
    IsFiatEventOperation boolean default false
);

create index idx_crypto_eventoperations_eventid
on crypto.EventOperations(EventId);

create index idx_crypto_eventoperations_type
on crypto.EventOperations(Type);

create index idx_crypto_eventoperations_asset
on crypto.EventOperations(Asset);

create index idx_crypto_eventoperations_isfiat
on crypto.EventOperations(IsFiatEventOperation);

create table crypto.Holdings (
    Year int not null,
    Asset VARCHAR(8) not null,
    Amount NUMERIC(38, 18),
    primary key (Year, Asset)
);

create table crypto.Fifo (
    InEventId int not null,
    SequenceNbr serial not null,
    OutEventId int not null,
    InAmount numeric(38, 18) not null,
    InValue numeric(16, 4) not null,
    InAsset varchar(8) not null,
    InIsFiat bool default false,
    OutAmount numeric(38, 18) default null,
    OutValue numeric(16, 4) default null,
    OutAsset varchar(8) default null,
    OutIsFiat bool default false,
    Type crypto.EventOperationType not null,
    primary key (InEventId, SequenceNbr),
    constraint udx_crypto_fifo_in_out_type unique(InEventId, OutEventId, Type),
    constraint fk_crypto_fifo_in foreign key (InEventId)
        references crypto.Events(Id)
        on delete cascade
        on update cascade,
    constraint fk_cypro_fifo_out foreign key (OutEventId)
        references crypto.Events(Id)
        on delete cascade
        on update cascade
);

create table crypto.Lifo (
    InEventId int not null,
    SequenceNbr serial not null,
    OutEventId int not null,
    InAmount numeric(38, 18) not null,
    InValue numeric(16, 4) not null,
    InAsset varchar(8) not null,
    InIsFiat bool default false,
    OutAmount numeric(38, 18) default null,
    OutValue numeric(16, 4) default null,
    OutAsset varchar(8) default null,
    OutIsFiat bool default false,
    Type crypto.EventOperationType not null,
    primary key (InEventId, SequenceNbr),
    constraint udx_crypto_lifo_in_out_type unique(InEventId, OutEventId, Type),
    constraint fk_crypto_lifo_in foreign key (InEventId)
        references crypto.Events(Id)
        on delete cascade
        on update cascade,
    constraint fk_crypto_lifo_out foreign key (OutEventId)
        references crypto.Events(Id)
        on delete cascade
        on update cascade
);
