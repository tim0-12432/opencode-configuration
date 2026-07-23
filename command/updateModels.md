---
description: Analyzes all defined agents and proposes optimal, cost-efficient models from "opencode models" (preview before applying, with justification).
agent: build
---

You are to update the model assignments of the agents defined in this local
OpenCode installation. Proceed in exactly this order:

## 1. Inventory

1. Run `opencode models` in the terminal and list ALL returned models in
   full. Only these models may be used later — no others, even if you know
   them from your training.
2. Find all agent definitions in the installation:
   - `opencode.json` / `opencode.jsonc` (field `agent`), project and global
   - `.opencode/agent/*.md` or `.opencode/agents/*.md` (project)
   - `~/.config/opencode/agent/*.md` or `~/.config/opencode/agents/*.md` (global)
   Take into account additional arguments `$ARGUMENTS`, if the user specifies
   a different search path or restricts the scope to specific agents.
3. For each agent found, list:
   - Name
   - Location (file path or `opencode.json`)
   - Currently assigned model (if none is set: note the fallback to the
     global `model`/`small_model`)
   - Purpose/role of the agent (brief, based on `description`/prompt body)

## 2. Model selection (do NOT apply yet)

For each agent in the list from step 1, choose exactly one model based on
the following criteria, in this priority order:

a) Capability must match the agent's task complexity (e.g. `architect`,
   `auditor`, `superreview`, `reviewer` need strong reasoning models; simple
   formatting, summarization, or lookup agents are fine with
   cheaper/faster models).
b) At comparable capability: choose the more cost-efficient model (lower
   price per token or cheaper model class).
c) Where sensible, favor a single unified default model for the majority of
   agents and reserve more expensive top-tier models only for agents with
   high complexity/responsibility.

Important: Use ONLY models from the output of `opencode models`. Do not
invent or guess model names. If you are unsure whether a model exists,
check again against the list from step 1.

## 3. Preview instead of immediate change

Do NOT modify any configuration file in this step. Create a markdown table
with the columns:

| Agent | Location | Current Model | Proposed Model | Change? |
|---|---|---|---|---|

After the table, explicitly wait for my approval before editing any file.

## 4. Justification

Immediately after the table, provide a short, concrete justification
(2–4 sentences) for EACH agent, including:

- Why the chosen model's capability is sufficient/necessary for this
  agent's typical tasks
- Why it is cost-efficient compared to other available models from
  `opencode models`
- If no change is proposed: why the current model is already optimal

## 5. Apply only after explicit confirmation

Only apply changes after I have explicitly confirmed them (e.g. "yes,
apply" or "apply proposals for architect, auditor"). Then edit ONLY the
affected configuration files (agent frontmatter field `model:` or
`agent.<name>.model` in `opencode.json`) with the confirmed models, without
changing any other fields. At the end, summarize which files were changed
and note that the running OpenCode session must be restarted for the
changes to take effect.

Additional user requirements: $ARGUMENTS
