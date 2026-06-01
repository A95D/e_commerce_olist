--DROP PROCEDURE IF EXISTS raw_vault.load_olist_order_items(INT, TIMESTAMP, VARCHAR);

create or replace procedure raw_vault.load_olist_order_items(p_batch_id int, p_load_date timestamp without time zone, p_source_name varchar)
language plpgsql
as $$
BEGIN
    --1. Логируем ошибки (Те, что не пройдут проверку типов или бизнес-ключей)
    --Один запрос на весь батч
    insert into raw_vault.etl_audit_log(batch_id, error_msg, failed_payload)
    select 
        p_batch_id,
        'Отсутствует бизнес-ключ: order_id или product_id is NULL',
        stg
    from staging.stg_order_items stg
    where batch_id = p_batch_id
        and (order_id is null or product_id is null or seller_id is null);

    -------------------------------------------------------------------------------
    -- 2. ЗАГРУЗКА ХАБОВ
    -------------------------------------------------------------------------------
    
    -- 2.1 Hub customer
    insert into raw_vault.hub_customer (hub_customer_hash, customer_unique_id, load_date, record_source, batch_id)
    select DISTINCT
        md5(upper(trim(customer_unique_id))),
        upper(trim(customer_unique_id)),
        p_load_date,
        p_source_name,
        p_batch_id
    from staging.stg_customers
    where batch_id = p_batch_id 
        and customer_unique_id is not null
    on conflict(hub_customer_hash) do nothing;

    --2.2 Hub seller
    insert into raw_vault.hub_seller(hub_seller_hash, seller_id, load_date, record_source, batch_id)
    select DISTINCT
        md5(upper(trim(seller_id))),
        upper(trim(seller_id)),
        p_load_date,
        p_source_name,
        p_batch_id
    from staging.stg_sellers
    where batch_id = p_batch_id 
        and seller_id is not null
    on conflict(hub_seller_hash) do nothing;

    --2.3 Hub geolocation
    insert into raw_vault.hub_geolocation(hub_geolocation_hash, zip_code_prefix, load_date, record_source, batch_id)
    select DISTINCT
        md5(upper(trim(geolocation_zip_code_prefix::text))),
        upper(trim(geolocation_zip_code_prefix::text)),
        p_load_date,
        p_source_name,
        p_batch_id
    from staging.stg_geolocation
    where batch_id = p_batch_id
        and geolocation_zip_code_prefix is not null
    on conflict(hub_geolocation_hash) do nothing;

    --2.4 Hub order
    insert into raw_vault.hub_order (hub_order_hash, order_id, load_date, record_source, batch_id)
    select distinct 
        md5(upper(trim(order_id))),
        upper(trim(order_id)),
        p_load_date,
        p_source_name,
        p_batch_id
    from staging.stg_order_items
    where batch_id = p_batch_id
        and order_id is not null
    on conflict(hub_order_hash) do nothing;

    --2.5 Hub product
    insert into raw_vault.hub_product (hub_product_hash, product_id, load_date, record_source, batch_id)
    select DISTINCT
        md5(upper(trim(product_id))),
        upper(trim(product_id)),
        p_load_date,
        p_source_name,
        p_batch_id
    from staging.stg_order_items
    where batch_id = p_batch_id
        and product_id is not null
    on conflict(hub_product_hash) do nothing;

    --2.6 Hub review
    insert into raw_vault.hub_review (hub_review_hash, review_id, load_date, record_source, batch_id)
    select distinct
        md5(upper(trim(review_id))),
        upper(trim(review_id)),
        p_load_date,
        p_source_name,
        p_batch_id
    from staging.stg_order_reviews
    where batch_id = p_batch_id
        and review_id is not null
    on conflict(hub_review_hash) do nothing;


    --2.6 Hub product category
    insert into raw_vault.hub_product_category (hub_product_category_hash, product_category_name, load_date, record_source, batch_id)
    select distinct
        md5(upper(trim(product_category_name))),
        upper(trim(product_category_name)),
        p_load_date,
        p_source_name,
        p_batch_id
    from staging.stg_product_category_translation
    where batch_id = p_batch_id
        and product_category_name is not null
    on conflict(hub_product_category_hash) do nothing;


    -------------------------------------------------------------------------------
    -- 3. ЗАГРУЗКА ЛИНКОВ
    -------------------------------------------------------------------------------

    -- 3.1 Link order_item
    insert into raw_vault.link_order_items (
        link_order_item_hash,
        hub_order_hash,
        hub_product_hash,
        hub_seller_hash,
        load_date,
        record_source,
        batch_id
    )
    select 
        md5(upper(trim(order_id)) || '|' || upper(trim(product_id)) || '|' || upper(trim(seller_id)) || '|' || order_item_id::text),
        md5(upper(trim(order_id))),
        md5(upper(trim(product_id))),
        md5(upper(trim(seller_id))),
        p_load_date,
        p_source_name,
        p_batch_id
    from staging.stg_order_items
    where batch_id = p_batch_id
        and order_id is not NULL
        and product_id is not NULL
        and seller_id is not null
    on conflict (link_order_item_hash) do nothing;


    ---3.2 Link order_review
    insert into raw_vault.link_order_review (
        link_order_review_hash,
        hub_review_hash,
        hub_order_hash,
        load_date,
        record_source,
        batch_id 
    )
    select 
        md5(upper(trim(review_id)) || '|' || upper(trim(order_id))),
        md5(upper(trim(review_id))),
        md5(upper(trim(order_id))),
        p_load_date,
        p_source_name,  
        p_batch_id
    from staging.stg_order_reviews
    where batch_id = p_batch_id
        and review_id is not NULL
        and order_id is not NULL
    on conflict(link_order_review_hash) do nothing;

    --3.3 Link order_customer
    insert into raw_vault.link_order_customer (
        link_order_customer_hash,
        hub_order_hash,
        hub_customer_hash,
        load_date,
        record_source,
        batch_id    
    )
    select 
        md5(upper(trim(order_id)) || '|' || upper(trim(customer_unique_id))),
        md5(upper(trim(order_id))),
        md5(upper(trim(customer_unique_id))),
        p_load_date,
        p_source_name,
        p_batch_id
    from staging.stg_orders o
    join staging.stg_customers c on o.customer_id = c.customer_id
    where o.batch_id = p_batch_id
        and o.order_id is not NULL
        and c.customer_unique_id is not NULL
    on conflict(link_order_customer_hash) do nothing;

    --3.4 Link seller_geolocation
    insert into raw_vault.link_seller_geolocation (
        link_seller_geolocation_hash,
        hub_seller_hash,
        hub_geolocation_hash,
        load_date,
        record_source,
        batch_id
    )
    select 
        md5(upper(trim(seller_id)) || '|' || upper(trim(seller_zip_code_prefix::text))),
        md5(upper(trim(seller_id))),
        md5(upper(trim(seller_zip_code_prefix::text))),
        p_load_date,
        p_source_name,
        p_batch_id
    from staging.stg_sellers
    where batch_id = p_batch_id
        and seller_id is not NULL
        and seller_zip_code_prefix is not NULL
    on conflict(link_seller_geolocation_hash) do nothing;

    -------------------------------------------------------------------------------
    -- 4. ЗАГРУЗКА САТЕЛЛИТОВ
    -------------------------------------------------------------------------------

    -- 4.1 Satellite order_item_finance (Сателлит Линка)
    insert into raw_vault.sat_order_item_finance (
        link_order_item_hash,
        order_item_id,
        shipping_limit_date,
        price,
        freight_value,
        hash_diff,
        load_date,
        record_source,
        batch_id
    )
    select 
        src.link_hash,
        src.order_item_id,
        src.shipping_limit_date,
        src.price,
        src.freight_value,
        src.row_hash,
        p_load_date,
        p_source_name,
        p_batch_id
    from (
        select
            --Ключ связи (бизнес-ключ + разделители)
            md5(upper(trim(order_id)) || '|' || upper(trim(product_id)) || '|' || upper(trim(seller_id)) || '|' || order_item_id::text) as link_hash,
            order_item_id,
            shipping_limit_date,
            price,
            freight_value,
            -- Hash diff для отслеживания изменений в атрибутах
            md5(
                coalesce(price::text, 'null') || '|' ||
                coalesce(freight_value::text, 'null')
            ) as row_hash
        from staging.stg_order_items
        where batch_id = p_batch_id
            and order_id is not NULL
            and product_id is not NULL
            and seller_id is not NULL
        ) src
    where not exists (
        -- Логика Delta Check: вставляем только если данных еще нет 
        -- или если последние данные отличаются от текущих (по hash_diff)
        select 1
        from raw_vault.sat_order_item_finance as latest
        where latest.link_order_item_hash = src.link_hash
            and latest.load_date = (
                select max(load_date)
                from raw_vault.sat_order_item_finance
                where link_order_item_hash = src.link_hash
            )
            and latest.hash_diff = src.row_hash);

    -- 4.2 Satellite order_status (Сателлит Хаба Заказов)
        insert into raw_vault.sat_order_status (
        hub_order_hash,
        order_status,
        order_purchase_timestamp,
        order_approved_at,
        order_delivered_carrier_date,
        order_delivered_customer_date,
        order_estimated_delivery_date,
        hash_diff,
        load_date,
        record_source,
        batch_id
    )
    select 
        src.link_hash,
        src.order_status,
        src.order_purchase_timestamp,
        src.order_approved_at,
        src.order_delivered_carrier_date,
        src.order_delivered_customer_date,
        src.order_estimated_delivery_date,
        src.row_hash,
        p_load_date,
        p_source_name,
        p_batch_id
    from (
        select
            --Ключ связи (бизнес-ключ + разделители)
            md5(upper(trim(order_id))) as link_hash,
            order_status,
            order_purchase_timestamp,
            order_approved_at,
            order_delivered_carrier_date,
            order_delivered_customer_date,
            order_estimated_delivery_date,
            -- Hash diff для отслеживания изменений в атрибутах
            md5(
                coalesce(order_status::text, 'null') || '|' ||
                coalesce(order_purchase_timestamp::text, 'null') || '|' ||
                coalesce(order_approved_at::text, 'null') || '|' ||
                coalesce(order_delivered_carrier_date::text, 'null') || '|' ||
                coalesce(order_delivered_customer_date::text, 'null') || '|' ||
                coalesce(order_estimated_delivery_date::text, 'null')
            ) as row_hash
        from staging.stg_orders
        where batch_id = p_batch_id
            and order_id is not NULL
        ) src
    where not exists (
        -- Логика Delta Check: вставляем только если данных еще нет 
        -- или если последние данные отличаются от текущих (по hash_diff)
        select 1
        from raw_vault.sat_order_status as latest
        where latest.hub_order_hash = src.link_hash
            and latest.load_date = (
                select max(load_date)
                from raw_vault.sat_order_status
                where hub_order_hash = src.link_hash
            )
            and latest.hash_diff = src.row_hash);


    -- 4.3 Satellite sat_order_payments (Multi-Active Сателлит Хаба заказов)
    insert into raw_vault.sat_order_payments (
        hub_order_hash,
        payment_sequential,
        payment_type,
        payment_installments,
        payment_value,
        hash_diff,
        load_date,
        record_source,
        batch_id
    )
    select 
        src.link_hash,
        src.payment_sequential,
        src.payment_type,
        src.payment_installments,
        src.payment_value,
        src.row_hash,
        p_load_date,
        p_source_name,
        p_batch_id
    from (
        select
            --Ключ связи (бизнес-ключ + разделители)
            md5(upper(trim(order_id))) as link_hash,
            payment_sequential,
            payment_type,
            payment_installments,
            payment_value,
            -- Hash diff для отслеживания изменений в атрибутах
            md5(
                coalesce(payment_type::text, 'null') || '|' ||
                coalesce(payment_installments::text, 'null') || '|' ||
                coalesce(payment_value::text, 'null')
            ) as row_hash
        from staging.stg_order_payments
        where batch_id = p_batch_id
            and order_id is not NULL
        ) src
    where not exists (
        -- Логика Delta Check: вставляем только если данных еще нет 
        -- или если последние данные отличаются от текущих (по hash_diff)
        select 1
        from raw_vault.sat_order_payments as latest
        where latest.hub_order_hash = src.link_hash
            and latest.payment_sequential = src.payment_sequential
            and latest.load_date = (
                select max(load_date)
                from raw_vault.sat_order_payments
                where hub_order_hash = src.link_hash
                    and payment_sequential = src.payment_sequential
            )
            and latest.hash_diff = src.row_hash);

    -- 4.4 Сателлит Customer Details (Сателлит Хаба Клиентов)
    insert into raw_vault.sat_customer_details (
        hub_customer_hash,
        customer_city,
        customer_state,
        zip_code_prefix,
        hash_diff,
        load_date,
        record_source,
        batch_id
    )
    select 
        src.link_hash,
        src.customer_city,
        src.customer_state,
        src.customer_zip_code_prefix,
        src.row_hash,
        p_load_date,
        p_source_name,
        p_batch_id
    from (
        select
            --Ключ связи (бизнес-ключ + разделители)
            md5(upper(trim(customer_unique_id))) as link_hash,
            customer_city,
            customer_state,
            customer_zip_code_prefix,
            -- Hash diff для отслеживания изменений в атрибутах
            md5(
                coalesce(customer_city::text, 'null') || '|' ||
                coalesce(customer_state::text, 'null') || '|' ||
                coalesce(customer_zip_code_prefix::text, 'null')
            ) as row_hash,
            row_number() over (partition by customer_unique_id order by customer_id) rn
        from staging.stg_customers
        where batch_id = p_batch_id
            and customer_unique_id is not NULL
        ) src
    where src.rn = 1
        and not exists (
        -- Логика Delta Check: вставляем только если данных еще нет 
        -- или если последние данные отличаются от текущих (по hash_diff)
        select 1
        from raw_vault.sat_customer_details as latest
        where latest.hub_customer_hash = src.link_hash
            and latest.load_date = (
                select max(load_date)
                from raw_vault.sat_customer_details
                where hub_customer_hash = src.link_hash
            )
            and latest.hash_diff = src.row_hash);

    -- 4.5 Сателлит Product Details (Сателлит Хаба Товаров)
    insert into raw_vault.sat_product_details (
        hub_product_hash,
        category_name,
        name_length,
        description_length,
        photos_qty,
        weight_g,
        length_cm,
        height_cm,
        width_cm,
        hash_diff,
        load_date,
        record_source,
        batch_id
    )
    select 
        src.link_hash,
        src.product_category_name,
        src.product_name_length,
        src.product_description_length,
        src.product_photos_qty,
        src.product_weight_g,
        src.product_length_cm,
        src.product_height_cm,
        src.product_width_cm,
        src.row_hash,
        p_load_date,
        p_source_name,
        p_batch_id
    from (
        select
            --Ключ связи (бизнес-ключ + разделители)
            md5(upper(trim(product_id))) as link_hash,
            product_category_name,
            product_name_length,
            product_description_length,
            product_photos_qty,
            product_weight_g,
            product_length_cm,
            product_height_cm,
            product_width_cm,
            -- Hash diff для отслеживания изменений в атрибутах
            md5(
                coalesce(product_weight_g::text, 'null') || '|' ||
                coalesce(product_length_cm::text, 'null') || '|' ||
                coalesce(product_height_cm::text, 'null') || '|' ||
                coalesce(product_width_cm::text, 'null')
            ) as row_hash
        from staging.stg_products
        where batch_id = p_batch_id
            and product_id is not NULL
        ) src
    where not exists (
        -- Логика Delta Check: вставляем только если данных еще нет 
        -- или если последние данные отличаются от текущих (по hash_diff)
        select 1
        from raw_vault.sat_product_details as latest
        where latest.hub_product_hash = src.link_hash
            and latest.load_date = (
                select max(load_date)
                from raw_vault.sat_product_details
                where hub_product_hash = src.link_hash
            )
            and latest.hash_diff = src.row_hash);


    -- 4.6 Сателлит order_reviews (Сателлит Хаба Отзывов)
    insert into raw_vault.sat_review_details (
        hub_review_hash,
        review_score,
        review_comment_title,
        review_comment_message,
        review_creation_date,
        review_answer_timestamp,
        hash_diff,
        load_date,
        record_source,
        batch_id
    )
    select 
        src.link_hash,
        src.review_score,
        src.review_comment_title,
        src.review_comment_message,
        src.review_creation_date,
        src.review_answer_timestamp,
        src.row_hash,
        p_load_date,
        p_source_name,
        p_batch_id
    from (
        select
            --Ключ связи (бизнес-ключ + разделители)
            md5(upper(trim(review_id))) as link_hash,
            review_score,
            review_comment_title,
            review_comment_message,
            review_creation_date,
            review_answer_timestamp,
            -- Hash diff для отслеживания изменений в атрибутах
            md5(
                coalesce(review_score::text, 'null') || '|' ||
                coalesce(review_comment_message::text, 'null') || '|' ||
                coalesce(review_answer_timestamp::text, 'null')
            ) as row_hash,
            row_number() over (partition by review_id order by order_id) rn
        from staging.stg_order_reviews
        where batch_id = p_batch_id
            and order_id is not NULL
        ) src
    where src.rn = 1 
        and not exists (
        -- Логика Delta Check: вставляем только если данных еще нет 
        -- или если последние данные отличаются от текущих (по hash_diff)
        select 1
        from raw_vault.sat_review_details as latest
        where latest.hub_review_hash = src.link_hash
            and latest.load_date = (
                select max(load_date)
                from raw_vault.sat_review_details
                where hub_review_hash = src.link_hash
            )
            and latest.hash_diff = src.row_hash);


exception
    when others then  
        insert into raw_vault.etl_audit_log(batch_id, error_msg, failed_payload)
        values(p_batch_id, 'CRITICAL_FAILURE ' || SQLERRM, 'Whole batch failed');
        raise;
end;
$$;