WITH deduplicated AS (
    {{ deduplicate('raw.races', 'race_id') }}
)

SELECT
    race_id,
    year,
    round,
    circuit_id,
    name AS race_name,
    race_date,
    race_time,
    url,
    loaded_at
FROM deduplicated
