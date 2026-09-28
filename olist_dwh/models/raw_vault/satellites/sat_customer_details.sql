{{ config(materialized='incremental') }}

{{ generate_satellite(
    source_model='stg_customers',
    src_pk='hub_customer_hash',
    src_hash_key='hub_customer_hash',
    src_attributes=['customer_city', 'customer_state', 'customer_zip_code_prefix'],
    src_ldts='load_date',
    src_source='record_source',
    src_batch_id='batch_id'
) }}
