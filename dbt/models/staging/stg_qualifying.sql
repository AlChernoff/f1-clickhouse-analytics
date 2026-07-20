WITH deduplicated AS (
    {{ deduplicate('raw.qualifying', 'qualify_id') }}
)

SELECT
    qualify_id,
    race_id,
    driver_id,
    constructor_id,
    number,
    position,
    q1,
    q2,
    q3,
    loaded_at
FROM deduplicated
