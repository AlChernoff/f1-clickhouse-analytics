WITH deduplicated AS (
    {{ deduplicate('raw.lap_times', 'race_id, driver_id, lap') }}
)

SELECT
    race_id,
    driver_id,
    lap,
    position,
    lap_time,
    milliseconds,
    milliseconds / 1000.0 AS lap_seconds,
    loaded_at
FROM deduplicated
