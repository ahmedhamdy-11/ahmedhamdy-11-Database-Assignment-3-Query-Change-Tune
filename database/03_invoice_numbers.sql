-- ============================================================================
-- DATABASE ASSIGNMENT 3: QUERY, CHANGE & TUNE DATA
-- Task 3 — Invoice Numbers
-- Student: Ahmed Hamdy (ahmedhamdy-11)
-- Track: Backend .NET (Cycle 1 - Simulation Academy)
-- Database: LmsTrainingLab
-- Rules: No JOIN anywhere. Sequence object independent of any single table.
-- ============================================================================

USE LmsTrainingLab;
GO

-- 3.1
-- Build what is needed for that numbering:
-- Finance requires a number like LAB-INV-2026-000001 that increases monotonically across applications.
-- A SEQUENCE object is the optimal enterprise database solution because it operates independently
-- of any single table, avoids table locks, and guarantees thread-safe generation.

IF OBJECT_ID('finance.InvoiceNumberSeq', 'SO') IS NULL
BEGIN
    CREATE SEQUENCE finance.InvoiceNumberSeq
        AS INT
        START WITH 1
        INCREMENT BY 1;
END;
GO

-- 3.2
-- Create one new invoice for an existing student: 4,500 EGP, due in 30 days, nothing paid yet.
DECLARE @NextVal INT = NEXT VALUE FOR finance.InvoiceNumberSeq;
DECLARE @FormattedNumber VARCHAR(30) = 'LAB-INV-' + CAST(YEAR(SYSUTCDATETIME()) AS VARCHAR(4)) + '-' + RIGHT('000000' + CAST(@NextVal AS VARCHAR(6)), 6);

DECLARE @TargetStudentId BIGINT;
SELECT TOP 1 @TargetStudentId = Id FROM [identity].StudentProfiles;

DECLARE @ActiveTermId INT;
SELECT TOP 1 @ActiveTermId = Id FROM delivery.AcademicTerms ORDER BY StartDate DESC;

INSERT INTO finance.Invoices (
    InvoiceNumber,
    StudentId,
    TermId,
    CurrencyCode,
    IssuedAtUtc,
    DueAtUtc,
    TotalAmount,
    PaidAmount,
    CreatedAtUtc,
    Status
)
VALUES (
    @FormattedNumber,
    @TargetStudentId,
    @ActiveTermId,
    'EGP',
    SYSUTCDATETIME(),
    DATEADD(DAY, 30, SYSUTCDATETIME()),
    4500.00,
    0.00,
    SYSUTCDATETIME(),
    1 -- Unpaid / Pending
);

-- Display the created invoice
SELECT Id, InvoiceNumber, StudentId, TotalAmount, PaidAmount, DueAtUtc, Status
FROM finance.Invoices
WHERE InvoiceNumber = @FormattedNumber;
GO

-- 3.3
-- A developer took a number inside a transaction and then cancelled the transaction.
-- Show what happens to that number.
-- Result: Sequences are designed outside transaction rollback boundaries for high concurrency.
-- When a transaction rolls back, the allocated number is PERMANENTLY consumed and not recycled,
-- resulting in a gap.

BEGIN TRANSACTION;
    DECLARE @RolledBackVal INT = NEXT VALUE FOR finance.InvoiceNumberSeq;
    DECLARE @RolledBackNumber VARCHAR(30) = 'LAB-INV-' + CAST(YEAR(SYSUTCDATETIME()) AS VARCHAR(4)) + '-' + RIGHT('000000' + CAST(@RolledBackVal AS VARCHAR(6)), 6);
    SELECT @RolledBackNumber AS NumberAllocatedInsideTransaction;
ROLLBACK TRANSACTION;

-- Show the next number requested after rollback:
DECLARE @NextValAfterRollback INT = NEXT VALUE FOR finance.InvoiceNumberSeq;
DECLARE @NextNumberAfterRollback VARCHAR(30) = 'LAB-INV-' + CAST(YEAR(SYSUTCDATETIME()) AS VARCHAR(4)) + '-' + RIGHT('000000' + CAST(@NextValAfterRollback AS VARCHAR(6)), 6);
SELECT @NextNumberAfterRollback AS NumberAllocatedAfterTransactionRollback;
GO
