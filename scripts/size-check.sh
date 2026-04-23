#!/usr/bin/env bash
set -euo pipefail

python3 - <<'PY'
import ast
import re
import subprocess
import sys
from fnmatch import fnmatch
from pathlib import Path


ROOT = Path('.')
CONFIG_PATH = ROOT / '.ai-layer' / 'PROJECT_CONFIG.md'
CHECKED_SUFFIXES = {'.json', '.md', '.py', '.sh', '.toml', '.txt', '.yaml', '.yml'}
CHECKED_NAMES = {'Makefile'}
IGNORED_PARTS = {'.git', '.pytest_cache', '__pycache__', 'node_modules'}
EXEMPT_MARKER = '# EXEMPT: cohesive atomic unit'


def fail(message: str) -> None:
    print(f'FAIL: {message}')
    sys.exit(1)


def parse_config(text: str) -> tuple[int, int, list[tuple[str, int]]]:
    file_match = re.search(r'^- max_file_lines:\s*(\d+)$', text, re.MULTILINE)
    func_match = re.search(r'^- max_function_lines:\s*(\d+)$', text, re.MULTILINE)
    block_match = re.search(
        r'^- max_file_lines_exempt_globs:\n(?P<body>(?:\s+- .*\n)+)',
        text,
        re.MULTILINE,
    )
    if not file_match or not func_match:
        fail('max_file_lines or max_function_lines missing from .ai-layer/PROJECT_CONFIG.md')
    exemptions: list[tuple[str, int]] = []
    if block_match:
        for line in block_match.group('body').splitlines():
            match = re.match(r'\s+-\s+"([^"]+)":\s*(\d+)$', line)
            if match:
                exemptions.append((match.group(1), int(match.group(2))))
    return int(file_match.group(1)), int(func_match.group(1)), exemptions


def tracked_files() -> list[Path]:
    try:
        result = subprocess.run(
            ['git', 'ls-files'],
            check=True,
            capture_output=True,
            text=True,
            cwd=ROOT,
        )
        candidates = [ROOT / line for line in result.stdout.splitlines() if line]
    except Exception:
        candidates = [path for path in ROOT.rglob('*') if path.is_file()]

    files: list[Path] = []
    for path in candidates:
        if not path.is_file():
            continue
        if any(part in IGNORED_PARTS for part in path.parts):
            continue
        if path.suffix not in CHECKED_SUFFIXES and path.name not in CHECKED_NAMES:
            continue
        files.append(path)
    return sorted(files)


def relative(path: Path) -> str:
    return path.relative_to(ROOT).as_posix()


def file_limit_for(path: Path, default_limit: int, exemptions: list[tuple[str, int]]) -> int:
    rel = relative(path)
    limits = [limit for pattern, limit in exemptions if fnmatch(rel, pattern)]
    return max(limits) if limits else default_limit


def signature_has_exemption(path: Path, lines: list[str], node: ast.AST) -> bool:
    if not isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)):
        return False
    signature_end = node.body[0].lineno - 1 if node.body else node.lineno
    signature_lines = lines[node.lineno - 1:signature_end]
    return any(EXEMPT_MARKER in line for line in signature_lines)


def file_line_count(path: Path) -> int:
    return len(path.read_text().splitlines())


def python_function_violations(path: Path, limit: int) -> list[str]:
    text = path.read_text()
    try:
        tree = ast.parse(text)
    except SyntaxError as exc:
        return [f'{relative(path)}: parse error at line {exc.lineno}: {exc.msg}']
    lines = text.splitlines()
    violations: list[str] = []
    for node in ast.walk(tree):
        if not isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)):
            continue
        end_lineno = getattr(node, 'end_lineno', None)
        if end_lineno is None:
            continue
        length = end_lineno - node.lineno + 1
        if length <= limit or signature_has_exemption(path, lines, node):
            continue
        violations.append(
            f'{relative(path)}:{node.lineno} {node.name} has {length} lines (max {limit})'
        )
    return violations


if not CONFIG_PATH.exists():
    fail(f'missing config file: {CONFIG_PATH}')

max_file_lines, max_function_lines, exemptions = parse_config(CONFIG_PATH.read_text())
file_violations: list[str] = []
function_violations: list[str] = []

for path in tracked_files():
    count = file_line_count(path)
    file_limit = file_limit_for(path, max_file_lines, exemptions)
    if count > file_limit:
        file_violations.append(f'{relative(path)} has {count} lines (max {file_limit})')
    if path.suffix == '.py':
        function_violations.extend(python_function_violations(path, max_function_lines))

if file_violations or function_violations:
    print('size-check: violations found')
    if file_violations:
        print('Files:')
        for violation in file_violations:
            print(f'  - {violation}')
    if function_violations:
        print('Functions:')
        for violation in function_violations:
            print(f'  - {violation}')
    sys.exit(1)

print('size-check: all passed')
PY
