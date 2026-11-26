#!/usr/bin/env bash
# Provision the repository-controlled agent toolchain.
# All mutations are explicit, reversible, version-pinned, and driven by .agentic/toolchain.json.
set -uo pipefail

# Preserve the caller's stdin for permission prompts; the heredoc below carries Python source.
exec 3<&0

exec python3 - "$@" <<'PY'
import json
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

try:
    PROMPT_STREAM = os.fdopen(3, "r", closefd=False)
except OSError:
    PROMPT_STREAM = sys.stdin

ROOT = Path(os.environ.get("AGENTIC_PROJECT_ROOT", os.getcwd())).resolve()
MANIFEST_PATH = Path(
    os.environ.get("TOOLCHAIN_MANIFEST", ROOT / ".agentic" / "toolchain.json")
).resolve()
DOCTOR = Path(os.environ.get("AGENTIC_DOCTOR", ROOT / "scripts" / "agentic-doctor.sh")).resolve()
def default_global_config():
    base = Path.home() / ".config" / "opencode"
    for name in ("opencode.json", "opencode.jsonc"):
        candidate = base / name
        if candidate.is_file():
            return candidate
    return base / "opencode.json"


_env_global_config = os.environ.get("AGENTIC_GLOBAL_CONFIG", "").strip()
GLOBAL_CONFIG = (
    Path(_env_global_config).resolve() if _env_global_config else default_global_config().resolve()
)
SKILLS_SOURCE = Path(os.environ["AGENTIC_SKILLS_SOURCE"]).resolve() if os.environ.get("AGENTIC_SKILLS_SOURCE") else None
ASSUME_YES = os.environ.get("AGENTIC_ASSUME_YES", "0") == "1"

changed = False
healthy = True


def run(args, shell=False):
    try:
        proc = subprocess.run(args, shell=shell, capture_output=True, text=True, check=False)
        return proc.returncode, proc.stdout.strip()
    except FileNotFoundError:
        return 127, ""
    except OSError as exc:
        return 126, str(exc)


def version_tuple(text):
    match = re.search(r"(\d+)\.(\d+)\.(\d+)", text or "")
    return tuple(int(part) for part in match.groups()) if match else None


def plugin_identity(spec):
    spec = spec.strip()
    if spec.startswith("@"):
        index = spec.find("@", 1)
        return spec[:index] if index > 0 else spec
    return spec.split("@", 1)[0]


def plugin_version(spec):
    if spec.startswith("@"):
        return spec.rsplit("@", 1)[1]
    if "#" in spec:
        return spec.rsplit("#", 1)[1]
    parts = spec.split("@", 1)
    return parts[1] if len(parts) > 1 else ""


def version_matches(actual, expected):
    actual = (actual or "").strip()
    expected = (expected or "").strip()
    if not actual or not expected:
        return False
    if actual == expected:
        return True
    if re.fullmatch(r"[0-9a-fA-F]{40}", expected) and re.fullmatch(r"[0-9a-fA-F]{7,40}", actual):
        return expected.lower().startswith(actual.lower())
    return False


def strip_json_comments(text):
    result = []
    i = 0
    n = len(text)
    in_string = False
    while i < n:
        ch = text[i]
        if in_string:
            result.append(ch)
            if ch == "\\\\" and i + 1 < n:
                result.append(text[i + 1])
                i += 2
                continue
            if ch == '"':
                in_string = False
            i += 1
        else:
            if ch == '"':
                in_string = True
                result.append(ch)
                i += 1
            elif ch == "/" and i + 1 < n and text[i + 1] == "/":
                while i < n and text[i] != "\n":
                    i += 1
            elif ch == "/" and i + 1 < n and text[i + 1] == "*":
                i += 2
                while i + 1 < n and not (text[i] == "*" and text[i + 1] == "/"):
                    i += 1
                i += 2
            else:
                result.append(ch)
                i += 1
    return "".join(result)


def load_json_config(path):
    text = path.read_text(encoding="utf-8")
    try:
        return json.loads(text)
    except json.JSONDecodeError:
        return json.loads(strip_json_comments(text))


def detect_agent(policy):
    for var in policy.get("agentDetection", {}).get("envVars", []):
        value = os.environ.get(var, "").strip()
        if value:
            return value, f"declared via {var}"
    markers = policy.get("agentDetection", {}).get("opencodeMarkers", [])
    if any(os.environ.get(var) for var in markers):
        return "opencode", "environment marker"
    return "opencode", "assumed"


def action(message):
    global changed
    print(f"[action] {message}")
    changed = True


def block(message, next_step=None):
    global healthy
    healthy = False
    print(f"BLOCK: {message}")
    if next_step:
        print(f"NEXT: {next_step}")


try:
    manifest = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
except (OSError, json.JSONDecodeError) as exc:
    print(f"STOP: toolchain manifest unreadable: {exc}")
    sys.exit(2)

components = {item["id"]: item for item in manifest.get("components", [])}
global_plugins = manifest.get("globalPlugins", [])
policy = manifest.get("platformPolicy", {})

print(f"manifest: {MANIFEST_PATH}")

# Platform and agent checks come before anything that could mutate a machine.
os_code, os_name = run(["uname", "-s"])
detected_os = (os_name or "unknown").lower()
if detected_os.startswith("linux"):
    detected_os = "linux"
elif detected_os.startswith("darwin"):
    detected_os = "darwin"
supported_os = policy.get("supportedOs", [])
if detected_os not in supported_os:
    print(f"unsupported platform: {os_name or 'unknown'}")
    print("STOP: unsupported platform; provision this toolchain manually after platform support is verified")
    sys.exit(2)

agent_name, agent_source = detect_agent(policy)
print(f"agent: {agent_name} ({agent_source})")
supported_agents = policy.get("supportedAgents", [])
if agent_name not in supported_agents:
    print(f"unsupported agent: {agent_name}")
    print("STOP: unsupported agent; use a supported agent or set AGENTIC_ACTIVE_AGENT explicitly")
    sys.exit(2)

code, out = run(["opencode", "--version"])
if code != 0 or not out:
    print("STOP: OpenCode is required before bootstrap can manage plugins")
    print("NEXT: follow https://opencode.ai/docs/cli/ and re-run this script")
    sys.exit(2)

# Initial read-only diagnosis.
code, doctor_out = run([str(DOCTOR)])
print(f"initial doctor: {'READY' if code == 0 else 'BLOCKED'}")
for line in doctor_out.splitlines():
    print(f"  doctor | {line}")

# Authentication is a manual gate. Bootstrap never bypasses or exports credentials.
code, auth_out = run(["opencode", "auth", "list"])
auth_lower = auth_out.lower()
no_provider = (
    code != 0
    or not auth_out
    or "no providers" in auth_lower
    or "not logged" in auth_lower
    or "not authenticated" in auth_lower
    or "no credentials" in auth_lower
)
if no_provider:
    print("STOP: model-provider authentication missing")
    print("NEXT: run `opencode auth login`, complete the provider prompts, then re-run bootstrap")
    sys.exit(2)

code, models_out = run(["opencode", "models"])
models = [line.strip() for line in models_out.splitlines() if line.strip()]
usable_models = [
    line for line in models
    if re.match(r"^[A-Za-z0-9_.-]+/[A-Za-z0-9_.:-]+(?:\s|$)", line)
]
if code != 0 or not usable_models:
    print("STOP: usable model unavailable")
    print("NEXT: authenticate a provider with `opencode auth login` or configure a local model, then re-run bootstrap")
    sys.exit(2)


def current_version(args, pattern=r"(\d+\.\d+\.\d+)"):
    code, out = run(args)
    if code != 0:
        return None, out
    match = re.search(pattern, out or "")
    return (match.group(1) if match else None), out


def install_component(component):
    cid = component["id"]
    version = component.get("version", {})
    expected_raw = version.get("exact") or version.get("minimum")
    method = component.get("install", {}).get("method", "")
    command = component.get("install", {}).get("command", "")

    if cid == "opencode":
        code, out = run(["opencode", "--version"])
        actual = version_tuple(out)
        minimum = version_tuple(version.get("minimum", ""))
        if actual and (not minimum or actual >= minimum):
            return True
        block("OpenCode version below the supported minimum", "Follow https://opencode.ai/docs/cli/ to upgrade OpenCode")
        return False

    if cid == "openspec":
        actual, out = current_version(["openspec", "--version"])
        expected = version.get("exact", "")
        if actual == expected:
            return True
        next_step = f"Run `{command}` manually if automatic installation is not permitted"
    elif cid == "graphify":
        actual, out = current_version(["graphify", "--version"])
        expected = version.get("exact", "")
        if actual == expected:
            return True
        next_step = f"Run `{command}` manually if automatic installation is not permitted"
    elif cid == "rtk":
        actual, out = current_version(["rtk", "--version"])
        expected = version.get("exact", "").lstrip("v")
        if actual == expected:
            return True
        next_step = f"Run `{command}` manually if automatic installation is not permitted"
    elif cid == "openspec-skills":
        return True
    else:
        return True

    elevation = component.get("install", {}).get("elevation", "never")
    if elevation == "prompt" and not ASSUME_YES:
        try:
            print(f"Install {cid} ({expected}) now? [y/N] ", end="", flush=True)
            answer = PROMPT_STREAM.readline().strip().lower()
        except (EOFError, OSError):
            answer = ""
        if answer not in {"y", "yes"}:
            print(f"permission denied for {cid}")
            print(f"NEXT: {next_step}")
            return False

    action(f"install {cid}")
    print(f"  command | {command}")
    code, install_out = run(command, shell=True)
    if install_out:
        print(f"  install | {install_out.splitlines()[-1]}")
    if code != 0:
        block(f"install failed for {cid}", next_step)
        return False

    if cid == "openspec":
        actual, _ = current_version(["openspec", "--version"])
    elif cid == "graphify":
        actual, _ = current_version(["graphify", "--version"])
    elif cid == "rtk":
        actual, _ = current_version(["rtk", "--version"])
    if actual != expected:
        block(f"verification failed for {cid}: got {actual or 'missing'}, expected {expected}", next_step)
        return False
    return True


for component_id in ("opencode", "openspec", "graphify", "rtk"):
    component = components.get(component_id)
    if component and not install_component(component):
        print("STOP: bootstrap halted after an install or verification failure")
        print("NEXT: resolve each BLOCK line, then re-run `scripts/agentic-bootstrap.sh`")
        sys.exit(1)

# Project-level skills are repository-controlled; restore them from the checked-out source.
skills_component = components.get("openspec-skills", {})
skills_dir = ROOT / skills_component.get("integration", {}).get("path", ".agents/skills")
for skill in skills_component.get("integration", {}).get("expected", []):
    target = skills_dir / skill / "SKILL.md"
    if target.is_file():
        continue
    source = SKILLS_SOURCE / skill / "SKILL.md" if SKILLS_SOURCE else None
    if source and source.is_file():
        action(f"install skill {skill}")
        shutil.copytree(source.parent, target.parent, dirs_exist_ok=True)
        if not target.is_file():
            block(f"verification failed for skill {skill}", "Restore the skill from the repository checkout")
    else:
        rel = target.relative_to(ROOT)
        git_code, git_out = run(["git", "-C", str(ROOT), "show", f"HEAD:{rel.as_posix()}"])
        if git_code == 0 and git_out:
            action(f"install skill {skill}")
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text(git_out.rstrip("\n") + "\n", encoding="utf-8")
            if not target.is_file():
                block(f"verification failed for skill {skill}", "Restore the skill from the repository checkout")
        else:
            block(f"missing skill: {skill}", f"Run `git checkout -- {rel}` from the repository root")


def backup_config():
    if not GLOBAL_CONFIG.is_file():
        return
    candidate = GLOBAL_CONFIG.with_name(GLOBAL_CONFIG.name + ".bak")
    index = 1
    while candidate.exists():
        candidate = GLOBAL_CONFIG.with_name(f"{GLOBAL_CONFIG.name}.bak.{index}")
        index += 1
    shutil.copy2(GLOBAL_CONFIG, candidate)
    action("backup: created")


try:
    config = load_json_config(GLOBAL_CONFIG) if GLOBAL_CONFIG.is_file() else {}
except (OSError, json.JSONDecodeError) as exc:
    config = {}
    block(f"global config unreadable: {exc}", f"Inspect {GLOBAL_CONFIG} and repair it manually")

specs = config.get("plugins", []) if isinstance(config, dict) else []
if not isinstance(specs, list):
    specs = []

for spec in list(specs):
    if isinstance(spec, str) and (spec.startswith("-") or "*" in spec):
        backup_config()
        action(f"remove plugin exclusion {spec}")
        run(["opencode", "plugin", "remove", spec])

for plugin in global_plugins:
    identity = plugin["identity"]
    expected_spec = plugin["package"]
    matches = [spec for spec in specs if isinstance(spec, str) and plugin_identity(spec) == identity]
    if len(matches) == 1 and matches[0] == expected_spec:
        continue
    if matches:
        backup_config()
        for spec in matches:
            action(f"remove plugin {spec}")
            run(["opencode", "plugin", "remove", spec])
    else:
        backup_config()
    action(f"add plugin {expected_spec}")
    run(["opencode", "plugin", "add", expected_spec])

# Verify effective plugin registrations from the agent's own inventory.
code, plugin_out = run(["opencode", "plugin", "list"])
plugin_lines = [line.strip() for line in plugin_out.splitlines() if line.strip()]
versions = {}
counts = {}
for line in plugin_lines:
    parts = line.split()
    if len(parts) < 2:
        continue
    list_id = parts[0]
    if list_id in ("ID", "NAME"):
        continue
    counts[list_id] = counts.get(list_id, 0) + 1
    versions[list_id] = parts[1]

for plugin in global_plugins:
    identity = plugin["identity"]
    list_id = plugin.get("listId", identity)
    version = versions.get(list_id)
    expected = plugin["expectedVersion"]
    if not version:
        block(f"plugin verification failed: {identity} missing", "Re-run bootstrap or use `opencode plugin list` to inspect")
    elif not version_matches(version, expected):
        block(f"plugin verification failed: {identity} {version}", f"Expected {expected}")
for identity, count in sorted(counts.items()):
    if identity in ("", "-"):
        continue
    if count > 1:
        block(f"duplicate plugin: {identity}", "Run `opencode plugin remove <specifier>` for the duplicate entry")

# RTK integration is configured only when the read-only status check reports it missing.
rtk_component = components.get("rtk", {})
code, status_out = run(["rtk", "init", "--show"])
opencode_status_lines = [
    line.strip().lower()
    for line in status_out.splitlines()
    if "opencode:" in line.lower()
]
not_configured = any(
    marker in line
    for line in opencode_status_lines
    for marker in ("not found", "not configured", "no opencode integration")
)
missing_integration = (
    code != 0
    or not any(line.startswith("[ok] opencode:") for line in opencode_status_lines)
    or not_configured
)
if missing_integration:
    action("configure RTK integration")
    configure_command = rtk_component.get("integration", {}).get("configureCommand", "rtk init -g --opencode")
    code, configure_out = run(configure_command, shell=True)
    if configure_out:
        print(f"  rtk | {configure_out.splitlines()[-1]}")
    if code != 0:
        block("RTK integration configuration failed", f"Run `{configure_command}` manually")
    code, status_out = run(["rtk", "init", "--show"])
    verify_lines = [
        line.strip().lower()
        for line in status_out.splitlines()
        if "opencode:" in line.lower()
    ]
    if code != 0 or not any(line.startswith("[ok] opencode:") for line in verify_lines):
        block("RTK integration verification failed", "Run `rtk init --show` to inspect the integration")

code, gain_out = run(["rtk", "gain"])
gain_lower = gain_out.lower()
if code != 0 or ("rtk token savings" not in gain_lower and "tokens saved:" not in gain_lower):
    block("RTK verification failed", "Run `rtk gain` to inspect the command filter")

# Final read-only diagnosis and readiness report.
code, final_out = run([str(DOCTOR)])
print(f"final doctor: {'READY' if code == 0 else 'BLOCKED'}")
for line in final_out.splitlines():
    print(f"  doctor | {line}")

if not changed and code == 0:
    print("no changes required")

if code == 0:
    print("READY: environment requirements satisfied")
    sys.exit(0)

print("BLOCKED: environment requirements unsatisfied")
print("NEXT: resolve each BLOCK line, then re-run `scripts/agentic-doctor.sh` and `scripts/agentic-bootstrap.sh`")
sys.exit(1)
PY
