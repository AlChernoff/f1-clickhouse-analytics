{% macro deduplicate(relation, partition_by) %}
SELECT *
FROM (
    SELECT
            *,
            row_number() OVER (
                PARTITION BY {{ partition_by }}
                ORDER BY loaded_at DESC, cityHash64(*) DESC
            ) AS _row_number
    FROM {{ relation }}
)
WHERE _row_number = 1
{% endmacro %}
