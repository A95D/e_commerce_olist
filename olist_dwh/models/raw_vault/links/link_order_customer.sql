-- models/raw_vault/links/link_order_customer.sql
{{ config(materialized='incremental') }}

{{ generate_link(
    source_model='stg_order',
    src_pk='link_order_customer_hash',
    src_fk=['hub_order_hash', 'hub_customer_hash'],
    src_ldts='load_date',
    src_source='record_source',
    src_batch_id='batch_id'
) }}