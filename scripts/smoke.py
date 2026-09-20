#!/usr/bin/env python3
"""End-to-end checks: JSON/privacy and native popover smoke."""
import json, pathlib, subprocess, sys
exe = pathlib.Path(sys.argv[1]).resolve()
result = subprocess.run([str(exe), '--diagnose'], check=True, capture_output=True, text=True)
data = json.loads(result.stdout)
assert isinstance(data['listeners'], list)
assert data['schemaVersion'] == 1
assert 'arguments' not in result.stdout and 'commandLine' not in result.stdout
result = subprocess.run([str(exe), '--ui-smoke-test'], check=True, capture_output=True, text=True, timeout=25)
assert 'UI_SMOKE_OK' in result.stdout, result.stdout + result.stderr
print('PASS: diagnose JSON/privacy + native status item/popover/search/toggle render')
