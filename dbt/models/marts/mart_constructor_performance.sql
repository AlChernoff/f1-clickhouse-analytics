SELECT
    r.constructor_id AS "constructor_id",
    c.constructor_name AS "constructor_name",
    c.nationality AS "nationality",
    count() AS "race_entries",
    sum(r.points) AS "total_points",
    avg(r.points) AS "avg_points_per_race",
    countIf(r.position_order = 1) AS "wins",
    countIf(r.position_order <= 3) AS "podiums",
    countIf(r.position_order <= 10) AS "points_finishes"
FROM {{ ref('fact_race_results') }} r
LEFT JOIN {{ ref('dim_constructors') }} c
    ON r.constructor_id = c.constructor_id
GROUP BY
    r.constructor_id,
    c.constructor_name,
    c.nationality
