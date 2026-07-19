SELECT
    driver_id,
    driver_ref,
    number,
    code,
    forename,
    surname,
    concat(forename, ' ', surname) AS driver_name,
    dob,
    nationality,
    url,
    loaded_at
FROM raw.drivers
