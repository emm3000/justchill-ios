# Release Checklist

This is the ordered gate a JustChill iOS release passes, from the last commit on `trunk` to a build
on the owner's phone. Nothing on this page is optional.

## Before the tag

- **Gate.** `/release` runs `scripts/gate` before tagging. The script is the gate's only
  definition; don't hand-write a substitute here.
- **Version.** `MARKETING_VERSION` in `project.yml` equals the tag without its `v`, landed on
  `trunk` in its own commit before `/release` runs.
- **QA passes**, on a real device:
  - clean install
  - a week of offline-first use
  - late sign-in — use the app accountless first, sign in after
  - sign-out
  - a real upgrade over the previous build — never delete the app first; only an upgrade runs the
    migrations against real data
- **Session check.** Sign in once, terminate the app, relaunch: Profile still shows the session.
  Sign out: the session is gone after a relaunch, and the local ledger is untouched.
- **Restore drill.** [ADR 009](adr/009-backup-is-a-snapshot-not-row-replication.md) Decision 4
  requires a continuously proven restore before backup ships, and this line is its only
  enforcement: delete it and nothing in the repo asks for the drill again.
  - While snapshot backup is behind its flag, the drill runs over the manual export: export from the
    installed build, record the account and category counts and the month's figures first, import
    onto a clean install, and confirm all of them and the ledger survive.
  - Once the flag flips, the drill runs over the newest verified snapshot instead.
  - A release that ships a schema change also runs the migration drill in `.claude/rules/grdb.md`.
  - Read the figures from the app's screens, not from the import confirmation.
- **The declarations agree.** The App Store privacy label, the tracking answer and the privacy
  policy describe one app; changing one without the rest produces two official statements that
  contradict each other.
- **If this release turns snapshot backup on**, update the privacy policy and the privacy label in
  this same release — the app stops being "nothing leaves your phone". Not after. Flipping the flag
  is a compliance event, not a feature flag.

## The tag

[`/release`](../.claude/commands/release.md) does the tagging, the pre-flight and the GitHub
release. Nothing else here.

## After the tag

A tag and a GitHub release reach no one. Until the TestFlight ticket lands, the owner installs the
tagged build on their phone from Xcode, as an upgrade over the previous one.
