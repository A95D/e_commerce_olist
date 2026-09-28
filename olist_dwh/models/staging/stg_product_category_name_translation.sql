select 
    md5(upper(trim(product_category_name))) as hub_product_category_hash,
    trim(product_category_name) as product_category_name,
    trim(product_category_name_english) as product_category_name_english,
    batch_id,
    load_date,
    source_name as record_source
from {{ source('olist_raw', 'product_category_name_translation') }}