-- Task 9 — One of Each (DISTINCT Operators)


USE LmsTrainingLab;
GO

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

-- 9.1: Return distinct values of a column that has no index

SELECT DISTINCT UnindexedValue 
FROM dbo.LargeTable;
GO

-- 9.2: The Cheaper Duplicate Removal Operator: Stream Aggregate

-- Demonstration: An index provides pre-sorted order, allowing Stream Aggregate:
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_LargeTable_UnindexedValue' AND object_id = OBJECT_ID('dbo.LargeTable'))
    CREATE INDEX IX_LargeTable_UnindexedValue ON dbo.LargeTable (UnindexedValue);
GO

SELECT DISTINCT UnindexedValue 
FROM dbo.LargeTable;
GO

-- 9.3: Run DISTINCT on a column that is already unique (Primary Key)

SELECT DISTINCT Id 
FROM dbo.LargeTable;
GO
