{{ config(materialized='incremental') }}
{{ generate_hub(
    source_model='stg_product_category_name_translation',
    src_pk='hub_product_category_hash',
    src_nk='product_category_name',
    src_ldts='load_date',
    src_source='record_source',
    src_batch_id='batch_id'
) }}