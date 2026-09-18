#!/usr/bin/env python3
"""Read CPU hwmon temperatures without querying unrelated hardware sensors."""
from pathlib import Path


def cpu_temperature():
    for device in Path('/sys/class/hwmon').glob('hwmon*'):
        try:
            if (device / 'name').read_text().strip() not in {'coretemp', 'k10temp', 'zenpower'}:
                continue
            inputs = [device / 'temp1_input']
            for label in device.glob('temp*_label'):
                if label.read_text().strip() in {'Package id 0', 'Tctl', 'Tdie'}:
                    inputs.insert(0, label.with_name(label.name.replace('_label', '_input')))
                    break
            for sensor in inputs:
                try:
                    return float(sensor.read_text().strip()) / 1000
                except (OSError, ValueError):
                    continue
        except OSError:
            continue
    return None


if __name__ == '__main__':
    temperature = cpu_temperature()
    print(f'󰈸 {temperature:.0f}°' if temperature is not None else '󰈸 —')
