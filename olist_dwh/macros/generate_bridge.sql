{% macro generate_bridge(link_model, link_pk, hub_pks, ldts_column, source_column, batch_id_column) %}

WITH bridge_dates AS (
    SELECT DISTINCT DATE_TRUNC('day', CURRENT_TIMESTAMP)::TIMESTAMP as snapshot_date
    FROM {{ ref(link_model) }}
)
SELECT
    bd.snapshot_date,
    l.{{ link_pk }},
    {% for pk in hub_pks %}
    l.{{ pk }}
    {%- if not loop.last %},{% endif %}
    {% endfor %}
FROM bridge_dates bd
INNER JOIN {{ ref(link_model) }} l ON l.{{ ldts_column }} <= bd.snapshot_date
{% if is_incremental() %}
    WHERE l.{{ ldts_column }} > (
        SELECT MAX({{ ldts_column }}) FROM {{ this }}
    )
{% endif %}

{% endmacro %}
