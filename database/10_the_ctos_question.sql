-- ============================================================================
-- DATABASE ASSIGNMENT 3: QUERY, CHANGE & TUNE DATA
-- Task 10 — The CTO's Question
-- Student: Ahmed Hamdy (ahmedhamdy-11)
-- Track: Backend .NET (Cycle 1 - Simulation Academy)
-- Database: LmsTrainingLab
-- ============================================================================

/*
Question from CTO:
"When should we use numbers and when should we use GUIDs for ids?"

--------------------------------------------------------------------------------
1. COMPREHENSIVE ARCHITECTURAL COMPARISON & TRADE-OFFS
--------------------------------------------------------------------------------

| Dimension / Aspect        | Sequential Numbers (INT / BIGINT)                 | Globally Unique Identifiers (GUID / UNIQUEIDENTIFIER) |
| :---                      | :---                                              | :---                                                   |
| Storage Footprint         | 4 bytes (INT) / 8 bytes (BIGINT)                   | 16 bytes (4x to 2x larger)                             |
| Clustered Index Overhead  | Compact, dense B-tree pages. Highly cache-friendly| Bloats index pages and all non-clustered leaf nodes    |
| Index Fragmentation       | Nearly 0% fragmentation on append-only inserts     | Severe B-tree fragmentation & page splits with NEWID() |
| Distributed Generation   | Requires centralized DB round-trip (Identity/Seq) | Client-side, offline, distributed generation safe      |
| Information Security      | Predictable, vulnerable to URL scraping/enumeration| Cryptographically unguessable, opaque                  |
| Merging & Replication     | Collisions occur when merging distributed DBs      | Globally collision-free across distributed systems     |

--------------------------------------------------------------------------------
2. WHEN TO USE NUMBERS (INT / BIGINT):
--------------------------------------------------------------------------------
- High-volume transaction processing (financial ledgers, audit logs, order line items).
- High-concurrency append workloads where insert throughput and cache density are critical.
- Tables with multiple secondary indexes (since the clustered key is duplicated into every non-clustered index leaf page).
- Internal surrogate keys where IDs are never directly exposed to external end-users.

--------------------------------------------------------------------------------
3. WHEN TO USE GUIDs (UNIQUEIDENTIFIER):
--------------------------------------------------------------------------------
- Distributed offline architectures (mobile apps generating IDs before syncing to the server).
- Microservices architectures where autonomous services generate identifiers without centralized database coordination.
- Public-facing APIs and URLs where exposing sequential IDs would leak business metrics (e.g. order volume) or invite enumeration attacks.
- Multi-tenant data consolidation and database merging scenarios.

--------------------------------------------------------------------------------
4. INDUSTRY BEST-PRACTICE RECOMMENDATION: THE HYBRID PATTERN
--------------------------------------------------------------------------------
The optimal architectural design adopted by top-tier enterprise systems is the "Hybrid Key Architecture":
1. Internal Clustered Key: BIGINT IDENTITY or SEQUENCE for internal joins, foreign keys, and clustered storage (ensuring optimal cache locality and 0% fragmentation).
2. Public External Identifier: UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID() with a unique non-clustered index, exposed in external APIs, URLs, and client interactions.
*/

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
