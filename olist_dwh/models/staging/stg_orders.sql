select 
    -- 1. Хэш линка link_order_customer
    md5(upper(trim(order_id)) || '|' || upper(trim(customer_id))) as link_order_customer_hash,

    -- 2. Внешние хэши для хабов
    md5(upper(trim(order_id))) as hub_order_hash,
    md5(upper(trim(customer_id))) as hub_customer_hash,
    

    trim(order_id) as order_id,
    trim(customer_id) as customer_id,
    trim(order_status) as order_status,
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_estimated_delivery_date,
    batch_id,
    load_date,
    source_name as record_source
from {{ source('olist_raw', 'orders') }}