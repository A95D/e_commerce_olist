{{ config(materialized='incremental') }}
{{ generate_hub(
    source_model='stg_order_payments',
    src_pk='hub_payment_hash',
    src_nk='order_id, payment_sequential',
    src_ldts='load_date',
    src_source='record_source',
    src_batch_id='batch_id'
) }}