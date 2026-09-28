{{ config(materialized='incremental') }}

{{ generate_satellite_multi_active(
    source_model='stg_order_payments',
    src_pk='hub_order_hash',
    src_hash_key='hub_order_hash',
    src_multi_key='payment_sequential',
    src_attributes=['payment_type', 'payment_installments', 'payment_value'],
    src_ldts='load_date',
    src_source='record_source',
    src_batch_id='batch_id'
) }}
