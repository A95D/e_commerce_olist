{{ config(materialized='incremental') }}
{{ generate_hub(
    source_model='stg_sellers',
    src_pk='hub_seller_hash',
    src_nk='seller_id',
    src_ldts='load_date',
    src_source='record_source',
    src_batch_id='batch_id'
) }}