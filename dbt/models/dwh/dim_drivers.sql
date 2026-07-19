SELECT
    driver_id,
    driver_ref,
    driver_name,
    forename,
    surname,
    number,
    code,
    dob,
    nationality,
    url
FROM {{ ref('stg_drivers') }}
