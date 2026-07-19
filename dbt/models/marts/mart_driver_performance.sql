SELECT
    r.driver_id AS "driver_id",
    d.driver_name AS "driver_name",
    d.nationality AS "nationality",
    count() AS "race_entries",
    sum(r.points) AS "total_points",
    avg(r.points) AS "avg_points_per_race",
    countIf(r.position_order = 1) AS "wins",
    countIf(r.position_order <= 3) AS "podiums",
    countIf(r.position_order <= 10) AS "points_finishes",
    avg(nullIf(r.position_order, 0)) AS "avg_finish_position"
FROM {{ ref('fact_race_results') }} r
LEFT JOIN {{ ref('dim_drivers') }} d
    ON r.driver_id = d.driver_id
GROUP BY
    r.driver_id,
    d.driver_name,
    d.nationality
