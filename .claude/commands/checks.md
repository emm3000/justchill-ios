---
description: Run the gate and summarize failures
allowed-tools: Bash(scripts/gate) Bash(scripts/check-swiftui-free-models) Read
disable-model-invocation: true
---

Run the standard pre-commit check for this iOS repo:

1. `scripts/gate` — the gate CI runs. It runs `scripts/check-swiftui-free-models`, regenerates the project with XcodeGen when stale, then builds and tests the `justchill` scheme on `iPhone 17` iOS 27.0. The script is the whole check; no lighter command substitutes for it, and `swift test` on one package is not the gate.

Group findings by package (`CoreDomain`, `CoreUI`, `Feature*`, `App`) and by kind (the model purity check, a compile error, a failing test). For each include `file:line` and the check or `@Test` name. If a package's tests did not run at all, check whether its test target is listed under `schemes.justchill.test.targets` in `project.yml` and say so.

Do NOT fix anything in this turn — only report. End with one line: **"ready to commit"** if the gate is green, or a short list of what to fix next.
