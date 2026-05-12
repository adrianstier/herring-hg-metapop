#!/usr/bin/env python3
"""Submit herring model-farm jobs to AWS Batch from a CSV manifest."""

from __future__ import annotations

import argparse
import csv
import json
import subprocess
import sys
from pathlib import Path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--manifest", default="cloud/model-farm-manifest.csv")
    parser.add_argument("--s3-prefix", required=True)
    parser.add_argument("--job-queue", required=True)
    parser.add_argument("--job-definition", required=True)
    parser.add_argument("--job-id", action="append", default=[])
    parser.add_argument("--family", action="append", default=[])
    parser.add_argument("--task-type", action="append", default=[])
    parser.add_argument("--include-spot", action="store_true")
    parser.add_argument("--include-planned", action="store_true")
    parser.add_argument("--dry-run", action="store_true")
    return parser.parse_args()


def keep(row: dict[str, str], args: argparse.Namespace) -> bool:
    if args.job_id and row["job_id"] not in args.job_id:
        return False
    if args.family and row["job_family"] not in args.family:
        return False
    if args.task_type and row["task_type"] not in args.task_type:
        return False
    if row.get("spot_ok", "").lower() == "true" and not args.include_spot:
        return False
    if row.get("task_type", "").startswith("planned_") and not args.include_planned:
        return False
    return True


def submit(row: dict[str, str], args: argparse.Namespace) -> None:
    script = Path(row["script"])
    if not script.exists():
        raise FileNotFoundError(f"Manifest script missing for {row['job_id']}: {script}")

    array_size = int(row.get("array_size") or "1")
    timeout_hours = int(row.get("timeout_hours") or "24")
    vcpus = int(row.get("vcpus") or "4")
    memory_mib = int(row.get("memory_mib") or "32000")
    env = row.get("env") or ""

    overrides = {
        "vcpus": vcpus,
        "memory": memory_mib,
        "environment": [
            {"name": "S3_PREFIX", "value": args.s3_prefix.rstrip("/")},
            {"name": "JOB_ID", "value": row["job_id"]},
            {"name": "JOB_SCRIPT", "value": row["script"]},
            {"name": "JOB_ENV", "value": env},
        ],
    }

    command = [
        "aws",
        "batch",
        "submit-job",
        "--job-name",
        row["job_id"],
        "--job-queue",
        args.job_queue,
        "--job-definition",
        args.job_definition,
        "--container-overrides",
        json.dumps(overrides),
        "--retry-strategy",
        "attempts=1",
        "--timeout",
        f"attemptDurationSeconds={timeout_hours * 3600}",
    ]
    if array_size > 1:
        command.extend(["--array-properties", f"size={array_size}"])

    print(" ".join(command))
    if not args.dry_run:
        subprocess.run(command, check=True)


def main() -> int:
    args = parse_args()
    manifest = Path(args.manifest)
    with manifest.open(newline="") as handle:
        rows = list(csv.DictReader(handle))

    selected = [row for row in rows if keep(row, args)]
    if not selected:
        print("No manifest rows selected.", file=sys.stderr)
        return 1

    for row in selected:
        submit(row, args)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
