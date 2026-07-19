SELECT
    r.year,
    r.race_name,
    r.circuit_name,
    r.country,
    d.driver_name,
    count() AS pit_stops_count,
    min(p.pit_stop_seconds) AS fastest_pit_stop_seconds,
    avg(p.pit_stop_seconds) AS avg_pit_stop_seconds,
    max(p.pit_stop_seconds) AS slowest_pit_stop_seconds
FROM {{ ref('fact_pit_stops') }} p
LEFT JOIN {{ ref('dim_races') }} r
    ON p.race_id = r.race_id
LEFT JOIN {{ ref('dim_drivers') }} d
    ON p.driver_id = d.driver_id
GROUP BY
    r.year,
    r.race_name,
    r.circuit_name,
    r.country,
    d.driver_name
