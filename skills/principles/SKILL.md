---
name: principles
description: Apply these 24 engineering principles before making changes. Load the relevant rules, then name the principles applied and the decisions they changed.
---

# Principles

Before making changes, scan this index and open the file of each principle that is relevant to the task. Read only the files you need; each principle is one file in this directory. In your response, name each applied principle and the decision it changed. A principle citation without a decision behind it is name-dropping, not application.

Layout follows the original pstack principles (cursor/plugins, `pstack/`, MIT): one principle per file, an index with a one-line rule for each.

## Core

| Principle | Rule |
|---|---|
| [laziness-protocol](./laziness-protocol.md) | Bias toward deletion and the smallest change that solves the problem. |
| [foundational-thinking](./foundational-thinking.md) | Apply before writing logic: choosing core types and data structures, sequencing scaffold-vs-feature work, asking what concurrent actors share. Get the data structures right so downstream code becomes obvious. |
| [redesign-from-first-principles](./redesign-from-first-principles.md) | Redesign as if the requirement had been a foundational assumption from day one, instead of bolting it on. |
| [attack-the-premise](./attack-the-premise.md) | Apply when two or more fixes that share one premise have failed the same gate. Write the premise down and test it directly before you write another fix that assumes it. |
| [subtract-before-you-add](./subtract-before-you-add.md) | Remove dead weight, redundant validators, and stub references first, then build on the simpler base. |
| [minimize-reader-load](./minimize-reader-load.md) | Count layers between question and answer, and hidden state in the reader's head; collapse one-caller wrappers and shrink mutable scope. |
| [outcome-oriented-execution](./outcome-oriented-execution.md) | Apply during planned rewrites and migrations with explicit phase boundaries. Converge on the target architecture; don't preserve smooth intermediate states with throwaway compatibility code. |
| [experience-first](./experience-first.md) | Choose user delight over implementation convenience; ship fewer polished features over more rough ones. |
| [exhaust-the-design-space](./exhaust-the-design-space.md) | Build 2-3 competing prototypes and compare side by side before committing. |
| [build-the-lever](./build-the-lever.md) | Apply to any non-trivial work, not just bulk work: edits, migrations, analyses, checks. Build the tool that does it or proves it (codemod, script, generator, or a skill your subagents follow) instead of working by hand. The tool is the artifact a reviewer can rerun. |

## Architecture

| Principle | Rule |
|---|---|
| [model-the-domain](./model-the-domain.md) | Encode the domain in a structure instead of scattered conditionals. |
| [boundary-discipline](./boundary-discipline.md) | Concentrate guards at system boundaries (CLI, config, network, external APIs); trust internal types and keep business logic in pure functions. |
| [type-system-discipline](./type-system-discipline.md) | Make illegal states unrepresentable, brand semantic primitives, parse external data at boundaries, exhaust variants, derive from authoritative schemas. |
| [make-operations-idempotent](./make-operations-idempotent.md) | Converge to the same end state regardless of partial prior runs. |
| [migrate-callers-then-delete-legacy-apis](./migrate-callers-then-delete-legacy-apis.md) | Migrate callers and delete the old API in the same wave instead of preserving compatibility layers. |
| [separate-before-serializing-shared-state](./separate-before-serializing-shared-state.md) | Eliminate the sharing first; serialize structurally only when one shared writer is a real invariant. |

## Verification

| Principle | Rule |
|---|---|
| [prove-it-works](./prove-it-works.md) | Apply after completing a task, before declaring done. Verify against the real artifact (run the feature, read the actual value, inspect the diff), not a proxy, self-report, or 'it compiles.'. |
| [fix-root-causes](./fix-root-causes.md) | Trace each symptom back to the first place the system went wrong and fix it there. A guard is a fix only when the state it handles is legitimate. |
| [sequence-verifiable-units](./sequence-verifiable-units.md) | Apply to multi-step work (sweeps, migrations, runs of similar edits) and to how you stack commits and PRs. Break work into small units that each end in a verifiable state, check each before the next, and order delivery so the sequence proves itself to a reviewer. |
| [test-behavior-not-implementation](./test-behavior-not-implementation.md) | Apply when you write, change, or keep a test. Assert what the code's users can observe, so the test fails when that behavior breaks and keeps passing when only the internals change. |
| [explain-the-number](./explain-the-number.md) | Apply before you trust, report, or act on a number you measured: a speedup, a regression, a throughput, a latency, or an eval result. Find what limits it, and rule out that it measured something other than the work you think. |

## Delegation

| Principle | Rule |
|---|---|
| [guard-the-context-window](./guard-the-context-window.md) | Route bulk to subagents; keep summaries in the main thread, not raw payloads. |
| [never-block-on-the-human](./never-block-on-the-human.md) | Proceed, present the result, let the human course-correct after the fact; reserve confirmation for irreversible actions. |

## Meta

| Principle | Rule |
|---|---|
| [encode-lessons-in-structure](./encode-lessons-in-structure.md) | Encode the rule as a lint, metadata flag, runtime check, or script instead of more text. |
