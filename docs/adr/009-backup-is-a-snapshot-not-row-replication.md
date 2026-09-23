Ported from the Android repo on 2026-09-22; the decision stands for iOS.

# ADR 009 — Backup is a snapshot, not row replication

- **Status**: Accepted
- **Date**: 2026-08-13
- **Deciders**: Edgardo Muñoz
- **Supersedes**: [ADR 006](006-sync-is-backup-only-one-device-at-a-time.md) Decisions 1, 5 and 6;
  [ADR 001](001-reverse-local-only-to-local-first-optional-sync.md) Decisions 5 (dirty flag +
  `lastPulledAt` cursor) and 8 (Supabase as a dumb LWW store). ADR 001 Decisions 1, 2, 3, 6 and 7
  stand — 6 and 7 are actively protected by Decision 9 below; Decision 4 was already superseded by
  ADR 006. ADR 006 Decisions 2 and 4 survive intact and are strengthened here; **ADR 006 Decision 3
  survives, retargeted** — see Decision 5.
- **Renders dormant**: ADR 002 (since removed) in full — it orders a pull, and there is no pull
  left to order. ADR 004 (since removed) was already dormant; the conflict resolver is deleted
  rather than parked (see Decision 2).

> Summary: backup stops being row-by-row replication and becomes a **snapshot**: the complete,
> versioned JSON export, uploaded automatically to Supabase Storage, with staggered retention and
> pinnable snapshots. ADR 006 had already declared that sync was "backup, not replication", but left
> the replication engine in place — it renamed the contract, not the machine, and every later
> problem came out of that seam. The forensics close the argument: the engine's whole productive
> life was **ten minutes** on 2026-06-11, **no delete ever reached the server**, and dangling
> references were left between two tenants. Restore already existed and was the only data path with
> a frozen-format compatibility test. The sync ENGINE goes; the sync **schema** stays, so reopening
> sync some day needs no destructive migration. What does NOT retire: a phone still has one
> database and no wipe on account change, so a change of backup destination is disclosed on screen
> before the first upload.

## Context

[ADR 006](006-sync-is-backup-only-one-device-at-a-time.md) redefined sync as backup and retired the
convergence machinery on paper. It did not remove that machinery. The product contract said
"backup", the code kept doing bidirectional replication, and every problem since came out of that
seam — most recently a re-point flow whose confirmation dialog could not honestly describe what
confirming would do, because clearing the pull cursor made the next cycle download the destination
account's ledger onto this device. That is a merge, and the predecessor's sync audit recorded that
**no read query filtered by `userId`**, so those foreign rows would surface on the home and report
screens.

Three facts from that audit settle whether the engine was worth repairing:

- **The engine's entire productive life was a ten-minute window.** Tenant A's 50 rows are frozen at
  `server_updated_at` 2026-06-11 10:25:27–10:35:24. Tenant B's 14 rows are all from 2026-08-12,
  its first sign-in ever. That is all of it.
- **Zero rows carry a non-null `deleted_at` anywhere.** No soft delete ever reached the server, not
  once. Half the protocol never worked in production, and that has nothing to do with the loop.
- **Cross-tenant dangling references.** All 13 of tenant B's transactions point at an account owned
  by tenant A; RLS hides the parents. The inserts succeeded because the public schema has no
  foreign keys at all, deliberately, per ADR 001.

The loop itself was a genuinely small fix — two predicates that had to agree and did not, plus a
second independent path that dropped any pending transaction whose `occurredAt` did not parse.
Fixing it was considered seriously and rejected: it returns the app to the engine described above.

Row-level replication earns its cost in four scenarios, and JustChill has none of them. Two
concurrent writers: rejected by the product definition, not merely absent (`PRODUCT_REQUIREMENTS.md`
W-04, shared multi-user ledgers). A dataset too large to ship whole: one human's personal finances.
A server that must read the rows: no server-side feature exists and push notifications are a
Won't-have (W-08). Real-time between devices: there is one owner and one phone, the premise ADR 006
already found was never exercised.

Discovery had answered this before ADR 001 was written: the owner's own answer was that cloud backup
was tempting only as a manual JSON export and import, and that cloud backend, Google Sign-In and
sync stayed out. ADR 006's alternatives table then rejected "drop sync entirely, keep the manual
JSON export" because the export is **a manual step the owner has to remember** — a rejection of
*manual*, not of *export*. Automating it removes the stated objection.

## Decision

1. **Backup is a snapshot.** The complete versioned JSON export is uploaded to Supabase Storage:
   one blob per snapshot, a sidecar manifest carrying its SHA-256, format version and per-table row
   counts, and a read-back hash check before any upload is recorded as successful. Retention is
   staggered — 7 daily, 8 weekly, 12 monthly — plus **pinned** snapshots that retention skips.
   **The pipeline inherits the opt-in gate unchanged**: it runs only for a signed-in session, and
   the app remains fully usable with no account and no network (ADR 001 Decisions 1 and 2; PRD
   W-02 and W-11). No session means no pipeline, not a queued upload.
2. **The row-replication engine is decommissioned, not parked.** The per-table syncs, the pull
   cursor, the conflict resolver, LWW, the synced/pending markers, the sync scheduling and its
   debounce are deleted. This amends ADR 006 Decision 5: keeping dead convergence machinery in the
   tree is what allowed the contract and the code to disagree for two months. Git history is the
   archive. **ADR 006 Decision 6 is cancelled, not merely deprioritized**: server-side conditional
   upsert was the fix for a replication protocol that no longer exists.
3. **Restore is the JSON import, unchanged in kind.** It is a transactional replace-all **over the
   tables the format carries** — every live row in those tables tombstoned, then the file's rows
   restored — and it drops, by design, rows it cannot represent: a transaction whose `occurredAt`
   does not parse, and a `categoryId` whose type no longer matches. Restore reports what landed,
   not what the file held. Every table, `recurring_movements` included, is in the format (see
   Consequences). The format is version-tagged and old shapes are frozen in their own types with
   fixtures pinning them — the only data path with a frozen-format compatibility test. It becomes
   the product.
4. **Backup ships only once restore is continuously proven**: a CI round-trip test over every
   exported table including tombstoned rows, an in-app "verify backup" that checks hash, parse and
   per-table counts *without applying*, and a documented restore drill on the release checklist.
   Until those pass, the pipeline stays behind its own flag.
5. **Changing the backup destination is disclosed on screen before the first upload to it.** This
   retargets ADR 006 Decision 3, which does not retire with the engine. Sign-out clears the session
   and nothing else — one database file per device, no per-user database, no wipe on user change —
   so *the next account inherits the previous one's rows*. Under snapshots that inheritance means
   the next automatic upload sends **this device's whole ledger, including the previous account's
   rows, into the new account's bucket**. That follows from ADR 006 Decision 2 (the data belongs to
   the DEVICE; the account is only a destination) and is acceptable behaviour — but only if the app
   says so first. It is a one-time **disclosure**, not a confirm-or-cancel dialog: nothing is
   downloaded, nothing is merged, and nothing is destroyed locally, so there is no fork to
   arbitrate.
6. **Trigger rule.** *Sync is only reopened when a second concrete writer exists: a physical device
   in daily use, or a deployed editable web surface. A plan or hypothesis does not qualify.
   Reopening requires a new ADR that names the device and cites this rule.* This is a product
   contract, not a technical invariant — nothing enforces it.
7. **Restore fork rule.** *Restoring a snapshot onto a device makes that device THE device. Any
   other device holding the data is retired at that moment; continuing to write from it forks
   history and is unsupported.* Also a contract, not an invariant: nothing detects a second writer,
   and under Decision 6 there is not supposed to be one.
8. **Encryption relies on Supabase at-rest encryption. End-to-end encryption is explicitly
   deferred**, and deferred for a reason rather than for effort: a Keychain-bound key dies with the
   phone, which is the exact scenario a backup exists to survive. Doing it properly means a
   passphrase-derived key and a recovery story for a forgotten passphrase, and that is its own ADR.
9. **The sync SCHEMA stays. Forbidden by this ADR:** dropping `userId`, `syncState` or `deletedAt`
   from any table; changing the UUID primary keys; reverting to hard deletes — soft delete plus
   `deletedAt IS NULL` on every read stays (ADR 001 Decisions 6 and 7, preserved). Reopening sync
   must therefore need **no destructive migration**: at most one additive table. Note what the
   columns become: with the synced/pending markers gone, every row is written `'Pending'` and
   nothing ever clears it, so `syncState` carries no information — a future engine must treat the
   first sync as a full push rather than trusting the flag.

ADR 006 Decision 2 (**the data belongs to the DEVICE; the account is only a backup destination**)
and Decision 4 (**production is derived, never authoritative**) survive and are strengthened: under
snapshots the account holds opaque blobs it cannot interpret, and the server is incapable of being
authoritative because nothing reads rows out of it.

## Alternatives considered

| Option | Why rejected |
|---|---|
| **Keep the engine, fix the loop** | The smallest change on the table, and the loop fix is real. It returns the app to an engine that never synced a single delete in production and left cross-tenant dangling references. The loop was the part that was visible, not the ceiling of the problem. |
| **Push-only row sync** (upload rows, never pull) | Kills the merge semantics that broke the re-point flow, but leaves no restore path — and a backup you cannot restore from is not a backup. The only tested restore is the JSON import, so this converges on snapshots with extra machinery. |
| **Local file backup only (Files / iCloud Drive), zero backend** | Genuinely attractive: it removes Supabase from the data path entirely and matches Discovery's "the app touches no server" line. Rejected because it needs the owner to keep choosing a destination and to notice when the file stops being written; that is ADR 006's "manual step the owner has to remember", relocated. Supabase Storage is chosen because auth already exists for it and RLS gives per-user isolation for free. Revisit if the Supabase dependency ever becomes the thing worth removing. |
| **Adopt a sync engine now** (PowerSync, Turso, ElectricSQL) | These are the correct answer to *a second writer*, and there is no second writer. Priced from vendor documentation on 2026-08-13: cost would not be the deciding factor at this volume — SDK maturity would. Recorded here so the trigger rule has somewhere to point; re-check before acting on it. |
| **Keep the manual export and change nothing** | The status quo ADR 006 rejected, for the right reason: a device loss between exports is real data loss on a phone with accumulated real data. Automating the export is the whole point of this ADR. |
| **Snapshot the raw SQLite file instead of the JSON export** | Simpler to produce and byte-exact, but it restores only into the schema version it was written from, so every migration turns old snapshots into liabilities. The JSON format survives schema changes by design — files written against an old schema restore into a newer one. |

## Consequences

### Positive

- **Snapshots survive owner mistakes; replication faithfully mirrors them.** An accidental wipe
  propagates to the server within one sync cycle and destroys the backup. With staggered retention
  the previous days are still there. For a feature whose entire purpose is backup, this is the
  point, not a detail.
- A whole class of problems retires: conflicts, cursors, tombstone propagation, LWW, clock skew,
  and the re-point merge that could not be honestly described on screen. **Not** the identity
  scoping findings — see Decision 5 and the costs below.
- The restore path is the one that was already tested, rather than a pull path never exercised.

### Negative / costs

- **Every table must be in the export format**, `recurring_movements` included. Shipping snapshots
  without one would silently drop it on device loss, and an import sweep that is not
  version-aware would destroy local rows of a table an older file does not carry.
- **Identity scoping does not retire.** One database file per device, no wipe on user change, and no
  read query filtering by `userId` all survive this ADR. Decision 5 discloses the consequence
  rather than removing it; a real fix is a schema question and is out of scope here.
- **One cycle at a time.** Account deletion and the backup cycle must not run concurrently, and the
  lock that serializes them needs a timeout before the pipeline ships, not after.
- **Point-in-time granularity.** A device lost hours after the last snapshot loses those hours.
  Row sync would have lost less — in principle; in practice it lost everything, since no delete and
  no row after 2026-06-11 10:35 ever reached the server.
- **Full re-upload per snapshot.** Irrelevant at this dataset size, and it would matter if the app
  ever grew a second user.
- ADR 001 remains on the books describing a system that no longer exists in any form. A reader who
  stops at it gets the wrong model; this ADR has to be reached first.

## Notes

- **What enforces the rules above.** Decisions 6 and 7 are contracts, not invariants, and say so.
  The retention/pinning behaviour and the version-aware import sweep are enforced by tests. "Every
  schema migration is preceded by a pinned snapshot" is enforced only by the release-checklist
  line Decision 4 creates (`docs/release.md`) — if that line is not written, the rule is prose.
