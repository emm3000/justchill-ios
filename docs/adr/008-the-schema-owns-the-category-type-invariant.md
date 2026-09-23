Ported from the Android repo on 2026-09-22; the decision stands for iOS.

# ADR 008 — The schema owns the category/type invariant

- **Status**: Accepted
- **Date**: 2026-08-12
- **Deciders**: Edgardo Muñoz
- **Amends**: nothing. It states an exception to the rule "referential integrity is enforced in
  domain use cases, not by foreign-key clauses", which no ADR had decided.

> Summary: that a movement's category has the same type as the movement stops being a convention and
> becomes a **composite foreign key** — `(categoryId, type) → categories(categoryId, categoryType)`
> on `transactions` and `recurring_movements`. The convention had nine writers holding it by hand and
> **three** that never pass through the domain, so any invariant placed there has a ceiling by
> design. The migration repairs before it rebuilds, and it always repairs **from the category side**:
> `type` signs the `amount`, so flipping it would rewrite the user's financial history. The picker
> scoped by type stays, as UX, not as the mechanism.

## Context

A movement (`transactions`, `recurring_movements`) carries a `type` — `Income` or `Spend` — and a
nullable `categoryId`. A category carries its own `categoryType`. Nothing related the two columns:
they were two independent TEXT fields that every writer had to keep in agreement by convention.

The convention did not hold. Creating a category from an Income movement saved it as `Spend` and
filed it under the Income movement anyway, confirmed on a device and against the database. The
proximate cause was one navigation default, but the defect class is wider: **nine writers** could
put a `(categoryId, type)` pair into the database, and **three of them never passed through the
domain** — the backup import and the two per-table sync pulls. A fourth, the category sync, could
change a category's type underneath movements already filed under it.

Four rounds of runtime patches were written against this and none closed it. That is not four
mistakes; it is the ceiling of the approach. An invariant in the domain cannot reach a writer that
does not call the domain, and the discarded attempt also introduced a CRITICAL of its own: a
not-found error raised on a tombstoned category made recurring templates permanently
unconfirmable. Those patches are kept only on the predecessor repo's tag
`patches-descartados-2026-08-12`.

Two facts about the data make "just fix it forward" insufficient. The owner runs the app daily on a
device holding real accumulated data, so mismatched rows already existed there. And every backup
file on disk predated any of this, so the one safety net was full of pairs the new rule rejects.

## Decision

1. **The database enforces it.** `transactions` and `recurring_movements` declare a composite
   foreign key `(categoryId, type) → categories(categoryId, categoryType)`. `categories` gains the
   UNIQUE index over `(categoryId, categoryType)` that SQLite requires over the parent columns —
   without it the child DDL parses and every insert then fails at runtime with "foreign key
   mismatch", which is a different error from a constraint violation and one no caller catches.
2. **`CategoryType` and `TransactionType` stay separate enums.** `TransactionType` maps totally onto
   `CategoryType`. Their user-facing labels differ on purpose (`"Ingresos"` vs `"Ingreso"`);
   collapsing them is churn that breaks UI copy. What IS load-bearing and invisible to the compiler
   is that the two enums share their RAW VALUES — the key compares the columns as text.
3. **Neither key carries an `ON DELETE` clause.** `ON DELETE SET NULL` on a composite key nulls
   every child column, `type` included, and `type` is `NOT NULL`, so the clause could only ever
   abort the delete. It is structurally impossible here, not merely unwanted.

   The clause it replaces was **not** dead code. A category write through `INSERT OR REPLACE`
   that hits an existing `categoryId` deletes the row before reinserting it, which fired
   `ON DELETE SET NULL` and stripped the category off every movement pointing at it. What justifies
   dropping it is that **the composite key answers the same situations better**: SQLite checks a
   REPLACE's implied delete at the end of the statement, so reinstating the same
   `(categoryId, categoryType)` pair strips nothing at all; a REPLACE that changes the type is
   refused instead of silently stripping; and a genuine physical `DELETE` of a referenced category
   is refused too. Every path that used to lose data quietly now either does nothing or fails
   loudly.
4. **The migration repairs from the category side, never the type side.** `type` signs the amount,
   so rewriting a movement's type to resolve a mismatch would move the user's totals. Nulling the
   category loses a label the user can restore in two taps; flipping the type loses the truth.
5. **Repair does not dirty the rows it touches** — no `updatedAt` bump, no `syncState = 'Pending'`.
   Under [ADR 006](006-sync-is-backup-only-one-device-at-a-time.md) there is no second replica for a
   correction to reach.
6. **The restore path repairs rather than fails.** Restore nulls the category on any pair the key
   would refuse, absent or mismatched alike, because the whole restore is one transaction and a raw
   violation costs the entire import. (The predecessor's sync pull kept a deliberate asymmetry
   between absent and mismatched parents; that pull is gone with ADR 009.)
7. **Scoping the pickers by type is UX, not the mechanism.** The forms only ever offer categories of
   the movement's type and the new-category route carries that type, so a user cannot reach the
   constraint. That is worth having — the alternative is a generic database error with nothing on
   screen explaining it — but it is not what makes the invariant true.

## Alternatives considered

| Option | Why rejected |
|---|---|
| **Enforce it in a domain use case / runtime invariant** | Cannot reach the writers that never call the domain, which is precisely where the corruption entered. Tried, reviewed, discarded; it also broke recurring confirmation on tombstoned categories. |
| **Collapse `CategoryType` into `TransactionType`** | Removes the mismatch by removing one of the types, but their labels are different user-facing copy, and it still leaves two unrelated TEXT columns in the database. Churn without enforcement. |
| **Fix only the navigation default that produced the bug** | Closes one of nine writers. The other eight, and the rows already on the device, stay exactly as they were. |
| **Repair by flipping the movement's type to match its category** | Silently rewrites financial history: the aggregates sign `amount` by `type`. Irreversible and invisible. |
| **Drop the mismatched rows in the migration** | Deletes movements the user actually recorded, to fix a label. |
| **A CHECK constraint or a trigger** | SQLite `CHECK` cannot reference another table. A trigger could, but it duplicates what a foreign key already means and is not covered by the migration tests the way a declared key is. |

## Consequences

### Positive
- The invariant holds for every writer, present and future, including ones written by someone who
  never read this file. That is the entire point.
- A `DomainError` for a database failure is the worst case, not silent corruption.
- The migration is also a data repair: existing mismatched and orphaned pairs are cleaned on the
  first open.

### Negative / costs
- **A category can no longer serve both sides of the ledger, and it genuinely could before.** The
  owner needs **two categories** for something like "Préstamos" — one Income, one Spend — and the
  two show as two rows.
- The two enums' raw values are a schema contract with no compiler check behind it. Renaming a raw
  value of `TransactionType` or `CategoryType` breaks every write in the app; `.claude/rules/grdb.md`
  says so where a migration writer reads it.
- The migration rebuilds two tables, and the migration tests from real fixtures are the only thing
  that run it against an old file.

## Notes

- Mechanics and the ordering constraint (repair before rebuild, because GRDB's migrator checks
  foreign keys at the end of each migration): `.claude/rules/grdb.md`.
- [ADR 001](001-reverse-local-only-to-local-first-optional-sync.md)'s Consequences describe the
  `categoryId` foreign key as `ON DELETE SET NULL`. That clause is gone as of this ADR; 001's own
  decision — that soft-delete integrity is reimplemented in use cases — is untouched, and 001 is
  left as written, per the rule that ADRs are amended by a new ADR and never rewritten.
