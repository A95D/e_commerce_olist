{{ config(materialized='incremental') }}
{{ generate_hub(
    source_model='stg_orders',
    src_pk='hub_order_hash',
    src_nk='order_id',
    src_ldts='load_date',
    src_source='record_source',
    src_batch_id='batch_id'
) }}