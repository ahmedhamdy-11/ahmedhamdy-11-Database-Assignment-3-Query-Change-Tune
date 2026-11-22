-- ============================================================================
-- DATABASE ASSIGNMENT 3: QUERY, CHANGE & TUNE DATA
-- ALL-IN-ONE MASTER SOLUTION SCRIPT
-- Student: Ahmed Hamdy (ahmedhamdy-11)
-- Track: Backend .NET (Cycle 1 - Simulation Academy)
-- Database: LmsTrainingLab
--
-- CRITICAL CONSTRAINTS RESPECTED:
--   1. NO JOIN anywhere in your answers across the entire assignment.
--   2. In Task 5: NO JOIN and NO SUBQUERIES (strictly one table per query).
--   3. All task numbers marked with standard comment format (-- 5.12).
-- ============================================================================

USE LmsTrainingLab;
GO

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

-- ============================================================================
-- Task 1 — The Finance Meeting
-- ============================================================================

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
FROM finance.Invoices
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


-- ============================================================================
-- Task 2 — A New Department
-- ============================================================================

-- 2.1
IF NOT EXISTS (SELECT 1 FROM academic.Departments WHERE Code = 'DSAI')
BEGIN
    INSERT INTO academic.Departments (Code, Name, Description, IsActive, CreatedAtUtc, IsDeleted)
    VALUES ('DSAI', N'Data Science & Artificial Intelligence', N'Department of Data Science and AI', 1, SYSUTCDATETIME(), 0);
END;
GO

-- 2.2
DECLARE @DsaiDeptId INT;
SELECT @DsaiDeptId = Id FROM academic.Departments WHERE Code = 'DSAI';

IF NOT EXISTS (SELECT 1 FROM academic.Courses WHERE Code = 'DSAI-101')
BEGIN
    INSERT INTO academic.Courses (DepartmentId, Code, Title, Description, CreditHours, PassingScore, IsActive, CreatedAtUtc)
    VALUES (@DsaiDeptId, 'DSAI-101', N'Introduction to Data Analysis', N'Introductory data science and exploratory analysis', 3.0, 60.0, 1, SYSUTCDATETIME());
END;
GO

-- 2.3
IF NOT EXISTS (SELECT 1 FROM delivery.AcademicTerms WHERE AcademicYear = 2027 AND TermCode = 'SUMMER')
BEGIN
    INSERT INTO delivery.AcademicTerms (AcademicYear, TermCode, Name, StartDate, EndDate, RegistrationStartDate, RegistrationEndDate, Status)
    VALUES (2027, 'SUMMER', N'Summer 2027', '2027-06-15', '2027-08-31', '2027-05-01', '2027-06-10', 1);
END;
GO

-- 2.4
IF NOT EXISTS (SELECT 1 FROM communication.Announcements WHERE Title = N'Summer 2027 Registration Opens May 1')
BEGIN
    INSERT INTO communication.Announcements (SectionId, Title, Body, PublishedAtUtc, ExpiresAtUtc, CreatedByUserId, CreatedAtUtc, UpdatedAtUtc, Status)
    VALUES (NULL, N'Summer 2027 Registration Opens May 1', N'Summer 2027 registration opens on 1 May.', SYSUTCDATETIME(), '2027-06-10', 1, SYSUTCDATETIME(), SYSUTCDATETIME(), 1);
END;
GO

-- 2.5
IF NOT EXISTS (SELECT 1 FROM [identity].Roles WHERE Code = 'TEACHING_ASSISTANT')
BEGIN
    INSERT INTO [identity].Roles (Code, Name, Description, IsSystem, IsDeleted)
    VALUES ('TEACHING_ASSISTANT', N'Teaching Assistant', N'Assists instructors in section delivery and tutoring.', 0, 0);
END;
GO


-- ============================================================================
-- Task 3 — Invoice Numbers
-- ============================================================================

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
SELECT TOP 1 @TargetStudentId = Id FROM [identity].StudentProfiles;

DECLARE @ActiveTermId INT;
SELECT TOP 1 @ActiveTermId = Id FROM delivery.AcademicTerms ORDER BY StartDate DESC;

INSERT INTO finance.Invoices (
    InvoiceNumber, StudentId, TermId, CurrencyCode, IssuedAtUtc, DueAtUtc, TotalAmount, PaidAmount, CreatedAtUtc, Status
)
VALUES (
    @FormattedNumber, @TargetStudentId, @ActiveTermId, 'EGP', SYSUTCDATETIME(), DATEADD(DAY, 30, SYSUTCDATETIME()), 4500.00, 0.00, SYSUTCDATETIME(), 1
);

SELECT Id, InvoiceNumber, StudentId, TotalAmount, PaidAmount, DueAtUtc, Status
FROM finance.Invoices
WHERE InvoiceNumber = @FormattedNumber;
GO

-- 3.3
BEGIN TRANSACTION;
    DECLARE @RolledBackVal INT = NEXT VALUE FOR finance.InvoiceNumberSeq;
    DECLARE @RolledBackNum VARCHAR(30) = 'LAB-INV-' + CAST(YEAR(SYSUTCDATETIME()) AS VARCHAR(4)) + '-' + RIGHT('000000' + CAST(@RolledBackVal AS VARCHAR(6)), 6);
    SELECT @RolledBackNum AS NumberAllocatedInsideTransaction;
ROLLBACK TRANSACTION;

DECLARE @NextValAfterRollback INT = NEXT VALUE FOR finance.InvoiceNumberSeq;
DECLARE @NextNumAfterRollback VARCHAR(30) = 'LAB-INV-' + CAST(YEAR(SYSUTCDATETIME()) AS VARCHAR(4)) + '-' + RIGHT('000000' + CAST(@NextValAfterRollback AS VARCHAR(6)), 6);
SELECT @NextNumAfterRollback AS NumberAllocatedAfterTransactionRollback;
GO


-- ============================================================================
-- Task 4 — Next Summer's Timetable
-- ============================================================================

DECLARE @Summer2027TermId INT;
SELECT @Summer2027TermId = Id
FROM delivery.AcademicTerms
WHERE AcademicYear = 2027 AND TermCode = 'SUMMER';

DECLARE @MostRecentTermId INT;
SELECT TOP 1 @MostRecentTermId = TermId
FROM delivery.Sections
WHERE TermId <> @Summer2027TermId
GROUP BY TermId
ORDER BY MAX(CreatedAtUtc) DESC;

IF NOT EXISTS (SELECT 1 FROM delivery.Sections WHERE TermId = @Summer2027TermId)
BEGIN
    INSERT INTO delivery.Sections (
        CourseId, TermId, SectionCode, Capacity, Location, CreatedAtUtc, DeliveryMode, Status
    )
    SELECT 
        CourseId, @Summer2027TermId, SectionCode, Capacity, Location, SYSUTCDATETIME(), DeliveryMode, Status
    FROM delivery.Sections
    WHERE TermId = @MostRecentTermId;
END;

SELECT Id AS SectionId, CourseId, TermId, SectionCode, Capacity, Location, DeliveryMode, Status
FROM delivery.Sections
WHERE TermId = @Summer2027TermId;
GO


-- ============================================================================
-- Task 5 — Management Reports (STRICTLY ONE TABLE PER QUERY, NO JOIN, NO SUBQUERY)
-- ============================================================================

-- 5.1
SELECT 
    Code AS [Course Code],
    Title AS [Course Title],
    CreditHours AS [Credit Hours]
FROM academic.Courses
ORDER BY CreditHours DESC, Title ASC;
GO

-- 5.2
SELECT TOP (5)
    StudentNumber,
    EmergencyContactName,
    EmergencyContactPhone
FROM [identity].StudentProfiles
ORDER BY NEWID();
GO

-- 5.3
SELECT 
    Id,
    FirstName,
    LastName,
    Email
FROM [identity].Users
WHERE DATALENGTH(Email) <> DATALENGTH(TRIM(Email));
GO

-- 5.4
SELECT 
    Id,
    FirstName,
    LastName,
    Email
FROM [identity].Users
WHERE Email COLLATE Latin1_General_BIN <> LOWER(Email);
GO

-- 5.5
SELECT 
    Id,
    FirstName,
    LastName,
    Email
FROM [identity].Users
WHERE Email NOT LIKE '%@%'
   OR Email LIKE '@%'
   OR Email NOT LIKE '%@%.%';
GO

-- 5.6
SELECT DISTINCT 
    SUBSTRING(Email, CHARINDEX('@', Email) + 1, LEN(Email)) AS EmailProvider
FROM [identity].Users
WHERE Email LIKE '%@%'
ORDER BY EmailProvider ASC;
GO

-- 5.7
SELECT 
    Id,
    FirstName,
    LastName,
    Email,
    LastLoginAtUtc
FROM [identity].Users
ORDER BY 
    CASE WHEN LastLoginAtUtc IS NULL THEN 1 ELSE 0 END ASC,
    LastLoginAtUtc DESC;
GO

-- 5.8
SELECT 
    Id,
    InvoiceId,
    Amount,
    CurrencyCode,
    PaidAtUtc
FROM finance.Payments
WHERE PaidAtUtc >= '2026-10-01T00:00:00'
  AND PaidAtUtc <  '2026-11-01T00:00:00';
GO

-- 5.9
SELECT 
    Id,
    InvoiceId,
    Amount,
    CurrencyCode,
    PaidAtUtc AT TIME ZONE 'UTC' AT TIME ZONE 'Egypt Standard Time' AS PaymentTimeCairo
FROM finance.Payments
WHERE CAST(PaidAtUtc AT TIME ZONE 'UTC' AT TIME ZONE 'Egypt Standard Time' AS TIME) >= '00:00:00'
  AND CAST(PaidAtUtc AT TIME ZONE 'UTC' AT TIME ZONE 'Egypt Standard Time' AS TIME) <= '05:00:00';
GO

-- 5.10
SELECT 
    Id,
    SectionId,
    SessionDate,
    StartsAtUtc,
    EndsAtUtc,
    Topic
FROM attendance.AttendanceSessions
WHERE DATENAME(WEEKDAY, SessionDate) = 'Friday';
GO

-- 5.11
SELECT 
    Id,
    FirstName,
    LastName,
    PhoneNumber
FROM [identity].Users
WHERE PhoneNumber LIKE '+201[0125]%'
   OR PhoneNumber LIKE '01[0125]%';
GO

-- 5.12
SELECT 
    Id,
    FirstName,
    LastName,
    CASE 
        WHEN LEN(PhoneNumber) > 5 
        THEN STUFF(PhoneNumber, 4, LEN(PhoneNumber) - 5, REPLICATE('*', LEN(PhoneNumber) - 5))
        ELSE PhoneNumber 
    END AS MaskedPhoneNumber
FROM [identity].Users;
GO

-- 5.13
SELECT 
    Id,
    InvoiceNumber,
    TRY_CAST(
        CASE 
            WHEN RIGHT(InvoiceNumber, CHARINDEX('-', REVERSE(InvoiceNumber)) - 1) LIKE 'NB%' 
            THEN SUBSTRING(RIGHT(InvoiceNumber, CHARINDEX('-', REVERSE(InvoiceNumber)) - 1), 3, 50)
            ELSE RIGHT(InvoiceNumber, CHARINDEX('-', REVERSE(InvoiceNumber)) - 1)
        END AS BIGINT
    ) AS RunningNumber
FROM finance.Invoices
ORDER BY RunningNumber ASC;
GO

-- 5.14
SELECT 
    Id,
    Title,
    EstimatedMinutes,
    CASE 
        WHEN EstimatedMinutes IS NULL THEN 'Not set'
        ELSE CAST(EstimatedMinutes / 60 AS VARCHAR(10)) + ' h ' + CAST(EstimatedMinutes % 60 AS VARCHAR(10)) + ' min'
    END AS FormattedLength
FROM content.Lessons;
GO

-- 5.15
SELECT 
    Id,
    Title,
    Body,
    PublishedAtUtc
FROM communication.Announcements
WHERE Title LIKE '%[%]%'
   OR Body  LIKE '%[%]%';
GO

-- 5.16
SELECT TOP (5) WITH TIES
    Id,
    InvoiceNumber,
    StudentId,
    TotalAmount,
    PaidAmount
FROM finance.Invoices
ORDER BY TotalAmount DESC;
GO

-- 5.17
SELECT TOP (10) PERCENT
    Id,
    InvoiceId,
    Amount,
    CurrencyCode,
    PaidAtUtc
FROM finance.Payments
ORDER BY Amount DESC;
GO

-- 5.18
SELECT 
    Id,
    CourseId,
    TermId,
    SectionCode,
    Location
FROM delivery.Sections
WHERE Location <> 'Hall A'
   OR Location IS NULL;
GO

-- 5.19
SELECT 
    Id,
    InvoiceNumber,
    TotalAmount,
    PaidAmount,
    TotalAmount - PaidAmount AS AmountOwed,
    CASE 
        WHEN PaidAmount > 0 THEN 'Partially Paid' 
        ELSE 'Not Paid' 
    END AS PaymentState,
    CASE 
        WHEN DueAtUtc < SYSUTCDATETIME() THEN 'Overdue' 
        ELSE 'Not Overdue' 
    END AS OverdueStatus,
    ISNULL(CAST(ROUND((PaidAmount * 100.0) / NULLIF(TotalAmount, 0), 1) AS DECIMAL(5,1)), 0.0) AS PercentagePaid
FROM finance.Invoices
WHERE PaidAmount < TotalAmount
ORDER BY AmountOwed DESC;
GO

-- 5.20
SELECT 
    Id,
    FirstName,
    LastName,
    Email,
    CreatedAtUtc
FROM [identity].Users
ORDER BY CreatedAtUtc DESC, Id DESC
OFFSET 40 ROWS FETCH NEXT 20 ROWS ONLY;
GO

-- 5.21
DECLARE @LastSeenAuditId BIGINT = 50000;
SELECT TOP (50)
    Id,
    OccurredAtUtc,
    ActorUserId,
    ActionCode,
    EntityName,
    EntityKey
FROM operations.AuditLogs
WHERE Id > @LastSeenAuditId
ORDER BY Id ASC;
GO

-- 5.22
SELECT TOP (10)
    Id,
    InvoiceId,
    Amount,
    CurrencyCode,
    PaidAtUtc
FROM finance.Payments
ORDER BY PaidAtUtc DESC, Id DESC;
GO

-- 5.23
SELECT DISTINCT TOP (10)
    UPPER(TRIM(Title)) AS LessonTitle,
    LEN(TRIM(Title)) AS TitleLength,
    CASE 
        WHEN EstimatedMinutes IS NULL THEN 'Not set'
        WHEN EstimatedMinutes <= 15   THEN 'Quick'
        WHEN EstimatedMinutes <= 45   THEN 'Standard'
        ELSE 'Long'
    END AS DurationCategory
FROM content.Lessons
WHERE IsPublished = 1
  AND LEN(TRIM(Title)) > 40
ORDER BY TitleLength DESC;
GO

-- 5.24
SELECT TOP (12)
    CONVERT(VARCHAR(7), DueAtUtc, 120) AS DueMonth,
    CurrencyCode,
    CASE 
        WHEN PaidAmount > 0 THEN 'Partially Paid' 
        ELSE 'Not Paid' 
    END AS PaymentState,
    COUNT(*) AS InvoiceCount,
    SUM(TotalAmount - PaidAmount) AS TotalOutstandingAmount
FROM finance.Invoices
WHERE DueAtUtc < SYSUTCDATETIME()
  AND PaidAmount < TotalAmount
GROUP BY 
    CONVERT(VARCHAR(7), DueAtUtc, 120),
    CurrencyCode,
    CASE 
        WHEN PaidAmount > 0 THEN 'Partially Paid' 
        ELSE 'Not Paid' 
    END
ORDER BY DueMonth DESC, CurrencyCode ASC, PaymentState ASC;
GO


-- ============================================================================
-- Task 6 — Reading the Plan
-- ============================================================================

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


-- ============================================================================
-- Task 7 — Make It Faster
-- ============================================================================

-- 7.1
SELECT Id, Email
FROM [identity].Users
WHERE CreatedAtUtc >= '2026-03-01T00:00:00'
  AND CreatedAtUtc <  '2026-04-01T00:00:00';
GO

-- 7.2
SELECT Id, InvoiceId, Amount
FROM finance.Payments
WHERE PaidAtUtc >= DATEADD(DAY, -30, SYSUTCDATETIME());
GO

-- 7.3
SELECT Id, FirstName, LastName
FROM [identity].Users
WHERE LastName LIKE N'Abd%';
GO

-- 7.4
SELECT *
FROM operations.AuditLogs
WHERE Id = 50000;
GO

-- 7.5
SELECT Id, TotalAmount, PaidAmount
FROM finance.Invoices
WHERE InvoiceNumber = 'INV-2026-00001';
GO

-- 7.6
DECLARE @EmailParam NVARCHAR(320) = N'academic.office@northbridge.edu';
SELECT Id, FirstName, LastName
FROM [identity].Users
WHERE Email = @EmailParam;
GO

-- 7.7
DECLARE @LastNameParam NVARCHAR(100) = N'Hassan';
SELECT Id, FirstName, Email
FROM [identity].Users
WHERE (@LastNameParam IS NULL OR LastName = @LastNameParam)
OPTION (RECOMPILE);
GO

-- 7.8
SELECT Id, Email
FROM [identity].Users
WHERE LastName = N'Hassan' 
  AND FirstName = N'Nadia';
GO


-- ============================================================================
-- Task 8 & 9 — Spill + Distinct Operators
-- ============================================================================

-- 8: Spill Resolution Demonstration
UPDATE STATISTICS dbo.LargeTable WITH FULLSCAN;
GO

-- 9.1: Distinct on unindexed column
SELECT DISTINCT UnindexedValue 
FROM dbo.LargeTable;
GO

-- 9.2: Stream Aggregate on sorted indexed column
SELECT DISTINCT UnindexedValue 
FROM dbo.LargeTable;
GO

-- 9.3: Distinct on unique Primary Key (Eliminated Operator)
SELECT DISTINCT Id 
FROM dbo.LargeTable;
GO


-- ============================================================================
-- Task 11 — End of Semester Changes
-- ============================================================================

-- 11.1
UPDATE academic.Courses
SET PassingScore = 65.0
WHERE Code LIKE 'DSAI-%';
GO

-- 11.2
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
DELETE FROM [identity].Roles
WHERE Code = 'TEACHING_ASSISTANT';
GO

-- 11.4
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

INSERT INTO finance.PaymentStaging (InvoiceId, Amount, CurrencyCode, PaymentMethodCode, ExternalReference, PaidAtUtc)
VALUES 
    (1, 1500.00, 'EGP', 'FAWRY', 'REF-STG-001', SYSUTCDATETIME()),
    (2, 2200.00, 'EGP', 'VODAFONE_CASH', 'REF-STG-002', SYSUTCDATETIME()),
    (3, 3100.00, 'EGP', 'CREDIT_CARD', 'REF-STG-003', SYSUTCDATETIME());
GO

TRUNCATE TABLE finance.PaymentStaging;
GO

-- 11.5
DROP TABLE IF EXISTS finance.PaymentStaging;
DROP TABLE IF EXISTS dbo.EnterpriseEntityExample;
DROP TABLE IF EXISTS #LateInvoices;
GO


-- ============================================================================
-- Task 12 — The Auditors Are Coming
-- ============================================================================

-- 12.1
DROP TABLE IF EXISTS academic.CoursePassMarkHistory;
GO

CREATE TABLE academic.CoursePassMarkHistory (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    CourseId INT NOT NULL,
    OldPassingScore DECIMAL(5,2),
    NewPassingScore DECIMAL(5,2),
    ChangedAtUtc DATETIME2 NOT NULL,
    ChangedBy NVARCHAR(100) NOT NULL
);
GO

DECLARE @DsaiDeptId2 INT;
SELECT @DsaiDeptId2 = Id FROM academic.Departments WHERE Code = 'DSAI';

UPDATE academic.Courses
SET PassingScore = PassingScore + 5
OUTPUT 
    deleted.Id AS CourseId,
    deleted.PassingScore AS OldPassingScore,
    inserted.PassingScore AS NewPassingScore,
    SYSUTCDATETIME() AS ChangedAtUtc,
    SUSER_SNAME() AS ChangedBy
INTO academic.CoursePassMarkHistory (CourseId, OldPassingScore, NewPassingScore, ChangedAtUtc, ChangedBy)
WHERE DepartmentId = @DsaiDeptId2;
GO

-- 12.2
DROP TABLE IF EXISTS communication.AnnouncementsArchive;
GO

CREATE TABLE communication.AnnouncementsArchive (
    Id BIGINT PRIMARY KEY,
    SectionId BIGINT NULL,
    Title NVARCHAR(200) NOT NULL,
    Body NVARCHAR(MAX) NOT NULL,
    PublishedAtUtc DATETIME2 NULL,
    ExpiresAtUtc DATETIME2 NULL,
    CreatedByUserId BIGINT NOT NULL,
    CreatedAtUtc DATETIME2 NOT NULL,
    UpdatedAtUtc DATETIME2 NOT NULL,
    Status TINYINT NOT NULL,
    ArchivedAtUtc DATETIME2 NOT NULL
);
GO

DELETE FROM communication.Announcements
OUTPUT 
    deleted.Id,
    deleted.SectionId,
    deleted.Title,
    deleted.Body,
    deleted.PublishedAtUtc,
    deleted.ExpiresAtUtc,
    deleted.CreatedByUserId,
    deleted.CreatedAtUtc,
    deleted.UpdatedAtUtc,
    deleted.Status,
    SYSUTCDATETIME() AS ArchivedAtUtc
INTO communication.AnnouncementsArchive (
    Id, SectionId, Title, Body, PublishedAtUtc, ExpiresAtUtc, CreatedByUserId, CreatedAtUtc, UpdatedAtUtc, Status, ArchivedAtUtc
)
WHERE ExpiresAtUtc < DATEADD(MONTH, -6, SYSUTCDATETIME());
GO


-- ============================================================================
-- Task 13 — The Nightly Website Sync
-- ============================================================================

DROP TABLE IF EXISTS dbo.WebsiteCourseCatalog;
GO

CREATE TABLE dbo.WebsiteCourseCatalog (
    CourseId INT PRIMARY KEY,
    Code VARCHAR(30) NOT NULL,
    Title NVARCHAR(200) NOT NULL,
    CreditHours DECIMAL(4,1) NOT NULL,
    IsVisible BIT NOT NULL,
    LastSyncedAtUtc DATETIME2 NOT NULL
);
GO

MERGE dbo.WebsiteCourseCatalog AS target
USING (
    SELECT Id AS CourseId, Code, Title, CreditHours, IsActive
    FROM academic.Courses
) AS source
ON target.CourseId = source.CourseId
WHEN MATCHED AND (
    (source.IsActive = 0 AND target.IsVisible = 1)
    OR
    (source.IsActive = 1 AND (
        target.Code <> source.Code OR
        target.Title <> source.Title OR
        target.CreditHours <> source.CreditHours OR
        target.IsVisible = 0
    ))
) THEN
    UPDATE SET 
        target.Code = source.Code,
        target.Title = source.Title,
        target.CreditHours = source.CreditHours,
        target.IsVisible = source.IsActive,
        target.LastSyncedAtUtc = SYSUTCDATETIME()
WHEN NOT MATCHED BY TARGET AND source.IsActive = 1 THEN
    INSERT (CourseId, Code, Title, CreditHours, IsVisible, LastSyncedAtUtc)
    VALUES (source.CourseId, source.Code, source.Title, source.CreditHours, 1, SYSUTCDATETIME())
OUTPUT 
    $action AS ActionType,
    COALESCE(inserted.CourseId, deleted.CourseId) AS CourseId,
    inserted.Code,
    inserted.Title,
    inserted.CreditHours,
    inserted.IsVisible;
GO
