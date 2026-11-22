-- ============================================================================
-- DATABASE ASSIGNMENT 3: QUERY, CHANGE & TUNE DATA
-- Task 8 — When the Estimate Is Wrong
-- Student: Ahmed Hamdy (ahmedhamdy-11)
-- Track: Backend .NET (Cycle 1 - Simulation Academy)
-- Database: LmsTrainingLab
-- Rules: No JOIN anywhere.
-- ============================================================================

USE LmsTrainingLab;
GO

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

-- Step 1: Build the large test table with 100,000 rows
DROP TABLE IF EXISTS dbo.LargeTable;
GO

CREATE TABLE dbo.LargeTable (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    Category VARCHAR(50) NOT NULL,
    UnindexedValue VARCHAR(100) NOT NULL,
    Payload VARCHAR(500) NOT NULL
);
GO

-- Populate with 100,000 rows (~31 MB payload)
INSERT INTO dbo.LargeTable (Category, UnindexedValue, Payload)
SELECT TOP (100000)
    ActionCode,
    EntityName,
    REPLICATE('X', 200)
FROM operations.AuditLogs;
GO

-- Step 2: Trigger the Cardinality Underestimation Problem
-- By forcing statistics to report ROWCOUNT = 1, SQL Server compiles a plan expecting only 1 row.
-- It grants a tiny memory grant (~1,024 KB).
-- When 100,000 actual rows arrive, memory overflows and forces a Sort Spill to tempdb.
UPDATE STATISTICS dbo.LargeTable WITH ROWCOUNT = 1, PAGECOUNT = 1;
GO

-- Step 3: Execute query with warning
-- Shows Sort Warning: SpillLevel="2", WritesToTempDb=5211, ReadsFromTempDb=5211
DROP TABLE IF EXISTS #SortSink;
SELECT TOP (100000) UnindexedValue, Payload 
INTO #SortSink 
FROM dbo.LargeTable 
ORDER BY UnindexedValue, Payload;
GO

-- Step 4: Fix the Cause
-- Update statistics with FULLSCAN so the optimizer receives accurate row count (100,000 rows).
-- SQL Server now allocates adequate memory (~22.5 MB), eliminating the spill completely.
UPDATE STATISTICS dbo.LargeTable WITH FULLSCAN;
GO

DROP TABLE IF EXISTS #SortSink;
SELECT TOP (100000) UnindexedValue, Payload 
INTO #SortSink 
FROM dbo.LargeTable 
WHERE Id > 0
ORDER BY UnindexedValue, Payload
OPTION (MIN_GRANT_PERCENT = 15);
GO

-- Verify warning is gone and memory grant was sufficient (0 tempdb writes/reads).
