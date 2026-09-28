{{ config(materialized='incremental') }}
{{ generate_hub(
    source_model='stg_order_reviews',
    src_pk='hub_review_hash',
    src_nk='review_id',
    src_ldts='load_date',
    src_source='record_source',
    src_batch_id='batch_id'
) }}