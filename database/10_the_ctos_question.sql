-- Task 10 — The CTO's Question

USE LmsTrainingLab;
GO

-- Demonstration script illustrating the Hybrid Key Architecture:
DROP TABLE IF EXISTS dbo.EnterpriseEntityExample;
GO

CREATE TABLE dbo.EnterpriseEntityExample (
    -- Internal surrogate key: compact, cache-friendly, zero fragmentation
    InternalId BIGINT IDENTITY(1,1) NOT NULL,
    
    -- Public external key: unguessable, safe for distributed client generation
    PublicId UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    
    EntityName NVARCHAR(100) NOT NULL,
    CreatedAtUtc DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),

    CONSTRAINT PK_EnterpriseEntity PRIMARY KEY CLUSTERED (InternalId),
    CONSTRAINT UQ_EnterpriseEntity_PublicId UNIQUE NONCLUSTERED (PublicId)
);
GO
