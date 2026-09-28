{% macro generate_pit(hub_model, hub_pk, satellite_models) %}

WITH pit_dates AS (
    {% for sat in satellite_models %}
    SELECT DISTINCT DATE_TRUNC('day', load_date)::TIMESTAMP as snapshot_date
    FROM {{ ref(sat) }}
    {% if not loop.last %}UNION ALL{% endif %}
    {% endfor %}
),
hubs_with_dates AS (
    SELECT
        h.{{ hub_pk }},
        pd.snapshot_date
    FROM {{ ref(hub_model) }} h
    CROSS JOIN pit_dates pd
)
SELECT
    hwd.snapshot_date,
    hwd.{{ hub_pk }},
    {% for sat in satellite_models %}
    MAX(CASE WHEN s{{ loop.index }}.load_date <= hwd.snapshot_date THEN s{{ loop.index }}.load_date END) as ldts_{{ sat }}
    {%- if not loop.last %},{% endif %}
    {% endfor %}
FROM hubs_with_dates hwd
{% for sat in satellite_models %}
LEFT JOIN {{ ref(sat) }} s{{ loop.index }} ON hwd.{{ hub_pk }} = s{{ loop.index }}.{{ hub_pk }}
    AND s{{ loop.index }}.load_date <= hwd.snapshot_date
{% endfor %}
GROUP BY hwd.snapshot_date, hwd.{{ hub_pk }}
ORDER BY hwd.snapshot_date, hwd.{{ hub_pk }}

{% endmacro %}
