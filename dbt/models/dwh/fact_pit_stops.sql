SELECT
    race_id,
    driver_id,
    stop,
    lap,
    pit_time,
    duration,
    milliseconds,
    pit_stop_seconds
FROM {{ ref('stg_pit_stops') }}
