{{ config(materialized='incremental') }}

{{ generate_satellite(
    source_model='stg_order_items',
    src_pk='link_order_item_hash',
    src_hash_key='link_order_item_hash',
    src_attributes=['price', 'freight_value', 'shipping_limit_date'],
    src_ldts='load_date',
    src_source='record_source',
    src_batch_id='batch_id'
) }}
