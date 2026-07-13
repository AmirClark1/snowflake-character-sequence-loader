/*
    Phase 3 protected baseline.

    Public portfolio version of a validated metadata-driven Snowflake loader.
    Runtime behavior is intentionally preserved. Production-hardening changes
    belong in Phase 4 rather than this baseline.
*/

USE DATABASE PORTFOLIO_DB;
USE SCHEMA INGESTION;

CREATE OR REPLACE PROCEDURE PORTFOLIO_DB.INGESTION.LOAD_CHARACTER_SEQUENCE_FILE(
    FILE_NAME STRING,
    TARGET_TABLE STRING
)
RETURNS STRING
LANGUAGE SQL
EXECUTE AS OWNER
AS
$$
DECLARE
    STAGE_PATH          STRING;
    HEADER_SQL          STRING;
    HEADER_RS           RESULTSET;
    HEADER_RECORD       STRING;

    COLUMN_COUNT        INTEGER;
    COLUMN_DEFINITIONS  STRING;
    SELECT_LIST         STRING;

    CREATE_SQL          STRING;
    INSERT_SQL          STRING;
    VALIDATION_SQL      STRING;
    VALIDATION_RS       RESULTSET;

    LOADED_ROW_COUNT    INTEGER;
BEGIN
    -- Build the complete staged-file path.
    STAGE_PATH :=
        '@PORTFOLIO_DB.INGESTION.CHARSEQ_STAGE/' || FILE_NAME;

    -- Read the first physical record as the header.
    HEADER_SQL :=
          'SELECT $1::TEXT AS HEADER_VALUE '
        || 'FROM '
        || STAGE_PATH
        || ' (FILE_FORMAT => '''
        || 'PORTFOLIO_DB.INGESTION.CHARSEQ_FILE_FORMAT'
        || ''') '
        || 'WHERE METADATA$FILE_ROW_NUMBER = 1 '
        || 'LIMIT 1';

    HEADER_RS := (EXECUTE IMMEDIATE :HEADER_SQL);

    FOR HEADER_ROW IN HEADER_RS DO
        HEADER_RECORD := HEADER_ROW.HEADER_VALUE;
    END FOR;

    -- Stop when the file is missing, empty, or has no readable header.
    IF (HEADER_RECORD IS NULL) THEN
        RETURN
              'FAILED: No header record was found for file '
            || FILE_NAME;
    END IF;

    -- Determine the number of fields defined by the header.
    COLUMN_COUNT :=
        ARRAY_SIZE(SPLIT(HEADER_RECORD, '|~|'));

    IF (COLUMN_COUNT = 0) THEN
        RETURN
              'FAILED: Header contains no columns for file '
            || FILE_NAME;
    END IF;

    -- Build CREATE TABLE column definitions.
    -- Original capitalization is preserved through quoted identifiers.
    SELECT LISTAGG(
               '"'
               || REPLACE(F.VALUE::STRING, '"', '""')
               || '" TEXT',
               ','
           )
           WITHIN GROUP (ORDER BY F.INDEX)
    INTO :COLUMN_DEFINITIONS
    FROM TABLE(
        FLATTEN(
            INPUT => SPLIT(:HEADER_RECORD, '|~|')
        )
    ) F;

    -- Build one NULLIF(SPLIT(...)) expression per source field.
    SELECT LISTAGG(
               'NULLIF(SPLIT($1, ''|~|'')['
               || FIELD_INDEX
               || ']::TEXT, '''')',
               ','
           )
           WITHIN GROUP (ORDER BY FIELD_INDEX)
    INTO :SELECT_LIST
    FROM (
        SELECT SEQ4() AS FIELD_INDEX
        FROM TABLE(GENERATOR(ROWCOUNT => 1000))
    )
    WHERE FIELD_INDEX < :COLUMN_COUNT;

    -- Recreate the destination table from the discovered header.
    CREATE_SQL :=
          'CREATE OR REPLACE TABLE PORTFOLIO_DB.INGESTION."'
        || REPLACE(TARGET_TABLE, '"', '""')
        || '" ('
        || COLUMN_DEFINITIONS
        || ')';

    EXECUTE IMMEDIATE :CREATE_SQL;

    -- Load all records except the header.
    INSERT_SQL :=
          'INSERT INTO PORTFOLIO_DB.INGESTION."'
        || REPLACE(TARGET_TABLE, '"', '""')
        || '" SELECT '
        || SELECT_LIST
        || ' FROM '
        || STAGE_PATH
        || ' (FILE_FORMAT => '''
        || 'PORTFOLIO_DB.INGESTION.CHARSEQ_FILE_FORMAT'
        || ''') '
        || 'WHERE METADATA$FILE_ROW_NUMBER > 1';

    EXECUTE IMMEDIATE :INSERT_SQL;

    -- Count the rows written to the destination table.
    VALIDATION_SQL :=
          'SELECT COUNT(*) AS ROW_COUNT '
        || 'FROM PORTFOLIO_DB.INGESTION."'
        || REPLACE(TARGET_TABLE, '"', '""')
        || '"';

    VALIDATION_RS := (EXECUTE IMMEDIATE :VALIDATION_SQL);

    FOR VALIDATION_ROW IN VALIDATION_RS DO
        LOADED_ROW_COUNT := VALIDATION_ROW.ROW_COUNT;
    END FOR;

    -- Return a concise load summary.
    RETURN
          'SUCCESS'
        || ' | File: ' || FILE_NAME
        || ' | Table: PORTFOLIO_DB.INGESTION.' || TARGET_TABLE
        || ' | Columns: ' || COLUMN_COUNT
        || ' | Rows loaded: ' || LOADED_ROW_COUNT;
END;
$$;
