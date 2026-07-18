from __future__ import annotations

from pathlib import Path

import pandas as pd


NULL_VALUES = ["\\N", "N", "NULL", "null", ""]


TARGET_COLUMNS = {
    "drivers": [
        "driver_id",
        "driver_ref",
        "number",
        "code",
        "forename",
        "surname",
        "dob",
        "nationality",
        "url",
    ],
    "constructors": [
        "constructor_id",
        "constructor_ref",
        "name",
        "nationality",
        "url",
    ],
    "circuits": [
        "circuit_id",
        "circuit_ref",
        "name",
        "location",
        "country",
        "lat",
        "lng",
        "alt",
        "url",
    ],
    "races": [
        "race_id",
        "year",
        "round",
        "circuit_id",
        "name",
        "race_date",
        "race_time",
        "url",
    ],
    "results": [
        "result_id",
        "race_id",
        "driver_id",
        "constructor_id",
        "number",
        "grid",
        "position",
        "position_text",
        "position_order",
        "points",
        "laps",
        "time",
        "milliseconds",
        "fastest_lap",
        "rank",
        "fastest_lap_time",
        "fastest_lap_speed",
        "status_id",
    ],
    "lap_times": [
        "race_id",
        "driver_id",
        "lap",
        "position",
        "lap_time",
        "milliseconds",
    ],
    "pit_stops": [
        "race_id",
        "driver_id",
        "stop",
        "lap",
        "pit_time",
        "duration",
        "milliseconds",
    ],
    "qualifying": [
        "qualify_id",
        "race_id",
        "driver_id",
        "constructor_id",
        "number",
        "position",
        "q1",
        "q2",
        "q3",
    ],
}


def read_csv(path: Path) -> pd.DataFrame:
    if not path.exists():
        raise FileNotFoundError(f"CSV file not found: {path}")

    return pd.read_csv(path, na_values=NULL_VALUES, keep_default_na=True)


def normalize_columns(df: pd.DataFrame) -> pd.DataFrame:
    df = df.copy()

    column_mapping = {
        "driverId": "driver_id",
        "driverRef": "driver_ref",
        "constructorId": "constructor_id",
        "constructorRef": "constructor_ref",
        "circuitId": "circuit_id",
        "circuitRef": "circuit_ref",
        "raceId": "race_id",
        "resultId": "result_id",
        "qualifyId": "qualify_id",
        "positionText": "position_text",
        "positionOrder": "position_order",
        "fastestLap": "fastest_lap",
        "fastestLapTime": "fastest_lap_time",
        "fastestLapSpeed": "fastest_lap_speed",
        "statusId": "status_id",
    }

    return df.rename(columns=column_mapping)


def apply_table_specific_mapping(df: pd.DataFrame, target_table: str) -> pd.DataFrame:
    df = df.copy()

    if target_table == "races":
        df = df.rename(columns={"date": "race_date", "time": "race_time"})

    if target_table == "lap_times":
        df = df.rename(columns={"time": "lap_time"})

    if target_table == "pit_stops":
        df = df.rename(columns={"time": "pit_time"})

    return df


def select_target_columns(df: pd.DataFrame, target_table: str) -> pd.DataFrame:
    df = df.copy()

    target_columns = TARGET_COLUMNS[target_table]
    missing_columns = [column for column in target_columns if column not in df.columns]

    if missing_columns:
        raise ValueError(
            f"Missing columns for table {target_table}: {missing_columns}. "
            f"Available columns: {list(df.columns)}"
        )

    return df[target_columns]


def convert_dates(df: pd.DataFrame) -> pd.DataFrame:
    df = df.copy()

    date_columns = ["dob", "race_date"]

    for column in date_columns:
        if column in df.columns:
            parsed = pd.to_datetime(df[column], errors="coerce")
            df[column] = parsed.dt.date
            df[column] = df[column].where(pd.notnull(df[column]), None)

    return df


def clean_dataframe(df: pd.DataFrame) -> pd.DataFrame:
    df = df.copy()

    df = convert_dates(df)

    # pandas NaN/NaT values should become None for ClickHouse Nullable columns
    df = df.astype(object)
    df = df.where(pd.notnull(df), None)

    return df
