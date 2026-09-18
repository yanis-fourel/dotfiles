#!/usr/bin/env python3
"""Read-only desktop status; explicit profile changes via the existing D-Bus service."""
import datetime as dt
import email.utils
import json
import subprocess
import sys
import urllib.request
import xml.etree.ElementTree as ET
from pathlib import Path

SERVICE = ['net.hadess.PowerProfiles', '/net/hadess/PowerProfiles', 'net.hadess.PowerProfiles']


def run(*args):
    return subprocess.run(args, capture_output=True, text=True, timeout=10, check=True).stdout.strip()


def prop(name):
    return json.loads(run('busctl', '--system', '--json=short', 'get-property', *SERVICE, name))['data']


def power():
    profile = prop('ActiveProfile')
    batteries = []
    for battery in Path('/sys/class/power_supply').glob('BAT*'):
        batteries.append(f"{battery.name}: {battery.joinpath('capacity').read_text().strip()}% · {battery.joinpath('status').read_text().strip()}")
    return {'profile': profile, 'emoji': {'performance': '⚡', 'balanced': '⚖️', 'power-saver': '🍃'}.get(profile, '?'),
            'profiles': [p['Profile']['data'] for p in prop('Profiles')],
            'detail': '\n'.join(batteries) + '\n\nManaged by the existing power-profile service (TLP on this machine).'}


def bluetooth():
    controller = run('bluetoothctl', 'show')
    devices = run('bluetoothctl', 'devices', 'Connected').splitlines()
    names = [line.split(' ', 2)[2] for line in devices if line.startswith('Device ') and len(line.split(' ', 2)) == 3]
    powered = 'Powered: yes' in controller
    return {'label': '󰂯 ' + (str(len(names)) if names else ('on' if powered else 'off')),
            'detail': ('Bluetooth enabled' if powered else 'Bluetooth disabled') + '\n\n' + ('Connected:\n' + '\n'.join(names) if names else 'No connected devices.')}


def last_upgrade(path=Path('/var/log/pacman.log')):
    # A command invocation alone is not proof of a completed upgrade.
    pending = False
    transaction = False
    last = None
    with path.open(errors='replace') as log:
        for line in log:
            if '[PACMAN] Running ' in line:
                pending = False
                transaction = False
            if '[PACMAN] starting full system upgrade' in line:
                pending = True
            if pending and '[ALPM] transaction started' in line:
                transaction = True
            if pending and transaction and '[ALPM] transaction completed' in line:
                last = dt.datetime.fromisoformat(line.split(']', 1)[0][1:])
                pending = False
    return last


def updates():
    last = last_upgrade()
    now = dt.datetime.now(dt.timezone.utc)
    days = max(0, (now - last).days) if last else None
    result = {'label': '󰚰 ' + (f'{days}d' if days is not None else '?'), 'links': [],
              'detail': 'Last upgrade · ' + (last.strftime('%Y-%m-%d %H:%M') if last else 'unknown') + '\n'}
    try:
        req = urllib.request.Request('https://archlinux.org/feeds/news/', headers={'User-Agent': 'Quickshell-Arch-News/1.0'})
        with urllib.request.urlopen(req, timeout=15) as response:
            feed = ET.fromstring(response.read(2_000_000))
        items = feed.findall('./channel/item')
        recent = []
        for item in items:
            date = email.utils.parsedate_to_datetime(item.findtext('pubDate'))
            if last is None or date > last:
                recent.append(item)
        result['detail'] += f'News checked · {now.astimezone().strftime("%H:%M")}\n\n'
        result['detail'] += ('Latest announcements' if last is None else f'{len(recent)} new announcement(s) since your upgrade' if recent else 'No new announcements since your upgrade')
        for item in (recent or items)[:8]:
            url = item.findtext('link', '')
            if url.startswith('https://archlinux.org/'):
                result['links'].append({'label': email.utils.parsedate_to_datetime(item.findtext('pubDate')).strftime('%Y-%m-%d') + ' · ' + item.findtext('title', 'Arch news'), 'url': url})
    except Exception:
        result['detail'] += 'News unavailable · try refreshing.'
    return result


if __name__ == '__main__':
    try:
        mode = sys.argv[1]
        if mode == 'set-profile':
            profile = sys.argv[2]
            if profile not in ('power-saver', 'balanced', 'performance'):
                raise ValueError('Invalid profile')
            run('busctl', '--system', 'set-property', *SERVICE, 'ActiveProfile', 's', profile)
            result = {'detail': 'Power profile changed to ' + profile}
        else:
            result = {'power': power, 'bluetooth': bluetooth, 'updates': updates}[mode]()
        print(json.dumps({'ok': True, **result}))
    except Exception:
        print(json.dumps({'ok': False, 'detail': 'Operation unavailable or denied. Check the service and authorization.', 'label': '—'}))
