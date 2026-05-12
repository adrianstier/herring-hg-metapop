#!/usr/bin/env python3
"""Summarize downloaded AWS model-farm results against the manifest."""

from __future__ import annotations

import argparse
import csv
import glob
from pathlib import Path


def parse_status(path: Path) -> dict[str, str]:
    values: dict[str, str] = {}
    if not path.exists():
        return values
    for line in path.read_text().splitlines():
        if "=" not in line:
            continue
        key, value = line.split("=", 1)
        values[key.strip()] = value.strip()
    return values


def artifact_status(job_dir: Path, expected: str) -> tuple[int, int, str]:
    if not expected:
        return (0, 0, "")
    patterns = [x.strip() for x in expected.split(";") if x.strip()]
    found: list[str] = []
    for pattern in patterns:
        matches = glob.glob(str(job_dir / pattern))
        if matches:
            found.extend(str(Path(m).relative_to(job_dir)) for m in matches)
    return (len(found), len(patterns), ";".join(sorted(found)))


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("results_dir", help="Directory containing downloaded jobs/")
    parser.add_argument("--manifest", default="cloud/model-farm-manifest.csv")
    parser.add_argument("--out", default="Output/diagnostics/cloud_model_farm_status.csv")
    args = parser.parse_args()

    results_dir = Path(args.results_dir)
    jobs_dir = results_dir / "jobs"
    manifest_path = Path(args.manifest)
    out_path = Path(args.out)
    out_path.parent.mkdir(parents=True, exist_ok=True)

    with manifest_path.open(newline="") as handle:
        rows = list(csv.DictReader(handle))

    summary_rows: list[dict[str, str]] = []
    for row in rows:
        job_id = row["job_id"]
        candidate_dirs = sorted(jobs_dir.glob(f"{job_id}*"))
        if not candidate_dirs:
            summary_rows.append({
                **row,
                "downloaded_job_dirs": "",
                "exit_codes": "",
                "job_started": "false",
                "job_succeeded": "false",
                "artifacts_found": "0",
                "artifacts_expected": str(len([x for x in row["expected_artifacts"].split(";") if x])),
                "artifact_paths": "",
            })
            continue

        exit_codes: list[str] = []
        artifact_found = 0
        artifact_expected = 0
        artifact_paths: list[str] = []
        for job_dir in candidate_dirs:
            status_files = list((job_dir / "job_status").glob("*.status"))
            if status_files:
                status = parse_status(status_files[0])
                exit_codes.append(status.get("exit_code", "missing"))
            else:
                exit_codes.append("missing")

            found, expected, paths = artifact_status(job_dir, row["expected_artifacts"])
            artifact_found += found
            artifact_expected = max(artifact_expected, expected)
            if paths:
                artifact_paths.append(f"{job_dir.name}:{paths}")

        summary_rows.append({
            **row,
            "downloaded_job_dirs": ";".join(d.name for d in candidate_dirs),
            "exit_codes": ";".join(exit_codes),
            "job_started": "true",
            "job_succeeded": str(any(code == "0" for code in exit_codes)).lower(),
            "artifacts_found": str(artifact_found),
            "artifacts_expected": str(artifact_expected),
            "artifact_paths": "|".join(artifact_paths),
        })

    fieldnames = list(summary_rows[0].keys()) if summary_rows else []
    with out_path.open("w", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(summary_rows)

    print(out_path)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
