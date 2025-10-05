# OpenCode configurations for AI Development

## Roles

The different agents and subagents should depict like an real software development team.
I'm using a GitHub Copilot subscription to get access to all the different models.
But of course the provider and used models can be changed in the opencode configuration.

- Main agent: mostly using GPT 5 Mini; works as the team lead and instructor of the other subagents
- Requirements engineer (@requirements): Claude Sonnet 4
- Application architect (@architect): GPT 5
- Software engineer (@coder): GPT 5 Codex
- Implementation Reviewer (@reviewer): Claude Sonnet 4
- Software Tester (@tester): GPT 5 Mini
- Documenter (@documenter): Claude Sonnet 4
- Security Auditor (@auditor): GPT 5

## AI Role Workflows

### Feature

### Bug

### Task

## Project Setup

- Execute `opencode /init` to create an AGENTS.md file
- Fill it with the project specific information needed to develop in that project
  - Compare with your general AGENTS.md file
  - Content to have in there: project specific technology stack, folder structure, special patterns

## Instruction Workflows

1. Create folder `mkdir ../foo`
2. Create branch `git checkout -b foo`
3. Create git worktree using the folder `git worktree add ../foo foo`
4. Swith to folder `cd ../foo`
5. Call opencode `opencode`
6. Instruct the main agent to implement the feature `/feature blabla`
7. If completed and tested push and merge into main `git commit -m "bla"; cd ../<main>; git merge foo`
8. Delete worktree `git worktree remove foo`
9. Delete folder `rmdir ../foo`
