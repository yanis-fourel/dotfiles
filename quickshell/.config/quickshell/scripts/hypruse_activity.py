#!/usr/bin/env python3
"""Pi desktop-task telemetry. The hypruse server beacon is NOT a busy flag."""
import json
import os
from pathlib import Path
import subprocess
import sys
import time

ROOT = Path(os.environ.get('XDG_RUNTIME_DIR', f'/run/user/{os.getuid()}')) / 'pi-hypruse'


def identity(pid):
    stat = Path(f'/proc/{int(pid)}/stat').read_text()
    return stat[stat.rfind(')') + 2:].split()[19]


def collect(root=ROOT, now=None, identify=identity):
    now = time.time() * 1000 if now is None else now
    active, uncertain = [], False
    for path in root.glob('*.json'):
        if not path.stem.isdigit():
            continue
        try:
            state = json.loads(path.read_text())
            if str(identify(state['pid'])) != str(state['processStart']):
                uncertain = True
                continue
            if not 0 <= now - state['heartbeat'] < 5000:
                uncertain = True
                continue
            active.append(state)
        except (OSError, ValueError, KeyError, TypeError, IndexError):
            uncertain = True
    elapsed = max(0, int((now - min(s['started'] for s in active)) / 1000)) if active else 0
    return {'active': bool(active), 'uncertain': uncertain, 'elapsed': elapsed,
            'count': len(active), 'runs': [s['run'] for s in active]}


def stop():
    # Notify running Pi sessions AND immediately stop native desktop input.
    # Include stale leases too: a stalled Pi can process the request on recovery.
    ROOT.mkdir(mode=0o700, parents=True, exist_ok=True)
    runs = []
    for path in ROOT.glob('*.json'):
        if path.stem.isdigit():
            try:
                runs.append(json.loads(path.read_text())['run'])
            except (OSError, ValueError, KeyError):
                pass
    tmp = ROOT / f'stop.{os.getpid()}.tmp'
    tmp.write_text(json.dumps({'runs': runs}))
    tmp.replace(ROOT / 'stop.json')
    try:
        subprocess.run(['/usr/bin/hypruse', 'stop'], timeout=3, check=False)
    except (OSError, subprocess.TimeoutExpired):
        pass


if __name__ == '__main__':
    if sys.argv[1:] == ['stop']:
        stop()
    else:
        print(json.dumps(collect()))
