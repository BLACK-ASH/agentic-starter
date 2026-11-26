#!/usr/bin/env bash
# Read-only environment report for the repository-controlled agent toolchain.
# This script never installs, configures, or authenticates anything.
set -uo pipefail

exec python3 - "$@" <<'PY'
import json
import os
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(os.environ.get("AGENTIC_PROJECT_ROOT", os.getcwd())).resolve()
MANIFEST_PATH = Path(
    os.environ.get("TOOLCHAIN_MANIFEST", ROOT / ".agentic" / "toolchain.json")
).resolve()


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

report = []
blockers = []


def note(line):
    report.append(line)


def block(line):
    if line not in blockers:
        blockers.append(line)


def run(args):
    try:
        proc = subprocess.run(args, capture_output=True, text=True, check=False)
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
        first = spec.find("@", 1)
        return spec[:first] if first > 0 else spec
    return spec.split("@", 1)[0]


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


try:
    manifest = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
except (OSError, json.JSONDecodeError) as exc:
    print(f"manifest: unreadable: {exc}")
    print("BLOCKED")
    sys.exit(1)

components = {item["id"]: item for item in manifest.get("components", [])}
required = [item for item in manifest.get("components", []) if item.get("requirement") == "required"]
global_plugins = manifest.get("globalPlugins", [])
project_plugins = manifest.get("projectPlugins", [])
recommended = manifest.get("recommendedIntegrations", [])

policy = manifest.get("platformPolicy", {})
note(f"manifest: {MANIFEST_PATH}")
note(f"platform policy: {', '.join(policy.get('supportedOs', [])) or 'unspecified'}")

agent_name, agent_source = detect_agent(policy)
note(f"agent: {agent_name} ({agent_source})")
supported_agents = policy.get("supportedAgents", [])
if agent_name not in supported_agents:
    block(f"unsupported agent: {agent_name}")

# Operating system support is checked before tool checks so unsupported
# platforms are never presented as merely "missing tools".
os_code, os_name = run(["uname", "-s"])
detected_os = (os_name or "unknown").lower()
if detected_os.startswith("linux"):
    detected_os = "linux"
elif detected_os.startswith("darwin"):
    detected_os = "darwin"
supported_os = manifest.get("platformPolicy", {}).get("supportedOs", [])
if detected_os not in supported_os:
    block(f"unsupported platform: {os_name or 'unknown'}")
note(f"detected platform: {detected_os}")

# OpenCode and OpenSpec CLI versions.
code, out = run(["opencode", "--version"])
oc_version = version_tuple(out)
if oc_version is None:
    note("OpenCode: missing")
    block("OpenCode missing")
else:
    note(f"OpenCode: {'.'.join(map(str, oc_version))}")
    minimum = version_tuple(components.get("opencode", {}).get("version", {}).get("minimum", ""))
    if minimum and oc_version < minimum:
        block(f"OpenCode version below minimum {'.'.join(map(str, minimum))}")

code, out = run(["openspec", "--version"])
ospec_version = version_tuple(out)
expected_ospec = version_tuple(components.get("openspec", {}).get("version", {}).get("exact", ""))
if ospec_version is None:
    note("OpenSpec CLI: missing")
    block("OpenSpec CLI missing")
else:
    note(f"OpenSpec CLI: {'.'.join(map(str, ospec_version))}")
    if expected_ospec and ospec_version != expected_ospec:
        block(f"OpenSpec CLI expected {'.'.join(map(str, expected_ospec))}")

# Project-level OpenSpec skills.
skills_component = components.get("openspec-skills", {})
skills_dir = ROOT / skills_component.get("integration", {}).get("path", ".agents/skills")
expected_skills = skills_component.get("integration", {}).get("expected", [])
present_skills = []
for skill in expected_skills:
    if (skills_dir / skill / "SKILL.md").is_file():
        present_skills.append(skill)
    else:
        block(f"missing skill: {skill}")
note(f"skills: {len(present_skills)}")

# Graphify CLI.
code, out = run(["graphify", "--version"])
graphify_version = version_tuple(out)
expected_graphify = version_tuple(components.get("graphify", {}).get("version", {}).get("exact", ""))
if graphify_version is None:
    note("Graphify: missing")
    block("Graphify missing")
else:
    rendered = ".".join(map(str, graphify_version))
    note(f"Graphify: {rendered}")
    if expected_graphify and graphify_version != expected_graphify:
        block(f"Graphify expected {'.'.join(map(str, expected_graphify))}")

# RTK CLI, integration status, and functional check.
code, out = run(["rtk", "--version"])
rtk_match = re.search(r"(\d+\.\d+\.\d+)", out or "")
expected_rtk_raw = components.get("rtk", {}).get("version", {}).get("exact", "")
expected_rtk = expected_rtk_raw.lstrip("v")
if not rtk_match:
    note("RTK: missing")
    block("RTK missing")
else:
    rendered = rtk_match.group(1)
    note(f"RTK: {rendered}")
    if expected_rtk and rendered != expected_rtk:
        block(f"RTK: {rendered}")
        block(f"expected {expected_rtk_raw}")

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
integration_ok = (
    code == 0
    and any(line.startswith("[ok] opencode:") for line in opencode_status_lines)
    and not not_configured
)
if not integration_ok:
    note("RTK integration: missing")
    block("RTK integration missing")
else:
    note("RTK integration: configured")
code, gain_out = run(["rtk", "gain"])
gain_lower = gain_out.lower()
if code != 0 or ("rtk token savings" not in gain_lower and "tokens saved:" not in gain_lower):
    block("rtk gain verification failed")

# Plugin inventory from the effective OpenCode configuration.
code, plugin_out = run(["opencode", "plugin", "list"])
plugin_lines = [line.strip() for line in plugin_out.splitlines() if line.strip()]
version_by_identity = {}
identity_counts = {}
for line in plugin_lines:
    parts = line.split()
    if len(parts) < 2:
        continue
    identity = parts[0]
    if identity in ("ID", "NAME"):
        continue
    identity_counts[identity] = identity_counts.get(identity, 0) + 1
    version_by_identity[identity] = parts[1]

for plugin in global_plugins:
    identity = plugin["identity"]
    list_id = plugin.get("listId", identity)
    version = version_by_identity.get(list_id)
    expected = plugin.get("expectedVersion", "")
    if not version:
        label = "DCP" if plugin["id"] == "dcp" else plugin["id"].capitalize()
        note(f"{label}: missing")
        block(f"plugin missing: {identity}")
        continue
    label = "DCP" if plugin["id"] == "dcp" else plugin["id"].capitalize()
    note(f"{label}: {version}")
    if not version_matches(version, expected):
        block(f"{identity} expected {expected}")

for identity, count in sorted(identity_counts.items()):
    if identity in ("", "-"):
        continue
    if count > 1:
        block(f"duplicate plugin: {identity}")

# Raw configuration duplicates, wildcards, and project-level declarations.
try:
    config = load_json_config(GLOBAL_CONFIG) if GLOBAL_CONFIG.is_file() else {}
except (OSError, json.JSONDecodeError) as exc:
    config = {}
    block(f"global config unreadable: {exc}")

configured_specs = config.get("plugins", []) if isinstance(config, dict) else []
configured_identities = {}
for spec in configured_specs:
    if not isinstance(spec, str):
        continue
    if spec.startswith("-") or "*" in spec:
        block(f"wildcard plugin exclusion: {spec}")
        continue
    identity = plugin_identity(spec)
    configured_identities[identity] = configured_identities.get(identity, 0) + 1
for identity, count in sorted(configured_identities.items()):
    if identity in ("", "-"):
        continue
    if count > 1:
        block(f"duplicate plugin: {identity}")

if project_plugins:
    block("project plugin declarations must remain empty")

for plugin_spec in project_plugins:
    if isinstance(plugin_spec, str) and (plugin_spec.startswith("-") or "*" in plugin_spec):
        block(f"wildcard plugin exclusion: {plugin_spec}")

note(f"plugin conflicts: {'none' if not [b for b in blockers if 'plugin' in b] else 'detected'}")

# Model-provider availability: report presence only, never credentials.
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
    note("provider: missing")
    block("model-provider authentication missing")
else:
    note("provider: authenticated")

code, models_out = run(["opencode", "models"])
models = [line.strip() for line in models_out.splitlines() if line.strip()]
usable_models = [
    line for line in models
    if re.match(r"^[A-Za-z0-9_.-]+/[A-Za-z0-9_.:-]+(?:\s|$)", line)
]
if code != 0 or not usable_models:
    note("usable model: no")
    block("usable model unavailable")
else:
    note(f"usable model: yes ({len(usable_models)} available)")

note(f"optional integrations: {', '.join(recommended) if recommended else 'none'}")

# Optional integrations are advisory; unsupported platforms are handled above.
for component in manifest.get("components", []):
    if component.get("requirement") != "optional":
        continue
    kind = component.get("integration", {}).get("type")
    if kind == "recommendation":
        continue
    note(f"optional integration needs review: {component['id']}")

for line in report:
    print(line)

if blockers:
    for item in blockers:
        print(f"BLOCK: {item}")
    print("BLOCKED")
    sys.exit(1)

print("READY")
PY
