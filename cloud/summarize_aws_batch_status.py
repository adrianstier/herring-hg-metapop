#!/usr/bin/env python3
"""Summarize the latest AWS Batch model-farm status CSV as Markdown.

This intentionally does not call AWS. It gives us a durable local status report
even when the AWS SSO token is expired or the laptop is offline.
"""

from __future__ import annotations

import argparse
import csv
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path


def parse_iso(value: str) -> datetime | None:
    if not value:
        return None
    try:
        return datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError:
        return None


def fmt_age(ts: datetime | None) -> str:
    if ts is None:
        return "unknown"
    delta = datetime.now(timezone.utc) - ts.astimezone(timezone.utc)
    hours = delta.total_seconds() / 3600
    if hours < 1:
        return f"{delta.total_seconds() / 60:.0f} min"
    return f"{hours:.1f} h"


def md_escape(value: object) -> str:
    text = "" if value is None else str(value)
    return text.replace("|", "\\|")


def table(rows: list[dict[str, str]], columns: list[tuple[str, str]]) -> list[str]:
    lines = [
        "| " + " | ".join(label for label, _ in columns) + " |",
        "| " + " | ".join("---" for _ in columns) + " |",
    ]
    for row in rows:
        lines.append("| " + " | ".join(md_escape(row.get(key, "")) for _, key in columns) + " |")
    return lines


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--status-csv",
        default="cloud/aws_batch_runs/2026-05-10-overnight-status.csv",
        help="CSV produced by cloud/watch_aws_batch_run.py",
    )
    parser.add_argument(
        "--out-md",
        default="Output/diagnostics/aws_batch_model_farm_status.md",
        help="Markdown report path",
    )
    parser.add_argument(
        "--local-model-status",
        default="Output/diagnostics/model_branch_status_table.csv",
        help="Optional local model-decision CSV used to add current local reads.",
    )
    args = parser.parse_args()

    status_path = Path(args.status_csv)
    out_path = Path(args.out_md)
    out_path.parent.mkdir(parents=True, exist_ok=True)

    if not status_path.exists():
        out_path.write_text(
            "\n".join(
                [
                    "# AWS Batch Model-Farm Status",
                    "",
                    f"Generated: {datetime.now().astimezone().strftime('%Y-%m-%d %H:%M:%S %Z')}",
                    "",
                    f"No status CSV found at `{status_path}`.",
                ]
            )
            + "\n"
        )
        return 0

    with status_path.open(newline="") as handle:
        rows = list(csv.DictReader(handle))

    local_status: dict[str, str] = {}
    local_status_path = Path(args.local_model_status)
    if local_status_path.exists():
        with local_status_path.open(newline="") as handle:
            for row in csv.DictReader(handle):
                model = row.get("model", "")
                if not model:
                    continue
                local_status[model] = row.get("use_for_monday", "") or row.get("comparison_status", "")

    updated_values = [parse_iso(row.get("updated_utc", "")) for row in rows]
    updated_values = [x for x in updated_values if x is not None]
    latest_update = max(updated_values) if updated_values else None
    status_counts = Counter(row.get("status", "UNKNOWN") or "UNKNOWN" for row in rows)
    stale = latest_update is None or (datetime.now(timezone.utc) - latest_update.astimezone(timezone.utc)).total_seconds() > 2 * 3600

    rows_sorted = sorted(rows, key=lambda row: (row.get("priority", ""), row.get("model", "")))
    compact_rows: list[dict[str, str]] = []
    for row in rows_sorted:
        model = row.get("model", "")
        local_decision = local_status.get(model, "")
        note = row.get("notes", "")
        if model == "m1_stier_obs_hier" and local_decision:
            note = "Local fit completed clean negative; stale AWS row only."
        elif model == "m3_stier_distance" and local_decision:
            note = "Local fit and exact re-LOO completed; held as spatial context."
        compact_rows.append(
            {
                "model": model,
                "priority": row.get("priority", ""),
                "queue": row.get("queue", "").replace("herring-hg-metapop-", ""),
                "status": row.get("status", ""),
                "runtime": row.get("runtime_minutes", ""),
                "exit": row.get("exit_code", ""),
                "job": row.get("aws_job_id", "")[:8],
                "local": local_decision,
                "notes": note,
            }
        )

    lines = [
        "# AWS Batch Model-Farm Status",
        "",
        f"Generated: {datetime.now().astimezone().strftime('%Y-%m-%d %H:%M:%S %Z')}",
        f"Source CSV: `{status_path}`",
        "",
        "## Snapshot",
        "",
        f"- Latest AWS poll represented here: `{latest_update.isoformat(timespec='seconds') if latest_update else 'unknown'}`.",
        f"- Status age: `{fmt_age(latest_update)}`.",
        "- Status counts: "
        + ", ".join(f"`{status}`={count}" for status, count in sorted(status_counts.items()))
        + ".",
    ]

    if stale:
        lines.extend(
            [
                "- This report is stale because AWS could not be polled recently. The most common cause in this repo has been an expired `herring` AWS SSO token.",
                "- Refresh command: `aws sso login --profile herring`, then rerun `cloud/watch_aws_batch_run.py --once` or the project status refresh wrapper.",
            ]
        )

    lines.extend(
        [
            "",
            "## Jobs",
            "",
            *table(
                compact_rows,
                [
                    ("model", "model"),
                    ("priority", "priority"),
                    ("queue", "queue"),
                    ("status", "status"),
                    ("runtime min", "runtime"),
                    ("exit", "exit"),
                    ("job id", "job"),
                    ("local decision", "local"),
                    ("notes", "notes"),
                ],
            ),
            "",
            "## Interpretation",
            "",
            "- `SUCCEEDED` jobs should be synced from S3 and only then promoted into local `Data/processed`, `Output/posteriors`, and diagnostics.",
            "- `RUNNING`, `STARTING`, and `RUNNABLE` rows are only the last known AWS state when this CSV was written.",
            "- If the report is stale, do not infer that jobs are still running; refresh AWS credentials and poll Batch first.",
        ]
    )

    out_path.write_text("\n".join(lines) + "\n")
    print(f"Wrote {out_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
