-- ===============================================================================
-- БРОНЕБОЙНЫЙ СЛОЙ STAGING С ПРЕДВАРИТЕЛЬНЫМ ПРИВЕДЕНИЕМ ТИПОВ (load_staging.sql)
-- ===============================================================================

-- 1. Загрузка customers
CREATE or replace procedure staging.load_customers(p_batch_id INT, p_source_name VARCHAR)
language plpgsql
as $$
declare 
    v_load_date timestamp := current_timestamp;
begin
    delete from staging.stg_customers where batch_id = p_batch_id;

    insert into staging.stg_customers (
        customer_id, customer_unique_id, customer_zip_code_prefix, 
        customer_city, customer_state, batch_id, load_date, source_name
    )
    select 
        upper(trim(customer_id)) as customer_id,                                            
        upper(trim(customer_unique_id)) as customer_unique_id,
        -- Исправлено: приведение к ::text перед trim предотвращает ошибку btrim(integer)
        nullif(trim(both E'\r\n\t ' from customer_zip_code_prefix::text), '')::int as customer_zip_code_prefix, 
        upper(trim(customer_city)) as customer_city,
        upper(trim(customer_state)) as customer_state,                               
        p_batch_id,
        v_load_date as load_date,
        p_source_name as source_name
    from ext.olist_customers;

exception
    when others then 
        insert into raw_vault.etl_audit_log(batch_id, error_msg, failed_payload)
        values (p_batch_id, SQLERRM, 'Table: stg_customers');
        raise exception 'Ошибка в процедуре load_customers для batch_id %: %', p_batch_id, SQLERRM;
end;
$$;

-- 2. Загрузка geolocation
CREATE or replace procedure staging.load_geolocation(p_batch_id INT, p_source_name varchar)
language plpgsql
as $$
declare 
    v_load_date timestamp := current_timestamp;
BEGIN
    delete from staging.stg_geolocation where batch_id = p_batch_id;

    insert into staging.stg_geolocation (
        geolocation_zip_code_prefix, geolocation_lat, geolocation_lng,
        geolocation_city, geolocation_state, batch_id, load_date, source_name
    )
    select 
        nullif(trim(both E'\r\n\t ' from geolocation_zip_code_prefix::text), '')::int as geolocation_zip_code_prefix,
        nullif(trim(both E'\r\n\t ' from geolocation_lat::text), '')::numeric(18,14) as geolocation_lat,
        nullif(trim(both E'\r\n\t ' from geolocation_lng::text), '')::numeric(18,14) as geolocation_lng,
        upper(trim(geolocation_city)) as geolocation_city,
        upper(trim(geolocation_state)) as geolocation_state,
        p_batch_id,
        v_load_date as load_date,
        p_source_name as source_name
    from ext.olist_geolocation;

exception
    when others then 
        insert into raw_vault.etl_audit_log(batch_id, error_msg, failed_payload)
        values (p_batch_id, SQLERRM, 'Table: stg_geolocation');
        raise exception 'Ошибка в процедуре load_geolocation для batch_id %: %', p_batch_id, SQLERRM;
end;
$$;

-- 3. Загрузка order_items
CREATE or replace procedure staging.load_order_items(p_batch_id INT, p_source_name varchar)
language plpgsql
as $$
declare 
    v_load_date timestamp := current_timestamp;
BEGIN
    delete from staging.stg_order_items where batch_id = p_batch_id;

    insert into staging.stg_order_items (
        order_id, order_item_id, product_id, seller_id,
        shipping_limit_date, price, freight_value, batch_id, load_date, source_name
    )
    select 
        trim(order_id) as order_id,
        nullif(trim(both E'\r\n\t ' from order_item_id::text), '')::int as order_item_id,
        trim(product_id) as product_id,
        trim(seller_id) as seller_id,
        nullif(trim(both E'\r\n\t ' from shipping_limit_date::text), '')::timestamp as shipping_limit_date,
        nullif(trim(both E'\r\n\t ' from price::text), '')::numeric(12,2) as price,
        nullif(trim(both E'\r\n\t ' from freight_value::text), '')::numeric(12,2) as freight_value,
        p_batch_id,
        v_load_date as load_date,
        p_source_name as source_name
    from ext.olist_order_items;

exception
    when others then 
        insert into raw_vault.etl_audit_log(batch_id, error_msg, failed_payload)
        values (p_batch_id, SQLERRM, 'Table: stg_order_items');
        raise exception 'Ошибка в процедуре load_order_items для batch_id %: %', p_batch_id, SQLERRM;
end;
$$;

-- 4. Загрузка order_payments
CREATE or replace procedure staging.load_order_payments(p_batch_id INT, p_source_name varchar)
language plpgsql
as $$
declare 
    v_load_date timestamp := current_timestamp;
BEGIN
    delete from staging.stg_order_payments where batch_id = p_batch_id;

    insert into staging.stg_order_payments (
        order_id, payment_sequential, payment_type, payment_installments,
        payment_value, batch_id, load_date, source_name
    )
    select 
        trim(order_id) as order_id,
        nullif(trim(both E'\r\n\t ' from payment_sequential::text), '')::int as payment_sequential,
        trim(payment_type) as payment_type,
        nullif(trim(both E'\r\n\t ' from payment_installments::text), '')::int as payment_installments,
        nullif(trim(both E'\r\n\t ' from payment_value::text), '')::numeric(12,2) as payment_value,
        p_batch_id,
        v_load_date as load_date,
        p_source_name as source_name
    from ext.olist_order_payments;

exception
    when others then 
        insert into raw_vault.etl_audit_log(batch_id, error_msg, failed_payload)
        values (p_batch_id, SQLERRM, 'Table: stg_order_payments');
        raise exception 'Ошибка в процедуре load_order_payments для batch_id %: %', p_batch_id, SQLERRM;
end;
$$;

-- 5. Загрузка order_reviews
CREATE or replace procedure staging.load_order_reviews(p_batch_id INT, p_source_name varchar)
language plpgsql
as $$
declare 
    v_load_date timestamp := current_timestamp;
BEGIN
    delete from staging.stg_order_reviews where batch_id = p_batch_id;

    insert into staging.stg_order_reviews (
        review_id, order_id, review_score, review_comment_title,
        review_comment_message, review_creation_date, review_answer_timestamp,
        batch_id, load_date, source_name
    )
    select 
        trim(review_id) as review_id,
        trim(order_id) as order_id,
        nullif(trim(both E'\r\n\t ' from review_score::text), '')::int as review_score,
        trim(review_comment_title) as review_comment_title,
        trim(review_comment_message) as review_comment_message,
        nullif(trim(both E'\r\n\t ' from review_creation_date::text), '')::timestamp as review_creation_date,
        nullif(trim(both E'\r\n\t ' from review_answer_timestamp::text), '')::timestamp as review_answer_timestamp,
        p_batch_id,
        v_load_date as load_date,
        p_source_name as source_name
    from ext.olist_order_reviews;

exception
    when others then 
        insert into raw_vault.etl_audit_log(batch_id, error_msg, failed_payload)
        values (p_batch_id, SQLERRM, 'Table: stg_order_reviews');
        raise exception 'Ошибка в процедуре load_order_reviews для batch_id %: %', p_batch_id, SQLERRM;
end;
$$;

-- 6. Загрузка orders
CREATE or replace procedure staging.load_orders(p_batch_id INT, p_source_name varchar)
language plpgsql
as $$
declare 
    v_load_date timestamp := current_timestamp;
BEGIN
    delete from staging.stg_orders where batch_id = p_batch_id;

    insert into staging.stg_orders (
        order_id, customer_id, order_status, order_purchase_timestamp,
        order_approved_at, order_delivered_carrier_date, order_delivered_customer_date,
        order_estimated_delivery_date, batch_id, load_date, source_name
        )
    select 
        upper(trim(order_id)) as order_id,
        upper(trim(customer_id)) as customer_id,
        trim(order_status) as order_status,
        nullif(trim(both E'\r\n\t ' from order_purchase_timestamp::text), '')::timestamp as order_purchase_timestamp,
        nullif(trim(both E'\r\n\t ' from order_approved_at::text), '')::timestamp as order_approved_at,
        nullif(trim(both E'\r\n\t ' from order_delivered_carrier_date::text), '')::timestamp as order_delivered_carrier_date,
        nullif(trim(both E'\r\n\t ' from order_delivered_customer_date::text), '')::timestamp as order_delivered_customer_date,
        nullif(trim(both E'\r\n\t ' from order_estimated_delivery_date::text), '')::timestamp as order_estimated_delivery_date,
        p_batch_id,
        v_load_date as load_date,
        p_source_name as source_name
    from ext.olist_orders;

exception
    when others then 
        insert into raw_vault.etl_audit_log(batch_id, error_msg, failed_payload)
        values (p_batch_id, SQLERRM, 'Table: stg_orders');
        raise exception 'Ошибка в процедуре load_orders для batch_id %: %', p_batch_id, SQLERRM;
end;
$$;

-- 7. Загрузка products (Сохранена исходная орфография ext-полей)
CREATE or replace procedure staging.load_products(p_batch_id INT, p_source_name varchar)
language plpgsql
as $$
declare 
    v_load_date timestamp := current_timestamp;
BEGIN
    delete from staging.stg_products where batch_id = p_batch_id;

    insert into staging.stg_products (
        product_id, product_category_name, product_name_length,
        product_description_length, product_photos_qty, product_weight_g,
        product_length_cm, product_height_cm, product_width_cm,
        batch_id, load_date, source_name
        )
    select 
        upper(trim(product_id)) as product_id,
        trim(product_category_name) as product_category_name,
        nullif(trim(both E'\r\n\t ' from product_name_lenght::text), '')::int as product_name_length,
        nullif(trim(both E'\r\n\t ' from product_description_lenght::text), '')::int as product_description_length,
        nullif(trim(both E'\r\n\t ' from product_photos_qty::text), '')::int as product_photos_qty,
        nullif(trim(both E'\r\n\t ' from product_weight_g::text), '')::numeric(12,2) as product_weight_g,
        nullif(trim(both E'\r\n\t ' from product_length_cm::text), '')::numeric(12,2) as product_length_cm,
        nullif(trim(both E'\r\n\t ' from product_height_cm::text), '')::numeric(12,2) as product_height_cm,
        nullif(trim(both E'\r\n\t ' from product_width_cm::text), '')::numeric(12,2) as product_width_cm,
        p_batch_id,
        v_load_date as load_date,
        p_source_name as source_name
    from ext.olist_products;

exception
    when others then 
        insert into raw_vault.etl_audit_log(batch_id, error_msg, failed_payload)
        values (p_batch_id, SQLERRM, 'Table: stg_products');
        raise exception 'Ошибка в процедуре load_products для batch_id %: %', p_batch_id, SQLERRM;
end;
$$;

-- 8. Загрузка olist_sellers
CREATE or replace procedure staging.load_sellers(p_batch_id INT, p_source_name varchar)
language plpgsql
as $$
declare 
    v_load_date timestamp := current_timestamp;
BEGIN
    delete from staging.stg_sellers where batch_id = p_batch_id;

    insert into staging.stg_sellers (
        seller_id, seller_zip_code_prefix, seller_city, seller_state,
        batch_id, load_date, source_name
        )
    select 
        upper(trim(seller_id)) as seller_id,
        nullif(trim(both E'\r\n\t ' from seller_zip_code_prefix::text), '')::int as seller_zip_code_prefix,
        trim(seller_city) as seller_city,
        trim(seller_state) as seller_state,
        p_batch_id,
        v_load_date as load_date,
        p_source_name as source_name
    from ext.olist_sellers;

exception
    when others then 
        insert into raw_vault.etl_audit_log(batch_id, error_msg, failed_payload)
        values (p_batch_id, SQLERRM, 'Table: stg_sellers');
        raise exception 'Ошибка в процедуре load_sellers для batch_id %: %', p_batch_id, SQLERRM;
end;
$$;

-- 9. Загрузка product_category_name_translation
CREATE or replace procedure staging.load_product_category_name_translation(p_batch_id INT, p_source_name varchar)
language plpgsql
as $$
declare 
    v_load_date timestamp := current_timestamp;
BEGIN
    delete from staging.stg_product_category_translation where batch_id = p_batch_id;

    insert into staging.stg_product_category_translation (
        product_category_name, product_category_name_english,
        batch_id, load_date, source_name
        )
    select 
        trim(product_category_name) as product_category_name,
        trim(product_category_name_english) as product_category_name_english,
        p_batch_id,
        v_load_date as load_date,
        p_source_name as source_name
    from ext.product_category_name_translation;

exception
    when others then 
        insert into raw_vault.etl_audit_log(batch_id, error_msg, failed_payload)
        values (p_batch_id, SQLERRM, 'Table: stg_product_category_translation');
        raise exception 'Ошибка в процедуре load_product_category_translation для batch_id %: %', p_batch_id, SQLERRM;
end;
$$;