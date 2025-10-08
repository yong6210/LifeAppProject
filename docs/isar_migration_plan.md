# ISAR Migration & Versioning Plan

## Versioning strategy
- Track schema version in `pubspec.yaml` via `isar_schema_version` dart define (to be added in build config).
- Persist current schema version in `Settings` (`int schemaVersion` TBD) to detect incompatible local DBs.
- On app startup, compare persisted version with bundled `currentSchemaVersion`:
  - If older, run migration routine (see below).
  - If newer (e.g., user downgraded), block DB open and prompt to update.

## Migration hooks
1. **Lightweight changes** (adding nullable fields or new embedded properties): handled automatically; ensure default values are set in repositories when data is read.
2. **Breaking schema changes** (renaming/removing fields, changing indexes):
   - Create a background migration command that reads all affected collections and writes updated entities into a shadow store.
   - Use `isar.copyCollection()` pattern: export data to JSON, wipe DB, import into new schema.
   - Provide backup prompt before destructive migrations.

## Testing migrations
- Add golden JSON fixtures representing previous schema versions under `test/fixtures/isar/`.
- Write integration tests that:
  1. Boot the app with fixture DB copied into Isar directory.
  2. Run `MigrationRunner.run()` and verify resulting data matches expectations.
- Include regression tests for `Settings.deviceId` persistence and `DailySummaryLocal` aggregation results after migration.

## Release checklist
- Update `docs/data_schema.md` when schema changes.
- Bump schema version constant and add migration notes to `CHANGELOG.md`.
- Run `dart run build_runner build` to regenerate adapters.
- Execute migration integration tests in CI before releasing.
