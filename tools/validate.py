#!/usr/bin/env python3
"""Validate the pinned Godot project without opening any window."""
import argparse
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]

def run(command):
    result = subprocess.run(command, cwd=ROOT, capture_output=True, text=True, timeout=90)
    output = result.stdout + result.stderr
    print(output.strip())
    if result.returncode or any(marker in output for marker in ("SCRIPT ERROR:", "ERROR:", "FAIL:")):
        raise RuntimeError("Godot validation failed")
    return output

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--godot", default="godot")
    args = parser.parse_args()
    expected = (ROOT / ".godot-version").read_text().strip()
    version = run([args.godot, "--headless", "--version"]).strip()
    if version.split(".stable")[0] != expected:
        raise RuntimeError(f"Expected Godot {expected}, got {version}")
    base = [args.godot, "--headless", "--path", str(ROOT)]
    run(base + ["--editor", "--quit"])
    run(base + ["--script", "res://tests/test_rules.gd"])
    run(base + ["--script", "res://tests/test_integration.gd"])
    run(base + ["--quit-after", "60"])
    print("VALIDATION: PASS")

if __name__ == "__main__":
    try:
        main()
    except (RuntimeError, OSError, subprocess.TimeoutExpired) as error:
        print(str(error), file=sys.stderr)
        sys.exit(1)
