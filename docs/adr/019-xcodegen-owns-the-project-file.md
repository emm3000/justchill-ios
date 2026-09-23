# ADR 019 — XcodeGen owns the project file

- **Status**: Accepted
- **Date**: 2026-09-22
- **Deciders**: Edgardo Muñoz

## Context

An Xcode project file (`project.pbxproj`) is a generated-looking file that humans edit through
Xcode's UI. It changes whenever a file is added, a setting is toggled or a package is linked, and
its object identifiers make two independent edits conflict. This repo runs several peer sessions at
once, each in its own worktree (`docs/agents/multi-session.md`); a committed project file would turn
every wave that adds files into a round of project-file merge conflicts, resolved by hand in a
format nobody reviews.

The code itself lives in local Swift packages (ADR 018), which need no project file. What still
needs one is the app target: its bundle identifier, Info.plist keys, asset catalog, the packages it
links and the scheme the gate runs.

## Decision

1. **`project.yml` is the source of truth**, and XcodeGen generates `justchill.xcodeproj` from it.
   The generated project is gitignored.
2. **`scripts/build` regenerates it** before every build: a full generation when the project is
   missing, `xcodegen generate --use-cache` otherwise, which skips the work when neither the spec
   nor the file tree moved. `scripts/gate` and CI go through `scripts/build`, so a stale project
   never reaches a test run.
3. **Never edit the generated project.** A setting changed in Xcode's target editor is lost at the
   next generation. Every change — a package, a build setting, an Info.plist key, a scheme test
   target — is a `project.yml` edit, reviewed like code.
4. **The scheme's test list is part of the spec.** A package's tests run on the gate only when its
   test target is listed under `schemes.justchill.test.targets`.

## Consequences

- Adding files never conflicts: packages pick up their sources from the folder, and the app target
  from `App/`.
- XcodeGen is a development dependency: installed with Homebrew locally and in CI.
- Opening the project in Xcode requires generating it first (`scripts/build` or `xcodegen
  generate`).
- A new package is wired in three places in `project.yml` — `packages`, the app target's
  `dependencies` and the scheme's test targets — and the `/feature` skill says so.
- Remote package dependencies are declared in the `Package.swift` that uses them, never in
  `project.yml`, so dependabot's `swift` ecosystem can see them.

## Alternatives considered

| Option | Why rejected |
|---|---|
| **Commit the `.xcodeproj`** | The default, and the source of merge conflicts on every parallel wave that adds a file. Reviewers skip the diff, so a wrong setting lands unseen. |
| **Tuist** | Generates the project from Swift manifests and adds caching and a module graph, at the cost of a larger tool with its own release cadence and cloud features unused here (ADR 018). |
| **An app built from `Package.swift` alone** | SwiftPM has no general iOS application product outside Swift Playgrounds; the app target still needs a project. |
| **Xcode's folder-based groups with a committed project** | Synchronized folders shrink the file-list churn, but settings, package links and schemes still live in the committed file and still conflict. |
