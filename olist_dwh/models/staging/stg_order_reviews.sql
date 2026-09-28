select 
    -- 1. Хэш Линка
    md5(upper(trim(review_id)) || '|' || upper(trim(order_id))) as link_order_review_hash,

    -- 2. Внешние хэше для хабов
    md5(upper(trim(review_id))) as hub_review_hash,
    md5(upper(trim(order_id))) as hub_order_hash,

    -- Атрибуты
    trim(review_id) as review_id,
    trim(order_id) as order_id,
    review_score,
    trim(review_comment_title) as review_comment_title,
    trim(review_comment_message) as review_comment_message,
    review_creation_date,
    review_answer_timestamp,
    batch_id,
    load_date,
    source_name as record_source
from {{ source('olist_raw', 'order_reviews') }}