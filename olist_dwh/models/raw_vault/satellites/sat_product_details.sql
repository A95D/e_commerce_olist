{{ config(materialized='incremental') }}

{{ generate_satellite(
    source_model='stg_products',
    src_pk='hub_product_hash',
    src_hash_key='hub_product_hash',
    src_attributes=['product_category_name', 'product_name_length', 'product_description_length', 'product_photos_qty', 'product_weight_g', 'product_length_cm', 'product_height_cm', 'product_width_cm'],
    src_ldts='load_date',
    src_source='record_source',
    src_batch_id='batch_id'
) }}
