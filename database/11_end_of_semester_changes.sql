-- ============================================================================
-- DATABASE ASSIGNMENT 3: QUERY, CHANGE & TUNE DATA
-- Task 11 — End of Semester Changes
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

-- 11.1
-- The Academic Director raises the pass mark of every DSAI course to 65.
UPDATE academic.Courses
SET PassingScore = 65.0
WHERE Code LIKE 'DSAI-%';
GO

-- 11.2
-- Grading: give every finished enrollment that has a final score its letter grade.
-- 90 and above is A, 80 is B, 70 is C, 60 is D, and anything below is F.
UPDATE delivery.Enrollments
SET FinalGrade = CASE 
    WHEN FinalScore >= 90 THEN 'A'
    WHEN FinalScore >= 80 THEN 'B'
    WHEN FinalScore >= 70 THEN 'C'
    WHEN FinalScore >= 60 THEN 'D'
    ELSE 'F'
END
WHERE FinalScore IS NOT NULL;
GO

-- 11.3
-- HR cancelled the Teaching Assistant role. Remove it.
DELETE FROM [identity].Roles
WHERE Code = 'TEACHING_ASSISTANT';
GO

-- 11.4
-- Finance loads payment files into a staging table every night and empties it after each load.
-- Build it, load 3 payments, and empty it the fastest way.
DROP TABLE IF EXISTS finance.PaymentStaging;
GO

CREATE TABLE finance.PaymentStaging (
    StagingId INT IDENTITY(1,1) PRIMARY KEY,
    InvoiceId BIGINT NOT NULL,
    Amount DECIMAL(18,2) NOT NULL,
    CurrencyCode CHAR(3) NOT NULL,
    PaymentMethodCode VARCHAR(30) NOT NULL,
    ExternalReference NVARCHAR(100),
    PaidAtUtc DATETIME2 NOT NULL
);
GO

-- Load 3 payments
INSERT INTO finance.PaymentStaging (InvoiceId, Amount, CurrencyCode, PaymentMethodCode, ExternalReference, PaidAtUtc)
VALUES 
    (1, 1500.00, 'EGP', 'FAWRY', 'REF-STG-001', SYSUTCDATETIME()),
    (2, 2200.00, 'EGP', 'VODAFONE_CASH', 'REF-STG-002', SYSUTCDATETIME()),
    (3, 3100.00, 'EGP', 'CREDIT_CARD', 'REF-STG-003', SYSUTCDATETIME());
GO

-- Empty it the fastest way: TRUNCATE TABLE deallocates data pages with minimal logging,
-- bypassing individual row deletion overhead and row locking.
TRUNCATE TABLE finance.PaymentStaging;
GO

-- 11.5
-- Clean up all practice tables created safely.
DROP TABLE IF EXISTS finance.PaymentStaging;
DROP TABLE IF EXISTS dbo.EnterpriseEntityExample;
DROP TABLE IF EXISTS #LateInvoices;
GO
