{{ config(materialized='table') }}

WITH pit_dates AS (
    SELECT DISTINCT DATE_TRUNC('day', load_date)::TIMESTAMP as snapshot_date
    FROM {{ ref('hub_orders') }}
)
SELECT
    pit.snapshot_date,
    h.hub_order_hash,
    MAX(CASE WHEN s1.load_date <= pit.snapshot_date THEN s1.load_date END) as ldts_sat_order_status,
    MAX(CASE WHEN s2.load_date <= pit.snapshot_date THEN s2.load_date END) as ldts_sat_order_payments,
    MAX(CASE WHEN s3.load_date <= pit.snapshot_date THEN s3.load_date END) as ldts_sat_order_item_finance
FROM pit_dates pit
CROSS JOIN {{ ref('hub_orders') }} h
LEFT JOIN {{ ref('sat_order_status') }} s1 ON h.hub_order_hash = s1.hub_order_hash
LEFT JOIN {{ ref('sat_order_payments') }} s2 ON h.hub_order_hash = s2.hub_order_hash
LEFT JOIN {{ ref('sat_order_item_finance') }} s3 ON h.hub_order_hash = s3.link_order_item_hash
GROUP BY pit.snapshot_date, h.hub_order_hash
