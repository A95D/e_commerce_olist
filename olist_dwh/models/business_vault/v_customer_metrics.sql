{{ config(materialized='table') }}

with customer_hub as (
    select
        hub_customer_hash,
        load_date
    from {{ ref('hub_customer') }}
),
customer_details as (
    select
        hub_customer_hash,
        customer_city,
        customer_state,
        load_date
    from {{ ref('sat_customer_details') }}
    qualify row_number() over (partition by hub_customer_hash order by load_date desc) = 1
),
link_order_customer as (
    select
        hub_customer_hash,
        hub_order_hash,
        load_date
    from {{ ref('link_order_customer') }}
),
order_status as (
    select
        hub_order_hash,
        order_status,
        order_purchase_timestamp,
        order_delivered_customer_date,
        load_date
    from {{ ref('sat_order_status') }}
    qualify row_number() over (partition by hub_order_hash order by load_date desc) = 1
),
order_payments as (
    select
        hub_order_hash,
        sum(payment_value) as total_order_value,
        max(load_date) as load_date
    from {{ ref('sat_order_payments') }}
    group by hub_order_hash
)
select
    ch.hub_customer_hash,
    cd.customer_city,
    cd.customer_state,
    count(distinct lc.hub_order_hash) as total_orders,
    sum(case when os.order_status = 'delivered' then 1 else 0 end) as delivered_orders,
    sum(op.total_order_value) as customer_lifetime_value,
    max(os.order_purchase_timestamp) as last_order_date,
    ch.load_date
from customer_hub ch
left join customer_details cd on ch.hub_customer_hash = cd.hub_customer_hash
left join link_order_customer lc on ch.hub_customer_hash = lc.hub_customer_hash
left join order_status os on lc.hub_order_hash = os.hub_order_hash
left join order_payments op on lc.hub_order_hash = op.hub_order_hash
group by ch.hub_customer_hash, cd.customer_city, cd.customer_state, ch.load_date