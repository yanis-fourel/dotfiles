#!/usr/bin/env python3
"""Launch bar applications, reporting missing commands to the native QML prompt."""
import json
import os
from pathlib import Path
import shlex
import shutil
import subprocess
import sys

TOOLS = {
    'audio': ('org.pulseaudio.pavucontrol', 'pavucontrol', '760 520'),
    'bluetooth': ('quickshell-bluetui', 'kitty --class quickshell-bluetui --title Bluetooth -e bluetui', '700 460'),
    'wifi': ('quickshell-impala', 'kitty --class quickshell-impala --title Wi-Fi -e impala', '700 460'),
    'browser': ('', 'xdg-open', ''),
}
CONFIG = Path(os.environ.get('XDG_CONFIG_HOME', str(Path.home() / '.config'))) / 'quickshell/commands.json'


def dispatch(*args):
    subprocess.run(['hyprctl', 'dispatch', *args], check=True, capture_output=True, timeout=10)


def launch(tool, replacement=None, url=''):
    app_class, default, size = TOOLS[tool]
    try:
        saved = json.loads(CONFIG.read_text())
        if not isinstance(saved, dict):
            raise ValueError('commands.json must contain an object')
    except FileNotFoundError:
        saved = {}
    command = replacement if replacement is not None else saved.get(tool, default)
    argv = shlex.split(command)
    if not argv:
        return {'ok': False, 'command': command, 'error': 'Enter a command.'}
    required = [argv[0]]
    # Validate the nested default terminal program as well as its terminal.
    if tool in ('bluetooth', 'wifi') and command == default:
        required.append('bluetui' if tool == 'bluetooth' else 'impala')
    missing = [name for name in required if not shutil.which(name)]
    if missing:
        return {'ok': False, 'command': command, 'error': 'Not found: ' + ', '.join(missing)}
    if tool == 'browser':
        if not url.startswith('https://archlinux.org/'):
            raise ValueError('Invalid news URL')
        subprocess.Popen(argv + [url], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, start_new_session=True)
    else:
        clients = json.loads(subprocess.check_output(['hyprctl', 'clients', '-j'], timeout=10))
        existing = next((c for c in clients if command == default and
                         (c['class'] == app_class or (tool == 'audio' and 'pavucontrol' in c['class'].lower()))), None)
        if existing:
            selector = 'address:' + existing['address']
            dispatch('setfloating', selector)
            dispatch('focuswindow', selector)
        else:
            dispatch('exec', f'[float; size {size}; center] {shlex.join(argv)}')
    if replacement is not None:
        saved[tool] = command
        CONFIG.parent.mkdir(parents=True, exist_ok=True)
        temporary = CONFIG.with_suffix('.json.tmp')
        temporary.write_text(json.dumps(saved, indent=2) + '\n')
        temporary.replace(CONFIG)
    return {'ok': True}


if __name__ == '__main__':
    try:
        print(json.dumps(launch(sys.argv[1], sys.argv[2] or None if len(sys.argv) > 2 else None,
                                sys.argv[3] if len(sys.argv) > 3 else '')))
    except Exception as error:
        print(json.dumps({'ok': False, 'error': str(error), 'command': ''}))
