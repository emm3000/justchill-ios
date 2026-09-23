---
name: feature
description: Scaffold a new Packages/Feature<Name> package with its screen, model, content view, route and tests, wired into project.yml and AppContainer
argument-hint: <FeatureName>
allowed-tools: Read Write Edit Bash(fd:*) Bash(rg:*) Bash(scripts/gate) Bash(scripts/build:*)
disable-model-invocation: true
---

Scaffold a new feature called **$ARGUMENTS** as its own local Swift package, `Packages/Feature$ARGUMENTS`. A feature owns its models, screens, content views and route payloads; `App/` owns the wiring that reaches it.

## Before creating anything

1. Confirm the name is PascalCase and that `Packages/Feature$ARGUMENTS/` does not exist yet (`fd`).
2. Read the most complete existing feature package end to end; it is the reference shape. If none exists yet, the templates are the reference, and `Packages/CoreUI` shows the package manifest style.
3. Confirm with me which existing feature you used as the template.

## The package

| Path | Content |
|---|---|
| `Packages/Feature$ARGUMENTS/Package.swift` | `Package.swift.template` — `CoreDomain` and `CoreUI` and nothing else unless a library is actually used |
| `Packages/Feature$ARGUMENTS/CLAUDE.md` | a short doc: what the feature owns, its routes and factories, its gotchas |

No per-package `.gitignore`: the root one already ignores `.build/` and `.swiftpm/` at any depth.

When `Packages/CoreTesting` exists, add `.package(path: "../CoreTesting")` to the manifest's dependencies and its product to the test target only.

## Swift files

Copy each template from `${CLAUDE_SKILL_DIR}/templates/<file>`, drop the `.template` suffix, substitute every placeholder, and place it:

| Template | Destination |
|---|---|
| `__Feature__Model.swift.template` | `Sources/Feature$ARGUMENTS/` |
| `__Feature__Screen.swift.template` | `Sources/Feature$ARGUMENTS/` |
| `__Feature__Content.swift.template` | `Sources/Feature$ARGUMENTS/` |
| `__Feature__Route.swift.template` | `Sources/Feature$ARGUMENTS/` |
| `__Feature__ModelTests.swift.template` | `Tests/Feature$ARGUMENTSTests/` |

The one placeholder is `__Feature__`, replaced by the PascalCase name **$ARGUMENTS**.

`Model` (`@Observable final class`, `private(set)` state, one method per user action, SwiftUI-free; it takes the ids it needs, never the route), `Screen` (owns the model in `@State`, starts its work in `.task`, hands values and closures to the content), `Content` (a pure view over values and closures with a `#Preview` per state), `Route` (the `Hashable` payload the root `Route` case wraps; fields carry ids, never entities) and `ModelTests` (Swift Testing, one `@Test` sentence per rule).

The templates are the minimal shape: one state property, one action. Grow them to fit the feature without changing the idioms they encode. A failure the model can hit becomes `private(set) var failure: DomainError?` plus `dismissFailure()`, rendered by the content with `.alert`; a finished action becomes a stored outcome the screen watches with `.onChange` and answers through a navigation closure (`architecture.md`, the model contract).

Placeholder copy in the content view is a literal Spanish string, tuteo. A message the model exposes is an enum resolved to text in the view, never a string in the model.

## Wiring into `project.yml`

1. Under `packages:` add `Feature$ARGUMENTS: { path: Packages/Feature$ARGUMENTS }`.
2. Under `targets.justchill.dependencies` add `- package: Feature$ARGUMENTS`.
3. Under `schemes.justchill.test.targets` add `- package: Feature$ARGUMENTS/Feature$ARGUMENTSTests`. Without this line the gate never runs the new tests and stays green by absence.

`scripts/build` regenerates the project on its next run; never edit `justchill.xcodeproj` by hand (ADR 019).

## Wiring into `App/`

1. `App/Composition/AppContainer.swift` — add `func make$ARGUMENTSModel(route: $ARGUMENTSRoute) -> $ARGUMENTSModel`, which reads the ids off the route and passes them with the shared instances the model needs. The factory is the only place its dependencies are chosen.
2. `App/Root/Route.swift` — add a case named for the screen in `lowerCamelCase`, wrapping `$ARGUMENTSRoute`.
3. `App/Root/RootView.swift` — handle the new case in the `.navigationDestination(for: Route.self)` switch with `$ARGUMENTSScreen(model: container.make$ARGUMENTSModel(route: route))`. While `Route` had no cases the destination returned `Never`; the first case turns it into a `@ViewBuilder` returning `some View`.
4. Give the route a door: an existing screen takes an `on<Action>` closure that `RootView` answers by appending the case to `path`, and a second door if the first is gated (`architecture.md`, one door is no door). Navigation out of the feature arrives as a closure the host supplies, never as a `Route` value.

## Hard rules (from `CLAUDE.md` and `.claude/rules/`)

- Views use **only** CoreUI atoms; `Text` and `Image` only with a `Typography` role and a `Palette` token. Never a raw styled SwiftUI control, never a material outside an atom.
- A feature depends on `CoreUI` and `CoreDomain` only, plus `CoreTesting` on the test target; never another feature.
- No SwiftUI, UIKit or CoreUI import in a `*Model.swift`; `scripts/check-swiftui-free-models` is on the gate for the first.
- Explicit types on every stored property and local; no comments.
- At most 4 levels of nesting, at most 2 real returns per function — review-enforced, see `.claude/rules/swift-style.md`.

After creating the files, run `scripts/gate`.
