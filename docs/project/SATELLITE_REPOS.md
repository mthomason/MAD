# Satellite repositories

A satellite is a repository outside `mthomason/MAD` that publishes something
built from MAD: today the `mad-action` GitHub Action, alongside the container
image on GHCR. Satellites are **publication targets, not forks**. MAD is the
source of truth; a satellite is generated from a directory here, and the only
things that cross the boundary are the published artifact and the files under
`satellites/<name>/`.

This is the same model as the image: `Linux/` is the source,
`.github/workflows/publish-image.yml` publishes `ghcr.io/mthomason/mad` on
every push to `master`, and nothing copies the engine's source anywhere else.
An action user gets a new engine because the image tag moved, not because the
satellite repository received a commit.

## Register

| Satellite | Source | Published by | References | Version tag |
|---|---|---|---|---|
| [mthomason/mad-action](https://github.com/mthomason/mad-action) | `satellites/mad-action/` | `.github/workflows/publish-mad-action.yml` | `ghcr.io/mthomason/mad:latest` | `v1` (moving; `satellites/mad-action/VERSION`) |
| `ghcr.io/mthomason/mad` (image, not a repo) | `Linux/` | `.github/workflows/publish-image.yml` | — | `latest`, `<short-sha>` |

`mthomason/mad-action` is generated. Do not edit it directly: a change goes
to `satellites/mad-action/` here, through the normal PR gate, and the publish
workflow carries it over. Issues and pull requests for the action belong in
`mthomason/MAD`.

## What needs a satellite commit

| Change in MAD | Satellite update |
|---|---|
| Engine or app code | None — the next master push republishes `:latest`, and the action runs it |
| Docs | None — the action README links to MAD |
| CLI verbs, flags, credential input, or export formats | `satellites/mad-action/action.yml`, `README.md` if the input mapping or docs change |
| Image name or tag policy | `satellites/mad-action/action.yml`, `README.md`, the workflows |
| `CLI/Fixtures/London.portable.mad` | Automatic: the publish workflow copies it to `fixtures/` |
| `LICENSE` or `NOTICE` | Automatic: the publish workflow copies both |
| `satellites/mad-action/**` | Automatic: the publish workflow syncs the directory |

The publish workflow runs on `master` when one of those paths changes, and by
hand with `workflow_dispatch`. It tests the source against the published
image, syncs the target, commits as `MAD release bot`, moves the major tag,
and lets the target's own test workflow run on the push. The satellite's test
workflow is also scheduled daily — the canary that catches an engine change
which breaks the wrapper even though the wrapper source did not change.

GitHub disables scheduled workflows after 60 days without repository activity.
The next sync commit re-enables it; a manual `workflow_dispatch` runs the test
immediately in the meantime. This is the one part of the arrangement that can
go quiet without failing.

## The release checklist

**A normal source change.**

1. Edit `satellites/mad-action/` and/or the fixture here.
2. Run the wrapper locally if the interface changed (`./Linux/build.sh
   --verify` builds `mad-cli:latest`; the action can be pointed at it with
   `image: mad-cli:latest`).
3. Open the PR. `Linux verification` runs the wrapper against the PR's own
   runtime image (`linux.yml`), in addition to the action's test in the
   target.
4. Merge. `Publish mad-action` tests and publishes; the satellite's own test
   run, in the target repository, must then be green.

**A CLI contract change.** The same PR updates `action.yml`'s inputs and the
README. The publish moves `v1`; existing users get the new wrapper on their
next run. If the change is breaking — an input renamed or removed, a default
changed incompatibly — bump `satellites/mad-action/VERSION` to `v2` in the
same PR and update the README's `@v1` references. The workflow then moves
`v2` and leaves `v1` where it is, so `mthomason/mad-action@v1` users keep the
old major until they move.

**A fixture refresh.** Regenerate the fixture in MAD
(`CLI/Fixtures/README.md`); the path filter copies it. Do not edit the copy in
the satellite repo.

**Deploy-key rotation.** Generate a new ed25519 key, add its public half to
`mthomason/mad-action` as a write deploy key, set the private half as the
`MAD_ACTION_DEPLOY_KEY` secret on `mthomason/MAD`, dispatch `Publish
mad-action`, then delete the old deploy key. The key is scoped to the one
target repository and can only write.

## One-time setup, recorded

The target repository was created empty and public; the first publish set its
default branch to `master`. It was not initialized with a README or licence,
because the first sync supplies both. Issues and the wiki are disabled there:
the README sends both to MAD. If it is ever recreated, repeat this:

1. `gh repo create mthomason/mad-action --public`
2. Disable issues and the wiki.
3. Add a write deploy key titled `MAD publish workflow`.
4. Set its private half as the `MAD_ACTION_DEPLOY_KEY` secret on
   `mthomason/MAD`.
5. Dispatch `Publish mad-action`.

The satellite has no third-party dependencies of its own: its body is
`docker run` of the published image, and its licence files are the MAD ones
(`LICENSE`, `NOTICE`).

## Adding another satellite

Create `satellites/<name>/` here, add a publish workflow in the shape of
`publish-mad-action.yml`, and add the register row above. The rules are the
same: MAD is the source of truth, the satellite consumes a published artifact,
and a version file (or equivalent) names the moving tag a user pins. Do not
mirror the engine source into a satellite; it already travels in the image.
