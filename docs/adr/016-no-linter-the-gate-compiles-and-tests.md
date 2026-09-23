Ported from the Android repo on 2026-09-22; the decision stands for iOS.

# ADR 016 — No linter: the gate compiles and tests

- **Status**: Accepted
- **Date**: 2026-09-18

The predecessor repo ran detekt, and it cost more than it caught. Two tickets in a row (#157, #173)
were about keeping it honest rather than about the product, and its analysis classpath broke
silently on every build-tool upgrade: type-resolution rules went quiet wherever a symbol did not
resolve and the task still passed, so a green gate was never evidence that the rules ran. The
findings it did report were style findings on a single-author app, arbitrated by review anyway.

## Decision

No linter runs in this repo: no SwiftLint, no `swift-format lint`, no formatter check in the gate.
The same trade holds for Swift as it did for detekt — a rule engine with its own configuration and
baselines, maintained for one author whose every PR a reviewer already reads.

`scripts/gate` keeps every check that proves something: `scripts/check-swiftui-free-models`, the
build of the app scheme, and every test target the scheme lists. The script stays the single source
of that list.

The complexity limits detekt enforced survive as review conventions in `.claude/rules/swift-style.md`
— nesting, return count, functions per file, function length. They are the reviewer's, not a
tool's.

## Consequences

Nothing mechanical rejects a formatting or complexity regression; a PR review is the only net, which
is what it already was for the rules a linter cannot see. A check that proves an architectural rule
(the model purity check is the precedent) is not a linter and may join the gate as a script, one
rule each, when review keeps catching the same violation.
