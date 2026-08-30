# Quality Gates — ATC & CVA

## ATC (ABAP Test Cockpit)

- Run ATC on every new or modified program **before** releasing the transport.
- **Max severity allowed: 1 or 2.**
- Severity 3 is tolerated only when explicitly justified in writing.
- Attach ATC results to the transport request.

## CVA (Code Vulnerability Analyzer)

- CVA **level 1** is mandatory.
- Level 1 findings must be cleared before release.

## Transport Hygiene

- ATC result set must be linked to the transport.
- No `BREAK-POINT`, no `WRITE` debug lines, no `*_BREAK_*` user break-points.
- Never ship hard-coded user names, client numbers, or file paths — use selection-screen parameters or customizing.

## Exception Handling Checklist

Every non-trivial statement needs defensive coding:

| API kind | What to check |
|----------|---------------|
| DB statements | `SY-SUBRC`, and `SY-DBCNT` when relevant |
| Function module (classic) | `SY-SUBRC`, EXCEPTIONS list must be enumerated |
| RFC / BAPI | `RETURN` table inspected + `BAPI_TRANSACTION_ROLLBACK` on error, no unchecked `COMMIT WORK` |
| Object-oriented API | `TRY … CATCH cx_…` around every call that can raise |
| File I/O | `TRY … CATCH cx_sy_file_…` around `OPEN / READ / CLOSE DATASET` |

## Commit/Rollback Discipline

- Single `COMMIT WORK AND WAIT` after a complete logical unit.
- Use `BAPI_TRANSACTION_ROLLBACK` when the return table contains an error of type `E` / `A`.
- Never `COMMIT WORK` inside a loop that iterates over BAPIs for a single logical transaction.

## Internal Table Hygiene

- No header lines. Always declare a separate work area (`gwa_*` for a `gt_*`).
- Prefer `LOOP AT gt_… INTO gwa_… .` — avoid implicit headers.
- Use `FIELD-SYMBOLS` when modifying in-place to avoid unnecessary copies.

## Don'ts

- ❌ No `BREAK-POINT`.
- ❌ No `WRITE` debug output.
- ❌ No dynamic `WHERE` clauses built from unsanitised user input (CVA).
- ❌ No `AUTHORITY-CHECK` omissions — every transaction-level entry must verify authorisations.
