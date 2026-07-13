-- Generic portfolio environment for the Phase 3 loader.
-- Review object names and privileges before deployment.

CREATE DATABASE IF NOT EXISTS PORTFOLIO_DB;
CREATE SCHEMA IF NOT EXISTS PORTFOLIO_DB.INGESTION;

USE DATABASE PORTFOLIO_DB;
USE SCHEMA INGESTION;

/*
    Each physical line must be exposed to the loader as a single value in $1.
    Confirm these settings against the target Snowflake environment before use.
*/
CREATE OR REPLACE FILE FORMAT PORTFOLIO_DB.INGESTION.CHARSEQ_FILE_FORMAT
    TYPE = CSV
    FIELD_DELIMITER = NONE
    RECORD_DELIMITER = '\n'
    SKIP_HEADER = 0
    TRIM_SPACE = FALSE
    ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE
    EMPTY_FIELD_AS_NULL = FALSE
    NULL_IF = ();

CREATE OR REPLACE STAGE PORTFOLIO_DB.INGESTION.CHARSEQ_STAGE
    FILE_FORMAT = PORTFOLIO_DB.INGESTION.CHARSEQ_FILE_FORMAT;
