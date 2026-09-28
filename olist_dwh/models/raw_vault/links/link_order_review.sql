-- models/raw_vault/links/link_order_reviews.sql
{{ config(materialized='incremental') }}

{{ generate_link(
    source_model='stg_order_reviews', 
    src_pk='link_order_review_hash',
    src_fk=['hub_review_hash', 'hub_order_hash'],
    src_ldts='load_date',
    src_source='record_source',
    src_batch_id='batch_id'
) }}