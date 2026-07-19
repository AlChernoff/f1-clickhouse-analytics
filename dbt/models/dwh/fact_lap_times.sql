SELECT
    race_id,
    driver_id,
    lap,
    position,
    lap_time,
    milliseconds,
    lap_seconds
FROM {{ ref('stg_lap_times') }}
