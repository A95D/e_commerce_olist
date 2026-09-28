select 
    md5(upper(trim(customer_unique_id))) as hub_customer_hash,
    upper(trim(customer_id)) as customer_id,
    upper(trim(customer_unique_id)) as customer_unique_id,
    customer_zip_code_prefix,
    upper(trim(customer_city)) as customer_city,
    upper(trim(customer_state)) as customer_state,
    batch_id,
    load_date,
    source_name as record_source
from {{ source('olist_raw', 'customers') }}