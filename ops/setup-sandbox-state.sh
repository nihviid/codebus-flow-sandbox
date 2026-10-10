#!/usr/bin/env bash
# Creates the SANDBOX state dir and the *-sandbox systemd user units on dev01. Does NOT enable or start anything.
# State dir is ~/flow-sandbox/state, never ~/flow/state. Re-run is idempotent.
set -eu
S=$HOME/flow-sandbox/state; R=nihviid/codebus-flow-sandbox; U=$HOME/.config/systemd/user
mkdir -p "$S" "$HOME/flow-sandbox/repo" "$U"
[ -d "$HOME/flow-sandbox/repo/.git" ] || { git -C "$HOME/flow-sandbox/repo" init -q; git -C "$HOME/flow-sandbox/repo" remote add origin https://github.com/$R.git; }
cat > "$U/flow-guardian-sandbox.service" <<UNIT
[Unit]
Description=flow-guardian SANDBOX ($R), state in ~/flow-sandbox/state
[Service]
Type=oneshot
Environment=PATH=%h/.local/bin:/usr/local/bin:/usr/bin:/bin
ExecStart=/usr/bin/env node %h/flow/src/CodeBus/scripts/ci/flow-guardian.mjs --repo $R --gate $R=CI\x20Gate --state-dir %h/flow-sandbox/state --once
TimeoutStartSec=120
UNIT
cat > "$U/flow-guardian-sandbox.timer" <<UNIT
[Unit]
Description=flow-guardian sandbox every 5 min
[Timer]
OnCalendar=*:0/5
[Install]
WantedBy=timers.target
UNIT
cat > "$U/flow-actuator-sandbox.service" <<UNIT
[Unit]
Description=flow-actuator SANDBOX (enforce on the sandbox queue only)
[Service]
Type=oneshot
EnvironmentFile=%h/.config/flow-actuator/env
Environment=PATH=%h/.local/bin:/usr/local/bin:/usr/bin:/bin
ExecStart=/usr/bin/env node %h/flow/src/CodeBus/scripts/ci/flow-actuator.mjs --enforce --state-dir %h/flow-sandbox/state --repo $R --repo-dir $R=%h/flow-sandbox/repo
TimeoutStartSec=120
UNIT
cat > "$U/flow-actuator-sandbox.timer" <<UNIT
[Unit]
Description=flow-actuator sandbox every 5 min
[Timer]
OnCalendar=*:2/5
[Install]
WantedBy=timers.target
UNIT
cat > "$U/flow-status-poster-sandbox.service" <<UNIT
[Unit]
Description=flow-status-poster SANDBOX (report-only context flow/main-state on the sandbox repo)
[Service]
Type=oneshot
Environment=PATH=%h/.local/bin:/usr/local/bin:/usr/bin:/bin FLOW_STATE_DIR=%h/flow-sandbox/state FLOW_GH_CONFIG_DIR=%h/.config/gh
ExecStart=/usr/bin/python3 %h/flow/bin/flow-status-poster.py --repo $R --post
UNIT
cat > "$U/flow-status-poster-sandbox.timer" <<UNIT
[Unit]
Description=flow-status-poster sandbox every 5 min
[Timer]
OnCalendar=*:3/5
[Install]
WantedBy=timers.target
UNIT
systemctl --user daemon-reload
echo "units written (NOT enabled): flow-{guardian,actuator,status-poster}-sandbox.{service,timer}"
echo "ghm in the sandbox: GHM_STATE_DIR=$S ghm pr merge N --repo $R ..."
