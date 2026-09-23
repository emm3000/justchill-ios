---
paths:
  - "App/**/*.swift"
  - "Packages/**/*.swift"
---

# Naming rules

Three combined sources: Uncle Bob (Clean Code), the Swift API Design Guidelines, and professional iOS practice. On conflict, that is the priority order.

## Language

- **English for every identifier**, including test fixtures. Spanish appears only in user-data VALUES: `name: "Sueldo"` is data; `let sueldo` is a violation. Name fixture locals by role (`incomeCategory`, `cashAccount`).
- User-facing Spanish addresses the reader as **tú, never vos**. A voseo string is a defect even when it reads well, and a test can pin the wrong one: grep the expectation, not just the source.

## Uncle Bob, applied to Swift

| Rule | Bad | Good |
|---|---|---|
| Name reveals intent | `d`, `data`, `tmp` | `accountID`, `filteredTransactions`, `elapsed` |
| No disinformation | `transactionList` (it's an `Array`) | `transactions` |
| Meaningful distinction | `getLoan` vs `fetchLoan` vs `retrieveLoan` | one verb per concept |
| Pronounceable | `genDtTmStmp` | `generatedAt` |
| Searchable (no magic literals) | `if days > 3` | `if days > Backup.staleAfterDays` |
| Types: nouns | `DataProcessor`, `Manager` | `LoanRepository`, `AuthModel` |
| Functions: verbs | `loan()`, `data()` | `loadLoan()`, `makeState()` |
| One word per concept | `fetch` in one place, `get` in another | pick one and use it across the codebase |
| No humor or jargon | `whack()`, `eatMyShorts()` | `delete()`, `clear()` |

A name that needs a comment to be understood is the wrong name. Rename it instead of explaining it — see `swift-style.md`, comments.

## Swift API Design Guidelines

- **Clarity at the point of use** beats brevity. Read the call site, not the declaration: `remove(at: index)`, `confirm(period:)`.
- **Types and protocols**: `UpperCamelCase`. Everything else, constants included, is `lowerCamelCase`: `static let resendCooldown`, never `RESEND_COOLDOWN`.
- **Acronyms** are uniformly upper- or lower-cased: `LoanID`, `loanID`, `urlString`, never `LoanId`.
- **Omit needless words**: `remove(_ member:)`, not `removeMember(_ member:)`. **Compensate for weak type information** with a label: `add(_ observer: Observer, for keyPath: String)`.
- **First argument label**: omit it when the argument completes a grammatical phrase with the base name (`addSubview(_:)`); label it when it does not (`move(from:to:)`).
- **Side effects read as verbs, results as nouns**: `sort()` mutates, `sorted()` returns. Mutating / non-mutating pairs use `-ed` / `-ing` or `form-`.
- **Protocols** that describe what something is are nouns (`LoanRepository`); capabilities end in `-able`, `-ible` or `-ing` (`Identifiable`).
- **Factory methods** begin with `make`: `makeLoanDetailModel(loanID:)`.
- **Booleans** read as assertions: `isLoading`, `hasLoans`, `canResend`.
- **Conversions** are initializers on the target type (`Loan(record)`), not `toDomain()` methods.
- Prefer `let` over `var`; prefer an extension on the type over a free function or a caseless utility enum.

## Patterns by layer

| Type | Pattern | Examples |
|---|---|---|
| Domain entity | `{Entity}`, no suffix, in `CoreDomain/<Entity>/` | `Loan`, `Transaction` |
| Insert / update payload | `{Entity}Insert`, `{Entity}Update` | `TransactionInsert`, `LoanUpdate` |
| Identifier | struct `{Entity}ID` wrapping the raw value | `AccountID`, `LoanID` |
| Use case | `<Verb><Subject>UseCase`, `callAsFunction` | `CreateLoanUseCase`, `GetSavingsRateUseCase` |
| Repository (protocol) | `{Entity}Repository` in `CoreDomain` | `LoanRepository` |
| Repository (impl) | `GRDB{Entity}Repository` in `CoreDatabase` | `GRDBLoanRepository` |
| GRDB record | `{Entity}Record` | `LoanRecord` |
| Migration | `v<N>-<what-it-does>`, registered in order | `v2-add-loan-note` |
| Screen model | `<Screen>Model`, `@Observable final class` | `AuthModel`, `LoanDetailModel` |
| Screen | `<Screen>` owning the model; `<Screen>Content` the pure view | `AuthScreen`, `AuthContent` |
| Route payload | `<Screen>Route`; the root case is the screen in `lowerCamelCase` | `LoanDetailRoute`, `Route.loanDetail(_)` |
| Factory | `make<Screen>Model` on `AppContainer` | `makeAuthModel()` |
| Presentation value | `<Thing>Presentation`, built by an initializer from the entity | `TransactionPresentation` |
| Atom | role name, file matches, under `CoreUI/Atoms/` | `PrimaryButton`, `Pill` |
| Exposed async sequence | name without a `Stream` or `Sequence` suffix | `accounts`, not `accountsStream` |
| Callbacks in a view | `on` prefix | `onBack`, `onDismiss`, `onOpenLoan` |
| Async function | named as if it were synchronous | `fetch(id:)`, not `fetchAsync(id:)` |
| Test | `@Test("sentence naming the rule")` on a short `lowerCamelCase` function | `@Test("refuses while live dependents exist")` |

## Additional rules

- A model method describes **what the user did or asked for**, not what the model does inside: `delete()`, not `triggerDeletion()`.
- A one-shot outcome property describes **the resulting state**, not the action: `savedTransactionID`, not `shouldNavigate`.
- A private model method takes the `handle` prefix only when it groups several sub-cases. If it does one thing, name it directly: `loadLoan()`, not `handleLoadLoan()`.
- Avoid redundant prefixes inside a scope: inside `LoanDetailModel`, `loadLoan()`, not `loadLoanDetail()`.
- A test expectation is pinned to the rule, not to the current output.
