# Database Assignment 3 — Query, Change & Tune Data

**Student Name:** Ahmed Hamdy  
**GitHub Username:** `ahmedhamdy-11`  
**Track:** Backend .NET — Cycle 1 (Simulation Academy)  
**Database:** `LmsTrainingLab` (Microsoft SQL Server)  
**Branch:** `assignment/1-13`  

---

## Overview

This repository contains the complete, production-grade solutions for **Database Assignment 3: Query, Change & Tune Data** at Simulation Academy.

All solutions strictly follow the architectural guidelines:
- **Zero `JOIN` operations anywhere** across solutions.
- **In Task 5: Zero subqueries and strictly ONE table per query**.
- **Execution plan analysis**, I/O work measurement, and graphical execution tree screenshots for Tasks 6 to 9.
- **Set-based DML operations**, single-statement atomic auditing via `OUTPUT`, and idempotent nightly syncing via `MERGE`.

---

## Repository Structure

```text
├── database/
│   ├── 01_the_finance_meeting.sql         -- Task 1: Session working list & urgency priority
│   ├── 02_a_new_department.sql           -- Task 2: Departments, courses, terms, roles, announcements
│   ├── 03_invoice_numbers.sql            -- Task 3: Independent SEQUENCE object & gap mechanics
│   ├── 04_next_summers_timetable.sql     -- Task 4: Set-based bulk sections copy
│   ├── 05_management_reports.sql         -- Task 5: 24 business reports (1 table/query, no JOIN/subquery)
│   ├── 06_reading_the_plan.sql           -- Task 6: Collections screen plan analysis & statistics
│   ├── 07_make_it_faster.sql             -- Task 7: Query tuning & sargability optimization (8 queries)
│   ├── 08_estimate_wrong_spill.sql       -- Task 8: Sort spill to tempdb & statistics resolution
│   ├── 09_one_of_each.sql                -- Task 9: Distinct operators (Hash, Stream, Unique elimination)
│   ├── 10_the_ctos_question.sql          -- Task 10: Numbers vs. GUIDs architectural trade-offs
│   ├── 11_end_of_semester_changes.sql    -- Task 11: Pass mark updates, letter grading, fast truncate
│   ├── 12_the_auditors_are_coming.sql    -- Task 12: Atomic pass-mark history & archiving via OUTPUT
│   ├── 13_the_nightly_website_sync.sql   -- Task 13: MERGE statement & 3-run lifecycle verification
│   └── all_tasks_solution.sql            -- Master script containing all tasks in sequential order
├── docs/
│   ├── screenshots/                      -- High-resolution execution plan & I/O measurement images
│   │   ├── task06_actual_plan.png
│   │   ├── task06_statistics_io_time.png
│   │   ├── task07_before_after_reads.png
│   │   ├── task08_sort_spill_warning.png
│   │   ├── task08_spill_resolved.png
│   │   └── task09_distinct_operators.png
│   └── plans/                            -- Valid SQL Server XML Execution Plan files (.sqlplan)
│       ├── task06_collections_screen.sqlplan
│       ├── task08_sort_spill.sqlplan
│       └── task08_sort_fixed.sqlplan
├── NOTES.md                              -- Comprehensive technical answers, proofs & plan breakdowns
└── README.md                             -- Student details, overview & execution instructions
```

---

## Key Performance Tuning Highlights (Task 7)

By removing non-sargable functions, eliminating implicit type conversions, and embedding parameters via `OPTION (RECOMPILE)`, total logical reads across all 8 queries were reduced from **136,847 reads to under 160 reads (~99.88% reduction)**:

| Task | Anti-Pattern | Slow Reads | Tuned Sargable Rewrite | Tuned Reads | Improvement |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **7.1** | `YEAR()` / `MONTH()` on column | 688 reads (Scan) | Range seek `[2026-03-01, 2026-04-01)` | **13 reads (Seek)** | **53x faster** |
| **7.2** | `DATEDIFF()` on column | 599 reads (Scan) | Column isolated `>= DATEADD(...)` | **76 reads (Seek)** | **7.8x faster** |
| **7.3** | `LEFT(LastName, 3)` | 1,267 reads (Scan) | Prefix pattern `LastName LIKE N'Abd%'` | **20 reads (Seek)** | **63x faster** |
| **7.4** | `Id + 1 = 50001` | 130,022 reads (Scan) | Constant evaluated: `Id = 50000` | **4 reads (Seek)** | **32,500x faster** |
| **7.5** | Type mismatch (`NVARCHAR` literal) | 728 reads (Scan) | Matched `VARCHAR`: `'INV-2026-00001'` | **6 reads (Seek)** | **121x faster** |
| **7.6** | `UPPER(Email)` on CI Collation | 1,009 reads (Scan) | Redundant function removed: `Email = @Email` | **3 reads (Seek)** | **336x faster** |
| **7.7** | Catch-all `(@Param IS NULL OR ...)` | 1,267 reads (Scan) | `OPTION (RECOMPILE)` parameter embedding | **18 reads (Seek)** | **70x faster** |
| **7.8** | Concatenation in WHERE | 1,267 reads (Scan) | Direct composite match: `LastName = ... AND FirstName = ...` | **18 reads (Seek)** | **70x faster** |

---

## Execution Instructions

To execute the entire solution suite in SQL Server:
```sql
-- Open SQL Server Management Studio (SSMS) or sqlcmd
-- Connect to LmsTrainingLab instance:
USE LmsTrainingLab;
GO

-- Run individual task scripts from the database/ directory,
-- or run the all-in-one consolidated script:
:r "database\all_tasks_solution.sql"
```

For full architectural write-ups and detailed query plan explanations, refer to [NOTES.md](file:///c:/Users/Ahmed%20Hamdy/Desktop/ahmedhamdy-11-Database-Assignment-3-Query-Change-Tune/NOTES.md).
