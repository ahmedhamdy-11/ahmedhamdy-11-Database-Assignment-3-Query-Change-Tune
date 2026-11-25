-- Task 12 — The Auditors Are Coming


USE LmsTrainingLab;
GO

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

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

DECLARE @DeptId INT;
SELECT @DeptId = Id FROM academic.Departments WHERE Code = 'DSAI';

-- Perform pass-mark update and record audit history in the SAME atomic statement using OUTPUT INTO:
UPDATE academic.Courses
SET PassingScore = PassingScore + 5
OUTPUT 
    deleted.Id AS CourseId,
    deleted.PassingScore AS OldPassingScore,
    inserted.PassingScore AS NewPassingScore,
    SYSUTCDATETIME() AS ChangedAtUtc,
    SUSER_SNAME() AS ChangedBy
INTO academic.CoursePassMarkHistory (
    CourseId,
    OldPassingScore,
    NewPassingScore,
    ChangedAtUtc,
    ChangedBy
)
WHERE DepartmentId = @DeptId;
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

-- Delete expired announcements and insert into archive in ONE single statement:
DELETE FROM [communication].[Announcements]
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
    Id,
    SectionId,
    Title,
    Body,
    PublishedAtUtc,
    ExpiresAtUtc,
    CreatedByUserId,
    CreatedAtUtc,
    UpdatedAtUtc,
    Status,
    ArchivedAtUtc
)
WHERE ExpiresAtUtc < DATEADD(MONTH, -6, SYSUTCDATETIME());
GO
