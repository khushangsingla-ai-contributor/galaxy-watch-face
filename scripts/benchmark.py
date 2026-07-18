#!/usr/bin/env python3
"""Benchmark the memory footprint of every watch face in this repo.

Memory footprint is the Wear OS battery/AOD proxy that Google Play itself uses
to gate power-hungry watch faces: watch faces must stay under 10 MB in ambient
(always-on) mode and 100 MB in interactive mode. Lower ambient memory generally
means fewer lit OLED pixels / cheaper redraws and therefore better battery life
in always-on display mode.

For each face this script:
  * builds the release APK (via ./gradlew assembleRelease),
  * runs Google's official Memory Footprint Evaluator,
  * writes faces/<name>/benchmark.json,
  * prints a comparison table and fails if any face exceeds the limits.

Real-world battery numbers require a physical Galaxy Watch 7; this measures the
static memory footprint, which is the reviewable, device-independent proxy.

The evaluator jar is expected at $HOME/wff-tools/memory-footprint.jar (override
with WFF_MEMORY_JAR). Build it once from https://github.com/google/watchface
(play-validations): ./gradlew :memory-footprint:executable-jar
"""
from __future__ import annotations

import datetime
import json
import os
import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
FACES_DIR = REPO_ROOT / "faces"
AMBIENT_LIMIT_MB = 10.0
ACTIVE_LIMIT_MB = 100.0
JAR = Path(os.environ.get("WFF_MEMORY_JAR", str(Path.home() / "wff-tools" / "memory-footprint.jar")))
SCHEMA_VERSION = os.environ.get("WFF_VERSION", "2")


def die(msg: str) -> None:
    print(f"ERROR: {msg}", file=sys.stderr)
    sys.exit(1)


def discover_faces() -> list[Path]:
    return sorted(p for p in FACES_DIR.iterdir() if (p / "build.gradle").exists())


def build_release() -> None:
    print("Building release APKs (./gradlew assembleRelease)...", flush=True)
    subprocess.run(
        [str(REPO_ROOT / "gradlew"), "assembleRelease", "-q", "--no-daemon"],
        cwd=REPO_ROOT,
        check=True,
    )


def evaluate(apk: Path) -> dict:
    out = subprocess.run(
        [
            "java", "-jar", str(JAR),
            "--watch-face", str(apk),
            "--schema-version", SCHEMA_VERSION,
            "--apply-v1-offload-limitations",
            "--estimate-optimization",
            "--report",
        ],
        capture_output=True, text=True, check=True,
    ).stdout
    return json.loads(out)


def main() -> int:
    if not JAR.exists():
        die(f"memory-footprint jar not found at {JAR}. See this script's docstring for build steps.")

    faces = discover_faces()
    if not faces:
        die("no watch faces found under faces/")

    build_release()

    rows = []
    ok_all = True
    for face in faces:
        apks = sorted((face / "build/outputs/apk/release").glob("*.apk"))
        if not apks:
            print(f"WARNING: no release APK for {face.name}", file=sys.stderr)
            ok_all = False
            continue
        report = evaluate(apks[0])
        active_mb = report["maxActiveBytes"] / 1048576.0
        ambient_mb = report["maxAmbientBytes"] / 1048576.0
        passed = active_mb <= ACTIVE_LIMIT_MB and ambient_mb <= AMBIENT_LIMIT_MB
        ok_all = ok_all and passed

        data = {
            "activeMb": round(active_mb, 2),
            "ambientMb": round(ambient_mb, 2),
            "activeLimitMb": ACTIVE_LIMIT_MB,
            "ambientLimitMb": AMBIENT_LIMIT_MB,
            "ambientPctOfLimit": round(100 * ambient_mb / AMBIENT_LIMIT_MB, 1),
            "pass": passed,
            "generatedAt": datetime.datetime.now(datetime.timezone.utc).isoformat(),
        }
        (face / "benchmark.json").write_text(json.dumps(data, indent=2) + "\n")
        rows.append((face.name, active_mb, ambient_mb, data["ambientPctOfLimit"], passed))

    print()
    print(f"{'FACE':<26}{'ACTIVE MB':>11}{'AMBIENT MB':>12}{'AMBIENT %LIMIT':>16}{'STATUS':>9}")
    print("-" * 74)
    for name, active, ambient, pct, passed in rows:
        print(f"{name:<26}{active:>11.2f}{ambient:>12.2f}{pct:>15.1f}%{'PASS' if passed else 'FAIL':>9}")
    print("-" * 74)
    print(f"Limits (Wear OS app quality): active <= {ACTIVE_LIMIT_MB:.0f} MB, ambient <= {AMBIENT_LIMIT_MB:.0f} MB")
    print("Lower ambient memory => better always-on-display battery life.")

    return 0 if ok_all else 2


if __name__ == "__main__":
    sys.exit(main())
