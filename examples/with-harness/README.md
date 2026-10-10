# With Harness Example

A full agent harness with conventions docs, enforcement rules, skills, and a cross-session memory system. This is the configuration used in the pilot run.

## Pilot Results

Scored against the bare-minimum baseline on tasks 1, 3, and 5:

| Rubric | Harness | Baseline | Delta |
|---|---|---|---|
| Correctness | 26/30 | 23/30 | +3 |
| Robustness | 27/30 | 13/30 | **+14** |
| Readability | 27/30 | 21/30 | +6 |
| Architecture | 24/30 | 20/30 | +4 |
| Domain Correctness | 27/30 | 16/30 | **+11** |
| Test Quality | 9/30 | 3/30 | +6 |
| **Total** | **140/180** | **96/180** | **+44** |

## What It Installs

- `CLAUDE.md` — Quick reference and non-negotiable rules
- `AGENTS.md` — 10 agent rules (null safety, SOLID, naming, Netcode lifecycle, etc.)
- `harness.yaml` — Central config
- `docs/` — architecture, conventions, domain (Netcode rules), testing strategy
- `enforcement/` — 7 non-negotiable rules checked after code is written
- `.claude/commands/` — 5 skills (implement-feature, create-tests, deslop, garden, retrospective)
- `memory/` — Cross-session learning stubs

## Usage

```bash
./scripts/run-task.sh 1 --agent "claude -p" --label harness --setup examples/with-harness/install.sh
```

## Adapting for Your Harness

Fork this example and modify the install script to copy your own scaffolding. The key is that whatever you write into the project copy becomes the agent's context when it starts working.
