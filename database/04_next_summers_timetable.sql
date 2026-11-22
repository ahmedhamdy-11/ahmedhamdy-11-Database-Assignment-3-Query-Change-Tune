-- ============================================================================
-- DATABASE ASSIGNMENT 3: QUERY, CHANGE & TUNE DATA
-- Task 4 — Next Summer's Timetable
-- Student: Ahmed Hamdy (ahmedhamdy-11)
-- Track: Backend .NET (Cycle 1 - Simulation Academy)
-- Database: LmsTrainingLab
-- Rules: No JOIN anywhere. Bulk set-based copy into the new term.
-- ============================================================================

USE LmsTrainingLab;
GO

-- Step 1: Locate the Summer 2027 Term ID
DECLARE @Summer2027TermId INT;
SELECT @Summer2027TermId = Id
FROM delivery.AcademicTerms
WHERE AcademicYear = 2027 AND TermCode = 'SUMMER';

-- Step 2: Dynamically detect the most recent term with scheduled sections
DECLARE @MostRecentTermId INT;
SELECT TOP 1 @MostRecentTermId = TermId
FROM delivery.Sections
WHERE TermId <> @Summer2027TermId
GROUP BY TermId
ORDER BY MAX(CreatedAtUtc) DESC;

-- Step 3: Copy all sections into the new term in a single set-based statement
IF NOT EXISTS (SELECT 1 FROM delivery.Sections WHERE TermId = @Summer2027TermId)
BEGIN
    INSERT INTO delivery.Sections (
        CourseId,
        TermId,
        SectionCode,
        Capacity,
        Location,
        CreatedAtUtc,
        DeliveryMode,
        Status
    )
    SELECT 
        CourseId,
        @Summer2027TermId,
        SectionCode,
        Capacity,
        Location,
        SYSUTCDATETIME(),
        DeliveryMode,
        Status
    FROM delivery.Sections
    WHERE TermId = @MostRecentTermId;
END;

-- Step 4: Show the newly created sections when finished
SELECT 
    Id AS SectionId,
    CourseId,
    TermId,
    SectionCode,
    Capacity,
    Location,
    DeliveryMode,
    Status
FROM delivery.Sections
WHERE TermId = @Summer2027TermId;
GO
