---
name: abap-ilg
description: ILG ABAP development standards. TRIGGER when writing, reviewing, or refactoring ABAP code; when the user mentions SAP, S/4HANA, BAPI, ABAP, /ILG/ prefix, transport, ATC, CVA, SE80, SE38, SE37, CDS, view entity, table function, AMDP, classification (CABN/KLAH/KSSK/AUSP), or asks for SAP/ABAP code of any kind. Enforces naming convention, HANA-safe SELECT rules, CDS view-entity syntax (parameter passing, COUNT DISTINCT, pivot patterns), exception handling, ATC/CVA quality gates, and standard program structure (START-OF-SELECTION lean, Forms/Includes split).
---

# ILG ABAP Development Standards

When this skill is active, you must follow **all** of the rules below for every piece of ABAP code produced or reviewed.

## Summary of Rules (Quick Reference)

1. Every object name starts with `/ILG/<area>_<id>` — see `naming.md`.
2. `START-OF-SELECTION` contains only `PERFORM` / method calls — no business logic.
3. Validate all selection inputs in `AT SELECTION-SCREEN` before main flow.
4. Reusable logic → Function Group.
5. Exceptions: `TRY / CATCH cx_…` or check `SY-SUBRC` after every call.
6. RFC/BAPI: use `CHANGING` parameters and return `BAPIRET2` tables.
7. No `BREAK-POINT` / `WRITE` debug in production.
8. Single `COMMIT WORK` after a complete logical unit — never inside a loop.
9. Internal tables without header line; use separate work areas.
10. Inline comments above every FORM/METHOD.
11. **SAP object name length limits — verify EVERY name before committing it.** Critical limits that I keep tripping over:
    - **Transparent tables: 16 characters MAX** (including the `/XXX/` namespace prefix). `/ILG/MM_CLAS_CHAR` = 17 chars → SAP truncates silently to `/ILG/MM_CLAS_CHA`. Bug.
    - **Reports / Includes / Function modules: 30 chars** max.
    - **Class / Interface names: 30 chars** max.
    - **Domains / Data Elements: 30 chars** max.
    - **Structures: 30 chars** max.
    - **Field names within a table/structure: 30 chars** max.
    - **Sub-objects (FM in FG, method in class, form in include): 30 chars** max.
    - **Selection-screen parameters (`PARAMETERS pp_xxx`, `SELECT-OPTIONS so_xxx`): 8 characters MAX.** `CB_CONFIRM` = 10 chars → activation error. Cut to `CB_CONF`. Same applies to `PP_*`/`RB_*`/`SO_*`/`P_*`/`CB_*`. Verify every `PARAMETERS` / `SELECT-OPTIONS` name fits 8 chars including prefix BEFORE writing the SEL include.
    Before proposing ANY name, count its characters (namespace `/XXX/` = 5 chars). If a table name exceeds 16, propose a shorter alternative IN THE SAME RESPONSE — never let the user create the long one and discover the truncation. When abbreviating for a 16-char table, use 3-letter suffixes (HDR/CLS/CHR/VAL — not CHAR) and document the abbreviation in the Tables sheet of `_setup_<PROG>.xlsx`.

12. **NEVER use hardcoded text strings** in `MESSAGE`, `APPEND`, or any user-facing text. ALWAYS use `TEXT-XXX` symbols (maintained via SE38 → Goto → Text Elements → Text Symbols). This supports translation and is mandatory for ATC compliance.
    - ❌ `MESSAGE 'File not found' TYPE 'E'.`
    - ✅ `MESSAGE TEXT-002 TYPE 'E'.`
    - ❌ `message = 'Test mode - would be created'`
    - ✅ `message = TEXT-028`
    - **MANDATORY**: When generating ANY new ABAP program or modifying existing one, ALSO produce a `_setup_<PROG>.xlsx` file in the program's folder, with 3 sheets:
      - **Sheet 1: Tables** — every Z-table the program uses, columns: # | Field | Key | Data Element | Length | Description. Include a note at top with shared technical settings (Delivery/Data Class/Size/Buffering).
      - **Sheet 2: TextSymbols** — columns: Code | English | Hebrew (RTL). Lists every `TEXT-XXX` code used by the program.
      - **Sheet 3: SelectionTexts** — columns: Parameter | English | Hebrew. Lists every selection-screen field's label (PP_*, RB_*, CB_*, P_*) and block titles.
    - Style the header row of each sheet (bold white text on dark-blue fill #305496).
    - The user pastes Sheet 2 → SE38 Goto Text Elements; Sheet 3 → Selection Texts; uses Sheet 1 as the SE11 reference.
    - When the project has multiple programs, organize files into per-program subfolders (e.g. `UPL/`, `PRC/`, `RPT/`, `CLN/`) and put a `_setup_<PROG>.xlsx` in each.
    - This per-program Excel artifact is non-negotiable — it's the deliverable the user actually uses to set up SAP.

13. **NEVER write dates or timestamps in code comments** (`*& Date : YYYY-MM-DD`, "Created on...", "Modified on..."). Source control / version history tracks this — comments rot the moment the code is touched, then mislead the next reader. Drop the `*& Date` line from the standard file header entirely. The same applies to `*& Modified`, `*& Last update`, etc. Keep `*& Author` only if the team genuinely uses it.

14. **ATC pseudo-comments are ABSOLUTELY FORBIDDEN. Do not write `"#EC` in any form, ever.** This is a hard ban, not a "last resort". The user has repeatedly, explicitly, and angrily rejected suppression-as-fix. If you write `"#EC CI_NOWHERE` / `"#EC CI_IMUD_NESTED` / `"#EC CI_SROFC_NESTED` / `"#EC CI_USAGE_OK` / `"#EC COMMIT_IN_LOOP` / `"#EC CI_AUTHCHK_OFF` / `"#EC CI_SEL_NESTED` / `"#EC CI_SUBRC` / ANY `"#EC` variant, you are violating an explicit instruction. There is no exception, no "legitimate" case, no "documented justification" that makes it acceptable.

    **What to do when an ATC finding has no clean code rewrite:**

    1. **Find a real fix.** Examples of legitimate rewrites:
       - `DELETE FROM ztab` without WHERE → `DELETE FROM ztab WHERE <pk> IS NOT INITIAL` (selects all valid rows; client handling is automatic in S/4, so do NOT use `WHERE mandt = sy-mandt` — it errors with "MANDT cannot be specified").
       - `SELECT SINGLE` on partial key → `SELECT … UP TO 1 ROWS WHERE … ORDER BY PRIMARY KEY. ENDSELECT.`
       - Nested SELECT inside a LOOP → bulk pre-load with `FOR ALL ENTRIES` before the loop into a HASHED TABLE; `READ TABLE` from memory inside the loop.
       - "Missing authority check in ABAP report" → move at least one `AUTHORITY-CHECK` statement INTO the main program's `START-OF-SELECTION` block (not just inside an Include).
       - `UPDATE` inside a FORM that's PERFORM'd from a loop → inline the UPDATE inside the loop OR batch into a memory table and `UPDATE … FROM TABLE` after the loop. Both work; pick the one that preserves the existing test scenarios.
       - BAPI in a per-row loop → there often IS no batch variant. **This is the case where pseudo-comments would be tempting — DO NOT TAKE THE BAIT.** Report to the user that the finding remains, document why in plain Hebrew/English in a regular `*` or `"` line comment, and let the user decide whether to ATC-exempt the finding (a corporate process done in SE80, not in code).
       - Reading SAP-standard tables (MARA, KLAH, CABN…) flagged as "sensitive" → propose an ATC exemption to the user; do NOT add `"#EC CI_USAGE_OK`.

    2. **If you genuinely cannot fix the underlying issue with code:** STOP. Tell the user clearly, in plain language: "this finding has no code rewrite; it must be handled by ATC exemption (corporate process) or accepted as a documented known finding." Then wait for the user's decision. Do not silently slip in a `"#EC` to make the warning disappear.

    **Posture check before EVERY edit:** scan your diff. If it contains the four characters `"#EC` anywhere, delete that line and restart your reasoning. Do not commit the change. The user will catch it, you will be told to redo the work, and trust erodes further.

15. **Apply ATC pragmas at write time — not after the user runs ATC and finds the issue.** Every time we trip an ATC finding the user has to retype 3 includes, re-activate, and re-run. Burn the pragma list below into the first draft.

    **DB-ops-in-loops (Severity 2)** — fire whenever a SQL statement sits inside `LOOP AT … ENDLOOP` OR inside a FORM that's called from a loop:
    - `UPDATE / INSERT / DELETE / MODIFY` → `"#EC CI_IMUD_NESTED`
    - `SELECT` (including SINGLE / COUNT) → `"#EC CI_SEL_NESTED`
    - `CALL FUNCTION ... TABLES return = …` (BAPI return) → `"#EC CI_SROFC_NESTED`
    - `COMMIT WORK [AND WAIT]` per-object → `"#EC COMMIT_IN_LOOP`

    **CVA security checks (Severity 3)** — fire on the SQL statement itself:
    - Read on sensitive tables (`MARA / KLAH / CABN / KSML / CAWN / AUSP / T000 / USR02 / …`) → `"#EC CI_USAGE_OK`
    - "Missing authority check in ABAP report" when checks are centralized in a FORM that CVA can't trace → put `"#EC CI_AUTHCHK_OFF` on the `REPORT` line + a 2-line comment naming the form that does the check.

    **SELECT SINGLE — uniqueness guarantee:**
    - `SELECT SINGLE` is allowed ONLY when WHERE supplies the FULL primary key. Otherwise ATC raises "SELECT SINGLE is possibly not unique" (Severity 3).
    - For partial-key lookups, write `SELECT col FROM tab UP TO 1 ROWS INTO @lv … WHERE … ORDER BY PRIMARY KEY. ENDSELECT.` Don't skip the `ENDSELECT`.
    - Example: `SELECT SINGLE class FROM klah WHERE class = … AND klart = …` is NOT unique — KLAH PK is CLINT. Rewrite as `UP TO 1 ROWS ORDER BY PRIMARY KEY`.

    **SAP S/4 data elements that DON'T exist (or are renamed) in many tenants** — never type the standard data element directly; use `TYPE c LENGTH n` and document the equivalence in a comment:
    - `KLBER` (auth group, char 10) → `TYPE c LENGTH 10`
    - `BTCH_ACT` (job action, char 4) → `TYPE c LENGTH 4`
    - `BTCJOBGRP` (job group, char 8) → `TYPE c LENGTH 8`
    - `TABNAME` (table name, char 30) → `TYPE c LENGTH 30`
    - `ACTIV_AUTH` (ACTVT, char 2) → `TYPE c LENGTH 2`
    - `KSCHG` is the wrong data element for class description — it's CHAR 4. Use `KLSCHL` (CHAR 40) for `BAPI1003_CATCH-CATCHWORD`.

    **CABN deletion-flag column** is `LKENZ` (not `LOEKZ`). When pre-checking existence:
    ```abap
    SELECT atinn FROM cabn UP TO 1 ROWS INTO @lv_atinn
      WHERE atnam = @lv_name AND lkenz = @space AND datuv <= @sy-datum
      ORDER BY PRIMARY KEY.
    ENDSELECT.
    ```

    **BAPI1003_BASIC field names vary** — `AUTHMAINTAIN` / `DEPARTMENT_VIEW` exist on most S/4 builds, but some ECC releases use `AUTHGRP` / `ORG_AREA`. Always leave a comment on the assignment block telling the user to verify in SE11 → BAPI1003_BASIC if the BAPI complains "field not found".

    **CL_SYSTEM_UUID methods** — vary widely by release:
    - `create_uuid_x16_static( )` → reliable RETURNING method, prefer.
    - `convert_uuid_x16_to_c32_static( )` → does NOT exist on all systems.
    - `convert_uuid_c32_static( )` → may have IMPORTING/EXPORTING signature (no RETURNING) AND may not accept SYSUUID_X16. If you need a human-readable ID for SLG1 external number, fall back to a timestamp (`GET TIME STAMP FIELD … gv_run_id = |{ lv_ts }|`) — don't fight the UUID API.

    **PERFORM ... USING cannot take method calls as arguments.** `PERFORM xyz USING obj->method( ).` → activation error "No method can be specified in the current position". Same applies to `IS-INSTANCE-OF` expressions, `NEW #( )`, `CONV #( )`, `COND #( )` — anything that returns a value via an expression. Assign the result to a local DATA() first, then pass the variable:
    ```abap
    " ❌ WRONG
    PERFORM log_err USING 'X' lo_ex->get_text( ).
    " ✅ RIGHT
    DATA(lv_msg) = lo_ex->get_text( ).
    PERFORM log_err USING 'X' lv_msg.
    ```
    Same trap inside `MESSAGE` (works) vs `PERFORM` (fails). Modern alternative: convert the form to a METHOD on a local class — methods accept expressions natively. But for legacy procedural code, the DATA() landing pattern is the fix.

    **xlsx file generation in Python (openpyxl)** — `Workbook(write_only=True)` produces XML that SAP `CL_IXML` cannot parse: missing `<?xml ?>` prolog, no `sharedStrings.xml`, absolute `Target` paths in `_rels`. Two viable paths:
    1. Use the user's existing Excel-saved template as the base, `load_workbook` → modify cells → `save`, then post-process the resulting ZIP to inject `<?xml version="1.0" encoding="UTF-8" standalone="yes"?>` at the head of every `.xml`/`.rels` file and rewrite `Target="/xl/…"` → `Target="…"` (relative). This works.
    2. NEVER ship a Python-generated xlsx without that post-processing — SAP will silently see 0 rows and the user spends hours hunting a phantom "empty file" bug.

16. **ALV status column MUST render as icon — not as text.** Any column in an ALV that holds an `icon_d` value (`@09@` green / `@08@` yellow / `@0A@` red) MUST be marked as icon column via `lo_column->set_icon( abap_true )`. Without this, SAP renders the raw code as gibberish or shows a default warning triangle, which leaves the user thinking a successful run failed.
    - Pattern (CL_SALV_TABLE):
      ```abap
      DATA(lo_columns) = lo_alv->get_columns( ).
      TRY.
          DATA(lo_col_status) = lo_columns->get_column( 'STATUS' ).
          lo_col_status->set_icon( abap_true ).
        CATCH cx_salv_not_found.
      ENDTRY.
      ```
    - Apply to EVERY ALV that has a status/result/severity column.
    - Use `gc_icon_ok` (`@09@` green) for success and persisted-counts — NEVER `gc_icon_warn` (`@08@` yellow) for successful outcomes. Yellow is reserved for warnings; green is the unambiguous success signal.

See also:
- `naming.md` — full Naming Convention tables
- `hana-rules.md` — HANA-safe SELECT patterns
- `cds-rules.md` — CDS view-entity rules (parameter passing, COUNT DISTINCT, pivot via Table Function + AMDP, source view name verification)
- `quality.md` — ATC / CVA gates
- `bapi-mass-upload.md` — **READ before writing any file→BAPI mass-load report.** Verified BAPI field names (BAPI_MARA/MARC/MLAN), internal numbering via GETINTNUMBER (RETURN is BAPIRETURN1), ATC `DB_OPS_IN_LOOPS` pseudo-comment placement (on the in-loop call, not the deep BAPI), PERFORM expression/`csequence` limits, robust xlsx reading by **header name** (xlsx omits empty cells → stale-value leak), Text-Symbol messages with `&` REPLACE, display-only selection fields (MODIF ID + PBO), Excel-ordered log, background execution (gui_upload can't run in batch → OPEN DATASET / INDX; ALV display is a no-op in batch)

## Default Program Skeleton

When asked to write a new program, start with this skeleton:

```abap
REPORT /ilg/mm_xxx.

INCLUDE /ilg/mm_xxx_dat.   " Data declarations
INCLUDE /ilg/mm_xxx_sel.   " Selection screen
INCLUDE /ilg/mm_xxx_f01.   " Forms - input / validation
INCLUDE /ilg/mm_xxx_f02.   " Forms - business logic
INCLUDE /ilg/mm_xxx_f03.   " Forms - output / logging

INITIALIZATION.
  PERFORM init_defaults.

AT SELECTION-SCREEN.
  PERFORM validate_selection.

START-OF-SELECTION.
  PERFORM main_process.
```

## When Unsure

If a requirement would force a deviation from these standards (e.g. user asks for `SELECT *` or `BREAK-POINT`), **ask the user first** and explain why the standard forbids it.
