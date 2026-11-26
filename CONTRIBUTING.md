# Contributing

This document defines how developers and coding agents share work in this repository. `AGENTS.md` defines the shared behavior rules; this document adds ownership, onboarding, parallelism, and Git rules.

## 0. First-time environment onboarding

Before implementation, every developer or coding agent MUST complete the readiness gate in `AGENTS.md`:

1. Read `.agentic/toolchain.json`.
2. Run `scripts/agentic-doctor.sh`.
3. If blocked, run `scripts/agentic-bootstrap.sh` and answer elevation prompts explicitly.
4. Re-run the doctor until it reports `READY` with at least one usable model.
5. Report readiness before starting work.

The required tools are OpenCode (minimum tested `2.2.5`), OpenSpec CLI `2.1.1`, the repository's OpenSpec skills, Superpowers at the pinned commit, Graphify CLI `graphifyy==0.9.119`, RTK `v1.2.1`, Ponytail `@dietrichgebert/ponytail@5.3.3`, and DCP `@tarquinen/opencode-dcp@3.2.1`. Context7 and Playwright are recommended integrations, not blockers. See `README.md` for official sources, commands, and troubleshooting.

- **Shared and reviewed:** `.agentic/toolchain.json`, scripts, `.agents/skills/`, OpenSpec artifacts, documentation, and ignore templates. Changes to these files require an OpenSpec change and review.
- **Machine-local and never committed:** global OpenCode plugins/configuration, RTK global integration, provider credentials, caches, and generated `graphify-out/` output.
- Authentication is manual: use `opencode auth login` when the doctor reports a missing provider or no usable model. Never bypass prompts or copy credentials into the repository.
- Brevity heuristics such as Ponytail's YAGNI ladder MUST NOT override OpenSpec requirements, acceptance criteria, architecture decisions, security, quality gates, or this onboarding gate.

## 1. Ownership model

- There is **one accountable owner per task**. The owner is an identified human or agent, recorded by name or agent identifier (not an unassigned role label) in the OpenSpec task list before implementation begins.
- One owner is responsible for a task from implementation through verification, review responses, and integration. Ownership may be transferred explicitly by updating the task record.
- Task lists MUST record: responsible developer or agent, dependencies, affected files or modules, and verification criteria.
- A reviewer is distinct from the owner. The owner prepares the work; the reviewer validates it. Self-review alone is not sufficient for merging.
- Every file or module has an owner for the duration of a change. Files not owned by a change MUST NOT be modified by it.

## 2. One change, one branch

- There is **one OpenSpec change per implementation branch**.
- Create the change first, complete its planning artifacts, then create the feature branch named after the change.
- Do not mix two OpenSpec changes in one branch, and do not implement part of a change on a different branch.
- Keep the branch focused: if work grows beyond the change's scope, update the proposal and specs deliberately or create a new change.

## 3. Branch roles and Git safety

- `main` is production-only. It receives reviewed releases, never implementation work.
- `dev` is the integration and testing branch. Feature branches merge into `dev`.
- Feature branches are the only place implementation happens.
- Never implement, commit, or push implementation changes directly to `main`.
- Never push to any remote unless the team has explicitly authorized that remote and the branch.
- Validate a feature branch before merging it into `dev`: run the task verification, the full suite or validation command, OpenSpec validation, and review.
- Never merge unvalidated changes into `dev` or `main`.
- Removing, resetting, or discarding Git history is destructive and is permitted only through `/starter-init` with explicit approval. Never do it ad hoc.
- Promotion from `dev` to `main` is a separate, human-owned release action with its own review.

### Linked worktrees

- A linked worktree may be used to isolate a feature branch. The worktree must be treated as the same feature branch, not a separate integration line.
- Linked worktree completion MUST include merging the validated feature branch into `dev` after validation. Closing or removing a worktree without that merge is incomplete work.
- Do not merge from a worktree whose validation has failed or is missing.

## 4. Parallel development

- Changes may proceed in parallel when their file ownership sets do not overlap and their external contracts are agreed.
- Before parallel implementation starts, record the ownership boundary in each change's tasks.
- Independent changes should not wait on one another for unrelated files, reviews, or decisions.
- When a dependency exists, record it explicitly in the task list and sequence the work accordingly rather than discovering it during merge.

## 5. API contracts before parallel work

- When frontend and backend (or any two independently implemented components) are developed in parallel, define and review the API contract first.
- The contract MUST describe inputs, outputs, error cases, compatibility expectations, and versioning rules, and MUST be recorded in the change's specs/design before implementation begins.
- Each side implements against the agreed contract. Changing the contract requires updating the spec and notifying every owner affected by it.
- Contract changes are never silent: they are a new or modified requirement in the change.

## 6. Shared-file conflicts

- If two changes need the same file, the owners MUST agree on a single owner or a sequencing plan before either change merges.
- Prefer extracting a stable interface or contract over concurrent edits to the same implementation file.
- If a shared file must change for both changes, one owner makes the change, the other reviews it, and both record the dependency in their task lists.
- Never resolve a conflict by overwriting another owner's work or by weakening either change's acceptance criteria.

## 7. Integration ownership and review

- Each change has an integration owner responsible for merging into `dev`, resolving conflicts, and confirming that `dev` still validates after the merge.
- The integration owner is usually the change owner but may be delegated explicitly in the task list.
- Review responsibilities: the reviewer checks requirements coverage, contract adherence, affected-file scope, verification evidence, and integration considerations — not just code style.
- After merging into `dev`, re-run validation there. A green feature branch does not guarantee a green integration branch.

## 8. Commit conventions

- Use small, logical commits with imperative subjects: `feat:`, `fix:`, `docs:`, `chore:`, `refactor:`, `test:`.
- One commit should serve one task or one clearly related group of changes.
- Never commit generated dependencies, machine-local files, credentials, or unrelated formatting changes.
- Do not commit directly to `main`. Do not commit to `dev` unless performing an integration merge or an explicitly authorized fix.
- Reference the OpenSpec change name in the commit body when helpful.

## 9. Pull request conventions

- Open a pull request from the feature branch to `dev`, never from a feature branch to `main` unless it is an approved release path.
- Title: `[<change-name>] <short summary>`.
- Description MUST use `.github/pull_request_template.md` and link the OpenSpec change.
- Attach verification evidence: exact commands and observed results. "Tests pass" without evidence is not acceptable.
- List affected files/modules and any shared-file or contract implications.
- A pull request is not mergeable until validation is green and review findings are resolved with evidence.

## 10. Definition of done

A task or change is done only when:

1. Its acceptance criteria are met.
2. The accountable owner is recorded and the work was done within the agreed file ownership.
3. Verification criteria were executed and results recorded.
4. The full validation or test suite passes on the feature branch.
5. Review is complete and findings are addressed.
6. The feature branch was validated before merging into `dev`.
7. If a linked worktree was used, the validated feature branch was merged into `dev` as part of completion.
8. `main` was never used for implementation and remains production-only.
