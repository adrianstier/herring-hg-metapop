#!/usr/bin/env python3
"""Watch a submitted AWS Batch run and optionally sync finished artifacts."""

from __future__ import annotations

import argparse
import csv
import json
import subprocess
import sys
import time
from datetime import datetime, timezone
from pathlib import Path


TERMINAL_STATUSES = {"SUCCEEDED", "FAILED"}


def run_aws(args: list[str], profile: str, region: str) -> dict:
    cmd = ["aws", "--profile", profile, "--region", region, *args]
    result = subprocess.run(cmd, check=True, capture_output=True, text=True)
    return json.loads(result.stdout)


def chunks(values: list[str], size: int) -> list[list[str]]:
    return [values[i : i + size] for i in range(0, len(values), size)]


def read_jobs(path: Path) -> list[dict[str, str]]:
    with path.open(newline="") as handle:
        return list(csv.DictReader(handle))


def describe_jobs(job_ids: list[str], profile: str, region: str) -> list[dict]:
    jobs: list[dict] = []
    for subset in chunks(job_ids, 100):
        payload = run_aws(["batch", "describe-jobs", "--jobs", *subset], profile, region)
        jobs.extend(payload.get("jobs", []))
    return jobs


def flatten_job(job: dict, submitted: dict[str, dict[str, str]]) -> dict[str, str]:
    container = job.get("container", {})
    attempts = job.get("attempts", [])
    latest_attempt = attempts[-1] if attempts else {}
    latest_container = latest_attempt.get("container", {})
    status_reason = job.get("statusReason") or latest_container.get("reason") or ""
    exit_code = latest_container.get("exitCode", container.get("exitCode", ""))
    started_at = job.get("startedAt") or latest_attempt.get("startedAt") or ""
    stopped_at = job.get("stoppedAt") or latest_attempt.get("stoppedAt") or ""
    job_id = job.get("jobId", "")
    row = submitted.get(job_id, {})
    return {
        "model": row.get("model", job.get("jobName", "")),
        "aws_job_id": job_id,
        "queue": row.get("queue", job.get("jobQueue", "")),
        "priority": row.get("priority", ""),
        "status": job.get("status", ""),
        "status_reason": status_reason,
        "created_at_ms": str(job.get("createdAt", "")),
        "started_at_ms": str(started_at),
        "stopped_at_ms": str(stopped_at),
        "runtime_minutes": runtime_minutes(started_at, stopped_at),
        "exit_code": str(exit_code),
        "log_stream": latest_container.get("logStreamName", container.get("logStreamName", "")),
        "updated_utc": datetime.now(timezone.utc).isoformat(timespec="seconds"),
        "notes": row.get("notes", ""),
    }


def runtime_minutes(started_at: int | str, stopped_at: int | str) -> str:
    try:
        start = int(started_at)
        stop = int(stopped_at) if stopped_at else int(time.time() * 1000)
    except (TypeError, ValueError):
        return ""
    if start <= 0:
        return ""
    return f"{(stop - start) / 60000:.1f}"


def write_csv(rows: list[dict[str, str]], path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    fieldnames = list(rows[0].keys()) if rows else []
    with path.open("w", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)


def maybe_sync(args: argparse.Namespace) -> None:
    if not args.sync_s3_prefix:
        return
    cmd = [
        "bash",
        "cloud/sync_model_farm_results.sh",
        args.sync_s3_prefix,
        args.sync_local_dir,
    ]
    subprocess.run(cmd, check=False)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--jobs-csv", required=True)
    parser.add_argument("--out-csv", required=True)
    parser.add_argument("--out-json", required=True)
    parser.add_argument("--profile", default="herring")
    parser.add_argument("--region", default="us-east-1")
    parser.add_argument("--interval-seconds", type=int, default=900)
    parser.add_argument("--max-hours", type=float, default=16.0)
    parser.add_argument("--once", action="store_true")
    parser.add_argument("--sync-s3-prefix", default="")
    parser.add_argument("--sync-local-dir", default="cloud/aws_results/2026-05-10")
    args = parser.parse_args()

    jobs_path = Path(args.jobs_csv)
    submitted_rows = read_jobs(jobs_path)
    submitted = {row["aws_job_id"]: row for row in submitted_rows}
    job_ids = list(submitted)
    deadline = time.time() + args.max_hours * 3600
    last_terminal_count = -1

    while True:
        try:
            jobs = describe_jobs(job_ids, args.profile, args.region)
        except subprocess.CalledProcessError as exc:
            print(exc.stderr or str(exc), file=sys.stderr)
            return exc.returncode or 1

        flat_rows = [flatten_job(job, submitted) for job in sorted(jobs, key=lambda x: x.get("jobName", ""))]
        write_csv(flat_rows, Path(args.out_csv))
        Path(args.out_json).parent.mkdir(parents=True, exist_ok=True)
        Path(args.out_json).write_text(json.dumps(jobs, indent=2))

        terminal_count = sum(row["status"] in TERMINAL_STATUSES for row in flat_rows)
        status_summary = ", ".join(f"{row['model']}={row['status']}" for row in flat_rows)
        print(f"[{datetime.now().isoformat(timespec='seconds')}] {status_summary}", flush=True)

        if terminal_count != last_terminal_count:
            maybe_sync(args)
            last_terminal_count = terminal_count

        if args.once or terminal_count == len(job_ids) or time.time() >= deadline:
            maybe_sync(args)
            break

        time.sleep(args.interval_seconds)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
