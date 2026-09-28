{{ config(materialized='incremental') }}

{{ generate_satellite(
    source_model='stg_orders',
    src_pk='hub_order_hash',
    src_hash_key='hub_order_hash',
    src_attributes=['order_status', 'order_purchase_timestamp', 'order_approved_at', 'order_delivered_carrier_date', 'order_delivered_customer_date', 'order_estimated_delivery_date'],
    src_ldts='load_date',
    src_source='record_source',
    src_batch_id='batch_id'
) }}
