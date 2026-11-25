-- Task 7 — Make It Faster

USE LmsTrainingLab;
GO

-- Ensure required production indexes exist
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Users_Email' AND object_id = OBJECT_ID('identity.Users'))
    CREATE INDEX IX_Users_Email ON [identity].[Users] (Email) INCLUDE (FirstName, LastName);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Users_LastName' AND object_id = OBJECT_ID('identity.Users'))
    CREATE INDEX IX_Users_LastName ON [identity].[Users] (LastName) INCLUDE (FirstName, Email);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Users_CreatedAtUtc' AND object_id = OBJECT_ID('identity.Users'))
    CREATE INDEX IX_Users_CreatedAtUtc ON [identity].[Users] (CreatedAtUtc) INCLUDE (Email);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Payments_PaidAtUtc' AND object_id = OBJECT_ID('finance.Payments'))
    CREATE INDEX IX_Payments_PaidAtUtc ON [finance].[Payments] (PaidAtUtc) INCLUDE (InvoiceId, Amount);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Invoices_Number' AND object_id = OBJECT_ID('finance.Invoices'))
    CREATE INDEX IX_Invoices_Number ON [finance].[Invoices] (InvoiceNumber);
GO

-- 7.1

SELECT Id, Email
FROM [identity].[Users]
WHERE CreatedAtUtc >= '2026-03-01T00:00:00'
  AND CreatedAtUtc <  '2026-04-01T00:00:00';
GO

-- 7.2

SELECT Id, InvoiceId, Amount
FROM [finance].[Payments]
WHERE PaidAtUtc >= DATEADD(DAY, -30, SYSUTCDATETIME());
GO

-- 7.3

SELECT Id, FirstName, LastName
FROM [identity].[Users]
WHERE LastName LIKE N'Abd%';
GO

-- 7.4

SELECT *
FROM [operations].[AuditLogs]
WHERE Id = 50000;   

-- 7.5

SELECT Id, TotalAmount, PaidAmount
FROM [finance].[Invoices]
WHERE InvoiceNumber = 'INV-2026-00001';
GO

-- 7.6

DECLARE @Email NVARCHAR(320) = N'academic.office@northbridge.edu';
SELECT Id, FirstName, LastName
FROM [identity].[Users]
WHERE Email = @Email;
GO

-- 7.7

DECLARE @LastName NVARCHAR(100) = N'Hassan';
SELECT Id, FirstName, Email
FROM [identity].[Users]
WHERE (@LastName IS NULL OR LastName = @LastName)
OPTION (RECOMPILE);
GO

-- 7.8

SELECT Id, Email
FROM [identity].[Users]
WHERE LastName = N'Hassan' 
  AND FirstName = N'Nadia';
GO
