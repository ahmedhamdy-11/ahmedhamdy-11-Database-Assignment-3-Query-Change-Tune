-- ============================================================================
-- DATABASE ASSIGNMENT 3: QUERY, CHANGE & TUNE DATA
-- Task 6 — Reading the Plan
-- Student: Ahmed Hamdy (ahmedhamdy-11)
-- Track: Backend .NET (Cycle 1 - Simulation Academy)
-- Database: LmsTrainingLab
-- ============================================================================

USE LmsTrainingLab;
GO

-- 6.1: Measure work and execution time
SET STATISTICS IO ON;
SET STATISTICS TIME ON;
GO

-- The query behind the collections screen:
SELECT TOP (15)
    i.InvoiceNumber,
    sp.StudentNumber,
    i.TotalAmount - i.PaidAmount AS Remaining,
    CASE 
        WHEN i.DueAtUtc < DATEADD(DAY, -60, SYSUTCDATETIME()) THEN 'Urgent' 
        ELSE 'Normal' 
    END AS Urgency
FROM finance.Invoices AS i
INNER JOIN [identity].StudentProfiles AS sp ON sp.Id = i.StudentId
WHERE i.PaidAmount < i.TotalAmount
  AND i.DueAtUtc < SYSUTCDATETIME()
ORDER BY Remaining DESC;
GO

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO

-- ============================================================================
-- DETAILED PLAN ANALYSIS & NOTES SUMMARY (See NOTES.md for complete breakdown):
--
-- 1. EXPECTED OPERATORS vs. ACTUAL OPERATORS:
--    - Initial Expectation: Developer often guesses Hash Match (Inner Join) across both tables,
--      followed by calculating Remaining, then Sort, and Top 15.
--    - Actual Choice: SQL Server opted for:
--        Clustered Index Scan (Invoices) -> Compute Scalar -> Sort (Top N Sort) -> 
--        Nested Loops (Inner Join) -> Clustered Index Seek (StudentProfiles) ->
--        Parallelism (Gather Streams) -> Top (15) -> Compute Scalar (Urgency).
--
-- 2. WHY SQL SERVER CHOSE NESTED LOOPS INSTEAD OF HASH MATCH:
--    - Because the TOP (15) filter with ORDER BY Remaining DESC allows SQL Server to sort
--      Invoices FIRST using a small Top-15 priority queue in memory.
--    - Once the top 15 overdue invoices are determined, SQL Server only needs to look up
--      EXACTLY 15 student records from StudentProfiles!
--    - Performing 15 Clustered Index Seeks on StudentProfiles (costing ~30 reads) is
--      vastly cheaper than building and probing a 85,000-row hash table.
--
-- 3. WHERE GUESS WAS WRONG:
--    - The guess was wrong in assuming the JOIN would happen before the ORDER BY / TOP.
--    - The Query Optimizer recognized that pushing the Sort down to the Invoices table
--      reduced join probe operations from 50,427 overdue invoices to just 15 seeks!
-- ============================================================================
