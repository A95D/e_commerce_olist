{{ config(materialized='incremental') }}
{{ generate_hub(
    source_model='stg_products',
    src_pk='hub_product_hash',
    src_nk='product_id',
    src_ldts='load_date',
    src_source='record_source',
    src_batch_id='batch_id'
) }}