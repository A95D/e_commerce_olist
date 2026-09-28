{{ config(materialized='view') }}

with link_order_items as (
    select
        link_order_items_hash,
        hub_order_hash,
        hub_product_hash,
        hub_seller_hash,
        load_date
    from {{ ref('link_order_items') }}
),
product_details as (
    select
        hub_product_hash,
        product_category_name,
        product_name_lenght,
        product_description_lenght,
        product_weight_g,
        load_date
    from {{ ref('sat_product_details') }}
    qualify row_number() over (partition by hub_product_hash order by load_date desc) = 1
),
order_item_finance as (
    select
        hub_order_item_hash,
        price,
        freight_value,
        load_date
    from {{ ref('sat_order_item_finance') }}
    qualify row_number() over (partition by hub_order_item_hash order by load_date desc) = 1
)
select
    loi.link_order_items_hash,
    loi.hub_order_hash,
    loi.hub_product_hash,
    loi.hub_seller_hash,
    pd.product_category_name,
    pd.product_name_lenght,
    pd.product_description_lenght,
    pd.product_weight_g,
    oif.price,
    oif.freight_value,
    (oif.price + oif.freight_value) as total_item_value,
    loi.load_date
from link_order_items loi
left join product_details pd on loi.hub_product_hash = pd.hub_product_hash
left join order_item_finance oif on loi.hub_order_hash = oif.hub_order_item_hash
