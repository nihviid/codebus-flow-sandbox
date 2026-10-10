# codebus-flow-sandbox

Disposable repo for the SR / C11 rehearsal (stop acknowledgement, freeze invariant, queue burst). Nothing here is production.
Never point real units at CodeBus or code-factory from here; never point sandbox units at the live state dir `~/flow/state`.

## What is here

| file | purpose |
|---|---|
| `.github/workflows/ci.yml` | one job named `CI Gate` (hosted runner). Fixture kind comes from the `kind` input of `workflow_dispatch`, else the first line of `fixture.txt` (`pass`, `fail`, `flaky`). Triggers: push to main, pull_request, workflow_dispatch. |
| `fixtures.py` | Temporal's deterministic fixtures: `pass` always passes, `fail` always fails, `flaky` fails for about 1 sha in 3 (sha-seeded, seed 1 in CI). |
| `fixture.txt` | the active fixture kind. A PR that sets it to `fail` is a red PR (X1); on the queue branch the merged content decides. |
| `.mergify.yml` | mirror of code-factory's queue: label `automerge`, squash, `batch_size: 3`, `max_parallel_checks: 3`, gate `CI Gate`, fix-main priority. |
| `ops/setup-sandbox-state.sh` | on dev01: creates `~/flow-sandbox/state` and the `*-sandbox` systemd user units. Writes them, enables nothing. |

## Drill state (dev01, isolated)

- State dir: `~/flow-sandbox/state` (guardian state, actuator log/STOP, status poster cache, merge ledger). Not `~/flow/state`.
- Units (written by the setup script, NOT enabled until told): `flow-guardian-sandbox`, `flow-actuator-sandbox`, `flow-status-poster-sandbox` (.service and .timer).
- ghm in the sandbox: `GHM_STATE_DIR=$HOME/flow-sandbox/state ghm pr merge N --repo nihviid/codebus-flow-sandbox --squash`.
- Pause/unpause target: the sandbox clone at `~/flow-sandbox/repo` (the Mergify CLI takes the repo from the git remote of the current directory).

## Reset to the known-good revision (pinned restore)

`known-good` is a tag on the first commit that has the files above and `fixture.txt = pass`.

1. Stop the sandbox units (`systemctl --user disable --now flow-*-sandbox.timer`) and `mergify queue pause` is not needed: delete open PRs and branches instead (step 3).
2. Reset main (needs force-push on main, so branch protection on this repo must stay off or allow it for the owner):
   `git fetch origin --tags && git push --force origin known-good:main`
3. Close and delete everything the drill created:
   `gh pr list -R nihviid/codebus-flow-sandbox --state open --json number -q '.[].number' | xargs -I{} gh pr close {} -R nihviid/codebus-flow-sandbox --delete-branch`
4. Clear the sandbox state: `rm -rf ~/flow-sandbox/state/* && mkdir -p ~/flow-sandbox/state`; then `mergify queue unpause` from `~/flow-sandbox/repo` if the queue is paused.
5. Check: `gh run list -R nihviid/codebus-flow-sandbox --branch main --limit 1` (a green `CI Gate` on the reset head; run `gh workflow run ci.yml -R nihviid/codebus-flow-sandbox -f kind=pass` if there is none).

## Owner-only steps in a UI (nothing in this repo can do them)

1. Install the Mergify GitHub App on the `nihviid` account for this repository (GitHub, Settings, Applications, Mergify, Repository access: add `codebus-flow-sandbox`), then in the Mergify dashboard activate Workflow Automation for it (rules are not evaluated otherwise).
2. Make sure Actions is enabled for the repo (default on).
3. Do NOT enable branch protection with required reviews on main; a protection rule that allows the owner to force-push is fine. Required status checks are not needed for the queue.
