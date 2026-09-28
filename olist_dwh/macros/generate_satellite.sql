{% macro generate_satellite(source_model, src_pk, src_hash_key, src_attributes, src_ldts, src_source, src_batch_id) %}

WITH src AS (
    SELECT
        {{ src_hash_key }},
        {% for attr in src_attributes %}
        {{ attr }},
        {% endfor %}
        md5(
            {% for attr in src_attributes %}
            coalesce({{ attr }}::text, 'null')
            {%- if not loop.last %} || '|' || {% endif %}
            {% endfor %}
        ) as hash_diff,
        {{ src_ldts }} as load_date,
        {{ src_source }} as record_source,
        {{ src_batch_id }} as batch_id
    FROM {{ ref(source_model) }}
)
SELECT *
FROM src
{% if is_incremental() %}
    WHERE NOT EXISTS (
        SELECT 1
        FROM {{ this }} as latest
        WHERE latest.{{ src_pk }} = src.{{ src_hash_key }}
            AND latest.load_date = (
                SELECT MAX(load_date)
                FROM {{ this }}
                WHERE {{ src_pk }} = src.{{ src_hash_key }}
            )
            AND latest.hash_diff = src.hash_diff
    )
{% endif %}

{% endmacro %}
