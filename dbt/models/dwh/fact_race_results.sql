SELECT
    result_id,
    race_id,
    driver_id,
    constructor_id,
    grid,
    position,
    position_text,
    position_order,
    points,
    laps,
    milliseconds,
    fastest_lap,
    rank,
    fastest_lap_time,
    fastest_lap_speed,
    status_id
FROM {{ ref('stg_results') }}
