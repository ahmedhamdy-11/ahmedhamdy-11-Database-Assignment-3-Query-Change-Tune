-- ============================================================================
-- DATABASE ASSIGNMENT 3: QUERY, CHANGE & TUNE DATA
-- Task 9 — One of Each (DISTINCT Operators)
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

-- 9.1: Return distinct values of a column that has no index
-- SQL Server uses: Hash Match (Aggregate) or Sort (Distinct)
-- How it works: SQL Server scans the unsorted rows, hashes the distinct keys,
-- builds an in-memory hash table, checks incoming rows, and discards duplicates.
SELECT DISTINCT UnindexedValue 
FROM dbo.LargeTable;
GO

-- 9.2: The Cheaper Duplicate Removal Operator: Stream Aggregate
-- Name: Stream Aggregate
-- How it works: Reads pre-sorted data in a single streaming pass. It compares each row
-- with the current group key. Since duplicate values are physically contiguous, duplicates
-- are dropped instantly. It requires almost zero memory grant (O(1) memory) and minimal CPU.
-- What the data needs: The data MUST be sorted by the distinct column(s) (e.g. via an Index or pre-sort).

-- Demonstration: An index provides pre-sorted order, allowing Stream Aggregate:
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_LargeTable_UnindexedValue' AND object_id = OBJECT_ID('dbo.LargeTable'))
    CREATE INDEX IX_LargeTable_UnindexedValue ON dbo.LargeTable (UnindexedValue);
GO

SELECT DISTINCT UnindexedValue 
FROM dbo.LargeTable;
GO

-- 9.3: Run DISTINCT on a column that is already unique (Primary Key)
-- Operator: Clustered Index Scan ONLY (No Aggregate / Distinct operator!)
-- Explanation: Because Id is the Unique Clustered Primary Key, the Query Optimizer
-- guarantees at compile time that every row is already distinct.
-- Therefore, the duplicate removal operator is completely eliminated from the execution plan!
SELECT DISTINCT Id 
FROM dbo.LargeTable;
GO
