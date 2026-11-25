-- Task 2 — A New Department


USE LmsTrainingLab;
GO

-- 2.1
IF NOT EXISTS (SELECT 1 FROM academic.Departments WHERE Code = 'DSAI')
BEGIN
    INSERT INTO [academic].[Departments] (
        Code,
        Name,
        Description,
        IsActive,
        CreatedAtUtc,
        IsDeleted
    )
    VALUES (
        'DSAI',
        N'Data Science & Artificial Intelligence',
        N'Department specializing in artificial intelligence, machine learning, and advanced analytics.',
        1,
        SYSUTCDATETIME(),
        0
    );
END;
GO

-- 2.2
DECLARE @DsaiDeptId INT;
SELECT @DsaiDeptId = Id FROM [academic].[Departments] WHERE Code = 'DSAI';

IF NOT EXISTS (SELECT 1 FROM [academic].[Courses] WHERE Code = 'DSAI-101')
BEGIN
    INSERT INTO [academic].[Courses] (
        DepartmentId,
        Code,
        Title,
        Description,
        CreditHours,
        PassingScore,
        IsActive,
        CreatedAtUtc
    )
    VALUES (
        @DsaiDeptId,
        'DSAI-101',
        N'Introduction to Data Analysis',
        N'Foundational concepts of exploratory data analysis, data wrangling, and statistical interpretation.',
        3.0,
        60.0,
        1,
        SYSUTCDATETIME()
    );
END;
GO

-- 2.3
IF NOT EXISTS (SELECT 1 FROM [delivery].[AcademicTerms] WHERE AcademicYear = 2027 AND TermCode = 'SUMMER')
BEGIN
    INSERT INTO [delivery].[AcademicTerms] (
        AcademicYear,
        TermCode,
        Name,
        StartDate,
        EndDate,
        RegistrationStartDate,
        RegistrationEndDate,
        Status
    )
    VALUES (
        2027,
        'SUMMER',
        N'Summer 2027',
        '2027-06-15',
        '2027-08-31',
        '2027-05-01',
        '2027-06-10',
        1
    );
END;
GO

-- 2.4
IF NOT EXISTS (SELECT 1 FROM [communication].[Announcements] WHERE Title = N'Summer 2027 Registration Opens May 1')
BEGIN
    INSERT INTO communication.Announcements (
        SectionId,
        Title,
        Body,
        PublishedAtUtc,
        ExpiresAtUtc,
        CreatedByUserId,
        CreatedAtUtc,
        UpdatedAtUtc,
        Status
    )
    VALUES (
        NULL,
        N'Summer 2027 Registration Opens May 1',
        N'Dear students, registration for the Summer 2027 academic term officially opens on 1 May 2027 and will close on 10 June 2027.',
        SYSUTCDATETIME(),
        '2027-06-10T23:59:59',
        1,
        SYSUTCDATETIME(),
        SYSUTCDATETIME(),
        1
    );
END;
GO

-- 2.5
IF NOT EXISTS (SELECT 1 FROM [identity].Roles WHERE Code = 'TEACHING_ASSISTANT')
BEGIN
    INSERT INTO [identity].Roles (
        Code,
        Name,
        Description,
        IsSystem,
        IsDeleted
    )
    VALUES (
        'TEACHING_ASSISTANT',
        N'Teaching Assistant',
        N'Assists course instructors in discussion sessions, student tutoring, and grading assistance.',
        0,
        0
    );
END;
GO
