#!/usr/bin/env python3
"""Repo-specific Python lint checks driven by *.pycheck.json files."""

from __future__ import annotations

import ast
import json
import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
IGNORED_PARTS = {
    ".git",
    ".pytest_cache",
    "__pycache__",
    "node_modules",
    ".venv",
    "venv",
}


def rel(path: Path) -> str:
    return path.relative_to(ROOT).as_posix()


def expand(patterns: list[str]) -> list[Path]:
    files: list[Path] = []
    for pattern in patterns:
        files.extend(
            path
            for path in ROOT.glob(pattern)
            if path.is_file() and not any(part in IGNORED_PARTS for part in path.parts)
        )
    return sorted({path.resolve() for path in files})


def load_configs(rule_dir: Path) -> list[tuple[Path, dict]]:
    configs: list[tuple[Path, dict]] = []
    for path in sorted(rule_dir.glob("*.pycheck.json")):
        configs.append((path, json.loads(path.read_text())))
    return configs


def scan_regex(path: Path, patterns: list[str]) -> list[str]:
    text = path.read_text()
    violations: list[str] = []
    for pattern in patterns:
        regex = re.compile(pattern)
        for number, line in enumerate(text.splitlines(), start=1):
            if regex.search(line):
                violations.append(f"{rel(path)}:{number} matches {pattern}")
    return violations


def check_structured_errors(config: dict) -> list[str]:
    violations: list[str] = []
    for path in expand(config.get("include", [])):
        violations.extend(scan_regex(path, config.get("banned_regexes", [])))
    return violations


def check_public_docstrings(config: dict) -> list[str]:
    violations: list[str] = []
    for path in expand(config.get("include", [])):
        source = path.read_text()
        try:
            tree = ast.parse(source)
        except SyntaxError as exc:
            violations.append(f"{rel(path)}:{exc.lineno} syntax error: {exc.msg}")
            continue
        public_defs = [
            node
            for node in tree.body
            if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef))
            and not node.name.startswith("_")
        ]
        if public_defs and ast.get_docstring(tree) is None:
            violations.append(f"{rel(path)}: missing module docstring")
        for node in public_defs:
            if ast.get_docstring(node) is None:
                violations.append(
                    f"{rel(path)}:{node.lineno} missing docstring for {node.name}()"
                )
    return violations


def check_file_placement(config: dict) -> list[str]:
    allowed = tuple(config.get("allowed_prefixes", []))
    exempt = tuple(config.get("exempt_prefixes", []))
    violations: list[str] = []
    for path in ROOT.glob("**/*.py"):
        if not path.is_file():
            continue
        if any(part in IGNORED_PARTS for part in path.parts):
            continue
        relative = rel(path)
        if relative.startswith(exempt):
            continue
        if not relative.startswith(allowed):
            violations.append(
                f"{relative}: outside allowed product/test Python locations"
            )
    return violations


def check_naming_conventions(config: dict) -> list[str]:
    violations: list[str] = []
    snake = re.compile(r"^[a-z_][a-z0-9_]*$")
    pascal = re.compile(r"^[A-Z][A-Za-z0-9]*$")
    upper = re.compile(r"^[A-Z][A-Z0-9_]*$")

    for path in expand(config.get("include", [])):
        source = path.read_text()
        try:
            tree = ast.parse(source)
        except SyntaxError as exc:
            violations.append(f"{rel(path)}:{exc.lineno} syntax error: {exc.msg}")
            continue

        is_test_file = rel(path).startswith("tests/")
        for node in ast.walk(tree):
            if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)):
                if is_test_file and node.name.startswith("test_"):
                    continue
                if not snake.match(node.name):
                    violations.append(
                        f"{rel(path)}:{node.lineno} function '{node.name}' is not snake_case"
                    )
            elif isinstance(node, ast.ClassDef) and not pascal.match(node.name):
                violations.append(
                    f"{rel(path)}:{node.lineno} class '{node.name}' is not PascalCase"
                )

        for node in tree.body:
            if not isinstance(node, ast.Assign):
                continue
            for target in node.targets:
                if isinstance(target, ast.Name) and len(target.id) > 1:
                    if target.id.startswith("_") or target.id.islower():
                        continue
                    if not upper.match(target.id):
                        violations.append(
                            f"{rel(path)}:{target.lineno} constant '{target.id}' is not UPPER_SNAKE_CASE"
                        )
    return violations


def check_required_matches(config: dict) -> list[str]:
    violations: list[str] = []
    for raw in config.get("required_paths", []):
        path = ROOT / raw
        if not path.exists():
            violations.append(f"{raw}: required path missing")
    for check in config.get("checks", []):
        path = ROOT / check["path"]
        if not path.exists():
            violations.append(f"{check['path']}: file missing")
            continue
        text = path.read_text()
        if re.search(check["regex"], text, re.MULTILINE) is None:
            violations.append(
                f"{check['path']}: missing required match {check['regex']}"
            )
    return violations


def check_testability_policy(config: dict) -> list[str]:
    violations = check_required_matches(config)
    for path in expand(config.get("include", [])):
        violations.extend(scan_regex(path, config.get("banned_regexes", [])))
    return violations


RULE_HANDLERS = {
    "structured_errors": check_structured_errors,
    "public_docstrings": check_public_docstrings,
    "file_placement": check_file_placement,
    "naming_conventions": check_naming_conventions,
    "required_matches": check_required_matches,
    "testability_policy": check_testability_policy,
}


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: python_rules.py <rule_dir>")
        return 1

    rule_dir = (ROOT / sys.argv[1]).resolve()
    violations: list[str] = []
    for path, config in load_configs(rule_dir):
        rule_name = config.get("rule")
        handler = RULE_HANDLERS.get(rule_name)
        if handler is None:
            violations.append(f"{rel(path)}: unknown rule '{rule_name}'")
            continue
        violations.extend(handler(config))

    if violations:
        print("python structural checks: violations found")
        for violation in violations:
            print(f"  - {violation}")
        return 1

    print("python structural checks: all passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
