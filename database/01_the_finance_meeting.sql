-- Task 1 — The Finance Meeting

USE LmsTrainingLab;
GO

-- 1.1 & 1.2

DROP TABLE IF EXISTS #LateInvoices;
GO

SELECT 
    InvoiceNumber,
    StudentId AS WhoOwesStudentId,
    TotalAmount AS InvoiceTotalAmount,
    PaidAmount AS InvoicePaidAmount,
    TotalAmount - PaidAmount AS RemainingAmount,
    DATEDIFF(DAY, DueAtUtc, SYSUTCDATETIME()) AS DaysLate,
    CASE 
        WHEN DueAtUtc < DATEADD(DAY, -60, SYSUTCDATETIME()) 
             OR (TotalAmount - PaidAmount) > 10000.00 THEN 'Urgent'
        WHEN DueAtUtc < DATEADD(DAY, -30, SYSUTCDATETIME()) THEN 'Medium'
        ELSE 'Low'
    END AS Priority
INTO #LateInvoices
FROM [finance].[Invoices]
WHERE DueAtUtc < SYSUTCDATETIME()
  AND PaidAmount < TotalAmount;
GO

-- 1.3

SELECT 
    InvoiceNumber,
    WhoOwesStudentId,
    InvoiceTotalAmount,
    InvoicePaidAmount,
    RemainingAmount,
    DaysLate,
    Priority
FROM #LateInvoices
ORDER BY 
    CASE Priority
        WHEN 'Urgent' THEN 1
        WHEN 'Medium' THEN 2
        WHEN 'Low'    THEN 3
        ELSE 4
    END ASC,
    RemainingAmount DESC;
GO
