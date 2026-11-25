-- Task 3 — Invoice Numbers


USE LmsTrainingLab;
GO

-- 3.1

IF OBJECT_ID('finance.InvoiceNumberSeq', 'SO') IS NULL
BEGIN
    CREATE SEQUENCE finance.InvoiceNumberSeq
        AS INT
        START WITH 1
        INCREMENT BY 1;
END;
GO

-- 3.2

DECLARE @NextVal INT = NEXT VALUE FOR finance.InvoiceNumberSeq;
DECLARE @FormattedNumber VARCHAR(30) = 'LAB-INV-' + CAST(YEAR(SYSUTCDATETIME()) AS VARCHAR(4)) + '-' + RIGHT('000000' + CAST(@NextVal AS VARCHAR(6)), 6);

DECLARE @TargetStudentId BIGINT;
SELECT TOP 1 @TargetStudentId = Id FROM [identity].[StudentProfiles]

DECLARE @ActiveTermId INT;
SELECT TOP 1 @ActiveTermId = Id FROM [delivery].[AcademicTerms] ORDER BY StartDate DESC;

INSERT INTO [finance].[Invoices] (
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
FROM [finance].[Invoices]
WHERE InvoiceNumber = @FormattedNumber;
GO

-- 3.3

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
