{{ config(materialized='incremental') }}
{{ generate_hub(
    source_model='stg_order_items',
    src_pk='hub_order_item_hash',
    src_nk='order_id, order_item_id',
    src_ldts='load_date',
    src_source='record_source',
    src_batch_id='batch_id'
) }}