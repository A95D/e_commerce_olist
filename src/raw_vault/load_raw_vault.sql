create or replace procedure raw_vault.load_olist_order_items(p_batch_id int, p_load_date timestamp, p_source_name varchar)
language plpgsql
as $$
BEGIN
    --1. Логируем ошибки (Те, что не пройдут проверку типов или бизнес-ключей)
    --Один запрос на весь батч
    insert into raw_vault.etl_audit_log(batch_id, error_msg, failed_payload)
    select 
        p_batch_id,
        'Отсутствует бизнес-ключ: order_id или product_id is NULL',
        row_to_json(stg)
    from staging.stg_order_items stg
    where batch_id = p_batch_id
        and (order_id is null or product_id is null or seller_id is null);

    --2. Загружаем Хабы (только те записи, где есть ключи)
    --2.1 Хаб заказов
    insert into raw_vault.hub_order (hub_order_hash, order_id, load_date, record_source)
    select distinct 
        md5(upper(trim(order_id))),
        upper(trim(order_id)),
        p_load_date,
        p_source_name
    from staging.stg_order_items
    where batch_id = p_batch_id
        and order_id is not null
    on conflict(hub_order_hash) do nothing;

    --2.2 Хаб продуктов
    insert into raw_vault.hub_product (hub_product_hash, product_id, load_date, record_source)
    select DISTINCT
        md5(upper(trim(product_id))),
        upper(trim(product_id)),
        p_load_date,
        p_source_name
    from staging.stg_order_items
    where batch_id = p_batch_id
        and product_id is not null
    on conflict(hub_product_hash) do nothing;

    --3. Загружаем Линк
    insert into raw_vault.link_order_items (
        link_order_item_hash,
        hub_order_hash,
        hub_product_hash,
        load_date,
        record_source,
        batch_id
    )
    select 
        md5(upper(trim(order_id)) || '|' || upper(trim(product_id)) || '|' || order_item_id::text),
        md5(upper(trim(order_id))),
        md5(upper(trim(product_id))),
        p_load_date,
        p_source_name,
        p_batch_id
    from staging.stg_order_items
    where batch_id = p_batch_id
        and order_id is not NULL
        and product_id is not NULL
    on conflict (link_order_item_hash) do nothing;

    --4. Загружаем Сателлит
    insert into raw_vault.sat_order_item_finance (
        link_order_item_hash,
        price,
        freight_value,
        hash_diff,
        load_date,
        record_source
    )
    select 
        src.link_hash,
        src.price,
        src.freight_value,
        src.row_hash,
        p_load_date,
        p_source_name
    from (
        select
            --Ключ связи (бизнес-ключ + разделители)
            md5(upper(trim(order_id)) || '|' || upper(trim(product_id)) || '|' || order_item_id::text) as link_hash,
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
        from raw_vault.sat_order_item_finance latest
        where latest.link_order_item_hash = src.link_hash
            and latest.load_date = (
                select max(load_date)
                from raw_vault.sat_order_item_finance
                where link_order_item_hash = src.link_hash
            )
            and latest.hash_diff = src.row_hash);

exception
    when others then  
        insert into raw_vault.etl_audit_log(batch_id, error_msg, failed_payload)
        values(p_batch_id, 'CRITICAL_FAILURE ' || SQLERRM, 'Whole batch failed');
        raise;
end;
$$;