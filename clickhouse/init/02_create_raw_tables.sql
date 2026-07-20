CREATE TABLE IF NOT EXISTS raw.drivers
(
    driver_id UInt32,
    driver_ref String,
    number Nullable(UInt16),
    code Nullable(String),
    forename String,
    surname String,
    dob Nullable(Date32),
    nationality String,
    url String,
    loaded_at DateTime64(3) DEFAULT now64(3)
)
ENGINE = ReplacingMergeTree(loaded_at)
ORDER BY driver_id;

CREATE TABLE IF NOT EXISTS raw.constructors
(
    constructor_id UInt32,
    constructor_ref String,
    name String,
    nationality String,
    url String,
    loaded_at DateTime64(3) DEFAULT now64(3)
)
ENGINE = ReplacingMergeTree(loaded_at)
ORDER BY constructor_id;

CREATE TABLE IF NOT EXISTS raw.circuits
(
    circuit_id UInt32,
    circuit_ref String,
    name String,
    location String,
    country String,
    lat Float64,
    lng Float64,
    alt Nullable(Int32),
    url String,
    loaded_at DateTime64(3) DEFAULT now64(3)
)
ENGINE = ReplacingMergeTree(loaded_at)
ORDER BY circuit_id;

CREATE TABLE IF NOT EXISTS raw.races
(
    race_id UInt32,
    year UInt16,
    round UInt8,
    circuit_id UInt32,
    name String,
    race_date Date32,
    race_time Nullable(String),
    url String,
    loaded_at DateTime64(3) DEFAULT now64(3)
)
ENGINE = ReplacingMergeTree(loaded_at)
PARTITION BY year
ORDER BY race_id;

CREATE TABLE IF NOT EXISTS raw.results
(
    result_id UInt32,
    race_id UInt32,
    driver_id UInt32,
    constructor_id UInt32,
    number Nullable(UInt16),
    grid Int16,
    position Nullable(UInt8),
    position_text Nullable(String),
    position_order UInt8,
    points Float32,
    laps UInt16,
    time Nullable(String),
    milliseconds Nullable(UInt32),
    fastest_lap Nullable(UInt16),
    rank Nullable(UInt8),
    fastest_lap_time Nullable(String),
    fastest_lap_speed Nullable(Float32),
    status_id UInt32,
    loaded_at DateTime64(3) DEFAULT now64(3)
)
ENGINE = ReplacingMergeTree(loaded_at)
PARTITION BY intDiv(race_id, 100)
ORDER BY result_id;

CREATE TABLE IF NOT EXISTS raw.lap_times
(
    race_id UInt32,
    driver_id UInt32,
    lap UInt16,
    position UInt8,
    lap_time String,
    milliseconds UInt32,
    loaded_at DateTime64(3) DEFAULT now64(3)
)
ENGINE = ReplacingMergeTree(loaded_at)
PARTITION BY intDiv(race_id, 100)
ORDER BY (race_id, driver_id, lap);

CREATE TABLE IF NOT EXISTS raw.pit_stops
(
    race_id UInt32,
    driver_id UInt32,
    stop UInt8,
    lap UInt16,
    pit_time String,
    duration String,
    milliseconds UInt32,
    loaded_at DateTime64(3) DEFAULT now64(3)
)
ENGINE = ReplacingMergeTree(loaded_at)
PARTITION BY intDiv(race_id, 100)
ORDER BY (race_id, driver_id, stop);

CREATE TABLE IF NOT EXISTS raw.qualifying
(
    qualify_id UInt32,
    race_id UInt32,
    driver_id UInt32,
    constructor_id UInt32,
    number UInt16,
    position UInt8,
    q1 Nullable(String),
    q2 Nullable(String),
    q3 Nullable(String),
    loaded_at DateTime64(3) DEFAULT now64(3)
)
ENGINE = ReplacingMergeTree(loaded_at)
PARTITION BY intDiv(race_id, 100)
ORDER BY qualify_id;
