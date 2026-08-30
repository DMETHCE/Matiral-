# Naming Convention — /ILG/

## Repository Prefix

All repository objects start with `/ILG/`.
- Replace `MM` with the actual application area: `FI`, `SD`, `PP`, `PM`, `QM`, `MM`, `CO`, …
- `XXX` is a 1-3 digit sequential number or a short functional mnemonic (`CLAS01`, `MIG02`, …).

## Program Object Name Patterns

| Object Type | Name Pattern | Purpose |
|-------------|--------------|---------|
| Main program | `/ILG/MM_XXX` | `INITIALIZATION`, `AT SELECTION-SCREEN`, `START-OF-SELECTION` only |
| Data Include | `/ILG/MM_XXX_DAT` | `TYPES`, `DATA`, `TABLES`, `CONSTANTS` |
| Selection-screen Include | `/ILG/MM_XXX_SEL` | `SELECTION-SCREEN`, `AT SELECTION-SCREEN ON VALUE-REQUEST`, F4 helpers |
| Forms Include | `/ILG/MM_XXX_FRM` **or** split as `_F01`, `_F02`, `_F03` | Split when file grows large |
| Module Include (PBO/PAI) | **Option A:** `/ILG/MM_XXX_MDL` — **Option B:** `_I01` (PAI) + `_O01` (PBO) | For dynpros |
| Macro Include | `/ILG/MM_XXX_MAC` | Or keep macros inside `_DAT` |

## Variable Naming — Two-Letter Prefix

### 1st letter — scope
| Letter | Scope |
|--------|-------|
| `G` | Global |
| `L` | Local |
| `S` | Static |
| `P` | Form parameter |

### 2nd letter — kind
| Letter | Kind |
|--------|------|
| `V` | Variable |
| `S` | Structure |
| `T` | Table |
| `C` | Constant |
| `WA` | Work area — name must match the corresponding `*t_*` table |
| `O` | Object instance |
| `I` | Interface reference |
| `TYP` | Type (global or local) |
| `TYP_T` | Table type — must be defined via `TYPES: typ_t_x TYPE TABLE OF typ_x.` |
| `REF` | Reference to data type |
| `R` | Ranges |

### Examples
```abap
DATA: lv_number    TYPE i,          " local variable
      gt_bseg      TYPE TABLE OF bseg,  " global internal table
      gwa_bseg     TYPE bseg,       " work area for gt_bseg
      sv_count     TYPE i,          " static variable (in a method)
      gtyp_buffer  TYPE REF TO data, " global type ref
      gr_belnr     TYPE RANGE OF belnr_d. " global ranges
CONSTANTS:
      lc_maxrows   TYPE i VALUE 1000.    " local constant
```

## Selection Screen Prefixes

| Prefix | Meaning | Example |
|--------|---------|---------|
| `SO` | Select-options | `so_belnr` |
| `PP` | Parameter | `pp_gjahr` |
| `RB` | Radio button | `rb_test` |
| `CB` | Check box | `cb_log` |

## Function-Module / Method Parameter Prefixes

| Prefix | Direction | Example |
|--------|-----------|---------|
| `IV` | Importing scalar | `iv_qmnum` |
| `EV` | Exporting scalar | `ev_result` |
| `CV` / `C` | Changing scalar | `c_flag` |
| `IT` | Importing table (changes **not** returned) | `it_acct` |
| `ET` | Exporting table (changes returned) | `et_amount` |
