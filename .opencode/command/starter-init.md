---
description: Initialize a project created from the Agentic Development Starter by planning and, only after approval, removing starter-specific artifacts.
---

# /starter-init

You are initializing a project created from the Agentic Development Starter. This command transforms the template into a project-specific workspace. It does not perform cleanup automatically.

## 1. Prerequisites

1. Verify the current project directory and confirm it is the intended repository.
2. Read `AGENTS.md` and any relevant project instructions.
3. Run the environment doctor if available:
   - `bash scripts/agentic-doctor.sh`
4. Require the environment to be `READY` before proceeding.
5. If the doctor reports `BLOCKED`, stop and report the blockers. Do not perform cleanup.

## 2. Inspect the starter and project

Analyze the repository and identify:

- Starter-specific configuration and manifests.
- Bootstrap and doctor scripts.
- Starter-only tests and fixtures.
- Starter documentation and contribution files.
- OpenSpec specifications and change artifacts belonging to the starter.
- Placeholder files, unused examples, and template artifacts.
- Git metadata, hooks, sample hooks, and starter-specific Git configuration.
- Project instructions, skills, commands, and configurations that should be retained.

Do not assume every file is unwanted simply because it originated from the starter. Distinguish reusable workflow files from starter-only artifacts.

## 3. Prepare a cleanup plan

Before removing anything, present a clear review to the user. Categorize files into:

A. Proposed removal
B. Proposed modification or adaptation
C. Files to preserve

For every proposed deletion, provide:

- Exact relative path.
- Reason for removal.
- Whether it is a file or directory.
- Any impact on project tooling or workflows.

Pay particular attention to `.git`. Identify unnecessary template-specific Git files, such as default sample hooks or starter-specific metadata, if applicable. Never treat Git internals as disposable. Preserve history, branches, refs, index, objects, HEAD, and essential repository configuration. If the user wants a project with no starter history, list removal of the entire `.git` directory and creation of a fresh repository as a separate, optional cleanup item; treat it as destructive and require its own explicit approval.

## 4. Permission requirement

Cleanup is destructive and requires explicit user approval.

- Show the cleanup plan first.
- Ask for confirmation before deleting, removing, overwriting, or cleaning any files.
- Do not interpret invoking `/starter-init` as permission to delete files.
- Do not interpret previous approvals as approval for a new cleanup plan.
- Do not delete any files before the user approves the exact proposed cleanup.
- If approval is denied or the user does not respond, leave all files untouched.
- If the user approves only part of the cleanup, perform only the approved actions.
- If additional unwanted files are discovered later, ask again before removing them.

## 5. Cleanup and project handover

After explicit approval:

- Remove only approved starter-specific artifacts.
- Remove approved unnecessary files from `.git` without damaging repository integrity.
- Preserve Git history, branches, refs, index, objects, HEAD, and essential repository configuration unless the user separately approves starter history removal.
- If the user separately approves starter history removal, remove only `.git`, run `git init`, and preserve every working-tree file.
- Do not remove starter history as part of ordinary cleanup.
- Adapt `.gitignore` to the new project without removing useful protections.
- Preserve `AGENTS.md`, relevant skills, commands, agent configuration, and useful workflow instructions.
- Retain relevant development tooling and safety rules.
- Do not remove dependencies or lockfiles without a specific reason and approval.
- Do not remove actual project source code, user-created files, or existing work.
- Do not perform broad wildcard deletions.
- Do not reset, reinitialize, rewrite, or discard Git history unless the user explicitly approves removing starter history after setup; then remove only `.git` and initialize a new repository without changing working-tree files.
- Do not change remotes or push anything.

## 6. Project identity

Where appropriate, help transition template identity to the new project by identifying:

- Project name.
- README.
- Description.
- Project-specific instructions.
- Placeholder references to the starter.
- Template-specific scripts or documentation references.

Ask for missing project identity information when necessary. Do not invent project details. Do not unnecessarily rewrite the entire README or project documentation.

## 7. Verification

After approved cleanup:

- Verify the project directory structure.
- Verify required retained agent instructions and skills.
- Verify OpenCode recognizes the custom command.
- Verify Git repository integrity.
- Run relevant checks that remain applicable.
- Run `git status` and inspect the resulting diff.
- Confirm no unapproved files were removed or changed.
- Confirm the project is no longer unnecessarily coupled to the starter.

If verification reveals additional cleanup needs, do not remove anything without obtaining additional approval.

## 8. Final handover report

Provide:

- Environment readiness status.
- Project initialization status.
- Files and directories removed.
- Files modified or retained.
- Git integrity verification.
- Tests/checks executed.
- Any remaining template references.
- Any manual actions required.

Clearly state when the project is successfully initialized and ready for development.

## Git safety

- Inspect current branch and working tree before proceeding.
- Never implement directly on `main`.
- Use a feature branch for implementation.
- Do not push to any remote.
- Preserve existing user changes and history.
- Removing starter history requires separate explicit approval and a fresh `git init`; it is never part of normal cleanup.
- Git history removal is permitted only through this command; never perform it ad hoc.
- If using a linked worktree, merge the completed and validated feature branch back into `dev`.

## Restrictions

- Work only inside the current project directory, except `/tmp` for isolated tests.
- Never access the home directory or unrelated files.
- Do not install unrelated tools.
- No destructive actions without explicit approval.
- Keep the implementation minimal and use the native OpenCode command mechanism.
