---
paths:
  - "App/**/*.swift"
  - "Packages/**/*.swift"
  - "Packages/*/Package.swift"
  - "project.yml"
---

# Architecture rules

Clean Architecture across the package layout in `CLAUDE.md`. SwiftPM enforces the package direction; these rules explain it and cover what SwiftPM cannot see.

## Layers and dependency direction

| Layer | Contains |
|---|---|
| `CoreDomain` | Pure Swift, Foundation only. Entities, value objects, use cases, and the **protocols** the outer layers implement. `DomainError` is its one failure type. |
| `CoreDatabase` | Implementations of the domain protocols over GRDB.swift: the `DatabaseMigrator`, records, the repositories, the snapshot store over the six tables. |
| `CoreBackup` | The snapshot file and its account: format versions, decoder, Supabase Storage, the backup cycle, auth. |
| `CoreUI` | The design system (tokens in `Theme/`, atoms in `Atoms/`), the Spanish money, date and search formatters, the Spanish copy for `DomainError`, the shared sheets and pickers, and route payloads more than one feature references. |
| `CoreTesting` | Fixtures and fakes on `CoreDomain` alone, a dependency of feature test targets only. |
| `Feature*` | One screen family: its `@Observable` models, its screens and `Content` views, its route payloads. |
| `App/` | `JustChillApp`, `AppContainer` (the composition root), `RootView` and `Route`, the platform ports that need `UIApplication` (Home Screen quick actions, scene phase). |

Allowed dependencies, and nothing else:

```
App           -> Feature*, CoreBackup, CoreDatabase, CoreUI, CoreDomain
Feature*      -> CoreUI, CoreDomain (+ CoreTesting on the test target)
CoreBackup    -> CoreDomain
CoreDatabase  -> CoreDomain
CoreUI        -> CoreDomain
CoreTesting   -> CoreDomain
```

A target imports only the packages its `Package.swift` declares, with `MemberImportVisibility` on, so an edge outside this graph fails to compile once someone would have to add it to a manifest. That manifest line is the review point: a feature's `Package.swift` naming another feature, `CoreDatabase` or `CoreBackup` is a blocking finding however small the diff.

- `CoreDomain` is pure Swift with default `nonisolated` isolation: Foundation only. No SwiftUI, UIKit, Observation, GRDB or Supabase. It also builds for macOS, so a UIKit import fails `swift test --package-path Packages/CoreDomain`; the rest is review. The check is `rg -n '^\s*import ' Packages/CoreDomain/Sources | rg -v 'import Foundation$'`, and it returns nothing.
- Whatever asks "what day is it" takes an injected `Clock` **and** an injected `TimeZone`, and neither parameter carries a default: a default never blocks an explicit argument, so a test passing a fake clock also passes against the ambient one. `Clock` is the domain's port that answers "now"; it is not the standard library's `Clock` protocol, which measures durations. `AppContainer` is the only place a clock or a zone enters the graph. The check is `rg -n 'Date\(\)|Date\.now|TimeZone\.current|Calendar\.current' App Packages --glob '!**/Tests/**' --glob '!App/Composition/**'`, and it returns nothing.
- `App/` depends on `CoreDatabase` and `CoreBackup` for one reason: `AppContainer` binds protocol to implementation in one place. The snapshot store is handed to `CoreBackup` there too, which is what keeps `CoreBackup` off `CoreDatabase`. A model takes `CoreDomain` protocols, never a GRDB type or a `GRDB*` implementation.
- GRDB on device is the source of truth for reads and writes. Supabase holds snapshot backups (ADR 009); nothing reads rows from it. A snapshot crosses the two packages as domain values, never as a GRDB record or a wire type.

## Dependency inversion is the seam

The domain declares the contract; the infrastructure obeys it. The domain never imports an implementation.

- Repository protocols (`{Entity}Repository`) live in `CoreDomain`. Implementations (`GRDB{Entity}Repository`) live in `CoreDatabase`.
- A platform capability a feature needs (Sign in with Google, a file exporter) is a protocol in that feature or in `CoreDomain`, implemented in `App/` and handed in by `AppContainer`.

## A use case only where there is domain logic

A pure read goes from the model straight to the repository protocol. A use case whose whole body is one `repository.x(...)` call on a read is a rename, not a layer. Writes earn one far more often, because a write is where the invariants are.

Loan writes always go through `CreateLoanUseCase` / `UpdateLoanUseCase`: `LoanRepository.create` / `update` accept a fully built `Loan`, so nothing compiles against the rule. A model calling them fails review, however well-formed the `Loan` looks.

## Errors

`DomainError` (`Packages/CoreDomain/Sources/CoreDomain/DomainError.swift`) is the one failure type, thrown with typed throws (`throws(DomainError)`) wherever the domain throws. `CoreDatabase` translates GRDB's errors into it at the repository boundary; `CoreUI` renders the Spanish message. Add a failure mode by adding a case, never with a new error type.

Every catch-all owes a cancellation arm first. A bare `catch` inside a `.task` swallows `CancellationError`, the body runs on, and a cancelled loader overwrites the winner. Catch `is CancellationError` first and return, then handle the rest.

## Each layer owns its own model

A GRDB record, a domain entity and the state a model exposes are three different things even when their fields match. Conversions live in the outer package as initializers on the target type (`LoanRecord(loan)` and `Loan(record)` in `CoreDatabase`, `<Thing>Presentation(entity)` beside the model that needs it).

- A GRDB record never reaches a model.
- A domain entity never carries presentation concerns (formatted strings, `Color`, SF Symbol names).
- A presentation value carries a semantic id (`iconID`, `colorID`), never an `Image` or a `Color`; the view resolves it against CoreUI's catalog.

This is not duplication to be removed. See `principles.md`, DRY.

## The model contract

Naming lives in `naming.md`. This is the flow.

- **One model per screen.** `@Observable final class <Screen>Model` in its feature package, default `MainActor` isolation. State is stored properties, `private(set)` so only the model writes them. User actions are methods named for what the user did (`save()`, `confirm(period:)`), never for UI mechanics (`saveButtonTapped()`).
- **One-shot outcomes are state the view reacts to.** A failure is `private(set) var failure: DomainError?`, shown with `.alert` and cleared by a `dismissFailure()` method; a finished save is a stored value the view watches with `.onChange` and answers by calling the navigation closure its host gave it. A model never holds a navigation closure and never emits into a stream the view has to drain.
- **State stores what the user chose, never what was resolved.** A selection is an id; the resolved object is a computed property over the catalog held in the same model. A stored resolved object is a cache with no invalidation, and it is how a movement gets filed under a deleted category. A save writes the resolved selection, never the raw id.
- **A visibility flag lives in the model, never in `@State` or `@SceneStorage`** (ADR 012). One sheet property per screen: an `Identifiable` enum when sheets are mutually exclusive, driving `.sheet(item:)`; a `Bool` when there is one.
- **A model never switches executor.** No `Task.detached`, no `@concurrent`, no `DispatchQueue` in a model; `CoreDatabase` owns its threading and exposes `async` APIs.
- **Long-lived observation runs in the view's `.task`.** A model exposes `func observe() async` that iterates a repository's `AsyncSequence`; the screen starts it in `.task`, which cancels it when the screen leaves. A model never starts an unstructured `Task` it does not cancel.
- **Models never hold literal UI copy.** A model exposes an enum or another typed value (`AuthNotice.confirmationLinkResent`), never a Spanish string; the view resolves it to text.
- **Container and presentational.** `<Screen>` owns the model (`@State private var model: <Screen>Model`, handed in by `AppContainer`'s factory), starts its work in `.task`, and passes values and closures to `<Screen>Content`. `<Screen>Content` is a pure view: no model, no repository, no use case, no `@State` that outlives a gesture. Previews and tests build `Content` directly.
- **Local UI state with no business meaning** (a pressed highlight, a focus ring) may stay as `@State` or `@FocusState` inside a view.

## A model is SwiftUI-free

`scripts/check-swiftui-free-models` is on the gate: it fails any `Packages/Feature*/Sources/**/*Model.swift` carrying an `import SwiftUI` line.

What the script cannot see, and review does, over the same files:

```
rg -n -e '^\s*import (UIKit|CoreUI)' -e 'LocalizedStringKey|Color\(|Image\(|#Preview' -g '*Model.swift' Packages/Feature*/Sources
```

A model imports `Foundation`, `Observation` and `CoreDomain`. Fakes never leak into `Sources/` either; they live in `CoreTesting` or a test target.

## The composition root

- `AppContainer` (`App/Composition/AppContainer.swift`) holds each shared instance once (the database, the repositories, the clock, the zone, the backup cycle) and exposes one `make<Screen>Model(...)` factory per screen. A factory is the single place that screen's dependencies are chosen; a new model means a new factory, never a model reaching for a global.
- Only `App/` names an implementation type. The leak check is `rg -l 'GRDB[A-Z][A-Za-z]*Repository|SupabaseClient' App Packages/Feature* Packages/CoreUI --glob '!App/Composition/**'`, and it returns nothing.
- No service locator, no property-wrapper injection, no singletons with `static let shared`. SwiftUI's `@Environment` carries system values and CoreUI tokens only, never a repository.

## Routes and the navigation stack

`Route` (`App/Root/Route.swift`) is a `Hashable` enum. Each case names one destination and wraps the payload it needs: a feature's route struct (`<Screen>Route`) or a CoreUI payload several features share. `RootView` owns `@State private var path: [Route]` and exactly one `.navigationDestination(for: Route.self)`, whose `switch` is exhaustive and builds each screen from `AppContainer`'s factory.

- **The compiler is the net.** The path is `[Route]`, never `NavigationPath`: a type-erased path accepts any `Hashable` and pushes a blank screen when no destination is registered for it, silently. A typed path rejects a foreign value, and the exhaustive `switch` rejects an unhandled case. A feature never registers its own `.navigationDestination`.
- **The path dies with the process** (ADR 012), so `Route` is not `Codable` and nothing restores it.
- **Navigation out of a screen arrives as a closure its host supplies** (`onOpenLoan: (LoanID) -> Void`), never as a `Route` value or the path itself: features never import `App/`.
- **One door is no door.** A destination reachable through exactly one entry point is unreachable the moment that entry is gated. Gate the content of an entry point, never its existence. Before deleting a view that pushes a route, `rg` the case and confirm a second door exists.
- **Moving to a route that may already be on the stack truncates to it** (`path.removeLast(path.count - 1 - index)`), never appends a duplicate. A second copy buried under the first is how back stops meaning back.
- **The amount pad is the stack's root** (ADR 017): it is the `NavigationStack`'s root view, outside the path, so back always walks down to the pad and exits from there. Nothing replaces the root but onboarding on first launch. `RootView` never calls `removeLast()` on an empty path; a screen that must not pop into nothing clears its own state instead.

## When a new dependency crosses a layer

Before adding a dependency to any `Package.swift`, check the direction above. If the change needs `CoreDomain` to reach outward, the design is wrong: invert it with a protocol in `CoreDomain`.
