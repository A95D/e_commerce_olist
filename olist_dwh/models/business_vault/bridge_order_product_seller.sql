{{ config(materialized='incremental') }}

WITH bridge_dates AS (
    SELECT DISTINCT DATE_TRUNC('day', load_date)::TIMESTAMP as snapshot_date
    FROM {{ ref('link_order_items') }}
)
SELECT
    bd.snapshot_date,
    l.link_order_item_hash,
    l.hub_order_hash,
    l.hub_product_hash,
    l.hub_seller_hash
FROM bridge_dates bd
INNER JOIN {{ ref('link_order_items') }} l ON l.load_date <= bd.snapshot_date
QUALIFY ROW_NUMBER() OVER (PARTITION BY l.link_order_item_hash, bd.snapshot_date ORDER BY l.load_date DESC) = 1

{% if is_incremental() %}
    WHERE bd.snapshot_date > (
        SELECT MAX(snapshot_date) FROM {{ this }}
    )
{% endif %}
