{% macro generate_link(source_model, src_pk, src_fk, src_ldts, src_source, src_batch_id) %}

SELECT DISTINCT
    {{ src_pk }},
    {% for fk in src_fk %}
    {{ fk }}
    {%- if not loop.last %},{% endif %}
    {% endfor %},
    {{ src_ldts }} as load_date,
    {{ src_source }} as record_source,
    {{ src_batch_id }} as batch_id
FROM {{ ref(source_model) }}

{% if is_incremental() %}
    WHERE {{ src_pk }} NOT IN (
        SELECT {{ src_pk }} FROM {{ this }}
    )
{% endif %}

{% endmacro %}