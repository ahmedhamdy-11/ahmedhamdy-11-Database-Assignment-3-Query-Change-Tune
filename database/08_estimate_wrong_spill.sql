-- Task 8 — When the Estimate Is Wrong


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

UPDATE STATISTICS dbo.LargeTable WITH ROWCOUNT = 1, PAGECOUNT = 1;
GO

-- Step 3: Execute query with warning

DROP TABLE IF EXISTS #SortSink;
SELECT TOP (100000) UnindexedValue, Payload 
INTO #SortSink 
FROM dbo.LargeTable 
ORDER BY UnindexedValue, Payload;
GO

-- Step 4: Fix the Cause

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

