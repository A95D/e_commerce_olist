{{ config(materialized='incremental') }}
{{ generate_hub(
    source_model='stg_customers',
    src_pk='hub_customer_hash',
    src_nk='customer_unique_id',
    src_ldts='load_date',
    src_source='record_source',
    src_batch_id='batch_id'
) }}