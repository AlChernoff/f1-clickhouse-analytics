WITH deduplicated AS (
    {{ deduplicate('raw.circuits', 'circuit_id') }}
)

SELECT
    circuit_id,
    circuit_ref,
    name AS circuit_name,
    location,
    country,
    lat,
    lng,
    alt,
    url,
    loaded_at
FROM deduplicated
