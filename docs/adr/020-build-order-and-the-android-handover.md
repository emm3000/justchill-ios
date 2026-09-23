# ADR 020 — Build order and the Android handover

- **Status**: Accepted
- **Date**: 2026-09-22
- **Deciders**: Edgardo Muñoz

## Context

ADR 018 decides how the iOS app is built and ADR 017 decides what it looks like, but neither says
what gets built first. The repo is two scaffold packages. ADR 017 requires every merged pull request
to leave the app usable on the owner's device with real data, which a scaffold cannot satisfy, and
the owner records every movement on the Android app today, so "usable" means "holds the Android
data". The wave rules in `docs/agents/multi-session.md` bound each wave: a schema change is a wave of
one, and no wave carries two tickets in the same package.

## Decision

1. **The first milestone is the amount pad saving a Transaction and showing the Month's spend.**
   Static defaults until the frequent-combo ranking lands: Spend, the first Account, no Category,
   today. Nothing before it is installed anywhere; nothing after it may leave trunk unusable.
2. **One schema migration, `v1`, creates the six tables** (accounts, categories, transactions,
   recurring movements, loans, loan payments) with the sync columns ADR 009 Decision 9 keeps,
   and seeds the Default categories and one cash Account named "Efectivo" inside the migration.
   Repositories and records arrive per slice; the schema does not grow per feature.
3. **Domain entities arrive per slice.** Wave 1 holds the ledger only; Recurring and Loan values
   enter `CoreDomain` with the Snapshot, which is the first code that needs all six.
4. **The Android data crosses as a file.** The owner exports on Android, picks the file on iOS.
   `CoreBackup` reads and writes the Android format, payload schema 4 inside manifest 1, and nothing
   older: a lower `schemaVersion` is a `DomainError`, not a migration. Exporting to a file ships in
   the same wave as importing so the owner can walk back to Android during the handover.
5. **Restore replaces everything.** One transaction deletes the six tables and loads the Snapshot;
   the seeded rows do not survive it. Row counts are reported afterwards.
6. **Test snapshots are synthetic.** The repo is public; no export of the owner's data enters git,
   anonymised or not. A builder in `CoreTesting` produces a schema-4 Snapshot with every table
   populated.
7. **Simulator only for now.** The owner keeps Android as the daily driver; waves are verified on
   the simulator with the imported Snapshot. Installing on a phone is a release decision, not a wave.
8. **Order of the waves**, each merged before the next starts:

   | Wave | Tickets |
   |---|---|
   | 1 | `CoreDomain` ledger ∥ `CoreUI` pad atoms with previews |
   | 2 | `CoreDatabase` `v1` migration, ledger repositories, fixture test (alone) |
   | 3 | `FeatureTransaction` pad, `App` route and container. Milestone 1 |
   | 4 | Month screen ∥ frequent-combo ranking |
   | 5 | `CoreDomain` Recurring, Loan and Snapshot values ∥ `CoreBackup` schema-4 reader and writer |
   | 6 | Importar from a file ∥ Exportar to a file |
   | 7 | Menu and Accounts CRUD ∥ Categories CRUD |
   | 8 | Recurring movements |
   | 9 | Loans |
   | 10 | Report |
   | 11 | Cloud Backup and Identity |
   | 12 | Manifesto, Acerca de, privacy policy |

## Consequences

- Waves 1 and 2 ship no screen; the gate and the previews are their only proof. The owner sees
  the app for the first time at wave 3.
- The `v1` fixture database carries the seeded rows, so the migration test also pins the Default
  categories; changing that list is a new migration, never an edit to `v1`.
- The Snapshot format is a shared contract with the Android app from wave 5 on. Either side
  changing it bumps `schemaVersion` on both.
- A `DomainError` case for a Snapshot version the app does not read exists from wave 5.
- `CoreBackup` starts as a file codec with no supabase-swift dependency; Storage and auth attach
  in wave 11 without moving the codec.

## Considered options

- **Foundation first, all six domains before any screen.** Three or four waves of code nobody
  runs, and the design review on ADR 017's tokens waits until the end.
- **Schema per feature (`v1` ledger, `v2` recurring, `v3` loans).** Less dead SQL per wave; each
  version adds a fixture database and a migration test that live forever, for a schema the
  Android app already settled.
- **Restore through Supabase with the same Identity.** Brings auth, Storage and the retention
  cycle before the owner has data on iOS; a file needs none of it.
- **Merge on Restore.** Upsert by id keeps local rows the Snapshot lacks, which makes deletions
  and the seeded Account ambiguous; a Snapshot is the whole state or it is not a Snapshot.
- **Read Snapshot schemas 1 to 3 too.** Parity with Android's frozen DTOs, for files that exist
  only in cloud retention and that the Android app can re-export as schema 4.
- **Ranking inside the pad ticket.** Milestone 1 would match ADR 017 fully, at the cost of a pull
  request holding the ranking use case, its no-history fallback and the chips alongside the pad.
- **A real export as the test fixture.** Better coverage of real shapes, one slip away from
  publishing personal finances.
