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
   - `opencode.json` / `opencode.jsonc` (field `agents`), project and global
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

## 2. Mandatory online research: benchmarks and GitHub Copilot pricing

Before proposing model assignments, you MUST research current benchmarks
and actual GitHub Copilot pricing on the internet. Do not rely solely on
training knowledge, model naming, or assumptions about model tiers.
This research is mandatory, not optional.

Research does NOT expand the permitted model list: only exact model IDs
returned by `opencode models` may be proposed.

If internet access is unavailable, applicable pricing cannot be verified,
or an important model-ID mapping is ambiguous, disclose the limitation
and request the missing information before finalizing recommendations.
Do not claim that the mandatory comparison has been completed.

### Benchmark research

1. Research the models returned by `opencode models`, prioritizing those
   relevant to the discovered agents.
2. Compare benchmarks relevant to each agent's role:
   - Coding and repository-level software engineering for implementation agents
   - Reasoning and complex problem-solving for architecture and planning agents
   - Code review, bug detection, and security evaluation for review/audit agents
   - Instruction following, summarization, and latency for lightweight agents
3. Prefer primary sources: benchmark publishers, original evaluation
   reports, and official model documentation. Supplement with independent
   evaluations where useful.
4. Record the source URL, access date, evaluated model version, and relevant
   results. Distinguish independently measured results from vendor claims.
   Do not treat scores from different benchmark versions, tool setups,
   reasoning budgets, or evaluation configurations as directly comparable.
5. If an available model has no reliable benchmark evidence, explicitly
   state that limitation. Do not invent scores or silently substitute
   evidence from a similarly named model.

### Actual GitHub Copilot pricing

1. Consult current official GitHub documentation and pricing pages.
   Establish which Copilot plan and billing mechanism apply to this
   installation; ask the user if this cannot be determined.
2. Verify and report, where applicable:
   - Plan subscription price, currency, and monthly versus annual billing
   - Included usage or allowances
   - Model-specific usage multipliers, credit consumption, or other
     model-specific charges
   - Overage pricing, usage limits, and relevant availability restrictions
   - Whether displayed prices include or exclude taxes
3. Do not assume GitHub Copilot uses a particular billing mechanism.
   Verify the current mechanism and use its actual terminology and units.
4. Distinguish the fixed subscription cost from the marginal cost of
   choosing a model. If estimating costs, state the workload assumptions
   and show the calculation; do not present estimates as actual charges.
5. Apply GitHub Copilot pricing only to models actually accessed through
   the GitHub Copilot provider. For other providers, use their applicable
   official pricing and identify it separately. Never substitute direct
   API token prices for GitHub Copilot charges.

## 3. Model selection (do NOT apply yet)

For each agent in the list from step 1, choose exactly one model based on
the following criteria, in this priority order:

a) Capability must match the agent's task complexity (e.g. `architect`,
   `auditor`, `superreview`, `reviewer` need strong reasoning models; simple
   formatting, summarization, or lookup agents are fine with
   cheaper/faster models).
b) At comparable capability: choose the more cost-efficient model using
   the mandatory benchmark and verified pricing research above. Compare
   actual charges for the applicable provider and plan—not assumed model
   tiers or unrelated API token prices.
c) Where sensible, favor a single unified default model for the majority of
   agents and reserve more expensive top-tier models only for agents with
   high complexity/responsibility.

Important: Use ONLY models from the output of `opencode models`. Do not
invent or guess model names. If you are unsure whether a model exists,
check again against the list from step 1.

## 4. Preview instead of immediate change

Do NOT modify any configuration file in this step. Create a markdown table
with the columns:

| Agent | Location | Current Model | Proposed Model | Change? |
|---|---|---|---|---|

After the table, explicitly wait for my approval before editing any file.

## 5. Justification

Immediately after the table, provide a short, concrete justification
(2–4 sentences) for EACH agent, including:

- Why the chosen model's capability is sufficient/necessary for this
  agent's typical tasks
- Why it is cost-efficient compared to other available models from
  `opencode models`
- If no change is proposed: why the current model is already optimal

## 6. Apply only after explicit confirmation

Only apply changes after I have explicitly confirmed them (e.g. "yes,
apply" or "apply proposals for architect, auditor"). Then edit ONLY the
affected configuration files (agent frontmatter field `model:` or
`agents.<name>.model` in `opencode.jsonc`) with the confirmed models, without
changing any other fields. At the end, summarize which files were changed
and note that the running OpenCode session must be restarted for the
changes to take effect.

Additional user requirements: $ARGUMENTS
