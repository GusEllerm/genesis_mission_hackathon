---
name: hpc-endpoint-setup
description: Use when the user asks to connect to Aurora, Perlmutter, or Frontier with hpc-bridge, install genesis_mission_hackathon on that system, or start, check, or stop the hackathon's Globus Compute endpoint (gm_endpoint) there. Covers Module 0 of this repo.
---

# Set up the hackathon endpoint on an HPC system with hpc-bridge

The goal is the state that Module 1 to 4 need:

- `~/genesis_mission_hackathon` on the system, installed with `uv sync`.
- An endpoint named `gm_endpoint`, configured from that repo's `.venv`, running on the **login node**.
- Its UUID in `settings.env` on this computer, and `remote_function_call.py` returning `Hello World from <login node>`.

Follow the `hpc-bridge:driving-hpc` guidance for the tools. This skill adds what that guidance does not know about this repo and these systems.

| System | `facility` | `ssh_host` | `settings.env` variable | Notes |
|---|---|---|---|---|
| Aurora | `aurora` | `aurora.alcf.anl.gov` | `AURORA_ENDPOINT_ID` | Tested. MobilePASS+ MFA. |
| Perlmutter | `perlmutter` | `perlmutter.nersc.gov` | `PERLMUTTER_ENDPOINT_ID` | Not tested yet. |
| Frontier | `frontier` | `frontier.olcf.ornl.gov` | `FRONTIER_ENDPOINT_ID` | Not tested yet. |

## Rules

- Run every remote command with `run_shell(shape="login")`. Do not call `ensure_endpoint_up` and do not start a `compute` shape. This setup uses no allocation.
- The user does the steps labelled **(user)** in their own terminal. Give them the exact command.
- Never ask for, type, or show a password or a PIN. Do not show the contents of `settings.env`.
- The plugin's credential guard blocks any command that contains `password=`, `token=`, `secret=`, or `api_key=` (also with `:`). Do not write such strings, not even in a `grep`.

## 1. Before you connect (user)

hpc-bridge reads the SSH user name only from `~/.ssh/config`. On a computer without an entry for the system, every SSH goes out as the local user name and fails. So first ask the user for their user name on the system. Then give them this one command to run (do not edit the file yourself). `~/.ssh` may not exist yet, so keep the `mkdir`:

```bash
mkdir -p ~/.ssh && chmod 700 ~/.ssh && printf 'Host aurora.alcf.anl.gov\n  User <their-user-name>\n' >> ~/.ssh/config && chmod 600 ~/.ssh/config
```

Check the result with `cat -A ~/.ssh/config`: `User` and the name must be on one line.

If `connect_facility` fails with `UNKNOWN HOST KEY`, the user runs `ssh aurora.alcf.anl.gov` once, accepts the fingerprint, logs in, and exits. Then call `connect_facility` again.

**Interactive SSH never works through the `!` prefix in Claude Code**: `!` has no terminal, so SSH cannot ask for the fingerprint or the passcode. Every `ssh` command in this skill is for the user's own terminal window.

## 2. Connect

```
connect_facility(facility="aurora", ssh_host="aurora.alcf.anl.gov")
```

| Result | Do this |
|---|---|
| `needs_login` | A Globus login. Give the user `login_url`; they paste the code back; call `complete_login(code)`. This one login also serves `globus_compute_sdk` on this computer. |
| `needs_preauth` | **On ALCF, skip `complete_preauth`** even if `preauth_code_ok` is `true`: Aurora labels its passcode prompt `Password:`, so `complete_preauth` refuses it and the passcode is wasted. **(user)** Give the user the `preauth_command` exactly as returned (no `user@`; the config supplies it). They run it in their own terminal window, not with `!`, and type the MobilePASS+ passcode at `Password:`. When they say it is done, call `connect_facility` again. |
| `proposed_facility_details` | Show the proposal and confirm it with the user. For Aurora, `interface` must be `hsn0`, `scheduler` `pbs`, `partition` `debug`. Set `scheduler_options` to `#PBS -l filesystems=home:flare`; Aurora rejects jobs without it. Then call `connect_facility(..., details=<confirmed>)`. |
| `provisioning` | Call again after a short wait. "allocating nodes" here means the free login-node worker; no job is queued. |
| `needs_account` | **Ready.** Do not look for an allocation; this setup does not need one. Continue with step 3. |

## 3. Install the repo

The `run_shell` environment has hpc-bridge's own virtualenv active and carries the variables `GLOBUS_COMPUTE_ENDPOINT_DIR`, `GLOBUS_COMPUTE_ENDPOINT_NAME`, and `GLOBUS_COMPUTE_LOG_PATH` from hpc-bridge's endpoint. Leave them in place and `globus-compute-endpoint start gm_endpoint` fails with exit code 73 ("Another instance of this endpoint is running"), because it acts on hpc-bridge's endpoint instead of `gm_endpoint`. **Start every command in steps 3 and 4 with:**

```bash
deactivate 2>/dev/null; unset VIRTUAL_ENV GLOBUS_COMPUTE_ENDPOINT_DIR GLOBUS_COMPUTE_ENDPOINT_NAME GLOBUS_COMPUTE_LOG_PATH;
```

Then:

```bash
cd ~ && { [ -d genesis_mission_hackathon ] || git clone -q https://github.com/academy-agents/genesis_mission_hackathon.git; }
cd ~/genesis_mission_hackathon && git pull -q --ff-only && uv sync -q
uv run python -c "import intermediate.custom_agents, rdkit, academy; print('imports ok')"
uv run globus-compute-endpoint version
```

If `git pull --ff-only` fails, the user has local changes on the system. Stop and tell them.

## 4. Configure and start `gm_endpoint`

Use the same prefix as step 3 on every command.

1. Make sure the system is logged in to Globus: `uv run globus-compute-endpoint whoami`. hpc-bridge copies the Globus login from this computer when it sets up its own endpoint, so this normally succeeds with no action. If it is not logged in, **(user)** the user runs the login over the SSH connection from step 2, so there is no second MFA prompt:
   ```bash
   ssh -o ControlPath=$HOME/.hpc-bridge/cm/%C aurora.alcf.anl.gov 'cd ~/genesis_mission_hackathon && uv run globus-compute-endpoint login'
   ```
2. Configure once: `[ -d ~/.globus_compute/gm_endpoint ] || uv run globus-compute-endpoint configure gm_endpoint`. The default template runs tasks on the login node, which is what this repo wants.
3. Start it detached: `uv run globus-compute-endpoint start --detach gm_endpoint`. Do not use `setsid`, `nohup`, or `&`; `--detach` is the supported way and the process survives the session. Without `--detach`, `start` runs in the foreground and never returns.
4. Check: `uv run globus-compute-endpoint list` must show `gm_endpoint` as `Running` with a UUID. If it shows `Initialized` and the start returned 73, the variables in step 3 were not unset.

The UUID is stable: a later `start` of the same `gm_endpoint` registers the same UUID, so `settings.env` stays valid.

## 5. Update `settings.env` and test (local)

Change only the line for the system, and do not print the file:

```bash
sed -i.bak 's/^AURORA_ENDPOINT_ID=.*/AURORA_ENDPOINT_ID=<uuid>/' settings.env && rm settings.env.bak
```

Then run the test from the repository root: `uv run python intermediate/00_endpoint_setup/remote_function_call.py`. It must print `Hello World from <login node>` for the system. The script tries every endpoint in `settings.env` in order and stops at the first one that is not online, so leave the other variables empty.

Report to the user: the system and login node, the endpoint UUID and status, that `settings.env` was updated, that nothing was charged to an allocation, and the restart command for after a login-node reboot:

```bash
cd ~/genesis_mission_hackathon && uv run globus-compute-endpoint start --detach gm_endpoint
```

## 6. Stop

To stop the hackathon endpoint: `uv run globus-compute-endpoint stop gm_endpoint` (with the step 3 prefix). Leave hpc-bridge's own login-node endpoint running; it costs nothing and makes the next connection zero-SSH. Only `teardown_endpoint` if the user asks for that explicitly.
