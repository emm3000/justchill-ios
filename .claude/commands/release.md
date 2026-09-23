---
description: Tag the current trunk HEAD as a release and publish a GitHub release
argument-hint: "patch | minor | major | vX.Y.Z [--skip-tests]"
allowed-tools:
  - Bash
  - Read
---

You are executing the `/release` slash command. The owner wants to tag the current `trunk` HEAD with a new semver tag and publish a GitHub release for it. Nothing uploads a build: there is no TestFlight step yet, and that upload is a future ticket.

## Parse arguments

The owner invoked: `/release $ARGUMENTS`

Recognized forms, from `v1.6.0`: `patch` → `v1.6.1`, `minor` → `v1.7.0` (patch reset), `major` → `v2.0.0` (minor and patch reset). An explicit semver is also accepted, with the leading `v` optional — add it if missing. `--skip-tests` skips the local gate run.

If the argument is missing or unrecognized, ask which bump or accept an explicit version. Don't guess.

## Safety preflight (in order, STOP on failure)

1. **On branch `trunk`?** `git rev-parse --abbrev-ref HEAD` must return `trunk`.
2. **Working tree clean?** `git status --porcelain` must return empty.
3. **Up to date with `origin/trunk`?** `git fetch origin trunk`, then `git rev-list --left-right --count origin/trunk...HEAD`; both numbers must be 0. Behind: tell the owner to pull. Ahead: tell the owner to push first, so the `trunk` gate run validates the state being tagged.
4. **Tag free?** `git ls-remote --tags origin "refs/tags/<new-tag>"` and `git tag -l "<new-tag>"` must both be empty.
5. **Version agrees?** `MARKETING_VERSION` in `project.yml` must equal the new tag without its `v`. If it does not, stop: the bump lands as its own commit on `trunk` first, and this command never commits.

## Determine the new tag

An explicit version is normalized to `vX.Y.Z` and must match `^v\d+\.\d+\.\d+(-[\w.]+)?$`.

For `patch` / `minor` / `major`, read the latest **release** tag. The `--match` filter is not optional (`.claude/rules/github-workflows.md` says why):

```bash
git describe --tags --abbrev=0 --match "v[0-9]*" 2>/dev/null
```

No tag at all: `v0.1.0` for `minor` / `patch`, `v1.0.0` for `major`. Otherwise strip the `v` and any `-suffix`, then bump.

## Show plan and confirm

```
Release plan
  Current HEAD:       <short SHA> <commit subject>
  Latest tag:         <last tag or "none">
  New tag:            <new tag>
  MARKETING_VERSION:  <value in project.yml>
  Publishes:          GitHub release <new tag>, notes generated from the commits since the last tag
```

Ask the owner to confirm with a clear yes/no. **Do not proceed without explicit confirmation.**

## Pre-flight gate

Unless `--skip-tests`, run `scripts/gate` before tagging. Never substitute a hand-written command list; the script is the gate. If it fails, STOP, show the failure, and do not tag.

## Tag, push, publish

```bash
git tag -a <new-tag> -m "Release <new-tag>"
git push origin <new-tag>
gh release create <new-tag> --verify-tag --generate-notes --title "<new-tag>"
```

Never push `trunk` here. Only the tag.

## Report

Give the owner the release URL `gh release create` printed. Remind them that a tag and a release ship nothing to a phone: the build still reaches their device through Xcode until the TestFlight ticket lands. The release checklist is `docs/release.md`.

## Failure recovery

Tag created but not pushed: `git tag -d <new-tag>`.

Tag pushed and the owner explicitly asks to retract it: `git push origin :refs/tags/<new-tag>` then `git tag -d <new-tag>`. Deleting the GitHub release is the owner's step; `gh release delete` is denied here.

## Rules

- Never push `trunk` as part of this command.
- Never amend or rebase commits as part of this command.
- Never override a safety check without the owner explicitly asking.
- Never auto-confirm; the owner must approve the plan.
