# Project Instructions

Use this as a starting point for a project-scope `CLAUDE.md` at the root
of a client or project repo. The content is tool-neutral. Where people
also use a tool that reads `AGENTS.md`, put it there and make
`CLAUDE.md` `@AGENTS.md` plus any Claude-only lines: an `AGENTS.md`
alone loses five things in Claude Code, each silently
([agent-instructions-scoping.md](../claude/rules/agent-instructions-scoping.md)).

## Project Context

- Purpose:
- Primary languages:
- Main runtime or platform:
- Data sensitivity:
- Production surfaces:

## Setup

- Install dependencies:
- Configure local environment:
- Required tools:
- Safe sample data:

## Build And Test

- Format:
- Lint:
- Unit tests:
- Integration tests:
- Validation:

## Coding Rules

- Naming:
- Error handling:
- Logging:
- SQL/data conventions:
- Generated files:

## Security Rules

- Do not hardcode secrets or tenant-specific IDs.
- Do not print credentials, tokens, connection strings, or raw auth headers.
- Ask before changing production data, deployed artifacts, infrastructure, permissions, credentials, or client data.

## Data Platform Rules

- Target engine or service:
- Read-only versus write paths:
- Required docs or schema files to inspect:
- Required validation before deployment:

## PR Or Final Response

- Summarize changed files.
- State validation run and outcome.
- Call out skipped validation and residual risk.
