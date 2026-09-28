select 
    md5(upper(trim(seller_id))) as hub_seller_hash,
    trim(seller_id) as seller_id,
    seller_zip_code_prefix,
    trim(seller_city) as seller_city,
    trim(seller_state) as seller_state,
    batch_id,
    load_date,
    source_name as record_source
from {{ source('olist_raw', 'sellers') }}