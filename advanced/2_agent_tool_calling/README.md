# Module 2: A coding agent that calls HPC tools

In [Module 1](../1_tool_calling/), you wrote the agent loop with LangChain and gave the LLM three Python functions as tools.
Here, you use a coding agent that has the loop and the tools already. The agent is [Pi](https://pi.dev) with the [Globus Harness](https://github.com/GusEllerm/pi-lab-profile) profile, and it runs in a Docker container. The agent has two types of tools:

- **Built-in tools:** read, write, edit, bash, grep, find, and ls. They operate on the files in the container.
- **MCP tools from [hpc-bridge](https://github.com/globus-labs/hpc-bridge):** connect to an HPC facility, start a compute block, run commands on it, and stop it.

You do not write code. You give the agent a task, and the agent selects the tools.

## What is in the image

| Part | Function |
|---|---|
| Pi (`@earendil-works/pi-coding-agent`) | The coding agent |
| Globus Harness, `lab` profile | A status column, `/endpoints`, a spend gate for HPC, and the ALCF inference gateway models |
| uv | Runs the hpc-bridge MCP server |
| git, ripgrep, OpenSSH client | Tools for the agent and for hpc-bridge |

## Before you start

- Install Docker. On macOS and Windows, use Docker Desktop.
- Get access to an LLM. Refer to [step 2](#2-choose-a-model).

## 1. Build the image

From the repository root:

```bash
docker build -t gm-agent advanced/2_agent_tool_calling
```

To test the image:

```bash
docker run --rm gm-agent pi --version
```

## 2. Choose a model

**Option A: An API key for a provider that Pi knows**, for example Anthropic or OpenAI. Put the key in your shell before you start the container:

```bash
export ANTHROPIC_API_KEY=<your key>
```

**Option B: The ALCF inference gateway.** If you have an ALCF account, you can use the gateway models (`alcf-minerva/…`, `alcf-metis/…`, `alcf-sophia/…`). The image has them already. Log in one time:

```bash
docker run --rm -it -v gm-agent-globus:/root/.globus gm-agent \
  uvx --from "alcf-ai==0.10.0" alcf-ai auth login
```

The `gm-agent-globus` volume keeps the login. The login stays valid for approximately six months if you do not use it.

> **Note:** The `globus/…` model in the profile needs the Globus Labs cluster. Select a different model.

## 3. Start the agent

From the repository root:

```bash
docker run --rm -it --name gm-agent \
  -e ANTHROPIC_API_KEY \
  -v "$PWD:/workspace" \
  -v gm-agent-home:/root/.pi/agent \
  -v gm-agent-globus:/root/.globus \
  gm-agent pi
```

- `-e ANTHROPIC_API_KEY` sends the key from your shell to the container. For a different provider, use the variable for that provider.
- `-v "$PWD:/workspace"` lets the agent read and change the files in this repository.
- The two named volumes keep your Pi settings, sessions, and logins between runs.

In Pi, type `/model` to select a model.

## 4. Give the agent a task

Type these in Pi:

| Input | Result |
|---|---|
| `!pwd` | Shows `/workspace`. `!` runs a shell command. |
| `/mcp` | Shows the `hpc` server and its tools. |
| `What HPC facilities can I use?` | The agent calls hpc-bridge and shows the facilities. |
| `Connect to Aurora and show the hostname of the login node.` | The agent connects to Aurora and runs `hostname` on the login node. |

If the system needs a password or a one-time passcode, the agent gives you an `ssh` command. Run the command inside the container, in a second terminal:

```bash
docker exec -it gm-agent <the ssh command from the agent>
```

> **Note:** Do not run the `ssh` command on your computer. hpc-bridge uses the SSH connection that you open in the container.

A compute block uses your allocation. The agent starts a compute block only after you confirm a dialog. When you are done, tell the agent to stop the endpoint. To see the facility, the block, and the node-hours, type `/hpc`.

## Rebuild the image

The `gm-agent-home` volume keeps the configuration from your first run. After you rebuild the image, remove the volume to get the new configuration:

```bash
docker volume rm gm-agent-home
```

This also removes your Pi sessions and your hpc-bridge logins.

**Challenge:** Tell the agent to do the [intermediate Module 1](../../intermediate/01_claude_code/README.md) task: calculate QED with RDKit on Aurora for aspirin and five similar molecules. Compare the result with the Claude Code result.
