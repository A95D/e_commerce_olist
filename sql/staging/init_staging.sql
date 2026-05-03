-- 1. Создание схемы staging
create schema if not exists staging;

-- 2. Создание staging таблиц
-- 2.1 Staging таблица для клиентов

-- drop table if exists staging.stg_customers cascade; 
create table if not exists staging.stg_customers (
    customer_id varchar not null,
    customer_unique_id varchar,
    customer_zip_code_prefix int,
    customer_city varchar,
    customer_state varchar,
    batch_id int not null,
    load_date timestamp default current_timestamp,
    source_name varchar,
    is_deleted boolean default false
);

-- 2.2 Staging таблица для геолокации
-- drop table if exists staging.stg_geolocation cascade;
create table if not exists staging.stg_geolocation (
    geolocation_zip_code_prefix int,
    geolocation_lat numeric(18, 14),
    geolocation_lng numeric(18, 14),
    geolocation_city varchar,
    geolocation_state varchar,
    batch_id int not null,
    load_date timestamp default current_timestamp,
    source_name varchar,
    is_deleted boolean default false
);

-- 2.3 Staging таблица для товаров в заказах
-- drop table if exists staging.stg_order_items cascade;
create table if not exists staging.stg_order_items (
    order_id varchar not null,
    order_item_id int,
    product_id varchar,
    seller_id varchar,
    shipping_limit_date timestamp,
    price numeric(12, 2),
    freight_value numeric(12, 2),
    batch_id int not null,
    load_date timestamp default current_timestamp,
    source_name varchar,
    is_deleted boolean default false
);

-- 2.4 Staging таблица для платежей заказов
-- drop table if exists staging.stg_order_payments cascade;
create table if not exists staging.stg_order_payments (
    order_id varchar not null,
    payment_sequential int,
    payment_type varchar,
    payment_installments int,
    payment_value numeric(12, 2),
    batch_id int not null,
    load_date timestamp default current_timestamp,
    source_name varchar,
    is_deleted boolean default false            
);

-- 2.5 Staging таблица для отзывов
-- drop table if exists staging.stg_order_reviews cascade;
create table if not exists staging.stg_order_reviews (
    review_id varchar not null,
    order_id varchar,
    review_score int,
    review_comment_title varchar,
    review_comment_message text,
    review_creation_date timestamp,
    review_answer_timestamp timestamp,
    batch_id int not null,
    load_date timestamp default current_timestamp,
    source_name varchar,
    is_deleted boolean default false
);

-- 2.6 Staging таблица для заказов
-- drop table if exists staging.stg_orders cascade;
create table if not exists staging.stg_orders (
    order_id varchar not null,
    customer_id varchar,
    order_status varchar,
    order_purchase_timestamp timestamp,
    order_approved_at timestamp,
    order_delivered_carrier_date timestamp,
    order_delivered_customer_date timestamp,
    order_estimated_delivery_date timestamp,
    batch_id int not null,
    load_date timestamp default current_timestamp,
    source_name varchar,
    is_deleted boolean default false
);

-- 2.7 Staging таблица для товаров  
-- drop table if exists staging.stg_products cascade;
create table if not exists staging.stg_products (
    product_id varchar not null,
    product_category_name varchar,
    product_name_length int,
    product_description_length int,
    product_photos_qty int,
    product_weight_g numeric(12, 2),
    product_length_cm numeric(12, 2),
    product_height_cm numeric(12, 2),
    product_width_cm numeric(12, 2),
    batch_id int not null,
    load_date timestamp default current_timestamp,
    source_name varchar,
    is_deleted boolean default false
);

-- 2.8 Staging таблица для продавцов
-- drop table if exists staging.stg_sellers cascade;
create table if not exists staging.stg_sellers (
    seller_id varchar not null,
    seller_zip_code_prefix int,
    seller_city varchar,
    seller_state varchar,
    batch_id int not null,
    load_date timestamp default current_timestamp,
    source_name varchar,
    is_deleted boolean default false
);

-- 2.9 Staging таблица для перевода категорий
-- drop table if exists staging.stg_product_category_translation cascade;
create table if not exists staging.stg_product_category_translation (
    product_category_name varchar not null,
    product_category_name_english varchar,
    batch_id int not null,
    load_date timestamp default current_timestamp,
    source_name varchar,
    is_deleted boolean default false
);

-- 3. Создание индексов для оптимизации запросов
--drop index if exists idx_stg_customers_id cascade;
--drop index if exists idx_stg_customers_batch cascade;
create index if not exists idx_stg_customers_id on staging.stg_customers (customer_id);
create index if not exists idx_stg_customers_batch on staging.stg_customers (batch_id);

--drop index if exists idx_stg_geolocation_zip cascade;
--drop index if exists idx_stg_geolocation_batch cascade;
create index if not exists idx_stg_geolocation_zip on staging.stg_geolocation (geolocation_zip_code_prefix);
create index if not exists idx_stg_geolocation_batch on staging.stg_geolocation (batch_id); 

--drop index if exists idx_stg_order_items_order cascade;
--drop index if exists idx_stg_order_items_product cascade;
create index if not exists idx_stg_orders_id on staging.stg_orders (order_id);
create index if not exists idx_stg_orders_customer on staging.stg_orders (customer_id);
create index if not exists idx_stg_orders_batch on staging.stg_orders (batch_id);

--drop index if exists idx_stg_order_items_order cascade;
--drop index if exists idx_stg_order_items_product cascade;
create index if not exists idx_stg_order_items_order on staging.stg_order_items (order_id);
create index if not exists idx_stg_order_items_product on staging.stg_order_items (product_id);
create index if not exists idx_stg_order_items_batch on staging.stg_order_items (batch_id);

--drop index if exists idx_stg_order_payments_order cascade;
--drop index if exists idx_stg_order_payments_batch cascade;
create index if not exists idx_stg_order_payments_order on staging.stg_order_payments (order_id);
create index if not exists idx_stg_order_payments_batch on staging.stg_order_payments (batch_id);

--drop index if exists idx_stg_order_reviews_order cascade;
--drop index if exists idx_stg_order_reviews_batch cascade;
create index if not exists idx_stg_order_reviews_order on staging.stg_order_reviews (order_id); 
create index if not exists idx_stg_order_reviews_batch on staging.stg_order_reviews (batch_id);

--drop index if exists idx_stg_products_id cascade;
--drop index if exists idx_stg_products_batch cascade;
create index if not exists idx_stg_products_id on staging.stg_products (product_id);
create index if not exists idx_stg_products_batch on staging.stg_products (batch_id);

--drop index if exists idx_stg_sellers_id cascade;
--drop index if exists idx_stg_sellers_batch cascade;
create index if not exists idx_stg_sellers_id on staging.stg_sellers (seller_id);
create index if not exists idx_stg_sellers_batch on staging.stg_sellers (batch_id);

--drop index if exists idx_stg_product_category_translation_batch cascade;
create index if not exists idx_stg_product_category_translation_batch on staging.stg_product_category_translation (batch_id);