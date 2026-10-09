# Module 0: Globus Compute endpoint setup

A Globus Compute endpoint runs your Python functions on a remote system, for example Aurora, Perlmutter, or Frontier.

The `globus-compute-endpoint` package is installed when you install this repo with `uv sync`. Refer to the [top-level README](../../README.md). Do the steps below on the system where the endpoint must run, for example a login node.

## 1. Configure the endpoint

```bash
uv run globus-compute-endpoint configure gm_endpoint
```

This command creates the endpoint configuration in `~/.globus_compute/gm_endpoint/`.

## 2. Start the endpoint

```bash
uv run globus-compute-endpoint start gm_endpoint
```

The first time, the command shows a Globus login link. Open the link and log in.

When the endpoint starts, it shows its endpoint UUID. To show the UUID again, use:

```bash
uv run globus-compute-endpoint list
```

## 3. Add the endpoint UUID to settings.env

Copy the endpoint UUID into `settings.env` in the project root. Use the variable for your system:

```
AURORA_ENDPOINT_ID=<your-endpoint-uuid>
PERLMUTTER_ENDPOINT_ID=<your-endpoint-uuid>
FRONTIER_ENDPOINT_ID=<your-endpoint-uuid>
```

## 4. Test the endpoint

```bash
uv run python intermediate/00_endpoint_setup/remote_function_call.py
```

The script runs `hello_world` on each endpoint in `settings.env` and shows the result.

## Alternative: set up the endpoint with hpc-bridge

[hpc-bridge](https://github.com/globus-labs/hpc-bridge) lets a coding agent do the steps above for you. It is a Claude Code plugin. It is also a standard MCP server, so you can use it with other coding agents, for example Cursor or the OpenAI Agents SDK. For other coding agents, refer to [other MCP hosts](https://github.com/globus-labs/hpc-bridge/blob/main/docs/user/other-hosts.md).

### Notes for coding agents

- The user must do the steps that have the label **(user)**. Give the user the exact command to run.
- Do not ask for, type, or show a password or a PIN. Do not show the contents of `settings.env`. It contains `USER_AGENT_ID`.
- Run all remote commands on the login node with `run_shell(shape="login")`. Do not start a compute block. This setup does not use the allocation.

### 1. Install the plugin (user)

An agent cannot run slash commands. Tell the user to type these commands in Claude Code:

```
/plugin marketplace add globus-labs/hpc-bridge
/plugin install hpc-bridge@hpc-bridge
/reload-plugins
```

Then give the agent one prompt, for example:

```
Connect to aurora.alcf.anl.gov, install genesis_mission_hackathon, and start a globus_compute_endpoint.
```

The agent does steps 2 to 5 below. It tells you when you must do a step.

### 2. Connect to the system

Call `connect_facility(facility="<system>", ssh_host="<alias>")`. `<alias>` is the `Host` entry for the system in the user's `~/.ssh/config`.

If the result is `needs_preauth`, the system needs an interactive login:

- **(user)** Give the user the `preauth_command` from the result. The user must run it in their own terminal, not with `!` in Claude Code, because the password must not go into the transcript. The command has this form:

  ```bash
  ssh -fN -o ControlMaster=yes -o ControlPath=$HOME/.hpc-bridge/cm/%C -o ControlPersist=1h -- <alias>
  ```

- If `preauth_code_ok` is `true` (for example, Aurora with MobilePASS+), the user can give you the current one-time passcode instead. Send it with `complete_preauth(code)`. Do not accept the PIN.

When the user confirms the login, call `connect_facility` again. Perlmutter and Aurora are not in the hpc-bridge registry, so the result is `proposed_facility_details`. Make sure that the user confirms these values:

| System | `interface` | `scheduler` | `partition` | `scheduler_options` |
|---|---|---|---|---|
| Perlmutter | `hsn0` | `slurm` | `debug` | none |
| Aurora | `hsn0` | `pbs` | `debug` | `#PBS -l filesystems=home:flare` |

Replace the proposed `env_setup` with the value below. The `{venv}` placeholder can resolve to a path that does not exist (for example, `/home/<user>` on Perlmutter).

```bash
V=$HOME/.hpc-bridge/gce-venv; [ -d $V ] || { mkdir -p $HOME/.hpc-bridge && uv venv $V --python 3.13; }; . $V/bin/activate; command -v globus-compute-endpoint >/dev/null 2>&1 || uv pip install -q 'globus-compute-endpoint==4.16.0'
```

Call `connect_facility(facility, ssh_host, details=<confirmed values>)`. While the result is `provisioning`, call `connect_facility` again. The login node is ready when the result is `needs_account`. You do not need an account for this setup.

### 3. Install the repo

The hpc-bridge session activates its own venv. Deactivate it first. Then clone the repo and install it:

```bash
deactivate 2>/dev/null; unset VIRTUAL_ENV
cd $HOME && git clone https://github.com/academy-agents/genesis_mission_hackathon.git
cd genesis_mission_hackathon && uv sync
```

If `~/genesis_mission_hackathon` already exists, run `git status` first. If there are no local changes to tracked files, run `git pull --ff-only` instead of `git clone`.

### 4. Start the endpoint

Configure the endpoint:

```bash
cd $HOME/genesis_mission_hackathon && uv run globus-compute-endpoint configure gm_endpoint
```

**(user)** Do not run `start` with `run_shell`: it exits with code 73 and the endpoint does not start. Tell the user to type this command in Claude Code. It uses the SSH connection from step 2, so it does not ask for a password while that connection is open:

```bash
! ssh -o ControlPath=$HOME/.hpc-bridge/cm/%C <alias> 'cd ~/genesis_mission_hackathon && uv run globus-compute-endpoint start gm_endpoint'
```

Make sure that the endpoint runs. The status must be `Running`, with an endpoint UUID:

```bash
cd $HOME/genesis_mission_hackathon && uv run globus-compute-endpoint list
```

On the local machine, you can also make sure that the endpoint is online. The result must be `online`:

```bash
uv run python -c "from globus_compute_sdk import Client; print(Client().get_endpoint_status('<uuid>')['status'])"
```

### 5. Update settings.env

On the local machine, set the endpoint UUID in `settings.env`. Change only the line for the system: `PERLMUTTER_ENDPOINT_ID`, `AURORA_ENDPOINT_ID`, or `FRONTIER_ENDPOINT_ID`. Do not commit `settings.env`.

Then do [step 4](#4-test-the-endpoint) to test the endpoint. The test script stops at the first endpoint that is not online. Remove endpoint IDs that are not online from `settings.env` before you run the test.
