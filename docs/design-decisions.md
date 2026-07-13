# Design Decisions

## Decision 1: Build one generic loader instead of file-specific scripts

The migration included multiple source files with different headers, widths, and row counts. Maintaining one SQL statement per file would have created unnecessary duplication and increased the risk of inconsistent null handling.

The selected design reads the header at runtime and generates both the destination schema and load expressions dynamically.

## Decision 2: Keep execution operator-initiated

The source delivery was a finite, one-time migration dataset. There was no recurring feed to monitor or schedule.

For that reason, the framework intentionally does not include:

- Snowflake Tasks,
- Streams,
- Snowpipe,
- event-driven orchestration,
- or an external scheduler.

This avoids introducing operational components that would have no continuing workload after the migration completed.

## Decision 3: Separate reuse from automation

A procedure can be reusable without being automated.

The same stored procedure was called manually for 23 structurally different source files. Reuse came from metadata-driven schema discovery, not from scheduling.

## Decision 4: Land all discovered columns as `TEXT`

The source exports did not provide a dependable machine-readable type contract. Creating all raw landing columns as `TEXT` avoids unsafe inference and preserves source values for later transformation.

Business typing belongs in downstream models where validation rules and domain context are available.

## Decision 5: Normalize blank strings during ingestion

The loader uses `NULLIF(..., '')` so blank source fields land as SQL `NULL` instead of empty strings. This produces more consistent downstream filtering, counting, and data-quality behavior.

## Decision 6: Preserve the working Phase 3 behavior

The validated Phase 3 procedure is maintained as a protected baseline. Safety improvements are documented and implemented separately so future changes can be compared against a known working version.

## Decision 7: Harden for migration reliability, not pipeline complexity

Phase 4 should improve:

- input validation,
- failure recovery,
- audit history,
- reject capture,
- and source-to-target reconciliation.

It should not add continuous-ingestion infrastructure unless a future requirement introduces recurring source deliveries.

## Trade-off summary

The architecture favors a small, transparent, reusable migration utility over a permanently running pipeline. This is the appropriate trade-off for a finite one-time load: enough engineering to make execution consistent and verifiable, without building infrastructure that has no long-term workload.
