select 
    -- 1. Хэш Линка
    md5(upper(trim(seller_id)) || '|' || upper(trim(seller_zip_code_prefix::text))) as link_seller_geolocation_hash,

    -- 2. Хэши хабов
    md5(upper(trim(seller_id))) as hub_seller_hash,
    md5(upper(trim(geolocation_zip_code_prefix::text))) as hub_geolocation_hash,

    -- Атрибуты
    geolocation_zip_code_prefix,
    geolocation_lat,
    geolocation_lng,
    upper(trim(geolocation_city)) as geolocation_city,
    upper(trim(geolocation_state)) as geolocation_state,
    batch_id,
    load_date,
    source_name as record_source
from {{ source('olist_raw', 'geolocation') }}