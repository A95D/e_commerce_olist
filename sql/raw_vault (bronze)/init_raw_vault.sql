-- создание схем
create schema if not exists raw_vault;

-- создание таблиц
-- Таблица аудита для отслеживания ошибок при загрузке данных
create table if not exists raw_vault.etl_audit_log(
    log_id serial primary key,
    batch_id int,
    error_msg text,
    failed_payload text,
    log_time timestamp default current_timestamp
);

-- Hub order
CREATE TABLE if not exists raw_vault.hub_order (
    hub_order_hash char(64) primary key,
    order_id varchar not null,
    load_date timestamp default current_timestamp,
    record_source varchar not null
);

-- Hub product
CREATE TABLE if not exists raw_vault.hub_product (
    hub_product_hash char(64) primary key,
    product_id varchar not null,
    load_date timestamp default current_timestamp,
    record_source varchar not null
);

-- Link order_item
create table if not exists raw_vault.link_order_items (
    link_order_item_hash char(64) primary key,
    hub_order_hash char(64) not null,
    hub_product_hash char(64) not null,
    load_date timestamp not null default current_timestamp,
    record_source varchar not null,
    batch_id int not null
);

-- Satellite order_item_finance
create table if not exists raw_vault.sat_order_item_finance (
    link_order_item_hash char(64),
    price numeric(12, 2),
    freight_value numeric(12, 2),
    load_date timestamp not null,
    record_source varchar not null,
    primary key (link_order_item_hash, load_date)
);

-- Создание индексов
create index if not exists idx_link_order_item_hub_order_hash on raw_vault.link_order_items (hub_order_hash);