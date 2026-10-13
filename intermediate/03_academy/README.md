# Module 3: Run many agents with Academy

In [Module 2](../02_langgraph/README.md), one LangGraph agent ran on your computer and sent one task to Aurora.
Here, Academy starts two agents on Aurora. Each agent runs its own LangGraph loop to find molecules with a high QED.

## Before you start

1. Do the steps in [Module 0](../00_endpoint_setup/README.md) for Aurora. The endpoint must run in the environment where this repo is installed, so that the workers can import `intermediate.custom_agents`.
2. On Aurora, get the latest code: `cd ~/genesis_mission_hackathon && git pull && uv sync`.
3. Add the MAG values to `settings.env` on your computer. Refer to [Module 2](../02_langgraph/README.md#before-you-start).

`discovery_campaign.py` sends `LLM_MODEL`, `OPENAI_BASE_URL`, and `AMSC_TOKEN` to the agents as arguments. You do not copy `settings.env` to Aurora.

## Run the campaign

```bash
uv run python intermediate/03_academy/discovery_campaign.py
```

The script:

1. Starts one `MolDesignAgent` on Aurora for each seed molecule.
2. Each agent plans, asks the LLM for molecules, calculates QED with RDKit, and makes a conclusion. Then the loop starts again.
3. Every 30 seconds, the script asks each agent for a report. The report shows how many molecules the agent calculated, and the five best molecules.

To stop the campaign, push Ctrl+C.

The agent code is in [`../custom_agents/mol_design_agents.py`](../custom_agents/mol_design_agents.py).

## Challenge

Add a third seed molecule to `seeds` in `discovery_campaign.py`. Compare the best QED of each agent.
