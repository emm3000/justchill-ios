# Per-target gates

Read the row for the target before opening any source file.

| Target | Read first | File budget |
|---|---|---|
| Feature / screen flow | `.claude/rules/ui-components.md`, then the screen, its `Content`, its model, its use cases | 15 |
| Architecture / package | `CLAUDE.md` `## Packages`, then that package's `Package.swift`, its own `CLAUDE.md` if it has one, and `.claude/rules/architecture.md` | 20 |
| Backup | `docs/adr/009-backup-is-a-snapshot-not-row-replication.md` and `.claude/rules/grdb.md` `## The restore drill` BEFORE any source file | 20 |
| GRDB migrations | `.claude/rules/grdb.md`, then the migrator, the fixtures under `Packages/CoreDatabase/Tests/Fixtures/` and the snapshot format versions in `CoreBackup`. Flag any drift between the schema and the format — in the predecessor repo this class broke production for two months (commit `72a9b03`) | 15 |
| Dates | `.claude/rules/architecture.md` `## Layers and dependency direction` — the live rule is an injected `Clock` AND an injected `TimeZone`, neither carrying a default, with its own `rg` check | 15 |
| `.github/` pipelines | `.claude/rules/github-workflows.md` — SHA-pinned actions, the `xcode-27` runner, the `git describe --match "v[0-9]*"` filter, secrets via `env:` | 10 |
| Project generation | `docs/adr/019-xcodegen-owns-the-project-file.md`, then `project.yml` against the packages on disk: every package with tests listed under the scheme's `test.targets` | 10 |
| Docs vs code | the code is the truth, the doc is the suspect | 20 |
| Whole project | do not attempt exhaustively. Sample the rows above, declare the sample, and emit `## Coverage` | 30 |

## Scope budget

- The budget counts source files opened, not the docs in the `Read first` column.
- On hitting the budget, stop and emit `## Coverage`. Never silently truncate.
