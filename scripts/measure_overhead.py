#!/usr/bin/env python3
"""Bounded real-system measurements. Does not retain listener names or paths."""
import json, pathlib, resource, statistics, subprocess, time
root = pathlib.Path(__file__).resolve().parent.parent
exe = str(root / 'dist/LocalPorts.app/Contents/MacOS/LocalPorts')
scans = []
for _ in range(7):
    before = resource.getrusage(resource.RUSAGE_CHILDREN)
    start = time.monotonic()
    result = subprocess.run([exe, '--diagnose'], capture_output=True, text=True, check=True, timeout=30)
    wall = time.monotonic() - start
    after = resource.getrusage(resource.RUSAGE_CHILDREN)
    scans.append(dict(wall_seconds=wall, cpu_seconds=(after.ru_utime+after.ru_stime)-(before.ru_utime+before.ru_stime), listeners=len(json.loads(result.stdout)['listeners'])))
def sample(args, seconds):
    process = subprocess.Popen([exe] + args, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    rows = []
    start = time.monotonic()
    try:
        while time.monotonic() - start < seconds and process.poll() is None:
            text = subprocess.check_output(['/bin/ps', '-p', str(process.pid), '-o', '%cpu=,rss='], text=True).strip()
            if text:
                cpu, rss = text.split()
                rows.append(dict(at_seconds=time.monotonic()-start, cpu_percent=float(cpu), rss_kb=int(rss)))
            time.sleep(0.5)
    finally:
        if process.poll() is None:
            process.terminate()
        process.wait(timeout=10)
    return dict(duration_seconds=time.monotonic()-start, samples=rows, mean_ps_cpu_percent=statistics.mean(r['cpu_percent'] for r in rows), max_rss_mb=max(r['rss_kb'] for r in rows)/1024)
report = dict(methodology='7 separate --diagnose processes: wall includes launch, scan and JSON encoding; RUSAGE_CHILDREN CPU delta includes terminated waited child processes and OS-accounted descendants, not unrelated processes. GUI ps CPU/RSS is app PID ONLY, excludes lsof/ps children; ps CPU is an OS rolling statistic, not an interval energy measurement. Closed sample includes startup and 10-second polling; open smoke sample lasts about 3 seconds, includes startup and is not a steady-state estimate. Fixtures are not used.', scans=scans, median_diagnose_wall_seconds=statistics.median(r['wall_seconds'] for r in scans), median_diagnose_cpu_seconds=statistics.median(r['cpu_seconds'] for r in scans), closed=sample([],22), open_startup_only=sample(['--ui-smoke-test'],4))
out = root / 'artifacts/overhead.json'
out.write_text(json.dumps(report, indent=2)+'\n')
print(json.dumps({k:v for k,v in report.items() if k not in ['closed','open_startup_only']}, indent=2))
for name in ['closed','open_startup_only']:
    print(name, {k:v for k,v in report[name].items() if k != 'samples'})
