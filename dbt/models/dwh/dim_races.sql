SELECT
    r.race_id,
    r.year,
    r.round,
    r.race_name,
    r.race_date,
    r.race_time,
    r.circuit_id,
    c.circuit_name,
    c.location,
    c.country,
    c.lat,
    c.lng,
    c.alt
FROM {{ ref('stg_races') }} r
LEFT JOIN {{ ref('stg_circuits') }} c
    ON r.circuit_id = c.circuit_id
