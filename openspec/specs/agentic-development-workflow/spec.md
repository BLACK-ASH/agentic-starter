# agentic-development-workflow Specification

## Purpose

Defines the observable rules and gates that let humans and coding agents collaborate safely on a stack-agnostic starter, from requirements and ownership through implementation, verification, review, and integration.

## Requirements

### Requirement: Shared instructions govern every contributor

The starter SHALL provide a root `AGENTS.md` that applies to human developers and AI coding agents alike and states the requirements-first workflow, the prohibition on assumed technology stacks, the prohibition on fabricated implementation or test results, the edit boundary limited to the current project directory plus `/tmp`, and the duty to respect existing conventions.

#### Scenario: Agent follows the shared rules

- **WHEN** an AI coding agent contributes to a project created from the starter
- **THEN** it reads and obeys the root `AGENTS.md` before making changes

#### Scenario: Out-of-scope edits are avoided

- **WHEN** a change would require writing outside the project directory other than `/tmp`
- **THEN** the contributor stops and reports the boundary instead of writing

### Requirement: OpenSpec is mandatory for non-trivial work

The shared instructions SHALL require an OpenSpec change for any non-trivial feature, refactor, or configuration change, and SHALL describe the propose to apply to archive lifecycle.

#### Scenario: Non-trivial work is proposed first

- **WHEN** a contributor is asked to implement a non-trivial feature
- **THEN** no implementation begins until an OpenSpec change with planning artifacts exists

#### Scenario: Trivial work is exempt

- **WHEN** a change is trivial and has no spec-level behavior change
- **THEN** the contributor records the reason for skipping OpenSpec in the work item

### Requirement: OpenSpec artifacts carry collaboration metadata

The OpenSpec configuration SHALL impose artifact rules that require clear requirements and acceptance criteria, architecture and design decisions, task dependencies, a responsible developer or agent, affected files or modules, and verification criteria for every task, plus testing and review requirements before completion and validation requirements before archiving. These rules are enforced by human and agent review; OpenSpec CLI validation does not mechanically check artifact prose.

#### Scenario: A task lacks ownership

- **WHEN** an authored task has no responsible developer or agent
- **THEN** reviewers and agents following the rules treat the artifact as incomplete and the change is not ready to apply

#### Scenario: A change is ready to archive

- **WHEN** all tasks are complete and validation requirements have been satisfied
- **THEN** the archive workflow may proceed

### Requirement: Ownership and parallel work are explicit

The collaboration guide SHALL define one accountable owner per task, one OpenSpec change per implementation branch, explicit task and file ownership, rules that allow independent parallel work, API contracts established before parallel frontend and backend implementation, shared-file conflict handling, and integration ownership with review responsibilities.

#### Scenario: Two developers work in parallel

- **WHEN** two changes touch disjoint file sets and share a documented API contract
- **THEN** both may be implemented independently on separate feature branches

#### Scenario: Shared file conflict arises

- **WHEN** two changes need the same file
- **THEN** the owners coordinate an agreed contract or sequence before either merges

### Requirement: Git branches protect integration and production

The collaboration guide SHALL require feature branches for implementation, `dev` as the integration and testing branch, `main` as production-only, forbid implementing or committing implementation changes directly to `main`, require validation of a feature branch before merging into `dev`, require that a linked worktree completion include merging the validated feature branch into `dev`, and forbid merging unvalidated changes.

#### Scenario: Work is completed on main

- **WHEN** a contributor attempts to implement or commit implementation changes on `main`
- **THEN** the action is rejected and the contributor is directed to a feature branch

#### Scenario: Feature branch validation fails

- **WHEN** a feature branch has not passed validation
- **THEN** it is not merged into `dev` or `main`

### Requirement: Agent toolchain is portable and pinned

The starter SHALL keep OpenSpec skills project-level, SHALL declare required tool versions in `.agentic/toolchain.json`, SHALL manage Superpowers, Ponytail, and DCP as global OpenCode plugins pinned in the manifest, SHALL keep project `opencode.json` free of plugin declarations, SHALL preserve unrelated global configuration, and SHALL document that other agent platforms require their own integration. It SHALL NOT claim Freebuff support for OpenCode-specific plugins.

#### Scenario: Teammate clones the starter

- **WHEN** a teammate opens the project with OpenCode and runs the bootstrap
- **THEN** project-level OpenSpec skills are available and global plugins are reconciled to the manifest pins

#### Scenario: Project plugin configuration is inspected

- **WHEN** a contributor inspects project `opencode.json`
- **THEN** it contains no plugin declarations, exclusions, or wildcard entries

#### Scenario: Non-OpenCode agent is used

- **WHEN** a contributor uses a different coding agent platform
- **THEN** documentation directs them to configure that platform's equivalent integration

### Requirement: Template stays generic and clean

The starter SHALL NOT include a sample application, SHALL NOT assume a technology stack or architecture, SHALL distinguish reusable skills from domain-specific skills without deleting useful skills, and SHALL exclude machine-specific artifacts and generated dependencies such as `.venv` from version control.

#### Scenario: A new project is created from the starter

- **WHEN** a developer starts a project from the template
- **THEN** they must choose and document their own stack before application work begins

#### Scenario: Machine-local environment exists

- **WHEN** a `.venv` directory is present in the working tree
- **THEN** it is ignored by Git and excluded from the reusable template

### Requirement: Evidence is required for completion claims

All shared instructions, task rules, review templates, and documentation SHALL require real verification evidence before claiming implementation or tests are complete, and SHALL forbid fabricating results.

#### Scenario: Test evidence is missing

- **WHEN** a task or pull request claims tests pass without attached evidence
- **THEN** review is blocked until evidence is provided

#### Scenario: Validation cannot be run

- **WHEN** a validation command cannot be executed
- **THEN** the contributor reports the limitation rather than asserting success

### Requirement: Toolchain definition is repository-controlled and declarative

The starter SHALL provide `.agentic/toolchain.json` as the single source of truth for required and optional tooling. Each component SHALL declare an identifier, description, requirement status, exact version or Git commit (or minimum plus verified version), official source, installation method and scope, supported agents and operating systems, prerequisites, verification commands, dependencies, and integration requirements.

#### Scenario: A contributor inspects the toolchain

- **WHEN** a contributor reads `.agentic/toolchain.json`
- **THEN** they find every required and optional component with source, exact version, scope, platform support, prerequisites, verification commands, dependencies, and integration requirements

#### Scenario: A script reads the toolchain

- **WHEN** a doctor or bootstrap script reads the manifest
- **THEN** it can determine required status, versions, install commands, and verification commands without parsing prose documentation

### Requirement: Required toolchain versions are prescribed

The manifest SHALL prescribe OpenCode 2.2.5 or newer (verified 2.4.1), OpenSpec CLI 2.1.1, the repository's project-level OpenSpec skills, Superpowers commit `22f0b463e7a5e579904dd6211a520321035526f7`, Graphify `graphifyy==0.9.119`, RTK `v1.2.1`, Ponytail `@dietrichgebert/ponytail@5.3.3`, and DCP `@tarquinen/opencode-dcp@3.2.1` as required. Context7 and Playwright MAY be recommendations. No personal-memory plugin SHALL be required.

#### Scenario: Versions are compared

- **WHEN** an agent checks a cloned starter
- **THEN** any missing or incompatible required component is identified by its manifest identifier and expected version

#### Scenario: Optional integrations are classified

- **WHEN** Context7 or Playwright is unavailable
- **THEN** readiness is unaffected because they are recommendations, while required tool failures block readiness

### Requirement: Agents must pass a readiness gate before implementation

Shared instructions SHALL require every coding agent, before writing application code or implementing a feature, to read the manifest, run the doctor, bootstrap missing or incompatible requirements, verify versions and integrations, confirm at least one usable model, report environment readiness, and only then begin work. A failed required check SHALL block development; missing model-provider authentication SHALL require manual developer action and a stop.

#### Scenario: Required tools are missing

- **WHEN** an agent is asked to implement a feature and the doctor reports a missing required component
- **THEN** the agent runs the approved bootstrap, rechecks readiness, and does not start implementation until required checks pass

#### Scenario: Provider is connected but no model is usable

- **WHEN** `opencode auth list` shows a provider but `opencode models` provides no usable model
- **THEN** the agent reports BLOCKED and asks the developer to authenticate or select a model manually

#### Scenario: Authentication is absent

- **WHEN** model-provider authentication is missing
- **THEN** the agent guides the developer through manual authentication and stops until authentication succeeds

### Requirement: Doctor is read-only and reports complete readiness

The starter SHALL provide a read-only `scripts/agentic-doctor.sh` that reports OpenCode, OpenSpec, Superpowers, Graphify, RTK, Ponytail, and DCP versions; available project skills; RTK integration status; plugin duplication or conflicts; model-provider availability without revealing credentials; unsupported integrations; and a final READY or BLOCKED status with reasons.

#### Scenario: Fully configured environment is checked

- **WHEN** the doctor runs on a configured Linux/OpenCode environment
- **THEN** it reports READY with all required components and a usable model

#### Scenario: Secrets are protected

- **WHEN** the doctor reports provider availability
- **THEN** it prints only provider identity and stored/authenticated status and never prints tokens, keys, or `opencode auth export` output

#### Scenario: Unsupported integration is encountered

- **WHEN** a required integration is unsupported on the detected platform or agent
- **THEN** the doctor marks it BLOCKED or unsupported with actionable guidance rather than claiming success

### Requirement: Bootstrap is safe, idempotent, and verifiable

The starter SHALL provide `scripts/agentic-bootstrap.sh` that reads the manifest, detects OS and agent, runs the doctor, installs only missing or incompatible components from official sources at pinned versions, backs up configuration before modification, asks before elevated privileges, preserves unrelated user configuration, verifies each installation, reruns the doctor, and produces a readiness report. Repeated runs SHALL NOT create duplicate entries or change a compliant environment.

#### Scenario: Bootstrap runs twice

- **WHEN** the bootstrap is executed twice on an already compliant fixture
- **THEN** the second run makes no installation or configuration changes and reports READY

#### Scenario: Elevated privileges are needed

- **WHEN** an installation method requires elevation
- **THEN** the bootstrap prompts the developer for permission and stops if permission is declined

#### Scenario: Installation fails

- **WHEN** an official install or verification command fails
- **THEN** the bootstrap reports the failing component, preserves backups, and gives actionable failure instructions

### Requirement: Global OpenCode plugins are reconciled from the manifest

Superpowers, Ponytail, and DCP SHALL be managed as global OpenCode plugins using official `opencode plugin list`, `add`, and `remove` commands. Stale manifest-managed entries SHALL be replaced or reconciled, unrelated entries SHALL be preserved, duplicate registrations SHALL NOT remain, wildcard or exclusion entries SHALL NOT be used, and effective versions SHALL be verified with `opencode plugin list`. Version requirements SHALL NOT be placed in project `opencode.json`.

#### Scenario: Unpinned Superpowers is present

- **WHEN** global configuration contains an unpinned Superpowers entry
- **THEN** the bootstrap backs up the configuration and replaces only that entry with the pinned manifest revision

#### Scenario: Duplicate plugins are found

- **WHEN** global configuration contains duplicate registrations for a manifest-managed plugin
- **THEN** the bootstrap reconciles them to exactly one pinned entry without touching unrelated plugins

#### Scenario: Project configuration is inspected

- **WHEN** a contributor inspects project `opencode.json`
- **THEN** it contains no plugin declarations, exclusions, or wildcard entries

### Requirement: Graphify is provisioned without always-on state

The bootstrap SHALL install the pinned Graphify CLI from the official `graphifyy` distribution. The starter SHALL NOT vendor the Graphify assistant skill, generate a graph, or run the always-on Graphify integration. A committed `.graphifyignore` SHALL exclude credentials, environment files, dependency directories, and build outputs, and generated Graphify output SHALL be Git-ignored.

#### Scenario: Developer prepares a real project

- **WHEN** a developer deliberately installs the OpenCode integration after a graph exists
- **THEN** documentation distinguishes that step from CLI installation and warns that it writes assistant guidance

#### Scenario: Empty starter is inspected

- **WHEN** a reviewer checks a fresh clone
- **THEN** no `graphify-out/` directory, vendored Graphify skill, credential, or generated dependency directory is present

### Requirement: RTK integration is checked before modification

The bootstrap SHALL install pinned RTK from the official release and SHALL check for a working OpenCode integration before changing it. It SHALL run the verified global OpenCode integration only when no working integration exists, verify functionality with `rtk gain`, and document `rtk bypass` as an unfiltered but tracked command. Global RTK configuration SHALL NOT be committed.

#### Scenario: Integration already works

- **WHEN** `rtk init --show` reports a working OpenCode integration
- **THEN** the bootstrap does not rerun integration setup

#### Scenario: Integration is missing

- **WHEN** RTK is installed but no OpenCode integration is present
- **THEN** the bootstrap runs `rtk init -g --opencode` and verifies it with `rtk gain`

### Requirement: Platform support is verified and honestly reported

OpenCode SHALL be the primary supported agent environment and Linux SHALL be supported first. Shared instructions and OpenSpec artifacts SHALL remain repository-based and reusable. The scripts SHALL detect OS and agent, use only verified installation paths, and report unsupported agents or platforms explicitly; OpenCode plugin behavior SHALL NOT be claimed for other agents without official support.

#### Scenario: Unsupported agent is detected

- **WHEN** the bootstrap detects an agent other than OpenCode
- **THEN** it reports that OpenCode plugins are not automatically supported there and stops rather than claiming readiness

#### Scenario: Shared instructions are inspected

- **WHEN** a developer uses another coding agent
- **THEN** repository instructions and OpenSpec artifacts remain available as shared, reusable files

### Requirement: Brevity heuristics do not override governance gates

Shared instructions SHALL state that Ponytail's "write less" and YAGNI guidance MUST NOT override OpenSpec requirements, acceptance criteria, architecture decisions, security controls, or quality gates. When the two conflict, the recorded requirements and gates SHALL take precedence.

#### Scenario: A minimal change would skip a required gate

- **WHEN** a brevity recommendation conflicts with an OpenSpec acceptance criterion or required validation
- **THEN** the contributor follows the acceptance criterion or validation and documents the conflict if relevant

#### Scenario: A security control looks verbose

- **WHEN** a brevity recommendation would remove validation, error handling, security, or accessibility behavior
- **THEN** the contributor retains that behavior and does not cite YAGNI as justification for removal

### Requirement: Global OpenCode configuration is detected
The readiness workflow SHALL locate the effective global OpenCode configuration file by preferring an existing `opencode.json` or `opencode.jsonc` under the global OpenCode configuration directory.

#### Scenario: JSONC configuration is present
- **WHEN** only `opencode.jsonc` exists in the global OpenCode configuration directory
- **THEN** the doctor and bootstrap use that file for global plugin reconciliation

#### Scenario: JSON configuration is present
- **WHEN** `opencode.json` exists in the global OpenCode configuration directory
- **THEN** the doctor and bootstrap use that file for global plugin reconciliation

### Requirement: Unrelated local plugin duplicates do not block readiness
The readiness workflow SHALL NOT treat duplicate registrations whose plugin list identity is `-` as a readiness blocker, because that identity represents unrelated local plugins rather than manifest-managed plugins.

#### Scenario: Graphify local plugin is duplicated
- **WHEN** `opencode plugin list` contains duplicate entries with identity `-`
- **THEN** readiness is not blocked solely by those entries

### Requirement: Bootstrap readiness follows the final doctor
The bootstrap SHALL determine its final success or failure from the final read-only doctor run rather than from an intermediate plugin verification step.

#### Scenario: Intermediate plugin check is stale
- **WHEN** an intermediate plugin verification reports a missing plugin that is present in the final doctor run
- **THEN** bootstrap does not fail solely because of the intermediate result

### Requirement: Project initialization command is available
The starter SHALL provide an OpenCode custom command named `starter-init` whose instructions are stored in `.opencode/command/starter-init.md`.

#### Scenario: Command file exists
- **WHEN** a developer opens a project created from the starter with OpenCode
- **THEN** `/starter-init` loads the instructions from `.opencode/command/starter-init.md`

### Requirement: Initialization cleanup requires explicit approval
The starter-init workflow SHALL require environment readiness, a reviewed cleanup plan, and explicit user approval before removing or modifying any file.

#### Scenario: Approval is not granted
- **WHEN** the user does not approve the cleanup plan
- **THEN** no files are removed or modified by the workflow

### Requirement: Optional starter Git history removal requires explicit approval
The starter-init workflow is the only permitted path for removing the starter's Git history; it MAY offer removal only after initialization cleanup is complete and only with a separate explicit user approval. The workflow SHALL preserve all working-tree files, SHALL NOT remove or alter project source or user-created files, and SHALL initialize a new repository without changing remotes or pushing. The workflow SHALL NOT remove Git history as part of default cleanup or without that approval.

#### Scenario: History removal is not approved
- **WHEN** the user does not explicitly approve starter history removal
- **THEN** the existing `.git` directory and all starter history remain unchanged

#### Scenario: History removal is approved
- **WHEN** the user explicitly approves starter history removal after setup
- **THEN** the workflow removes only `.git`, initializes a new repository, preserves all working-tree files, and does not push or alter remotes
