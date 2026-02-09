# CLAUDE.md

## Required Reading

Before making any changes, read these files:

- [AGENTS.md](AGENTS.md) — project overview, commands, conventions, operating mode
- [.ai/rules/security.md](.ai/rules/security.md) — non-negotiable security invariants
- [.ai/rules/agent-safety.md](.ai/rules/agent-safety.md) — untrusted input policy and escalation rules
- [.ai/rules/testing.md](.ai/rules/testing.md) — test requirements and conventions

For domain context: [.ai/context/glossary.md](.ai/context/glossary.md)

## Operating Mode

Follow the Agent Operating Mode defined in AGENTS.md: read context, plan, make minimal changes, verify, produce a reviewable PR, and fail safe when uncertain.

## Quick Reference

```bash
forge install       # Install dependencies
forge build         # Build contracts
forge test -vvv     # Run all tests
forge fmt           # Format code
```
