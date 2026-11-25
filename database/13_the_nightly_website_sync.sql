-- Task 13 — The Nightly Website Sync
GO

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

-- Step 1: Create the public website course catalog table
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

-- TEST HARNESS: LIFECYCLE VERIFICATION (3-RUN DEMONSTRATION)

PRINT '=== RUN 1: INITIAL SYNC (Populate website with active courses) ===';
MERGE dbo.WebsiteCourseCatalog AS target
USING (
    SELECT Id AS CourseId, Code, Title, CreditHours, IsActive
    FROM [academic].[Courses]
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

PRINT '=== MODIFY COURSES FOR VERIFICATION ===';
-- Rename Course 1
UPDATE academic.Courses 
SET Title = N'Introduction to Computer Science (2027 Edition)' 
WHERE Id = 1;

-- Deactivate Course 2
UPDATE academic.Courses 
SET IsActive = 0 
WHERE Id = 2;
GO

PRINT '=== RUN 2: RE-RUN SYNC (Should update Course 1 and hide Course 2) ===';
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

PRINT '=== RUN 3: THIRD RUN (MUST CHANGE NOTHING - 0 Rows Affected) ===';
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

-- Revert modifications to preserve clean dataset
UPDATE academic.Courses SET Title = N'Introduction to Computer Science' WHERE Id = 1;
UPDATE academic.Courses SET IsActive = 1 WHERE Id = 2;
GO
