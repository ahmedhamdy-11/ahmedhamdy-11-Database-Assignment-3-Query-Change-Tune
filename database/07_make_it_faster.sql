-- ============================================================================
-- DATABASE ASSIGNMENT 3: QUERY, CHANGE & TUNE DATA
-- Task 7 — Make It Faster
-- Student: Ahmed Hamdy (ahmedhamdy-11)
-- Track: Backend .NET (Cycle 1 - Simulation Academy)
-- Database: LmsTrainingLab
-- Rules: No JOIN anywhere.
-- ============================================================================

USE LmsTrainingLab;
GO

-- Ensure required production indexes exist
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Users_Email' AND object_id = OBJECT_ID('identity.Users'))
    CREATE INDEX IX_Users_Email ON [identity].Users (Email) INCLUDE (FirstName, LastName);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Users_LastName' AND object_id = OBJECT_ID('identity.Users'))
    CREATE INDEX IX_Users_LastName ON [identity].Users (LastName) INCLUDE (FirstName, Email);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Users_CreatedAtUtc' AND object_id = OBJECT_ID('identity.Users'))
    CREATE INDEX IX_Users_CreatedAtUtc ON [identity].Users (CreatedAtUtc) INCLUDE (Email);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Payments_PaidAtUtc' AND object_id = OBJECT_ID('finance.Payments'))
    CREATE INDEX IX_Payments_PaidAtUtc ON finance.Payments (PaidAtUtc) INCLUDE (InvoiceId, Amount);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Invoices_Number' AND object_id = OBJECT_ID('finance.Invoices'))
    CREATE INDEX IX_Invoices_Number ON finance.Invoices (InvoiceNumber);
GO

-- 7.1
-- Problem: YEAR() and MONTH() scalar functions wrap the indexed CreatedAtUtc column,
-- making the predicate non-sargable and forcing an Index Scan (688 reads).
-- Rewrite: Sargable range [2026-03-01, 2026-04-01) enabling an Index Seek (13 reads, 98% reduction).
SELECT Id, Email
FROM [identity].Users
WHERE CreatedAtUtc >= '2026-03-01T00:00:00'
  AND CreatedAtUtc <  '2026-04-01T00:00:00';
GO

-- 7.2
-- Problem: DATEDIFF(DAY, PaidAtUtc, SYSUTCDATETIME()) wraps PaidAtUtc in a function,
-- preventing Index Seek and forcing an Index Scan (599 reads).
-- Rewrite: Move calculation to constant side, isolating PaidAtUtc for an Index Seek (76 reads).
SELECT Id, InvoiceId, Amount
FROM finance.Payments
WHERE PaidAtUtc >= DATEADD(DAY, -30, SYSUTCDATETIME());
GO

-- 7.3
-- Problem: LEFT(LastName, 3) wraps the column in a function, forcing an Index Scan (1,267 reads).
-- Rewrite: Use LIKE prefix pattern N'Abd%', which SQL Server translates to a dynamic seek range (20 reads).
SELECT Id, FirstName, LastName
FROM [identity].Users
WHERE LastName LIKE N'Abd%';
GO

-- 7.4
-- Problem: Id + 1 = 50001 performs arithmetic on the clustered key, causing a full clustered table scan (130,022 reads).
-- Rewrite: Pre-compute constant: Id = 50000, turning it into a 4-read Clustered Index Seek (32,500x faster).
SELECT *
FROM operations.AuditLogs
WHERE Id = 50000; -- 50001 - 1
GO

-- 7.5
-- Problem: Literal N'LAB-INV-2026-000001' is Unicode (NVARCHAR), while InvoiceNumber is VARCHAR(30).
-- By SQL type precedence, the column is implicitly converted (CONVERT_IMPLICIT), causing an Index Scan (728 reads) and a warning.
-- Rewrite: Remove the N prefix to match VARCHAR(30), enabling direct Index Seek (6 reads).
SELECT Id, TotalAmount, PaidAmount
FROM finance.Invoices
WHERE InvoiceNumber = 'INV-2026-00001';
GO

-- 7.6
-- Problem: UPPER(Email) = UPPER(@Email) wraps Email in a function on a Case-Insensitive (CI) database collation,
-- forcing an Index Scan (1,009 reads).
-- Rewrite: The collation SQL_Latin1_General_CP1_CI_AS is already case-insensitive; matching directly enables Index Seek (3 reads).
DECLARE @Email NVARCHAR(320) = N'academic.office@northbridge.edu';
SELECT Id, FirstName, LastName
FROM [identity].Users
WHERE Email = @Email;
GO

-- 7.7
-- Problem: Catch-all query (@LastName IS NULL OR LastName = @LastName) forces a single cached plan that must handle NULL,
-- causing an Index Scan (1,267 reads) even when a specific value is passed.
-- Rewrite: Use OPTION (RECOMPILE) so parameter embedding eliminates the OR branch at runtime, giving an Index Seek (18 reads).
DECLARE @LastName NVARCHAR(100) = N'Hassan';
SELECT Id, FirstName, Email
FROM [identity].Users
WHERE (@LastName IS NULL OR LastName = @LastName)
OPTION (RECOMPILE);
GO

-- 7.8
-- Problem: Concatenating FirstName + ' ' + LastName in WHERE prevents index seek, scanning 1,267 pages.
-- Rewrite: Match individual columns directly against indexed fields, enabling Index Seek (18 reads).
SELECT Id, Email
FROM [identity].Users
WHERE LastName = N'Hassan' 
  AND FirstName = N'Nadia';
GO
