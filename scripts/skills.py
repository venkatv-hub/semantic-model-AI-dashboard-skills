#!/usr/bin/env python3
"""Validate skills and generate the skills catalog.

Usage:
    python3 scripts/skills.py validate        # check every skills/*/SKILL.md
    python3 scripts/skills.py catalog         # regenerate CATALOG.md
    python3 scripts/skills.py catalog --check # fail if CATALOG.md is out of date (CI)

No third-party dependencies, so it runs anywhere Python 3.8+ is available.
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SKILLS_DIR = ROOT / "skills"
CATALOG = ROOT / "CATALOG.md"
MARKETPLACE = ROOT / ".claude-plugin" / "marketplace.json"

NAME_RE = re.compile(r"^[a-z0-9]+(-[a-z0-9]+)*$")
RESERVED_WORDS = ("anthropic", "claude")
MAX_NAME = 64
MAX_DESCRIPTION = 1024
MAX_BODY_LINES = 500
LINK_RE = re.compile(r"`((?:references|scripts|assets)/[A-Za-z0-9_\-./]+?)(?:#[\w\-]+)?`")

# Display order of groups in the catalog.
GROUPS = [
    ("Core", ("bi-",)),
    ("Platform builders", ("powerbi-", "tableau-", "looker-")),
    ("Finance", ("finance-",)),
    ("Supply chain", ("supply-chain-",)),
    ("Healthcare", ("healthcare-",)),
    ("Sales", ("sales-",)),
    ("HR", ("hr-",)),
]


def parse_frontmatter(text: str) -> tuple[dict, str]:
    """Parse simple `key: value` YAML frontmatter (single-line values)."""
    if not text.startswith("---\n"):
        raise ValueError("file must start with '---' frontmatter")
    end = text.find("\n---", 4)
    if end == -1:
        raise ValueError("frontmatter is not closed with '---'")
    block = text[4:end]
    body = text[end + 4 :].lstrip("\n")
    meta: dict[str, str] = {}
    for raw in block.splitlines():
        if not raw.strip() or raw.lstrip().startswith("#"):
            continue
        if ":" not in raw:
            raise ValueError(f"cannot parse frontmatter line: {raw!r}")
        key, value = raw.split(":", 1)
        value = value.strip()
        if len(value) >= 2 and value[0] == value[-1] and value[0] in "\"'":
            value = value[1:-1]
        meta[key.strip()] = value
    return meta, body


def load_skills() -> list[dict]:
    skills = []
    for skill_md in sorted(SKILLS_DIR.glob("*/SKILL.md")):
        text = skill_md.read_text(encoding="utf-8")
        meta, body = parse_frontmatter(text)
        skills.append({"dir": skill_md.parent, "meta": meta, "body": body})
    return skills


def validate() -> int:
    errors: list[str] = []
    warnings: list[str] = []

    for folder in sorted(p for p in SKILLS_DIR.iterdir() if p.is_dir()):
        if not (folder / "SKILL.md").exists():
            errors.append(f"{folder.name}: missing SKILL.md")

    try:
        skills = load_skills()
    except ValueError as exc:  # pragma: no cover - reported below
        print(f"ERROR: {exc}")
        return 1

    names = set()
    for skill in skills:
        folder = skill["dir"].name
        meta, body = skill["meta"], skill["body"]
        where = f"skills/{folder}/SKILL.md"
        name = meta.get("name", "")
        desc = meta.get("description", "")

        if not name:
            errors.append(f"{where}: missing 'name'")
        elif name != folder:
            errors.append(f"{where}: name '{name}' must equal folder name '{folder}'")
        if name and not NAME_RE.match(name):
            errors.append(f"{where}: name must be lowercase letters, digits and hyphens")
        if len(name) > MAX_NAME:
            errors.append(f"{where}: name longer than {MAX_NAME} characters")
        if any(word in name for word in RESERVED_WORDS):
            errors.append(f"{where}: name must not contain {RESERVED_WORDS}")
        if name in names:
            errors.append(f"{where}: duplicate name '{name}'")
        names.add(name)

        if not desc:
            errors.append(f"{where}: missing 'description'")
        elif len(desc) > MAX_DESCRIPTION:
            errors.append(f"{where}: description is {len(desc)} chars (max {MAX_DESCRIPTION})")
        if "<" in desc or ">" in desc:
            errors.append(f"{where}: description must not contain angle brackets")
        if desc and "use" not in desc.lower():
            warnings.append(f"{where}: description should say when to use the skill")

        body_lines = body.count("\n") + 1
        if body_lines > MAX_BODY_LINES:
            warnings.append(f"{where}: body has {body_lines} lines (aim for < {MAX_BODY_LINES})")

        for ref in sorted(set(LINK_RE.findall(body))):
            if not (skill["dir"] / ref).exists():
                errors.append(f"{where}: referenced file '{ref}' does not exist")

        if folder.endswith("-dashboard") and not (skill["dir"] / "references" / "metrics.md").exists():
            errors.append(f"skills/{folder}: domain skills need references/metrics.md")

    # Marketplace must list every skill exactly once.
    if MARKETPLACE.exists():
        data = json.loads(MARKETPLACE.read_text(encoding="utf-8"))
        listed = []
        for plugin in data.get("plugins", []):
            listed += [Path(p).name for p in plugin.get("skills", [])]
        missing = sorted(names - set(listed))
        extra = sorted(set(listed) - names)
        if missing:
            errors.append(f"marketplace.json: skills not listed: {', '.join(missing)}")
        if extra:
            errors.append(f"marketplace.json: listed skills that don't exist: {', '.join(extra)}")
    else:
        errors.append(".claude-plugin/marketplace.json is missing")

    for w in warnings:
        print(f"WARN  {w}")
    for e in errors:
        print(f"ERROR {e}")
    print(f"\n{len(skills)} skills checked, {len(errors)} error(s), {len(warnings)} warning(s).")
    return 1 if errors else 0


def short_description(desc: str) -> str:
    first = re.split(r"(?<=[.])\s", desc, maxsplit=1)[0]
    return first.replace("|", "\\|")


def group_of(name: str) -> str:
    for label, prefixes in GROUPS:
        if name.startswith(prefixes):
            return label
    return "Other"


def render_catalog(skills: list[dict]) -> str:
    lines = [
        "# Skills Catalog",
        "",
        "<!-- Generated by `python3 scripts/skills.py catalog`. Do not edit by hand. -->",
        "",
        f"{len(skills)} skills. Domain skills decide *what* a dashboard shows; core skills decide",
        "*how* it looks and how it is built on each platform.",
        "",
    ]
    order = [label for label, _ in GROUPS] + ["Other"]
    for label in order:
        members = [s for s in skills if group_of(s["meta"]["name"]) == label]
        if not members:
            continue
        lines += [f"## {label}", "", "| Skill | What it does |", "|---|---|"]
        for s in members:
            name = s["meta"]["name"]
            lines.append(f"| [`{name}`](skills/{name}/SKILL.md) | {short_description(s['meta']['description'])} |")
        lines.append("")
    return "\n".join(lines)


def catalog(check: bool) -> int:
    content = render_catalog(load_skills())
    if check:
        current = CATALOG.read_text(encoding="utf-8") if CATALOG.exists() else ""
        if current != content:
            print("CATALOG.md is out of date. Run: python3 scripts/skills.py catalog")
            return 1
        print("CATALOG.md is up to date.")
        return 0
    CATALOG.write_text(content, encoding="utf-8")
    print(f"Wrote {CATALOG.relative_to(ROOT)}")
    return 0


def main(argv: list[str]) -> int:
    if not argv or argv[0] in ("-h", "--help"):
        print(__doc__)
        return 0
    if argv[0] == "validate":
        return validate()
    if argv[0] == "catalog":
        return catalog(check="--check" in argv[1:])
    print(f"Unknown command: {argv[0]}\n{__doc__}")
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
