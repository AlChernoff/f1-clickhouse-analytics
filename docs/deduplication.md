# Deduplication Strategy

The project uses a layered deduplication strategy.

## Raw layer

Raw tables use ReplacingMergeTree with loaded_at as a version column.

This allows ClickHouse to eventually collapse rows with the same business key during background merges.

Business keys are defined through ORDER BY:

- raw.drivers: driver_id
- raw.constructors: constructor_id
- raw.circuits: circuit_id
- raw.races: race_id
- raw.results: result_id
- raw.qualifying: qualify_id
- raw.lap_times: race_id, driver_id, lap
- raw.pit_stops: race_id, driver_id, stop

## Important note

ReplacingMergeTree does not work like a strict unique constraint.

Duplicate rows may still be visible before ClickHouse background merges complete. Queries that require immediate deduplication can use FINAL, but FINAL may be expensive on large tables.

## dbt staging layer

The dbt staging layer also applies logical deduplication using `row_number` over business keys and keeps the latest loaded record. It orders rows by `loaded_at DESC` and then by `cityHash64(*) DESC`, so records with the same millisecond timestamp are selected deterministically.

This guarantees that analytical DWH models and marts are duplicate-free even if duplicate rows temporarily exist in raw tables.

## Design choice

The project does not automatically truncate raw tables during normal loading.

This is closer to a real ingestion scenario where raw data is preserved and analytical correctness is handled in transformation layers.
