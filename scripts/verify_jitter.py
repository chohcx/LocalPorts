#!/usr/bin/env python3
"""Time-sample a real attached NSPopover, not source or a fixed-size window."""
import json, pathlib, subprocess, sys
exe = pathlib.Path(sys.argv[1]).resolve()
out = pathlib.Path(sys.argv[2] if len(sys.argv) > 2 else 'artifacts/jitter').resolve()
out.mkdir(parents=True, exist_ok=True)
r = subprocess.run([str(exe), '--jitter-evidence', str(out)], capture_output=True, text=True, timeout=25)
assert r.returncode == 0, r.stdout + r.stderr
rows = json.loads((out / 'frames.json').read_text())
errors = []
assert {r['phase'] for r in rows} == {'idle', 'first-open', 'both-open', 'scrolled-idle', 'first-close', 'second-close', 'second-open', 'polling', 'final-close', 'search'}
anchored = [r for r in rows if r['phase'] != 'scrolled-idle']
for field in ('nativeHeaderScreenY', 'contentTop', 'firstHeaderScreenY'):
    assert max(r[field] for r in anchored) - min(r[field] for r in anchored) <= 1, f'Header failed to retain/restore its anchor: {field}'
for phase in dict.fromkeys(r['phase'] for r in rows):
    data = [r for r in rows if r['phase'] == phase]
    heights = [r['height'] for r in data]
    changes = sum(abs(a-b) > 0.5 for a,b in zip(heights, heights[1:]))
    top_motion = max(r['firstHeaderScreenY'] for r in data) - min(r['firstHeaderScreenY'] for r in data)
    print(f'{phase}: samples={len(data)} height={min(heights):.1f}..{max(heights):.1f} resizeSteps={changes} headerMotion={top_motion:.1f}')
    if changes != 0:
        errors.append(f'{phase}: repeated native window resizing ({changes} steps)')
    for field in ('top', 'nativeHeaderScreenY'):
        motion = max(r[field] for r in data) - min(r[field] for r in data)
        if motion > 1:
            errors.append(f'{phase}: {field} moved {motion}pt')
    if top_motion > 1:
        errors.append(f'{phase}: header moved {top_motion}pt')
for field in ('x', 'y', 'width', 'height'):
    assert max(r[field] for r in rows) - min(r[field] for r in rows) <= 1, f'Fixed panel moved/resized: {field}'
assert 330 <= rows[0]['height'] <= 500, 'Bounded fixed viewport fits a 13-inch display'
for phase in ('first-open', 'first-close'):
    heights = [r['detailHeight'] for r in rows if r['phase'] == phase]
    low, high = min(heights), max(heights)
    intermediate = sorted(set(round(h, 2) for h in heights if low + 1 < h < high - 1))
    print(f'{phase}: detail height {low:.1f}..{high:.1f}, intermediate frames={intermediate}')
    assert low <= 1 and high > 100 and len(intermediate) >= 2, f'{phase}: no measured reveal/collapse animation'
assert not errors, '\n'.join(errors)
print('PASS: fixed native window/header, first/second/both disclosure, overflow actions reachable by scroll, search, two deterministic poll publications')
