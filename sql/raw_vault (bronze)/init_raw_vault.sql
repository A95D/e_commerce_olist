-------------------------------------------------------------------------------
-- 0. Создание схемы
-------------------------------------------------------------------------------
create schema if not exists raw_vault;

-------------------------------------------------------------------------------
-- 1. ТЕХНИЧЕСКИЙ СЛОЙ (АУДИТ)
-------------------------------------------------------------------------------

-- Таблица для регистрации каждого запуска процесса загрузки
-- drop table if exists raw_vault.etl_audit_log cascade;
create table if not exists raw_vault.etl_audit_log(
    log_id serial,
    batch_id int,
    error_msg text,
    failed_payload text,
    log_time timestamp default current_timestamp,
    constraint pk_raw_vault_etl_audit_log primary key (log_id)
);

-------------------------------------------------------------------------------
-- 2. HUBS (Существительные / Бизнес-сущности)
-- Только уникальные бизнес-ключи. insert-only.
-------------------------------------------------------------------------------

-- Hub customer: Якорь для личности покупателя
-- drop table if exists raw_vault.hub_customer cascade;
create table if not exists raw_vault.hub_customer (
    hub_customer_hash char(32) not null, --MD5(customer_unique_id)
    customer_unique_id varchar not null,    -- Естественный бизнес-ключ
    load_date timestamp default current_timestamp,
    record_source varchar not null,
    batch_id int not null,
    constraint pk_raw_vault_hub_customer primary key (hub_customer_hash)
);

-- Hub seller: Продавцы маркетплейса
-- drop table if exists raw_vault.hub_seller cascade;
CREATE TABLE if not exists raw_vault.hub_seller (
    hub_seller_hash char(32) not null,
    seller_id varchar not null,
    load_date timestamp default current_timestamp,
    record_source varchar not null,
    batch_id int not null,
    constraint pk_raw_vault_hub_seller primary key (hub_seller_hash)
);

-- Hub geolocation: Географические точки (ZIP-коды)
-- drop table if exists raw_vault.hub_geolocation cascade;
create table if not exists raw_vault.hub_geolocation (
    hub_geolocation_hash char(32) not null,
    zip_code_prefix varchar not null,
    load_date timestamp default current_timestamp,
    record_source varchar not null,
    batch_id int not null,
    constraint pk_raw_vault_hub_geolocation primary key (hub_geolocation_hash)
);

-- Hub order: Якорь для транзакции заказа
-- drop table if exists raw_vault.hub_order cascade;
CREATE TABLE if not exists raw_vault.hub_order (
    hub_order_hash char(32) not null,
    order_id varchar not null,
    load_date timestamp default current_timestamp,
    record_source varchar not null,
    batch_id int not null,
    constraint pk_raw_vault_hub_order primary key (hub_order_hash)
);

-- Hub product: Артикулы товаров
-- drop table if exists raw_vault.hub_product cascade;
CREATE TABLE if not exists raw_vault.hub_product (
    hub_product_hash char(32) not null,
    product_id varchar not null,
    load_date timestamp default current_timestamp,
    record_source varchar not null,
    batch_id int not null,
    constraint pk_raw_vault_hub_product primary key (hub_product_hash)
);

-- Hub review: Уникальные идентификаторы отзывов
-- drop table if exists raw_vault.hub_review cascade;
create table if not exists raw_vault.hub_review (
    hub_review_hash char(32) not null,
    review_id varchar not null,
    load_date timestamp default CURRENT_TIMESTAMP,
    record_source varchar not null,
    batch_id int not null,
    constraint pk_raw_vault_hub_review primary key (hub_review_hash)
);

-- Hub product category: категории товаров
-- drop table if exists raw_vault.hub_product_category cascade;
create table if not exists raw_vault.hub_product_category (
    hub_product_category_hash char(32) not null,
    product_category_name varchar not null,
    load_date timestamp not null default CURRENT_TIMESTAMP,
    record_source varchar not null,
    batch_id int not null,
    constraint pk_raw_vault_hub_product_category primary key (hub_product_category_hash)
)

-------------------------------------------------------------------------------
-- 3. LINKS (Глаголы / Отношения)
-- Фиксируют связи между Хабами. Без описательных полей.
-------------------------------------------------------------------------------

-- Link order_item: Кто (Seller) продал Что (Product) в рамках Чего (Order)
-- drop table if exists raw_vault.link_order_items cascade;
create table if not exists raw_vault.link_order_items (
    link_order_item_hash char(32) not null, --MD5(order_id + product_id + seller_id)
    hub_order_hash char(32) not null,
    hub_product_hash char(32) not null,
    hub_seller_hash char(32) not null,
    load_date timestamp not null default current_timestamp,
    record_source varchar not null,
    batch_id int not null,
    constraint pk_raw_vault_link_order_items primary key (link_order_item_hash)
);

-- Link order_review: Связь отзыва с заказом
-- drop table if exists raw_vault.link_order_review cascade;
create table if not exists raw_vault.link_order_review (
    link_order_review_hash char(32) not null,
    hub_review_hash char(32) not null,
    hub_order_hash char(32) not null,
    load_date timestamp not null default current_timestamp,
    record_source varchar not null,
    batch_id int not null,
    constraint pk_raw_vault_link_order_review primary key (link_order_review_hash)
);

-- Link order_customer: Связь транзакции с человеком
-- drop table if exists raw_vault.link_order_customer cascade;
create table if not exists raw_vault.link_order_customer (
    link_order_customer_hash char(32) not null,
    hub_order_hash char(32) not null,
    hub_customer_hash char(32) not null,
    load_date timestamp not null default current_timestamp,
    record_source varchar not null,
    batch_id int not null,
    constraint pk_raw_vault_link_order_customer primary key (link_order_customer_hash)
);

-- Link seller_geolocation: Связь продавца с геолокацией
-- drop table if exists raw_vault.link_seller_geolocation cascade;
create table if not exists raw_vault.link_seller_geolocation (
    link_seller_geolocation_hash char(32) not null,
    hub_seller_hash char(32) not null,
    hub_geolocation_hash char(32) not null,
    load_date timestamp not null default current_timestamp,
    record_source varchar not null,
    batch_id int not null,
    constraint pk_raw_vault_link_seller_geolocation primary key (link_seller_geolocation_hash)
);

-------------------------------------------------------------------------------
-- 4. SATELLITES (Прилагательные / Описание и История)
-- Хранят данные, которые могут меняться. Всегда Insert-Only.
-------------------------------------------------------------------------------

-- Satellite order_item_finance: Финансы и логистика строки заказа (к Link order_item)
-- drop table if exists raw_vault.sat_order_item_finance cascade;
create table if not exists raw_vault.sat_order_item_finance (
    link_order_item_hash char(32) not null,
    order_item_id int,
    shipping_limit_date timestamp, 
    price numeric(12, 2),
    freight_value numeric(12, 2),
    hash_diff char(32) not null,
    load_date timestamp not null,
    record_source varchar not null,
    batch_id int not null,
    constraint pk_raw_vault_sat_order_item_finance primary key (link_order_item_hash, load_date)
);

-- Satellite order_status: Жизненный цикл заказа (к Hub Order)
-- drop table if exists raw_vault.sat_order_status cascade;
create table if not exists raw_vault.sat_order_status (
    hub_order_hash char(32) not null, -- Часть PK
    order_status  varchar,
    order_purchase_timestamp timestamp,
    order_approved_at timestamp,
    order_delivered_carrier_date timestamp,
    order_delivered_customer_date timestamp,
    order_estimated_delivery_date timestamp,
    hash_diff char(32) not null, -- Хэш всех полей выше для дельта-загрузки
    load_date timestamp not null, -- Часть PK
    record_source varchar not null,
    batch_id int not null,
    constraint pk_raw_vault_sat_order_status primary key (hub_order_hash, load_date)
);

-- Satellite order_payments: Мульти-активный сателлит (т.к. платежей у заказа может быть >1)
-- drop table if exists raw_vault.sat_order_payments cascade;
create table if not exists raw_vault.sat_order_payments (
    hub_order_hash char(32) not null,
    payment_sequential int, -- Доп. ключ уникальности (sub-key)
    payment_type varchar,
    payment_installments int,
    payment_value numeric(12, 2),
    hash_diff char(32) not null,
    load_date timestamp not null,
    record_source varchar not null,
    batch_id int not null,
    constraint pk_raw_vault_sat_order_payments primary key (hub_order_hash, load_date, payment_sequential)
);

-- Sat Customer Details: Описание клиента (к Hub Customer)
-- DROP TABLE IF EXISTS raw_vault.sat_customer_details CASCADE;
create table if not exists raw_vault.sat_customer_details (
    hub_customer_hash char(32) not null,
    customer_city varchar,
    customer_state varchar,
    zip_code_prefix integer,
    hash_diff char(32) not null,
    load_date timestamp not null,
    record_source varchar not null,
    batch_id int not null,
    constraint pk_raw_vault_sat_customer_details primary key (hub_customer_hash, load_date)
);

-- Sat Product Details: Физические параметры товара (к Hub Product)
-- DROP TABLE IF EXISTS raw_vault.sat_product_details CASCADE;
CREATE TABLE IF NOT EXISTS raw_vault.sat_product_details (
    hub_product_hash     CHAR(32) NOT NULL,
    category_name       VARCHAR,
    name_length         INTEGER,
    description_length  INTEGER,
    photos_qty          INTEGER,
    weight_g            NUMERIC(12, 2),
    length_cm           NUMERIC(12, 2),
    height_cm           NUMERIC(12, 2),
    width_cm            NUMERIC(12, 2),
    hash_diff           CHAR(32) NOT NULL,
    load_date           TIMESTAMP NOT NULL,
    record_source       VARCHAR NOT NULL,
    batch_id            INTEGER NOT NULL,
    constraint pk_raw_vault_sat_product_details primary key (hub_product_hash, load_date)
);


-- Satellite order_reviews: Детали отзывов (к hub review)
-- drop table if exists raw_vault.sat_review_details cascade;
create table if not exists raw_vault.sat_review_details (
    hub_review_hash char(32) not null,
    review_score int,
    review_comment_title varchar,
    review_comment_message text,
    review_creation_date timestamp,
    review_answer_timestamp timestamp,
    hash_diff char(32) not null,
    load_date timestamp not null,
    record_source varchar not null,
    batch_id INTEGER NOT NULL,
    constraint pk_raw_vault_sat_review_details primary key (hub_review_hash, load_date)
);

-------------------------------------------------------------------------------
-- 5. ИНДЕКСЫ ДЛЯ ПРОИЗВОДИТЕЛЬНОСТИ
-------------------------------------------------------------------------------
-- Индексы на Foreign Keys (логические), чтобы ускорить JOIN-ы при сборке витрин
CREATE INDEX IF NOT EXISTS idx_link_item_order ON raw_vault.link_order_items (hub_order_hash);
CREATE INDEX IF NOT EXISTS idx_link_item_prod  ON raw_vault.link_order_items (hub_product_hash);
CREATE INDEX IF NOT EXISTS idx_link_item_seller ON raw_vault.link_order_items (hub_seller_hash);
CREATE INDEX IF NOT EXISTS idx_sat_order_status_h ON raw_vault.sat_order_status (hub_order_hash);