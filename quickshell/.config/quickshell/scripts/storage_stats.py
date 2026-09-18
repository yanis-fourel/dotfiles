#!/usr/bin/env python3
"""Print mounted filesystems and block devices as JSON."""

import json
import subprocess


def run_json(command):
    return json.loads(subprocess.check_output(command, text=True))


def flatten_mounts(items, output):
    for item in items:
        source = str(item.get("source", ""))
        target = item.get("target", "")
        if source.startswith("/dev/") and target:
            percent = str(item.get("use%", "0%")).rstrip("%")
            output.append({
                "source": source, "target": target, "type": item.get("fstype", ""),
                "size": item.get("size") or 0, "used": item.get("used") or 0,
                "available": item.get("avail") or 0,
                "percent": int(percent) if percent.isdigit() else 0,
            })
        flatten_mounts(item.get("children", []), output)


def flatten_devices(items, output, depth=0):
    for item in items:
        mounts = [value for value in (item.get("mountpoints") or []) if value]
        output.append({
            "name": item.get("name", ""), "size": item.get("size") or 0,
            "type": item.get("type", ""), "fstype": item.get("fstype") or "",
            "mount": ", ".join(mounts), "depth": depth,
        })
        flatten_devices(item.get("children", []), output, depth + 1)


mounts = []
flatten_mounts(run_json([
    "findmnt", "-J", "-b", "-o", "SOURCE,TARGET,FSTYPE,SIZE,USED,AVAIL,USE%"
]).get("filesystems", []), mounts)
devices = []
flatten_devices(run_json([
    "lsblk", "-J", "-b", "-o", "NAME,SIZE,TYPE,FSTYPE,MOUNTPOINTS"
]).get("blockdevices", []), devices)
print(json.dumps({"mounts": mounts, "devices": devices}))
