-- models/raw_vault/links/link_seller_geolocation.sql
{{ config(materialized='incremental') }}

{{ generate_link(
    source_model='stg_geolocation', 
    src_pk='link_seller_geolocation_hash',
    src_fk=['hub_seller_hash', 'hub_geolocation_hash'],
    src_ldts='load_date',
    src_source='record_source',
    src_batch_id='batch_id'
) }}