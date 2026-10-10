# Scoring

Absolute scoring protocol — run your agent, get a percentage score.

## How It Works

1. **Run tasks.** Your agent produces code changes for each task.
2. **Score.** A scoring agent (or human) evaluates each task's output against applicable rubrics.
3. **Get your score.** Reported as a percentage.

```
unity-gamedev-bench score: 81% (389/480)
```

No opponent needed. The score measures how well your agent performs against the rubrics.

## Score Calculation

Each task is scored on up to 6 rubrics (0-10 each). Not all rubrics apply to every task — see Rubric Applicability below.

```
Percentage = total points earned / total applicable rubric slots × 10 × 100
```

The maximum depends on how many tasks are scored and which rubrics apply. For a run where all 6 rubrics apply to every task: `max = tasks × 60`.

## Rubric Applicability

Not all rubrics are meaningful for every task. A one-line bounds fix shouldn't be penalized for Architecture, and a task whose scoring notes say "do not add tests" shouldn't score 0 on Test Quality.

When a rubric is not applicable to a task, mark it **N/A** and exclude it from both the task total and the overall calculation.

Guidelines:
- Task scoring notes say "do not add tests" → Test Quality = N/A
- Change is a one-line fix or trivial bounds correction → Architecture = N/A
- Task involves no Unity/Netcode-specific APIs → Domain Correctness = N/A

When in doubt, apply the rubric. N/A is for clear mismatches, not borderline cases.

## Who Can Score

### AI Scorer (recommended)
Use `scoring-agent-prompt.md` as the system prompt for a separate AI session. The scorer gets:
- The task prompt
- The project context (starter project or source repo)
- The output diff
- The rubrics

It produces per-rubric scores with code-referenced justifications.

### Human Scorer
A human reviewer reads the diff and fills in `results-template.md`.

### Both
AI scoring for scale, human review for spot-checking.

## Scoring Rules

- Every score must reference specific code — variable names, patterns, line numbers.
- Violations must be observable in the diff, not assumed.
- Score each task independently — don't let one task's quality influence another's score.
- Mark inapplicable rubrics as N/A, not 0.
- A 7th rubric (Efficiency) records objective counts but does NOT contribute to the percentage.

## Running the Scorer

```bash
# Score a single run
./scripts/score.sh results/my-agent/

# Compare two runs head-to-head (optional)
./scripts/score.sh results/agent-a/ results/agent-b/ --compare
```

When comparing, the scorer receives randomized "Output A" / "Output B" labels to prevent bias.

## Output Format

See [results-template.md](results-template.md) for the expected output structure.
