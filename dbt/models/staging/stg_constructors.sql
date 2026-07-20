WITH deduplicated AS (
    {{ deduplicate('raw.constructors', 'constructor_id') }}
)

SELECT
    constructor_id,
    constructor_ref,
    name AS constructor_name,
    nationality,
    url,
    loaded_at
FROM deduplicated
