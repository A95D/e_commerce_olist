select 
    -- 1. Хэш линка link_order_items
    md5(upper(trim(order_id)) || '|' || upper(trim(product_id)) || '|' || upper(trim(seller_id)) || '|' || order_item_id::text) as link_order_item_hash,
    
    -- 2. Внешние хэши для Хабов
    md5(upper(trim(order_id))) as hub_order_hash,
    md5(upper(trim(product_id))) as hub_product_hash, 
    md5(upper(trim(seller_id))) as hub_seller_hash,

    -- Атрибуты
    trim(order_id) as order_id,
    order_item_id,
    trim(product_id) as product_id,
    trim(seller_id) as seller_id,
    shipping_limit_date,
    price,
    freight_value,
    batch_id,
    load_date,
    source_name as record_source
from {{ source('olist_raw', 'order_items') }}