SELECT
    constructor_id,
    constructor_ref,
    constructor_name,
    nationality,
    url
FROM {{ ref('stg_constructors') }}
