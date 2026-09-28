select 
    md5(upper(trim(product_id))) as hub_product_hash,
    trim(product_id) as product_id,
    trim(product_category_name) as product_category_name,
    product_name_length,
    product_description_length,
    product_photos_qty,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm,
    batch_id,
    load_date,
    source_name as record_source
from {{ source('olist_raw', 'products') }}