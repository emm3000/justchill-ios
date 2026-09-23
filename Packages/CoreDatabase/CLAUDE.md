# CoreDatabase

GRDB.swift over the six tables: the `DatabaseMigrator`, the `{Entity}Record` types, the `GRDB{Entity}Repository` implementations of the `CoreDomain` protocols. `.claude/rules/grdb.md` binds every change here.

## Build and test

- `swift test --package-path Packages/CoreDatabase` runs the suite on the Mac host in seconds; the package builds for macOS for this reason. A fast loop, never a gate substitute.
- `scripts/gate` runs `CoreDatabaseTests` on the simulator because `project.yml` lists it under `schemes.justchill.test.targets`.
- The GRDB version is pinned `exact:` in `Package.swift`, the only place it is written. `swift test` writes a `Package.resolved` next to it; do not commit it.
- Default isolation is `nil`, as in `CoreDomain`.

## Layout

- `AppDatabase.open(at:)` is the one public entry: it opens a `DatabasePool` at the URL and migrates it to head. Tests open every database through it, so they run with the app's configuration.
- `Migrations/`: `DatabaseMigrator.app` registers the migrations in order; each one's body lives in `Database` extensions named for its version (`createV1Tables()`, `seedV1Defaults()`).
- A record holds only the columns its repository reads or writes. `userId`, `deletedAt` and `syncState` fall to the schema defaults on insert; reads go through `TableRecord.live()`, the one place `deletedAt IS NULL` is written.
- The test target's `path` is `Tests`, so `Tests/Fixtures` is a resource of it: `Bundle.module.url(forResource: "v1", withExtension: "sqlite", subdirectory: "Fixtures")`.

## Gotchas

- The migration takes no `Clock`. Seed rows carry the fixed epoch-ms literal `1790035200000`, since reading the wall clock would fail the architecture check.
- The composite key compares `transactions.type` with `categories.categoryType` as text (ADR 008), so the raw values of `TransactionType` and `CategoryType` are schema. Without the UNIQUE index on `categories(categoryId, categoryType)` the whole migration fails with "foreign key mismatch", because the migrator checks foreign keys at the end of each migration.
- A refused foreign key surfaces as `DomainError.storageFailure`, like every other GRDB error. `DomainError(translating:)` keeps a `DomainError` thrown while converting a row.
- `DomainFailingSequence` ends the sequence on `CancellationError` instead of failing it: a screen leaving is not a storage failure.
- An async GRDB `read` or `write` returns across isolation, so its value must be `Sendable`. `Row` is not: map rows to a `Sendable` value inside the closure.
- Write `any CoreDomain.Clock`: the bare name collides with the standard library's `Clock`.
- The app opens the database at `Application Support/justchill.sqlite`, chosen in `AppContainer`. The name is permanent: renaming it orphans the owner's data.

## The v1 fixture

`Tests/Fixtures/v1.sqlite` was built once by a throwaway test: `DatabaseMigrator.app.migrate(queue, upTo: "v1-create-ledger-with-defaults")` on an empty `DatabaseQueue` file, then one raw-SQL `INSERT` per table, a soft-deleted transaction among them. It is a committed fixture: never regenerate or hand-edit it. With `v1` as head its test migrates nothing; it becomes a migration test when `v2` lands.
