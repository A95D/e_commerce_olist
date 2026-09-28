select 
    md5(upper(trim(order_id)) || '|' || payment_sequential::text) as hub_payment_hash,
    trim(order_id) as order_id,
    payment_sequential,
    trim(payment_type) as payment_type,
    payment_installments,
    payment_value,
    batch_id,
    load_date,
    source_name as record_source
from {{ source('olist_raw', 'order_payments') }}