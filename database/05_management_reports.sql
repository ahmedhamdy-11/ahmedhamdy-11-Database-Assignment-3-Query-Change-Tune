-- ============================================================================
-- DATABASE ASSIGNMENT 3: QUERY, CHANGE & TUNE DATA
-- Task 5 — Management Reports
-- Student: Ahmed Hamdy (ahmedhamdy-11)
-- Track: Backend .NET (Cycle 1 - Simulation Academy)
-- Database: LmsTrainingLab
-- CRITICAL RULES:
--   1. NO JOIN anywhere in your answers.
--   2. NO SUBQUERIES in Task 5: exactly ONE table per query.
--   3. Put the task number (-- 5.12) above every answer.
-- ============================================================================

USE LmsTrainingLab;
GO

-- 5.1
-- Marketing needs the course catalog: course code, title and credits, with headers a non-technical person can read.
-- Show the heaviest courses first. Courses with the same credits should be in alphabetical order.
SELECT 
    Code AS [Course Code],
    Title AS [Course Title],
    CreditHours AS [Credit Hours]
FROM academic.Courses
ORDER BY CreditHours DESC, Title ASC;
GO

-- 5.2
-- The quality office wants to call 5 random students for a satisfaction survey.
-- They should get a different 5 every time they ask.
SELECT TOP (5)
    StudentNumber,
    EmergencyContactName,
    EmergencyContactPhone
FROM [identity].StudentProfiles
ORDER BY NEWID();
GO

-- 5.3
-- Some emails were imported with spaces at the start or the end, and those users cannot log in. Find them.
-- Be careful: the obvious solution misses some of them (in SQL Server string equality and LEN() ignore trailing spaces;
-- DATALENGTH() vs DATALENGTH(TRIM()) detects both leading and trailing spaces accurately).
SELECT 
    Id,
    FirstName,
    LastName,
    Email
FROM [identity].Users
WHERE DATALENGTH(Email) <> DATALENGTH(TRIM(Email));
GO

-- 5.4
-- The rule is that emails are stored in lowercase. Find every email that breaks the rule.
-- In SQL Server CP1_CI_AS collation, comparisons are Case-Insensitive by default.
-- An explicit Case-Sensitive (CS/BIN) collation is required to catch uppercase characters.
SELECT 
    Id,
    FirstName,
    LastName,
    Email
FROM [identity].Users
WHERE Email COLLATE Latin1_General_BIN <> LOWER(Email);
GO

-- 5.5
-- Find the emails that are clearly invalid: no @, nothing before the @, or no dot in the part after it.
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
-- IT wants the list of email providers our users use, each one once, alphabetically.
SELECT DISTINCT 
    SUBSTRING(Email, CHARINDEX('@', Email) + 1, LEN(Email)) AS EmailProvider
FROM [identity].Users
WHERE Email LIKE '%@%'
ORDER BY EmailProvider ASC;
GO

-- 5.7
-- Show all users ordered by their last login, most recent first.
-- Users who have never logged in must come at the very end, not at the top.
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
-- Finance wants every payment received during October 2026.
-- Payments made late on 31 October must be included too (half-open range [2026-10-01, 2026-11-01)).
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
-- Fraud check: list the payments made between midnight and 5 in the morning, Cairo time.
-- Show the payment time in Cairo time.
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
-- The schedule office wants every attendance session that was held on a Friday.
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
-- Marketing is sending an SMS campaign to Egyptian mobile numbers only (Vodafone, Etisalat, Orange, WE).
-- Prefixes: +2010 (Vodafone), +2011 (Etisalat), +2012 (Orange), +2015 (WE) or local 010, 011, 012, 015.
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
-- For privacy, the call center screen must show phone numbers with only the first 3 and the last 2 digits visible.
-- Hide the other digits with stars.
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
-- Finance wants the running number at the end of each invoice number (the part after the last dash)
-- as a real number they can sort by.
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
-- The content team wants each lesson's length shown like 1 h 25 min.
-- Lessons without an estimate should show Not set.
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
-- Marketing wants every announcement that mentions a percentage, like 50% off.
-- The wildcard % is escaped via brackets [%].
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
-- The CFO wants the 5 largest invoices. If other invoices have the same amount as the fifth one,
-- they must appear too (TOP WITH TIES).
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
-- Finance wants the top 10% of payments by amount.
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
-- Facilities is moving everything out of Hall A. List all the other sections,
-- including those that have no location yet (IS NULL must be preserved under 3-valued logic).
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
-- For every invoice that still has money owed, show whether it is partially paid or not paid,
-- whether it is overdue, and the percentage paid to one decimal place. Put the largest amounts owed first.
-- An invoice with a total of zero must not break the report (NULLIF prevents division by zero).
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
-- The admin screen shows users 20 per page, newest first. Return page 3 (skip 40, take 20).
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
-- The audit screen has millions of rows. The screen already showed logs up to a certain id.
-- Return the next 50 quickly, in a way that stays fast even on page 10,000 (Keyset Pagination via Clustered Seek).
DECLARE @LastSeenId BIGINT = 50000;

SELECT TOP (50)
    Id,
    OccurredAtUtc,
    ActorUserId,
    ActionCode,
    EntityName,
    EntityKey
FROM operations.AuditLogs
WHERE Id > @LastSeenId
ORDER BY Id ASC;
GO

-- 5.22
-- A colleague wrote a query that takes the first 10 rows of the payments table to show the latest 10 payments on the dashboard.
-- Is it correct? Write the correct one.
-- Explanation: The colleague's query is INCORRECT. Relational tables are unordered mathematical sets;
-- without an explicit ORDER BY clause, SQL Server guarantees no specific order.
-- To show the true latest 10 payments, we must order by payment timestamp descending.
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
-- Challenge. The mobile app cuts lesson titles longer than 40 characters.
-- The content team wants the 10 longest published lesson titles that will be cut.
-- Each title should appear once, ignoring extra spaces at the ends, and written in capitals.
-- Show each title's length, and say whether the lesson is quick (15 minutes or less),
-- standard (up to 45 minutes), long, or not set. Longest titles first.
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
-- Challenge. Finance wants a short overview of overdue invoices that are not fully paid.
-- They want one row for each combination of due month (written like 2026-09), currency,
-- and payment state (partially paid or not paid). Show only the 12 most recent rows, newest month first.
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
