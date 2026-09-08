#!/usr/bin/env python3
"""Print one compact system-resource snapshot as JSON."""

import json
import os
from cpu_temperature import cpu_temperature
import subprocess
import time


def cpu_times():
    fields = [int(value) for value in open("/proc/stat").readline().split()[1:9]]
    idle = fields[3] + fields[4]
    return sum(fields), idle


def read_meminfo():
    result = {}
    with open("/proc/meminfo") as handle:
        for line in handle:
            key, value = line.split(":", 1)
            result[key] = int(value.split()[0]) * 1024
    return result


def process_list(sort_key):
    output = subprocess.check_output(
        ["ps", "-eo", "pid=,comm=,%cpu=,rss=", f"--sort=-{sort_key}"], text=True
    )
    rows = []
    for line in output.splitlines():
        parts = line.split(None, 3)
        if len(parts) != 4 or parts[1] in {"ps", "python3", "bash", "awk"}:
            continue
        rows.append({
            "pid": int(parts[0]), "name": parts[1],
            "cpu": float(parts[2]), "memory": int(parts[3]) * 1024,
        })
        if len(rows) == 7:
            break
    return rows


def cpu_model():
    for line in open("/proc/cpuinfo"):
        if line.startswith("model name"):
            return line.split(":", 1)[1].strip()
    return "Unknown CPU"


total1, idle1 = cpu_times()
time.sleep(0.2)
total2, idle2 = cpu_times()
delta = total2 - total1
cpu_usage = round(100 * (delta - (idle2 - idle1)) / delta) if delta else 0
mem = read_meminfo()
mem_total = mem.get("MemTotal", 0)
mem_available = mem.get("MemAvailable", mem.get("MemFree", 0))
swap_total = mem.get("SwapTotal", 0)
swap_free = mem.get("SwapFree", 0)
load = os.getloadavg()
uptime_seconds = int(float(open("/proc/uptime").read().split()[0]))

print(json.dumps({
    "cpu": {
        "model": cpu_model(), "usage": cpu_usage,
        "temperature": cpu_temperature(), "load": [round(x, 2) for x in load],
    },
    "memory": {"total": mem_total, "used": mem_total - mem_available},
    "swap": {"total": swap_total, "used": swap_total - swap_free},
    "uptime": uptime_seconds,
    "topCpu": process_list("%cpu"),
    "topMemory": process_list("rss"),
}))
