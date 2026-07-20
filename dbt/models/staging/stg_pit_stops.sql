WITH deduplicated AS (
    {{ deduplicate('raw.pit_stops', 'race_id, driver_id, stop') }}
)

SELECT
    race_id,
    driver_id,
    stop,
    lap,
    pit_time,
    duration,
    milliseconds,
    milliseconds / 1000.0 AS pit_stop_seconds,
    loaded_at
FROM deduplicated
