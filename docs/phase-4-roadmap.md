# Phase 4 Operational-Hardening Roadmap

Phase 4 will improve the safety, repeatability, and auditability of operator-initiated one-time loads without changing the documented Phase 3 baseline.

## Scope boundary

This project supports a finite migration dataset. It is not intended to become a scheduled or continuously running ingestion pipeline unless the source requirement changes.

Phase 4 therefore excludes:

- recurring Snowflake Tasks,
- Streams and change-data-capture patterns,
- Snowpipe or event-driven ingestion,
- external schedulers,
- and continuous monitoring designed for recurring feeds.

Those capabilities would add complexity without serving the validated one-time-load requirement.

## Safety

- Validate file names against an approved pattern.
- Validate target table names against a strict identifier pattern.
- Reject duplicate and blank header values.
- Add an explicit maximum-column guard.
- Separate deployment configuration from procedure logic.

## Recoverability

- Load into a temporary or versioned table.
- Validate the staged result before publishing it.
- Add structured exception handling.
- Use swap-based or otherwise atomic publication where appropriate.
- Preserve the previously published target if a new load fails.

## Auditability

- Add a persistent load-audit table.
- Record start time, end time, file name, target table, column count, row count, status, query ID, and error details.
- Capture rejected records and failure reasons.
- Add independent source-to-target reconciliation.
- Retain enough metadata to reproduce or investigate a manual execution.

## Quality

Add repeatable validation scripts for:

- missing files,
- empty files,
- duplicate headers,
- blank headers,
- embedded quotes,
- empty values,
- trailing delimiters,
- wide schemas,
- malformed records,
- and failed publication scenarios.

A CI workflow may validate repository SQL or documentation in the future, but CI is not a runtime ingestion requirement.

## Extensibility

- Parameterize database, schema, stage, file format, and delimiter.
- Add replace, append, and fail-if-exists load modes only where justified.
- Preserve raw source values for traceability.
- Keep business-type casting in downstream transformation layers.
- Maintain explicit operator control over when each one-time load runs.

## Completion criteria

Phase 4 is complete when an operator can run a one-time load with validated inputs, receive a durable audit record, recover safely from a failure, reconcile source and target counts, and publish the result without risking the previous target table.
