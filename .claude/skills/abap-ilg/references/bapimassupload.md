# BAPI Mass-Upload Programs & Hard-Won Traps

Practical rules for reports that read a file (xlsx) and create master data in a loop via BAPI
(learned building `/ILG/MM_MATERIAL_MASS_CREATE`). **Read this before writing any /ILG/ BAPI
mass-load report.** Each item is a real bug that cost a debugging cycle.

---

## 1. BAPI field names — NEVER guess, always verify on leanx.eu / SE11
Wrong field name = activation failure. Confirmed names for material BAPIs:

| Structure | Correct field | Common wrong guess |
|---|---|---|
| BAPI_MARA / BAPI_MARAX | `BATCH_MGMT` (XCHPF) | ❌ batch_mng |
| BAPI_MARA | `MANU_MAT` (MFRPN) | ❌ mfr_pno / MFR_PNO (does NOT exist) |
| BAPI_MARA | `ITEM_CAT` (MTPOS_MARA, gen. item cat. grp) | — |
| BAPI_MARC / BAPI_MARCX | `SOURCELIST`, `SERNO_PROF`, `PROFIT_CTR` | (all correct, no underscore on SOURCELIST) |
| BAPI_MBEW | `VAL_AREA`, `VAL_CLASS`, `PRICE_CTRL`, `PRICE_UNIT` | — |
| BAPI_MLAN | `TAX_TYPE_1..9` / `TAXCLASS_1..9` (NUMBERED!) | ❌ TAX_TYPE / TAXCLASS |
| BAPI_MLAN | `TAX_IND` = **purchasing** tax indicator | (≠ sales TAXCLASS) |
| BAPI_MAKT | `LANGU`, `MATL_DESC` | — |
| BAPIMATINR | `MATERIAL` | — |

To verify: `https://leanx.eu/sap/table/<struct>/` or SE11 → structure → Components tab.

## 2. BAPI_MATERIAL_SAVEDATA / GETINTNUMBER specifics
- **Internal numbering:** SAVEDATA does NOT accept a blank MATERIAL (error M3 262). First call
  `BAPI_MATERIAL_GETINTNUMBER` (EXPORTING material_type, industry_sector, required_numbers;
  TABLES material_number = BAPIMATINR) and put the number in `HEADDATA-MATERIAL`.
- **GETINTNUMBER `RETURN` is an EXPORTING param of type `BAPIRETURN1`** (single struct) — NOT a
  TABLES param and NOT BAPIRET2. Only `MATERIAL_NUMBER` is in TABLES.
- **Views:** set HEADDATA view flags only for views you fill (BASIC_VIEW, PURCHASE_VIEW,
  STORAGE_VIEW, ACCOUNT_VIEW…). Setting ACCOUNT_VIEW with no plant/valuation → BAPI error.
- **Force a field empty** to override a material-type default (e.g. ZSRV defaults item cat. grp to
  `LEIS`): blank value + the X-flag = 'X' (`CLEAR lwa_client-item_cat. lwa_clintx-item_cat = abap_true.`).
- Each material = one LUW: per-row `BAPI_TRANSACTION_COMMIT WAIT='X'`, `ROLLBACK` on `type CA 'EAX'`.
- Prefer reading the `RETURNMESSAGES` table over the single `RETURN` for field-level error text.

## 3. ATC `CL_CI_TEST_DB_OPS_IN_LOOPS` ("DB ops in loops across modularization units")
Fires when a BAPI/FM **in a loop** does SELECT/INSERT in SAP-standard code. Unavoidable for
mass-create (one BAPI call per row). **Pseudo-comment placement is the trap:**
- ✅ on the call **directly inside the loop** (`PERFORM create_one. "#EC CI_SEL_NESTED`)
- ❌ NOT on the deep BAPI call two levels down (does not suppress).
- Reads: `#EC CI_SEL_NESTED` or `#EC CI_SROFC_NESTED`. Writes: `#EC CI_IMUD_NESTED`. Multiple on
  one (multi-line) statement is allowed: `"#EC CI_IMUD_NESTED "#EC CI_SROFC_NESTED`.
- Fallback if the ATC variant ignores pseudo-comments: **Request Exemption** with justification
  ("DB op is in SAP-standard BAPI reached transitively; mass-create is one BAPI per row").
- **If a CORRECT pseudo-comment still shows after re-activate + fresh ATC run, the customer's ATC
  variant has "apply pseudo-comments" switched OFF** (common in hardened/central ATC). Then no inline
  comment ever clears it — only an **ATC Exemption** does. Tell from the finding detail: if it offers
  only "Request Exemption" and no "pseudo comment" hint, comments are disabled.

### CVA / SLIN_SEC security check "Read on sensitive database tables/views" (Priority 3)
Fires on direct SELECTs against tables SAP marks sensitive. **NOT clearable by any inline `#EC`** —
there is no pseudo-comment for it (do NOT invent `"#EC SENSITIVE`). Sanctioned fix = **ATC Exemption**
(best practice for read-only **Customizing** existence checks like T134/T001W/T023/T025/T137 — no
sensitive data disclosed; back it with an `AUTHORITY-CHECK … ACTVT '03'` before the reads to make the
justification airtight, though the check itself only clears via the exemption). Priority 3 is
acceptable under the ILG gate ("severity 3 only when justified"); CVA level 1 = no HIGH findings only.

## 4. PERFORM USING limitations (older releases / strict syntax)
- **No expressions** as actual params — a string template fails with `Field "|" is unknown`. Build
  into a variable first: `lv_msg = |…{ x }…|. PERFORM f USING lv_msg.`
- **Type mismatch** passing a CHAR field (e.g. `bapi_msg`) to a `TYPE string` formal param. Declare
  the formal param `TYPE csequence` (generic char: accepts string + CHAR + literals).

## 5. xlsx reading robustness (the stable pattern)
- **xlsx OMITS empty cells inconsistently** (row 2 may have A..N, row 3 A..P). A positional
  `READ TABLE lt_row INDEX n` that fails leaves the STALE previous value in the var → it leaks into
  the next field (classic symptom: an empty col gets a neighbour's value, e.g. SERNP 'EQB1' → KORDB 'E').
  Fix: `CLEAR` before each READ, or pad the row, or (best) read by header name.
- **Read by HEADER NAME, not position** = bulletproof: find the header row (cell = 'MTART'), build a
  map `name(upper) → absolute col`, read each field via a safe helper that returns '' if the header
  or cell is absent. → column order / inserted / extra / missing columns all handled.
- **Detect the header row by CONTENT** (cell = 'MTART'), not `sy-tabix = 1` (blank rows above the
  header / serializer quirks break position). Compare the raw `string` cell, not a CHAR4 target
  ('MTART' is 5 chars → truncates).
- The generic reader (`cl_abap_zip` + `cl_ixml`, forms `parse_sheet`/`col_from_ref`/
  `get_cell_value`) already pads middle gaps and handles out-of-order cells, shared/inline/number/
  formula values — reuse it; the risk lives in the field-mapping step.

## 6. Translatable messages — Text Symbols, never literals
- All user text → `TEXT-nnn` symbols (passes the ATC literal-text check + translatable via SE63).
- Value-in-the-middle: put `&` in the symbol text and `REPLACE '&' IN lv_msg WITH lv_value.` in code.
  (A symbol with `&` is NOT auto-substituted — needs the REPLACE.)
- Two separate tabs in Goto → Text Elements: **Text symbols** vs **Selection texts**.

## 7. Display-only selection-screen fields (fixed, non-editable)
`MODIF ID` alone only tags — the locking is in a PBO loop:
```abap
PARAMETERS pp_x ... MODIF ID dsp.
* main program:
AT SELECTION-SCREEN OUTPUT.
  PERFORM screen_output.
* form:
FORM screen_output.
  LOOP AT SCREEN.
    IF screen-group1 = 'DSP'. screen-input = 0. MODIFY SCREEN. ENDIF.
  ENDLOOP.
ENDFORM.
```

## 8. Result LOG that mirrors the input file
For "one line per input row, in sheet order" (not "all errors then all successes", no duplicates):
- Validation **stamps** each bad row (transient `err`/`errmsg` fields on the row structure) instead
  of appending to the log directly.
- Build the log in a **single pass** over the rows (Excel order); a stamped row emits one error line
  and is skipped, a good row emits its create/test line. Carry the true source row number.
- `SORT log BY row_num` before ALV display AND before SLG1 write so both match the sheet order.

## 9. Background execution (batch / SM37)
- `cl_gui_frontend_services=>gui_upload` (and F4, file_exist) **cannot run in background** (no SAPGUI).
  For batch, read the file from the app server with `OPEN DATASET … IN BINARY MODE` (AL11), or hand
  off via an **INDX cluster** (`EXPORT … TO DATABASE indx(xx) ID runid` in the foreground,
  `IMPORT … FROM DATABASE` in the job) — a "temporary table" with no new DDIC object.
- `cl_salv_table=>display( )` is a **no-op in batch** — guard with `sy-batch` and rely on SLG1 + a
  spool `WRITE` summary. Force the SLG1 log on in background (it's the only persistent record).
- `MESSAGE … TYPE 'E'` in a background step terminates the job — log + controlled RETURN instead.
- ~1000 rows × per-row `COMMIT WAIT` risks the dialog `TIME_OUT` (~10 min) → run in background.

## 10. Misc constants / limits
- **Icon traffic light:** `@08@` green (success), `@09@` yellow (warning), `@0A@` red (error). Easy to swap by mistake.
- **Program / Include name max = 30 chars** for normal use ("longer than 30… internal use only");
  the technical 40-char limit is not usable as a runnable program.
- UoM from a localized commercial form (Hebrew "יח") → internal code via
  `CONVERSION_EXIT_CUNIT_INPUT` with `language = sy-langu` (run in the right logon language).
