{{ config(materialized='incremental') }}
{{ generate_hub(
    source_model='stg_geolocation',
    src_pk='hub_geolocation_hash',
    src_nk='geolocation_zip_code_prefix',
    src_ldts='load_date',
    src_source='record_source',
    src_batch_id='batch_id'
) }}