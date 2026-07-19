SELECT
    race.year,
    countDistinct(race.race_id) AS races_count,
    countDistinct(result.driver_id) AS drivers_count,
    countDistinct(result.constructor_id) AS constructors_count,
    sum(result.points) AS total_points_awarded,
    countIf(result.position_order = 1) AS wins_count,
    countIf(result.position_order <= 3) AS podiums_count
FROM {{ ref('dim_races') }} race
LEFT JOIN {{ ref('fact_race_results') }} result
    ON race.race_id = result.race_id
GROUP BY race.year
ORDER BY race.year
