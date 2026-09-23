Ported from the Android repo on 2026-09-22; the decision stands for iOS.

# ADR 012 — Typed form input dies with the process

- **Status**: Accepted
- **Date**: 2026-08-27
- **Deciders**: Edgardo Muñoz
- **Amends and supersedes**: nothing. No W- row moves and none is added — `PRODUCT_REQUIREMENTS.md`
  §1 has never carried a row about state restoration. §2's **Persistence** row ("a crash or a force
  quit loses no data") stands untouched: it is about the ledger in the database, and text still
  being typed into a form has not reached it and is not data yet.

> Summary: what you type into a form and do not save is lost if the system terminates the app. No
> state restoration is adopted. That alternative costs **permanently** duplicating every typed field
> — once in the screen model and again in a restorable store, and every new field has to be
> remembered into the mirror, forever — in exchange for rescuing a few seconds of typing. The only
> irreversible loss in this app is saved data, and that lives in the database, not in a text field.
> What is fixed instead: a sheet must never outlive, or die before, the fields it contains, so its
> visibility flag lives in the same model as those fields.

## Context

1. **Nothing restores screen state.** No `@SceneStorage`, no state restoration of the navigation
   path, no restorable store. This ADR decides whether that stays true.
2. **The exposure is the forms.** In the predecessor app it was six forms holding seven typed
   fields: `amount`, `description`, `personName`, `amountDigits`, `interestPercentText`, `note` and
   `name` — capture, edit, loan, recurring, category and account.
3. **The forms are short and there is one user.** No third-party users, and the owner runs the app
   daily on real data. A lost form is retyped in seconds; the failure this app cannot afford is
   losing a committed row, and that is the database's obligation, not the form's.
4. **A sheet flag held apart from its fields drifts from them.** The predecessor held sheet
   visibility in a holder the system restored after process death while the fields inside lived in
   a holder it did not, so a restored screen showed a restored sheet over empty fields — the app was
   inconsistent with itself, in the direction this ADR rejects.

## Decision

1. **Typed form input dies with the process, and nothing restores it.** The rule a future writer
   applies without re-reading this page: a text field's value belongs in the screen's
   `@Observable` model and nowhere else. It survives as long as the screen does; it is gone after the
   system terminates the app, and that is the accepted behaviour, not a bug to file.
2. **A sheet, a dialog, or any visibility flag the UI keeps rendering lives in the model too.** The
   model is the only holder whose lifetime matches the fields the sheet contains, and `Content`
   views are pure, so they cannot own it anyway.
3. **`@State` in a subview and `@SceneStorage` are both wrong for such a flag, for opposite
   reasons.**

   | Holder | Survives the view being rebuilt with a new identity | Survives the app being terminated |
   |---|---|---|
   | `@State` in a subview | no — a changed branch or `.id` resets it | no |
   | `@SceneStorage` | yes | yes |
   | the screen's model | yes | no |
   | *the typed fields, for reference* | yes | no |

   `@SceneStorage` **over-survives**: the sheet outlives the fields inside it. `@State` in a subview
   **under-survives**: the sheet closes on an identity change while those fields are still there.
   Only the model matches the fields in both columns. Moving a flag from one wrong holder to the
   other is not the alignment — it trades one mismatch for the other.
4. **Two deliberate exclusions in the auth screen, and both stay.** The password is never mirrored
   into anything that outlives the model — a credential in restorable storage is a credential the
   system writes to disk. And the password-visible toggle stays a plain view `@State`, not model
   state: re-masking the password whenever the view is rebuilt is the wanted behaviour. It is the
   one flag whose correct lifetime is deliberately shorter than the field it describes.

## Alternatives considered

| Option | Why rejected |
|---|---|
| **Adopt state restoration across the forms** | The real alternative, and the platform's own answer. Rejected on cost: each typed field would live twice — once in the model, once in the restorable store — permanently, and every field added later has to be remembered into the mirror, with nothing mechanical catching the omission. What that buys is a few seconds of retyping, for one user, on a screen he can reopen. |
| **Keep sheet flags in view `@State`** | The obvious-looking place, and it is wrong — see Decision 3. It replaces "the sheet outlives its fields" with "the sheet dies while its fields live", and it breaks the pure `Content` view. |
| **Persist form drafts to the database** | Turns an unsaved form into stored data, which nobody asked for: a half-typed movement then needs a lifecycle, a discard path, and a place in the ADR 009 snapshot. |

## Consequences

### Positive

- One holder per piece of screen state. No mirror to keep in sync, and every visibility flag is
  assertable on the model in a plain test.
- Context 4's mismatch cannot arise.

### Negative / costs

- **A backgrounded form loses what was typed into it, silently.** Under memory pressure the system
  terminates the app and the user returns to an empty form with nothing explaining why. Accepted,
  not mitigated.
- **The rule is a convention, not a mechanism.** Nothing rejects a `@SceneStorage` added to a view
  tomorrow; review does.
- Wanting restored forms later means adopting state restoration after all, across every form.

## Notes

- Sheet-internal draft state (the amount pad sheet's digits and its kin) is a sheet's own scratch
  space, not screen state, and this ADR does not decide it.
