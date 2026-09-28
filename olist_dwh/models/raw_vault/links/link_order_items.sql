-- models/raw_vault/links/link_order_items.sql
{{ config(materialized='incremental') }}

{{ generate_link(
    source_model='stg_order_items',
    src_pk='link_order_item_hash',
    src_fk=['hub_order_hash', 'hub_product_hash', 'hub_seller_hash'],
    src_ldts='load_date',
    src_source='record_source',
    src_batch_id='batch_id'
) }}