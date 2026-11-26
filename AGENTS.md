# AGENTS.md

Shared instructions for every contributor to this repository — human developers and AI coding agents alike. These rules are tool-agnostic: they describe how work is done, not which product performs it. Tool-specific setup lives in `README.md`.

## 1. Scope and authority

- This file governs all work in this repository. Read it before making changes.
- If a root `CONTRIBUTING.md` exists, it adds collaboration and Git rules; together they are the working agreement.
- If a tool-specific instruction file conflicts with this file, this file wins for shared behavior. Tool-specific configuration may add detail but may not weaken these rules.

## 2. Requirements-first development

- Begin by clarifying the outcome, constraints, acceptance criteria, and non-goals.
- Do not start implementation while material requirements are ambiguous. Ask, or capture the ambiguity explicitly as an open decision.
- Write down decisions and their rationale where the project records them, so another developer or agent can continue without reconstructing the conversation.
- Prefer the smallest change that satisfies the stated acceptance criteria.

## 3. OpenSpec is mandatory for non-trivial work

- Any non-trivial feature, refactor, behavior change, or configuration change MUST have an OpenSpec change before implementation starts.
- Use the `spec-driven` lifecycle: **propose** (proposal, delta spec, design, tasks) → **apply** (implementation tracked by tasks) → **archive** (after validation and review).
- Planning artifacts are not implementation. Do not write product code in the propose phase, and do not start applying until the plan is available.
- Every task MUST state its owner, dependencies, affected files or modules, and verification criteria.
- Trivial edits with no spec-level behavior change may skip OpenSpec, but the reason MUST be recorded in the work item.
- Never fabricate a requirement to satisfy a template. If there is no behavior change, say so explicitly.

## 4. Superpowers workflow expectations

Use the Superpowers practices (available as skills in supported agents) throughout the work:

- **Brainstorming / design** before creative or architectural work: explore options, choose an approach, write the design, get agreement.
- **Writing plans** before multi-step implementation: exact files, interfaces, verification, and small ordered tasks.
- **Implementation** by executing the plan task by task; keep a record of decisions and progress.
- **Test-driven development** for code: write the test, watch it fail, implement the minimum, watch it pass, then clean up.
- **Systematic debugging** for any unexpected behavior: find the cause before changing the symptom.
- **Verification before completion**: run the actual commands and read the output before claiming success.
- **Code review** before integration: request and receive review with technical rigor, not performative agreement.
- **Finishing a development branch**: validate, review, and integrate according to the Git rules in `CONTRIBUTING.md`.

If a tool does not provide these as skills, follow the same practices manually. The practices are the requirement; the plugin is not.

Brevity heuristics such as Ponytail's YAGNI ladder are advisory. They MUST NOT override OpenSpec requirements, acceptance criteria, architecture decisions, security checks, quality gates, verification evidence, or the readiness gate below.

## 4a. Mandatory environment readiness gate

Before writing application code or implementing any feature, every coding agent MUST follow this procedure:

1. Read `.agentic/toolchain.json`, the shared source of truth for required and optional tooling.
2. Run `scripts/agentic-doctor.sh` (read-only).
3. If required components are missing, run the approved `scripts/agentic-bootstrap.sh`.
4. Verify all required versions and integrations with the doctor; `READY` and exit `0` are required.
5. Confirm at least one usable model is available; a connected provider alone is not sufficient.
6. Report environment readiness with observed doctor output.
7. Only then begin application implementation.

- If model-provider authentication is missing, guide the developer through `opencode auth login` and stop until it succeeds. Never bypass authentication or security prompts, and never print credentials.
- A failed or incomplete required check is a development blocker, not a warning to ignore.
- Tool versions and plugin registrations are declared in the manifest and reconciled globally by the bootstrap. Do not commit global OpenCode or RTK configuration, and do not add plugin declarations to `opencode.json`.
- Graphify is installed for developers, but its assistant skill is not vendored, `graphify opencode install` is never run automatically, and the starter has no always-on graph integration. Do not generate a graph for the empty starter.
- Global plugin reconciliation must preserve unrelated entries, avoid duplicates and wildcard exclusions, and back up configuration before mutation.

## 5. No assumptions about technology or architecture

- This starter is stack-agnostic. Do not introduce a language, framework, runtime, database, package manager, deployment target, or architecture as a project default.
- Do not create a sample application or placeholder implementation to imply a stack.
- Establish the stack with the project owners, then record that choice in an OpenSpec change before application work begins.
- Skills in this repository may be domain-specific. Use them only when the task genuinely matches; their presence is not a stack decision.

## 6. No fabricated implementation or test results

- Never claim code was written, a command was run, a test passed, a review happened, or a check succeeded unless it actually did in the current session.
- Never invent output, coverage numbers, file paths, commits, or validation evidence.
- If a command cannot be run, report the limitation and its reason. If verification is incomplete, say "not verified" rather than implying success.
- An agent must not mark a task done, and a human must not approve a task, without evidence attached or referenced.

## 7. Edit boundaries

- Work only inside the current project directory. The sole exception is `/tmp`, which may be used for scratch files, temporary validation scripts, and isolated workspaces.
- Do not modify global agent configuration, machine-local configuration, sibling repositories, or system files as part of project work.
- Do not remove, reset, or discard Git history except through the approved `/starter-init` workflow with explicit approval.
- Do not delete, rename, or overwrite existing skills or configuration without first assessing their purpose and getting agreement.
- Do not add machine-specific artifacts, generated dependencies, credentials, or local environment files to version control.

## 8. Respect existing conventions

- Inspect the repository before editing. Follow existing structure, naming, file layout, and documentation style.
- Keep changes minimal and scoped to the task. Do not reformat unrelated files, upgrade unrelated dependencies, or drive-by refactor.
- If the repository has no convention for something, establish one deliberately, document it, and use it consistently.
- When a change would affect files owned by another task or developer, coordinate before editing (see `CONTRIBUTING.md`).

## 9. Verification and review before completion

- Each task defines verification criteria. Run them and record the command plus observed result.
- Before declaring work complete, run the project's full validation or test suite, not only the narrow check for the last edit.
- Validation includes OpenSpec structural checks, documentation consistency, and any stack-specific checks once a stack exists.
- Submit changes for review. Address findings with evidence, and re-run verification after fixes.
- Never merge unvalidated changes into an integration or production branch.

## 10. Quick checklist

- [ ] Requirements and acceptance criteria are clear.
- [ ] Non-trivial work has an OpenSpec change.
- [ ] Design decisions and task ownership are recorded.
- [ ] No stack or architecture was assumed.
- [ ] Tests were written and run where code changed.
- [ ] Commands were actually executed; results are recorded.
- [ ] No writes outside the project directory except `/tmp`.
- [ ] Unrelated files and existing skills/configuration were left alone.
- [ ] Review and validation are complete before integration.
