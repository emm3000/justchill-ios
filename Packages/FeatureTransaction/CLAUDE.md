# FeatureTransaction

The amount pad (ADR 017): the app's launch screen and the `NavigationStack`'s root. It types an Amount, saves a Transaction through `CreateTransactionUseCase` and shows the Month's Spend from `GetMonthSpendUseCase`. The Month screen, pushed from the pad, lists the Month's Transactions grouped by day under its totals.

## Build and test

- iOS only, so tests run on a simulator: `xcodebuild test -scheme FeatureTransaction -destination id=<udid>` from this directory, or `scripts/gate`, which runs `FeatureTransactionTests` because `project.yml` lists it.
- Tests build the model over `CoreTesting`'s fakes with `FixedClock` and `America/Lima`. They wait through `Observations` on model state, never by sampling, and the suite carries a one-minute `timeLimit` so a missed transition fails instead of hanging.

## Layout

- `AmountPadModel`: the typed `AmountEntry`, the Transaction type, the live Accounts and the Month's Spend. `observe()` follows both sequences and runs in the screen's `.task`.
- `AmountPadScreen` owns the model and maps each `KeypadKey` to a model action, so the model never imports CoreUI. `AmountPadContent` is the pure view; `Components/` holds its header and chips.
- Factory: `AppContainer.makeAmountPadModel()`. The pad is the stack's root, outside the path; tapping its month total or swiping up calls `onOpenMonth`, which `RootView` answers by appending `Route.month`.
- `MonthModel`: the Month and today, derived from the injected `Clock` and `TimeZone` when the factory runs, so each push reads the current Month. `observe()` follows `transactions(in:)` into a `MonthPresentation`: Spend and Income totals, and the days newest first with rows by `occurredAt` descending, ties by `TransactionID`.
- `MonthScreen` owns the model; `MonthContent` is the pure view; `Components/MonthTotalsHeader` and `Components/MonthDaySection` draw its parts. Factory: `AppContainer.makeMonthModel()`, route `Route.month`.

## Gotchas

- Defaults are static until the frequent-combo ranking lands (ADR 020 Decision 1): Spend, the oldest live Account (the repository orders by creation), no Category, now. The chips only show them and are disabled; `±` is the one override.
- A digit that would overflow `Int64` cents, a third decimal and a second separator are ignored.
- A save cancelled mid-write surfaces as `DomainError.storageFailure` from GRDB; the model drops it when the task is cancelled, keeps the typed Amount and shows no alert.
- A second save while one is writing is ignored, so a double tap records one movement.
- `transactions(in:)` has no ORDER BY, so `MonthPresentation` sorts and groups in memory.
- Neto goes through CoreUI's `MoneyText(netOf:minus:)`; never pick its sign or tint at the call site.
- SwiftUI declares its own `Transaction`: write `CoreDomain.Transaction` in any file that imports SwiftUI.
- The saved amount leaves through `Motion.signatureTransition`, keyed on `savedTransactionID`; Reduce Motion turns it into a cross-fade.
