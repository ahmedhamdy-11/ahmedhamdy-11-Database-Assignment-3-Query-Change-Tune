-- Task 5 — Management Reports


USE LmsTrainingLab;
GO

-- 5.1

SELECT 
    Code AS [Course Code],
    Title AS [Course Title],
    CreditHours AS [Credit Hours]
FROM [academic].[Courses]
ORDER BY CreditHours DESC, Title ASC;
GO

-- 5.2

SELECT TOP (5)
    StudentNumber,
    EmergencyContactName,
    EmergencyContactPhone
FROM [identity].[StudentProfiles]
ORDER BY NEWID();
GO

-- 5.3

SELECT 
    Id,
    FirstName,
    LastName,
    Email
FROM [identity].[Users]
WHERE DATALENGTH(Email) <> DATALENGTH(TRIM(Email));
GO

-- 5.4

SELECT 
    Id,
    FirstName,
    LastName,
    Email
FROM [identity].[Users]
WHERE Email COLLATE Latin1_General_BIN <> LOWER(Email);
GO

-- 5.5

SELECT 
    Id,
    FirstName,
    LastName,
    Email
FROM [identity].[Users]
WHERE Email NOT LIKE '%@%'
   OR Email LIKE '@%'
   OR Email NOT LIKE '%@%.%';
GO

-- 5.6

SELECT DISTINCT 
    SUBSTRING(Email, CHARINDEX('@', Email) + 1, LEN(Email)) AS EmailProvider
FROM [identity].[Users]
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
FROM [identity].[Users]
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
FROM [finance].[Payments]
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
FROM [finance].[Payments]
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
FROM [attendance].[AttendanceSessions]
WHERE DATENAME(WEEKDAY, SessionDate) = 'Friday';
GO

-- 5.11

SELECT 
    Id,
    FirstName,
    LastName,
    PhoneNumber
FROM [identity].[Users]
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
FROM [identity].[Users]
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
FROM [finance].[Invoices]
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
FROM [content].[Lessons]
GO

-- 5.15

SELECT 
    Id,
    Title,
    Body,
    PublishedAtUtc
FROM [communication].[Announcements]    
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
FROM [finance].[Invoices]
ORDER BY TotalAmount DESC;
GO

-- 5.17

SELECT TOP (10) PERCENT
    Id,
    InvoiceId,
    Amount,
    CurrencyCode,
    PaidAtUtc
FROM [finance].[Payments]
ORDER BY Amount DESC;
GO

-- 5.18

SELECT 
    Id,
    CourseId,
    TermId,
    SectionCode,
    Location
FROM [delivery].[Sections]
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
FROM [finance].[Invoices]
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
FROM [identity].[Users]
ORDER BY CreatedAtUtc DESC, Id DESC
OFFSET 40 ROWS FETCH NEXT 20 ROWS ONLY;
GO

-- 5.21

DECLARE @LastSeenId BIGINT = 50000;

SELECT TOP (50)
    Id,
    OccurredAtUtc,
    ActorUserId,
    ActionCode,
    EntityName,
    EntityKey
FROM [operations].[AuditLogs]
WHERE Id > @LastSeenId
ORDER BY Id ASC;
GO

-- 5.22

SELECT TOP (10)
    Id,
    InvoiceId,
    Amount,
    CurrencyCode,
    PaidAtUtc
FROM [finance].[Payments]
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
FROM [content].[Lessons]
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
FROM [finance].[Invoices]
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
