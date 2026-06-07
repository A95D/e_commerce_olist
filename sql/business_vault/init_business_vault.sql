-- Создаем новую схему
create schema if not exists business_vault;

-- Создание PIT для таблицы заказов
create table if not exists business_vault.pit_order (
    snapshot_date timestamp not null,
    hub_order_hash char(32) not null,
    ldts_sat_order_status timestamp not null,
    ldts_sat_order_payments timestamp not null,
    ldts_sat_order_item_finance timestamp not null,
    constraint pk_pit_order primary key (snapshot_date, hub_order_hash)
);

create index if not exists idx_pit_order_hub on business_vault.pit_order (hub_order_hash, snapshot_date);

-- Создание bridge таблица order_product_seller
create table if not exists business_vault.bridge_order_product_seller (
    snapshot_date timestamp not null,
    link_order_item_hash char(32) not null,
    hub_order_hash char(32) not null,
    hub_product_hash char(32) not null,
    hub_seller_hash char(32) not null,
    constraint pk_bridge_order_product_seller primary key (hub_seller_hash, hub_product_hash, hub_order_hash, link_order_item_hash, snapshot_date)
);