---
paths:
  - "App/**/*.swift"
  - "Packages/**/*.swift"
---

# Swift style rules

Readability is the goal these rules serve. When a rule and readability disagree, say so instead of silently picking one.

## Explicit types

Declare the type on every stored property and every local `let` / `var`.

| Case | Write |
|---|---|
| Local value | `let remaining: Amount = balance.remaining` |
| Stored property | `private(set) var accounts: [Account] = []` |
| Function return | `func loadAccount() -> Account` — always declared |
| Abstraction matters | `private let loans: any LoanRepository` — the protocol, not `GRDBLoanRepository` |

Declare the **protocol** whenever the caller should depend on the abstraction rather than the concrete implementation.

Omit the explicit type only when it would be pure noise:

- The right-hand side is a constructor call that already names the type: `let insert = TransactionInsert(...)`. Writing it anyway is fine; the existing code often does.
- Property wrappers where the annotation fights the wrapper: `@Environment(\.dismiss) private var dismiss` is fine.
- Closure parameters whose type is fixed by the call and obvious in context.

Function parameters always carry their type — Swift requires it.

## Comments

**Write none.** No `///`, no `//`, no `/* */`, no `// MARK:`, no commented-out code.

The code is the explanation. If a line needs a comment to be understood, the fix is a better name or an extracted function with a name that says it — see `naming.md`. A test's display name is its documentation.

Three exceptions survive, and only these. Each is one to three lines of present-tense fact; a surviving comment names a constraint the code cannot show.

1. **Why a non-obvious constraint exists.** The code can show *what* the value is, never *why* it was chosen: the exclusive `>` on the backup staleness threshold, `ñ` folding to `n` in the person key. Without it, someone "fixes" the value back.
2. **A warning of consequences.** A workaround, an ordering requirement, a known platform bug, an `@unchecked Sendable` and what keeps it safe, an invariant no test pins.
3. **An external reference.** An ADR, a spec, a migration note the code cannot carry.

A constraint lives once, at the declaration it constrains, never at a call site or on a consuming type. A comment describing behaviour enforced elsewhere is a copy, and copies diverge. Zero history: a sentence about what the code used to be or what a review said is deleted, not rephrased.

Never acceptable: restating what the code does, `// MARK:` headers, `// maps the state`, dead code left commented, or a `TODO` committed without an owner and a reason. A file already in the diff gets its non-surviving comments stripped in the same commit; no repo-wide sweep.

When you delete code, delete it. Git has the history.

## Swift idioms

- Prefer `let`. Reach for `var` only when mutation is the point.
- **Value types first.** Entities, value objects, payloads and presentation values are `struct` or `enum`. A `final class` is for identity and shared mutable state: a screen model, `AppContainer`, a repository holding a database handle. No subclassing outside what a framework demands.
- **Mutually exclusive states are an `enum` with associated values**, not a set of optionals and flags. `switch` over it exhaustively; `default:` on a domain enum hides the next case.
- **`guard` for early exit**, with the happy path left-aligned. `guard let` unwraps; nested `if let` pyramids get flattened.
- **No force unwrap, `try!` or `as!` outside tests**, and in tests prefer `try #require(...)`. An implicitly unwrapped optional is never a stored property.
- **Access control is the API.** `public` only what crosses a package; `private` by default inside a type; `private(set)` for model state.
- **Conformances in extensions** when they carry more than a line; one conformance per extension.
- **Typed throws** in `CoreDomain` (`throws(DomainError)`); a throwing `init` rejects invalid construction — see `principles.md`, fail fast.
- A signature that fits in 120 columns sits on one line; a hand-wrapped short signature is a review comment.

## Concurrency

Swift 6 language mode, strict concurrency complete, approachable concurrency on (`project.yml` and each `Package.swift` set it).

- **Default isolation is `MainActor`** in `App/`, `CoreUI` and every `Feature*` package. Models, views and the container need no annotation.
- **`CoreDomain` defaults to `nonisolated`.** Its values are `Sendable` structs and enums; a domain type is never `@MainActor`.
- **`@concurrent` only for deliberate background work** (decoding a snapshot, hashing a file), and never in a model. `nonisolated(nonsending)` is the default for `async` functions, so an `async` call stays on the caller's actor unless it says otherwise.
- **No `Task.detached`, no `DispatchQueue`, no `DispatchGroup`, no Combine.** Structured concurrency only: `async let`, task groups, `.task` in views.
- **`@unchecked Sendable` and `nonisolated(unsafe)`** carry the comment exception naming what makes them safe, or they do not ship.
- **Cancellation is not failure.** A catch-all catches `is CancellationError` first and returns (`architecture.md`, errors).

## Complexity limits

No linter runs in this repo, and none is coming (ADR 016). These limits are review-enforced:

- At most 4 levels of nesting. A `guard` or an extracted function flattens the rest.
- At most 2 real returns per function; a `return` inside a closure is not one, a `guard ... else { return }` is. More than two means the function should be split.
- At most 8 functions per file — the limit the repo leans on for view decomposition.
- Cyclomatic complexity around 14 per function, and 60 lines is a long function in production and in a test alike. A view's `body` and a `#Preview` are exempt from the length number — see view sizing below, where decomposition is the measure instead.

`scripts/gate` must be green before every commit, but it compiles and tests; it never judges style. Passing it is necessary, never sufficient: a reviewer may require a change no number here forbids.

### View sizing

Length is a weak signal in SwiftUI: a flat 200-line layout reads fine, a 60-line one with local state and nested conditionals does not. The repo measures **decomposition, not length**: one file carrying the model wiring, the layout *and* N subviews fails review. Both routes count equally, a `Components/` folder in the feature or sibling files beside the screen.

A parameter carrying a default does not count toward coupling: the number that matters is what every caller must supply. The default does not launder a real overage; the length and decomposition limits own what a view builds out of what it receives.

### Check before committing

1. More than 4 levels of nesting? Extract a function or a subview.
2. A chain of `else if`? Use `switch`, or extract functions.
3. A function doing several things? Split it — see `principles.md`, SLAP.
4. A nested `if let` pyramid? `guard` it flat.
