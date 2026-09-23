Ported from the Android repo on 2026-09-22; the decision stands for iOS.

# ADR 010 — Loans are a parallel ledger

- **Status**: Accepted
- **Date**: 2026-08-21
- **Deciders**: Edgardo Muñoz
- **Amends and supersedes**: nothing. No W- row moves and none is added — `PRODUCT_REQUIREMENTS.md`
  §1 has never carried a row about lending. The Won't-have table runs W-01, W-04–W-10 and W-12, plus
  the opt-in W-02/W-03/W-11; none mentions loans. Unaddressed scope, not rejected scope.

> Summary: a loan is a **parallel ledger**. Lending S/500 creates no Spend and a payment (abono)
> creates no Income: `loans` and `loan_payments` touch neither `transactions`, nor an account's
> figures, nor the month report. The real alternative — modelling it as a Spend/Income pair joined
> by an id — keeps the figures current with no effort, and is rejected because **a repayment is not
> income**: it is the return of capital. Putting it in the report inflates both sides — the month of
> the loan looks like a spending spike and the month of the repayment like a windfall — and worse
> the bigger the loan. The accepted cost, stated plainly: the app's figures do not reflect money lent
> out until the user records the movement by hand. Interest is **flat and frozen at creation**, not
> accrued.

## Context

The owner lends money informally and repeatedly, and repayments arrive piecemeal, in cash or by
transfer. Those balances lived in their head or on paper; the feature holds them instead.

The app has exactly one ledger: `transactions`. Every row carries a `type` that signs its `amount`,
and the aggregates read that sign — the per-account month net, the month totals and the month
report. A loan is the only money the app would ever hold that is neither earned nor spent: it left
the account and is expected back. This ADR decides whether it enters that ledger, and what it
carries once it does not.

## Decision

1. **A loan is a parallel ledger.** It never posts to `transactions`, never moves an account figure,
   and never appears in the month report. Lending creates no `Spend`; a payment creates no `Income`.
   `loans` and `loan_payments` are read by the loans screens and by nothing else — no home total's
   query and no report query references either table. The user records the real cash movement as an
   ordinary transaction if and when they choose; the app neither prompts for it nor links the two.
2. **Interest is flat and frozen at creation.** `totalDue = principal +
   roundHalfUp(principal * interestBps / 10_000)`, computed once by the domain's loan math and
   stored. It does not accrue with time and no instalment schedule is generated. These are informal
   loans between two people who agreed on one number; an accruing rate is a different product, and
   the predecessor feature deleted in commit `d1d9446a` — `interest`, `duration`, a stored `status`
   and a daily instalment generator that skipped Sundays — is the evidence of what that one becomes.
3. **That rounding is HALF-UP, and deliberately not the display rounding.** CoreUI's Spanish number
   formatter rounds HALF-EVEN because it imitates the es-PE locale's formatting for display; the
   loan math rounds HALF-UP because it computes an amount that gets stored and that a person will
   be asked to pay. A display formatter and money math are different jobs — do not unify them.

## Acceptance criterion — `PRODUCT_REQUIREMENTS.md` §3

- **Not in §1** — verified against the table itself, row by row; see the header block above.
- **Saves time or gives clarity** — it replaces a per-person balance kept in the owner's head.
- **Does not slow down recording a movement** — loans are a separate surface and add zero taps to
  the capture flow. This is the criterion Decision 1 most directly protects: wiring a loan into
  `transactions` would have put a loan concept inside the movement form.
- **Discoverable, no onboarding or tutorial** — the menu is the entry point, and no contacts CRUD
  stands between the user and their first loan: the person is a `personKey` column.
- **Asks for no data the app does not need** — a typed name, an amount, a date. No contacts
  permission, no phone numbers, and nothing leaves the device beyond the snapshot already opted into
  under [ADR 009](009-backup-is-a-snapshot-not-row-replication.md).

## Alternatives considered

| Option | Why rejected |
|---|---|
| **Model the loan as a `Spend` and each payment as an `Income`, linked by a loan id** | The real alternative, and it keeps the account figures truthful with no user effort. Rejected because **a repayment is not income** — it is the return of capital. Folding it into the month report inflates both sides: the month of the loan reads as a spending spike, the month of the repayment as a windfall, and the report stops answering the question it exists to answer ("what did I earn and what did I spend"). The distortion is worst exactly when the loan is largest. |
| **Post to the figures, exclude from the report** | The middle option: real `transactions` rows, filtered out of the report by a marker column or a reserved category. It buys truthful figures, but the exclusion is a rule every present and future aggregate has to remember, and the row still carries a `type` that misdescribes it. ADR 008's cost table is the precedent for how many writers such a convention has to survive. |
| **A "Préstamos" category pair instead of new tables** | Cheapest by far, and ADR 008 already forces two categories (one Income, one Spend) for exactly this name. A category is a label, not a ledger: it carries no counterparty, no principal/total split and no remaining balance — which is the whole feature — and the amounts land in the report anyway. |
| **Accruing interest with a generated instalment schedule** | What `d1d9446a` deleted. It turns an agreement between two people into a loan product: a due-date calendar, late rules, and a schedule that has to be kept in sync with piecemeal repayments that ignore it. |

## Consequences

### Positive

- The month report keeps answering its own question. Lending and being repaid do not move it.
- Nothing in the movement form changes, so §2's `<15s` registration budget is untouched.
- Both tables are additive and read by one screen set, so nothing can depend on them by accident.

### Negative / costs

- **The account figures do not reflect money that is out on loan**, until and unless the user
  records the movement themselves. A truthful report is chosen over an automatic figure, knowingly.
- **The report is truthful about earning and spending, not about cash.** If the user does record
  the cash movement as an ordinary transaction, the distortion above returns — nothing links the two
  entries and nothing detects the pair. That is the price of leaving the call to the user.
- **Interest earned never reaches the month report either, and interest genuinely is income.**
  Decision 1 treats every payment as return of capital, which is exactly wrong for the interest
  slice of it. Splitting a payment into principal and interest needs an amortization convention —
  the accruing product Decision 2 refuses. Accepted as understatement, not claimed as correctness.
- Nothing reconciles a loan against the account it came from: no check that a recorded payment
  corresponds to money that actually arrived.

## Notes

- The invariants every loan ticket inherits — settled-ness derived, never stored; `totalDue` written
  on every write path; cascade soft-delete of payments; `personKey`; the loans in the backup
  payload — belong in `CoreDomain`'s loan types and their tests.
- Decision 3 is money math; the display side is CoreUI's number formatter and its golden test.
