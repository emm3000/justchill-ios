# ADR 018 — Rebuild for iOS on SwiftUI, Observation, local packages and GRDB

- **Status**: Accepted
- **Date**: 2026-09-22
- **Deciders**: Edgardo Muñoz

## Context

JustChill exists as an Android app written in Kotlin with Jetpack Compose, an MVI base class, Koin,
SQLDelight and supabase-kt, split into feature modules. The owner wants the same product on iOS: the
same scope (`docs/PRODUCT_REQUIREMENTS.md`), the same domain (`CONTEXT.md`), the same decisions
(ADRs 001–017 where they are not platform facts) and the same agent workflow (ADRs 013 and 014).

What does not carry over is the code. A port that mirrors the Android structure would import idioms
that exist to solve Android problems: a sealed-intent MVI base to funnel Compose events, a DI
container to reach ViewModels across a process-death boundary, a serializer test to catch routes
that crash on restore, three schema artifacts per migration because SQLDelight verifies against
snapshots. iOS in 2026 answers each of those differently, and "rebuild, never adapt" applies to
the port itself.

## Decision

1. **Xcode 27, Swift 6.4, iOS 27.0, SwiftUI only.** Swift 6 language mode with strict concurrency
   and approachable concurrency: default `MainActor` isolation in the app, `CoreUI` and every
   feature; default `nonisolated` in `CoreDomain`; `@concurrent` only for deliberate background
   work.
2. **One `@Observable final class <Screen>Model` per screen** — MVVM on Observation, SwiftUI's
   native model. State is stored properties, user actions are methods, one-shot outcomes are state
   the view reacts to (`.alert`, `.onChange`). No `ObservableObject`, no Combine, no base class, no
   Intent or Effect enums. A container view owns the model; a pure `<Screen>Content` view renders
   values and closures for previews and tests. Models never import SwiftUI, and
   `scripts/check-swiftui-free-models` keeps it so.
3. **Local Swift packages for modules.** `CoreDomain` (Foundation only), `CoreDatabase` (GRDB),
   `CoreBackup` (supabase-swift), `CoreUI`, `CoreTesting`, and one `Feature<Name>` per screen
   family. SwiftPM's declared dependencies enforce the graph in `CLAUDE.md`; features never import
   each other.
4. **Manual dependency injection in a composition root.** `AppContainer` in `App/` holds the shared
   instances and exposes one `make<Screen>Model()` factory per screen. No DI framework.
5. **Typed navigation.** A `Route: Hashable` enum and a `[Route]` path in `RootView`, with one
   exhaustive `navigationDestination`. The compiler replaces the predecessor's route serialization
   test.
6. **GRDB.swift for persistence**, with a `DatabaseMigrator` of named, append-only migrations and a
   migration test per shipped fixture database (`.claude/rules/grdb.md`).
7. **Swift Testing** for every unit test; one XCUITest smoke test later.
8. **XcodeGen owns the project file** (ADR 019).

## Consequences

- The domain, the product rules and the ADRs port as text; the code is written fresh. A reviewer
  who finds a Kotlin idiom translated into Swift (a sealed intent enum, a `Default*` repository
  hierarchy, a navigator object passed into screens) has found a defect.
- The compiler carries rules the predecessor needed tests or Gradle tasks for: package boundaries,
  exhaustive routes, actor isolation. What it cannot see — model purity beyond the SwiftUI import,
  atoms-only views, injected clocks — stays in review and in `.claude/rules/`.
- Swift 6 strict concurrency makes some third-party code awkward to call; a package that is not
  `Sendable`-clean is wrapped inside the one Core package that uses it, never exposed across it.
- Nothing is shared with the Android codebase. A domain rule fixed on one side is fixed on the
  other by hand, which is acceptable while one of them is the owner's daily driver and the other is
  being built.
- The snapshot format (ADR 009) is the one contract the two apps could share; whether the iOS
  restore reads snapshots the Android app wrote is a separate decision.

## Alternatives considered

| Option | Why rejected |
|---|---|
| **The Composable Architecture (TCA)** | A reducer, actions and effects for every screen: the MVI ceremony this rebuild is leaving behind, plus a large third-party dependency whose major versions reshape every feature. Observation gives the same testability with plain methods and properties. |
| **SwiftData** | Schema migration through `VersionedSchema` and migration plans is less explicit than named SQL migrations, raw SQL for the composite foreign key (ADR 008) and the restore sweep is awkward, and model objects are bound to a context and an actor in ways that leak into the domain. GRDB keeps the database a plain SQLite file with SQL the owner can read. |
| **Tuist** | Swift manifests and module graphs are appealing, but Tuist is a larger tool with its own release cadence and cloud features this project does not use; XcodeGen solves the only problem at hand, a generated project file (ADR 019). |
| **Kotlin Multiplatform, sharing the domain** | The predecessor already dropped its KMP build and iOS target once. Sharing Kotlin means Kotlin idioms at the Swift boundary, a second toolchain in every build, and a domain that cannot use Swift's type system. The domain is small enough to rewrite. |
| **Port the MVI shape** (a `MviModel<State, Intent, Effect>` base, intent enums, an effect stream) | It exists to funnel Compose events and survive a ViewModel's lifecycle. On Observation it adds a translation layer between the view and the model with nothing to translate, and an effect stream reintroduces the replay-versus-drop problem that state plus `.onChange` does not have. |
