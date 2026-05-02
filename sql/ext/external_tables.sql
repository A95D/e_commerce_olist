-- Настройка внешних таблиц для работы с данными 

-- 1. Включение расширения file_fdw для работы с файлами
create extension if not exists file_fdw;

-- 2. Создание сервера для доступа к файлам
create server if not exists olist_files foreign data wrapper file_fdw;

-- 3. Создание отдельной схемы для внешних таблиц
create schema if not exists ext;


-- 4. Создание внешних таблиц для файлов Olist

-- 4.1 Внешняя таблица для клиентов
create foreign table if not exists ext.olist_customers (
    customer_id varchar,
    customer_unique_id varchar,
    customer_zip_code_prefix int,
    customer_city varchar,
    customer_state varchar
)
server olist_files
options (filename '/opt/datasets/olist_customers_dataset.csv', format 'csv', header 'true', delimiter ',');

-- 4.2 Внешняя таблица для геолокации
create foreign table if not exists ext.olist_geolocation (
    geolocation_zip_code_prefix int,
    geolocation_lat numeric(18, 14),
    geolocation_lng numeric(18, 14),
    geolocation_city varchar,
    geolocation_state varchar
)
server olist_files
options (filename '/opt/datasets/olist_geolocation_dataset.csv', format 'csv', header 'true', delimiter ',');

-- 4.3 Внешняя таблица для товаров в заказах
create foreign table if not exists ext.olist_order_items (
    order_id varchar,
    order_item_id int,
    product_id varchar,
    seller_id varchar,
    shipping_limit_date timestamp,
    price numeric(12, 2),
    freight_value numeric(12, 2)
)
server olist_files
options (filename '/opt/datasets/olist_order_items_dataset.csv', format 'csv', header 'true', delimiter ',');

-- 4.4 Внешняя таблица для платежей заказов
create foreign table if not exists ext.olist_order_payments (
    order_id varchar,
    payment_sequential int,
    payment_type varchar,
    payment_installments int,
    payment_value numeric(12, 2)
)
server olist_files
options (filename '/opt/datasets/olist_order_payments_dataset.csv', format 'csv', header 'true', delimiter ',');

-- 4.5 Внешняя таблица для отзывов
create foreign table if not exists ext.olist_order_reviews (
    review_id varchar,
    order_id varchar,
    review_score int,
    review_comment_title varchar,
    review_comment_message varchar,
    review_creation_date date,
    review_answer_timestamp timestamp
)
server olist_files
options (filename '/opt/datasets/olist_order_reviews_dataset.csv', format 'csv', header 'true', delimiter ',');

-- 4.6 Внешняя таблица для заказов
create foreign table if not exists ext.olist_orders (
    order_id varchar,
    customer_id varchar,
    order_status varchar,
    order_purchase_timestamp timestamp,
    order_approved_at timestamp,
    order_delivered_carrier_date timestamp,
    order_delivered_customer_date timestamp,
    order_estimated_delivery_date timestamp
)
server olist_files
options (filename '/opt/datasets/olist_orders_dataset.csv', format 'csv', header 'true', delimiter ',');

-- 4.7 Внешняя таблица для товаров
create foreign table if not exists ext.olist_products (
    product_id varchar,
    product_category_name varchar,
    product_name_lenght int,
    product_description_lenght int,
    product_photos_qty int,
    product_weight_g int,
    product_length_cm int,
    product_height_cm int,
    product_width_cm int
)
server olist_files
options (filename '/opt/datasets/olist_products_dataset.csv', format 'csv', header 'true', delimiter ',');

-- 4.8 Внешняя таблица для продавцов
create foreign table if not exists ext.olist_sellers (
    seller_id varchar,
    seller_zip_code_prefix int,
    seller_city varchar,
    seller_state varchar
)
server olist_files
options (filename '/opt/datasets/olist_sellers_dataset.csv', format 'csv', header 'true', delimiter ',');

-- 4.9 Внешняя таблица для перевода категорий товаров
create foreign table if not exists ext.product_category_name_translation (
    product_category_name varchar,
    product_category_name_english varchar
)
server olist_files
options (filename '/opt/datasets/product_category_name_translation.csv', format 'csv', header 'true', delimiter ',');
