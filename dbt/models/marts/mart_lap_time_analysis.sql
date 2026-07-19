SELECT
    r.year,
    r.race_name,
    r.circuit_name,
    r.country,
    d.driver_name,
    count() AS laps_count,
    min(l.lap_seconds) AS best_lap_seconds,
    avg(l.lap_seconds) AS avg_lap_seconds,
    max(l.lap_seconds) AS slowest_lap_seconds
FROM {{ ref('fact_lap_times') }} l
LEFT JOIN {{ ref('dim_races') }} r
    ON l.race_id = r.race_id
LEFT JOIN {{ ref('dim_drivers') }} d
    ON l.driver_id = d.driver_id
GROUP BY
    r.year,
    r.race_name,
    r.circuit_name,
    r.country,
    d.driver_name
