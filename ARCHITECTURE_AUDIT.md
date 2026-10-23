# Source Audit and Requirements Matrix

| Requirement | Source evidence | Implemented status | Verification |
|---|---|---|---|
| Keep Project B primary | B contains backend, React Admin, Flutter; A contributes device/fingerprint apps | Done in package structure | Static |
| One backend/database | Device event API lives in B attendance app and `Attendance` model | Implemented | Django unavailable |
| Multiple daily sessions | B had unique employee/date constraint; new migration removes it; check-in creates row per open/closed cycle | Implemented | Django unavailable |
| Fingerprint alternating actions | A's `record_fingerprint_attendance` pattern adapted to B; serialized event endpoint locks device/employee | Implemented | Django unavailable |
| Idempotent device scan | Device/event UUID uniqueness and device FIFO queue | Implemented | Queue unit only; backend not run |
| Permission defaults | Employee model defaults all false; migration preserves old effective mobile behavior | Implemented | Migration not run |
| GPS/photo enforcement | B mobile API checks GPS; optional photo parsing and conditional required check; photo discarded when off | Implemented | Django unavailable |
| Cross-method actions | Action-level method audit separate from session check-in source | Implemented | Django unavailable |
| Manual Admin attendance | Scoped role-checked API and employee drawer button; actor audit | Implemented | Django unavailable/UI build unavailable |
| Enrollment and device management | A device/fingerprint models/endpoints; scoped device API and Admin page | Partial: status polling/history UI omitted | Static |
| Flutter multi-session status | Session parser, repeat check-in state and session summary | Implemented for today view; historical session screen omitted | Flutter unavailable |
| Data protection | New migrations do not delete/overwrite attendance rows; new null evidence supports non-GPS events | Designed data-preserving | No DB/restore check |

The previous transcript quoted comparison counts (144 identical, 98 modified, 127 A-only, 116 B-only); these were not independently reproduced in this run and are not used as verified findings. Archive `.git` internals were not extracted into a working checkout, so Git status, uncommitted diff, and applied migration state remain UNKNOWN.
