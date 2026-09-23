---
description: Self-review pending changes against the repo rules
allowed-tools: Bash(git status:*) Bash(git diff:*) Read Grep
disable-model-invocation: true
---

Review the pending changes (staged + unstaged) against `CLAUDE.md` and `.claude/rules/`. Use `git status`, `git diff` and `git diff --cached` to see what changed.

## Checklist

1. **Package boundaries**
   - Any file under `Packages/CoreDomain/Sources/` importing anything but Foundation?
   - Any `*Model.swift` importing SwiftUI, UIKit or CoreUI, or holding `Color`, `Image`, `LocalizedStringKey` or a `#Preview`?
   - Any file outside `App/Composition/` naming a `GRDB*Repository` or a Supabase client?
   - Any `Package.swift` edge outside: `App -> Feature*, CoreBackup, CoreDatabase, CoreUI, CoreDomain`; `Feature* -> CoreUI, CoreDomain` (plus `CoreTesting` on the test target); every other `Core*` -> `CoreDomain`?

2. **The model contract**
   - One `@Observable final class <Screen>Model` per screen, state `private(set)`, no `ObservableObject`, no Combine, no Intent or Effect enum?
   - One-shot outcomes as state the view reacts to, never a navigation closure stored on the model?
   - State stores ids, never resolved objects; no literal Spanish string in a model?
   - A new model built by one `make<Screen>Model` factory on `AppContainer`?
   - `<Screen>Content` pure: no model, no repository, no use case?

3. **UI**
   - Any raw styled SwiftUI control in a feature view (`Button` with a style, `TextField`, `Toggle`, `Picker`, `.buttonStyle(...)`)?
   - Any literal `Color`, font size or padding number outside `Tokens.swift`? Any material or glass effect outside an atom?
   - New shared components in `CoreUI/Atoms/` with a `#Preview` of every state?
   - Every new destination a `Route` case handled by `RootView`'s switch, with a second door?

4. **Complexity (`.claude/rules/swift-style.md`, review-enforced)**
   - More than 4 levels of nesting? More than 2 real returns per function? A force unwrap, `try!` or `as!` outside tests?
   - A function, view or file doing several things that should be split?

5. **Local-first and data**
   - Any code assuming a backend, row sync or a mandatory login?
   - A schema change appends a new named migration, never edits a shipped one, and carries its fixture and migration test?
   - `Clock` and `TimeZone` injected, no defaults? Every catch-all handles `CancellationError` first?
   - A new test target listed under `schemes.justchill.test.targets` in `project.yml`?

6. **Hygiene**
   - Comments beyond the three exceptions in `swift-style.md`? Explicit types on stored properties and locals?
   - Spanish only in user-facing values, tuteo never voseo; English identifiers?
   - Sensitive files in the diff (`Secrets.xcconfig`, `.env`, `*.p12`, `*.mobileprovision`, `GoogleService-Info.plist`, `ExportOptions.plist`) or a committed `justchill.xcodeproj`?

## Output

For each violation: `file:line` + rule + suggestion on a single line. If everything is clean, reply **"clean — ready to commit"**. Do not edit files in this turn.
