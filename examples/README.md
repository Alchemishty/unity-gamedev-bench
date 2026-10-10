# Examples

Example setup scripts for use with `--setup` when running the benchmark.

A setup script is a shell script that runs inside the project copy before the agent starts. Use it to install a harness, framework, custom CLAUDE.md, or any configuration that you want to test.

## Usage

```bash
# Run with a harness
./scripts/run-task.sh 1 --agent "claude -p" --label my-harness --setup examples/with-harness/install.sh

# Run bare minimum (baseline)
./scripts/run-task.sh 1 --agent "claude -p" --label baseline --setup examples/bare-minimum/install.sh
```

## Available Examples

- **bare-minimum/** — A one-line CLAUDE.md. The minimal baseline configuration.
- **with-harness/** — A full agent harness with conventions docs, enforcement rules, and memory system. This is the configuration that scored 140/180 in the pilot run.

## Writing Your Own

A setup script receives no arguments. It runs with `cwd` set to the project copy. It can:
- Write files (CLAUDE.md, AGENTS.md, docs, etc.)
- Create directories
- Install packages
- Anything that configures the agent's environment

The only requirement is that it exits 0 on success.
