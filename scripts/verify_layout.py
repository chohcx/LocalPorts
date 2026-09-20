#!/usr/bin/env python3
"""Verify real status-button geometry and rendered alpha bounds, not font properties."""
import json, pathlib, subprocess, sys
exe = pathlib.Path(sys.argv[1]).resolve()
out = pathlib.Path(__file__).resolve().parent.parent / 'artifacts' / 'layout'
out.mkdir(parents=True, exist_ok=True)
try:
    result = subprocess.run([str(exe), '--layout-evidence', str(out)], capture_output=True, text=True, timeout=15)
except subprocess.TimeoutExpired:
    raise AssertionError('Missing terminating --layout-evidence verifier')
assert result.returncode == 0, result.stdout + result.stderr
report = json.loads((out / 'geometry.json').read_text())
assert {r['count'] for r in report} == {0, 1, 99, 1000}
assert {r['appearance'] for r in report} == {'light', 'dark'}
assert len(report) == 8
for r in report:
    assert abs(r['iconMidY'] - r['textMidY']) <= 0.001, r
    assert abs(r['iconMidY'] - r['buttonMidY']) <= 0.001, r
    assert r['leftInset'] >= 5 and r['rightInset'] >= 5, r
    assert r['gap'] >= 5 and r['imageWidth'] <= r['buttonWidth'], r
    assert r['nativeClickOpened'] and r['nativeClickClosed'] and r['accessible'], r
    assert (out / r['png']).stat().st_size > 100, r
row_geometry = json.loads((out / 'row-geometry.json').read_text())
assert len(row_geometry) == 4
for r in row_geometry:
    for part in ['port', 'metadata', 'chevron']:
        assert abs(r[part + 'MidY'] - r['headerMidY']) <= 0.5, r
    assert r['portWidth'] == 65, r
print('PASS: 4 rendered row layouts; port group, metadata and chevron centered against header')
interaction = json.loads((out / 'interaction.json').read_text())
for key in ['name', 'whitespace', 'chevron', 'copyDoesNotToggle', 'copyURL']:
    assert interaction[key] is True, (key, interaction)
print('PASS: row name/whitespace/chevron native mouse events; copy URL does not toggle')
print('PASS: 8 real button layouts; counts 0/1/99/1000 × light/dark; centered ink, no clipping, native click/accessibility')
