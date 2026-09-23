---
paths:
  - ".github/**"
  - "scripts/**"
  - "project.yml"
  - ".claude/commands/release.md"
---

# CI, release and the gate

- `scripts/gate` is the gate, locally and in CI. Its definition is the script itself — `scripts/check-swiftui-free-models`, then `scripts/build build test`, which regenerates the project with XcodeGen when stale and runs `xcodebuild` on `iPhone 17` iOS 27.0 — never a prose copy elsewhere. What it tests is the scheme's `test.targets` list in `project.yml`: a package test target missing from that list never runs anywhere.
- One workflow, `.github/workflows/gate.yml`, on a PR to `trunk`, on every `trunk` push and by hand. A `changes` job runs `git diff --name-only` against the PR base; the required check `gate` is skipped (counted as passing) only when the PR touches `**/*.md`, `docs/**`, `.claude/**`, `scripts/justchill-*` or `.github/dependabot.yml` alone, and runs whenever `changes` did not succeed. A `trunk` push always runs it.
- The runner is the `xcode-27` image label: macOS 27 with Xcode 27 as the default and an `iPhone 17` iOS 27.0 simulator. `macos-26` exists but ships only the Xcode 26 line, which cannot build an iOS 27.0 target (checked against `actions/runner-images` on 2026-09-22). The label is a preview image; when Xcode 27 reaches a GA image, move there and select Xcode explicitly with `xcode-select`. XcodeGen and ripgrep are not on the image, so the job installs them with Homebrew before the gate. actionlint does not know the preview label yet; `.github/actionlint.yaml` declares it, and goes when actionlint learns it.
- Branch protection is `strict: false`, so the `trunk` push run is the only net for semantic conflicts between PRs green on their own. Never drop it.
- Measure before adding a cache. No DerivedData or SwiftPM cache is wired yet. The predecessor repo measured two cache levers in paired rounds on 2026-09-19 (#153) and applied neither: the lever moved the number less than `trunk` landing between rounds did. Measure paired rounds, never one run against another day's, and write the run ids down with the decision.
- Every action is pinned to a full commit SHA with its tag in a trailing comment, GitHub's own `actions/*` included: a floating tag can be repointed upstream. Do not tidy them into tags; dependabot proposes bumps.
- Dependabot watches two ecosystems: `github-actions` over `.github/workflows`, and `swift` over `Packages/*`. It reads `Package.swift` and `Package.resolved` only, so a remote dependency declared in `project.yml` instead would rot unseen; remote dependencies live in the `Package.swift` that uses them. Majors are ignored for `swift`: a GRDB or supabase-swift major is a migration project, not a routine update, and Dependabot alerts still surface a CVE the ignore rule suppresses.
- `run:` blocks take secrets and event fields through `env:`, never `${{ }}` spliced into the script text. Validate workflow edits with `actionlint`.
- `trunk` protection has `enforce_admins: false` on purpose: direct pushes to `trunk` skip PR CI, and the `trunk` push run catches a bad one after it lands; with linear history and a single author, reverting it is cheap. Change protection with a `PUT` of the whole object, never a PATCH. Check it: `gh api repos/emm3000/justchill-ios/branches/trunk/protection --jq '{checks: .required_status_checks.contexts, admins: .enforce_admins.enabled, linear: .required_linear_history.enabled, force: .allow_force_pushes.enabled}'`.
- The release version is `MARKETING_VERSION` in `project.yml`, and a release tag equals it with a `v` prefix. The latest release tag is `git describe --tags --abbrev=0 --match "v[0-9]*"`; the filter is load-bearing, because a repo that carries non-release tags otherwise names a build after one (the predecessor shipped a build called `pre-kmp`). Same filter in `/release`.
- A tag ships nothing. No workflow runs on a tag today: `/release` tags `trunk` and publishes a GitHub release. A TestFlight upload is a future ticket, and it brings signing secrets, which is when this file grows a secrets section.
