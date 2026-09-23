# PRODUCT REQUIREMENTS — scope limits and non-functional criteria

This doc does not describe what is built: the code does that. What is left are the two things the
code cannot show — **what is out of scope** and **which criteria judge what gets in**.

**The row ids in §1 are immutable**: ADRs amend this doc by citing them (ADR 001 → W-02 / W-03 /
W-11; ADR 009 → W-04, W-08). Renumbering breaks those references.

---

## 1. Won't have — explicitly out of scope

These are not built. If one moves into scope, the positioning is renegotiated first and the
decision is signed in an ADR.

| ID | Not built | Reason |
|---|---|---|
| W-01 | **Bank connection / bank sync** | The app is manual capture; bank sync drags in permissions, credentials and support that a one-person side project cannot sustain. |
| W-04 | **Shared multi-user ledgers (couples, teams)** | The product is individual. ADR 009 rests on this row: with no two concurrent writers, row-by-row replication does not pay. |
| W-05 | **Rigid budgets ("don't spend more than X")** | The app observes; it does not police. |
| W-06 | **Multiple currencies** | Soles only. |
| W-07 | **Financial education courses or lessons** | It is not a content app. |
| W-08 | **Daily push notifications / gamification / badges** | Anti-complexity. ADR 009 rests on this row: no feature needs a server that reads the rows. |
| W-09 | **Premium subscription / paywall** | Free, no paywall. A wall over basic features betrays the positioning. |
| W-10 | **Ads** | No ads. The App Store privacy label declares no tracking, and the app never asks for App Tracking Transparency. |
| W-12 | **OCR / automatic reading of Yape notifications** | The radical message (manual, 30 seconds) was chosen over the bold integration. |

### Revisited as optional opt-in (ADR 001)

These three were Won't. They stay **opt-in**: the app works 100% without them, with no account
and no network, and the "no account" state is permanent and supported.

| ID | Original decision | Status |
|---|---|---|
| W-02 | **Own cloud backend** | **Opt-in.** Supabase is used only if the user turns on backup from Profile (ADR 009 replaces "sync" with "backup" without touching the row). |
| W-03 | **Google Sign-In / account** | **Optional.** An email/password account or Google Sign-In, only if the user wants backup. |
| W-11 | **Sync between devices** | **Opt-in**, and ADR 009 reduced it to snapshot backup: no row-by-row replication and no multi-device convergence. |

---

## 2. Non-functional criteria

| Area | Requirement |
|---|---|
| **Launch** | <3s first launch (cold), <1s warm, on a mid-range iPhone. |
| **Recording one movement** | <15s end to end for the regular user. Any change that adds a tap to the main flow is rejected. |
| **App size** | Download size target <15MB, hard limit 25MB. |
| **Minimum iOS** | iOS 27.0, set once as `deploymentTarget` in `project.yml` and mirrored by each package's `platforms`. |
| **Language** | Spanish only. No English fallback, no language picker. |
| **Accessibility** | Dynamic Type without breakage, WCAG AA contrast, accessibility labels on interactive elements. Full VoiceOver support is not committed. |
| **Offline** | 100% functional without network for reading and writing. **Zero HTTP requests without explicit consent**: with no account, the app contacts no server. |
| **Persistence** | The local GRDB database is the single source of truth. A crash or a force quit loses no data. Every migration preserves the user's data. |
| **Battery** | No periodic `BGTaskScheduler` work and no background services. With an active session, backup runs when the app moves to the background or returns to the foreground; with no session, zero network activity. |
| **Crashes** | Crash telemetry, if it is ever added, reports from Release builds only. Debug builds never report. |

---

## 3. Acceptance criterion

A feature gets in only if it meets **all** of this:

- It is not in §1.
- It saves the user time or gives them clarity. "It looks nice" and "every app has it" are not
  reasons.
- It does not slow down recording a movement.
- It is discoverable: it needs no onboarding or tutorial to be found.
- It asks for no user data the app does not need to work.
