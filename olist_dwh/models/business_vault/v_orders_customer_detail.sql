{{ config(materialized='view') }}

with order_hub as (
    select hub_order_hash, load_date from {{ ref('hub_orders') }}
),
customer_hub as (
    select hub_customer_hash, load_date from {{ ref('hub_customer') }}
),
link_order_customer as (
    select * from {{ ref('link_order_customer') }}
),
order_status as (
    select
        hub_order_hash,
        order_status,
        order_purchase_timestamp,
        order_approved_at,
        order_delivered_customer_date,
        load_date
    from {{ ref('sat_order_status') }}
    qualify row_number() over (partition by hub_order_hash order by load_date desc) = 1
)
select
    lc.link_order_customer_hash,
    lc.hub_order_hash,
    lc.hub_customer_hash,
    os.order_status,
    os.order_purchase_timestamp,
    os.order_approved_at,
    os.order_delivered_customer_date,
    lc.load_date,
    lc.record_source
from link_order_customer lc
left join order_status os on lc.hub_order_hash = os.hub_order_hash