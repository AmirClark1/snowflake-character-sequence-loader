USE DATABASE PORTFOLIO_DB;
USE SCHEMA INGESTION;

-- 1. Confirm generated structure.
SELECT
    ordinal_position,
    column_name,
    data_type
FROM PORTFOLIO_DB.INFORMATION_SCHEMA.COLUMNS
WHERE table_schema = 'INGESTION'
  AND table_name = 'EMPLOYEE_SAMPLE'
ORDER BY ordinal_position;

-- 2. Confirm the expected sample row count.
SELECT COUNT(*) AS loaded_row_count
FROM PORTFOLIO_DB.INGESTION."EMPLOYEE_SAMPLE";

-- 3. Confirm blank values became SQL NULL rather than empty strings.
SELECT
    COUNT_IF("EmployeeStatus" IS NULL) AS employee_status_nulls,
    COUNT_IF("EmployeeStatus" = '') AS employee_status_empty_strings,
    COUNT_IF("PublicNotes" IS NULL) AS public_notes_nulls,
    COUNT_IF("PublicNotes" = '') AS public_notes_empty_strings
FROM PORTFOLIO_DB.INGESTION."EMPLOYEE_SAMPLE";
