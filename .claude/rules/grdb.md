---
paths:
  - "Packages/CoreDatabase/**"
  - "Packages/CoreBackup/**"
---

# GRDB schema rules

The GRDB database on device is the source of truth. Every schema change is a migration unit with its own falsifier. The category/type composite key: ADR 008. The snapshot format and the restore path: ADR 009.

`Packages/CoreDatabase` does not exist yet; the first ticket that needs a table creates it, its `DatabaseMigrator` and its `Tests/Fixtures/` folder, and these rules bind from that commit.

## The migration is the diff

- Every schema change **appends one new named migration** to the app's `DatabaseMigrator`: `migrator.registerMigration("v<N>-<what-it-does>") { db in ... }`, `N` one above the last. A fresh install runs the same list from the top, so there is no second schema to drift from the migrated one.
- **Never edit, rename, reorder or delete a shipped migration.** GRDB records applied migrations by name: an edited body never runs again on a device that already applied it, and a renamed one runs twice. A migration is shipped once it is on `trunk`.
- **Never set `eraseDatabaseOnSchemaChange`.** It deletes the database whenever the schema moves, which on the owner's device means the ledger.
- **Never call `disablingDeferredForeignKeyChecks()`.** The migrator checks foreign keys at the end of each migration by default, so a migration that writes a violating row fails loudly instead of leaving it on the device forever.

## The fixture is part of the diff

- `Packages/CoreDatabase/Tests/Fixtures/v<N>.sqlite` is the database exactly as a build shipping migration `v<N>` left it on disk, with representative rows. A migration commit adds the fixture for the version it migrates **from** when that file is missing, created once by migrating an empty file with `migrator.migrate(db, upTo: "v<N>-...")` and inserting rows with raw SQL.
- Never delete, regenerate or hand-edit a committed fixture, and never reset the schema. Each one stands for a database a shipped build wrote, and the owner's device holds the oldest real data: a broken migration only fires there.
- The oldest fixture kept is the floor. Retiring old migrations means deleting that floor file in its own commit, a visible edit in the diff, never a side effect.

## Writing the migration

- Additive by default: `ALTER TABLE ... ADD COLUMN`, nullable or with a default. Renames, drops and new constraints go through a new table plus a copy (`create table`, `INSERT INTO ... SELECT`, `drop table`, `alter table ... rename to`), with the data repaired **before** the copy when a foreign key could reject rows (ADR 008: repair from the category side, never the type side).
- Deletes are soft (`deletedAt`) and every read filters `deletedAt IS NULL`. Foreign-key clauses fire only on a physical `DELETE`; deletion integrity lives above the schema.
- `transactions.occurredAt` is ISO local text with no zone; `createdAt` / `updatedAt` / `deletedAt` are epoch milliseconds. Keep that split.
- The two type enums share their raw values with the database text the composite key compares (ADR 008). Renaming a raw value is a schema change.

## The migration test

- Coverage is **one test per starting fixture** in `CoreDatabaseTests`, each copying `v<N>.sqlite` into a temporary directory, opening it with the app's own configuration and migrating to **head**, never to the next step: a device opens once and runs the whole chain in one `migrate` call.
- Set-up and in-chain reads use raw SQL against the historical schema; the app's records match only the head schema and work for assertions once the chain reaches it.
- Never build the starting database inside the test by migrating an empty file: it tests the migrator against itself and skips the shape a real device holds.
- Prove the test is not vacuous before trusting it: point it at a copy already at head so nothing migrates, watch it fail on the missing column or row, restore it.
- The suite is ordinary Swift Testing and runs on `scripts/gate` once `CoreDatabaseTests` is listed under `schemes.justchill.test.targets` in `project.yml`. Until then it is green by absence.

## The restore drill

The suite proves a migration keeps rows already on the device, never that a snapshot written before the bump still restores after it. Before shipping a bump, run it on the owner's `iPhone 17` simulator, never on a peer's simulator and never with a seeded database file:

1. Build `trunk` before the bump and install it: `scripts/build build -derivedDataPath build/DerivedData`, then `xcrun simctl install <udid> build/DerivedData/Build/Products/Debug-iphonesimulator/justchill.app`. Import the latest production snapshot through the app and record the six counts restore reports (`accounts`, `categories`, `transactions`, `recurring`, `loans`, `loanPayments`).
2. The owner deletes the app from the simulator. Agents never uninstall or erase anything on the owner's simulator, so this step is always the owner's.
3. Install the post-bump build, import the same file, and compare the six counts. Any count that moved is a failure.

Restore is the only way back from a migration that loses data, so a bump never restored from is untested. A schema change is always a wave of one.
