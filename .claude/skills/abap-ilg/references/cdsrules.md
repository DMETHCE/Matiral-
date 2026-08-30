# ABAP CDS Rules

Lessons learned from building `/ILG/I_Obj_Chars_Flat` (classification flattener) and similar CDS work. Apply to every CDS view written for this user.

## 1. View Entity vs Classic DDL View — different syntax

`define view entity` (modern, since 7.55) is **not** syntactically identical to `define view` (classic DDIC). The differences below trip people up at activation time.

| Topic | Classic `define view` | `define view entity` |
|-------|----------------------|---------------------|
| Pass parameter to source view | `Src( P : :p_keydate )` | `Src( P : $parameters.p_keydate )` |
| `COUNT(field)` | Allowed | **Forbidden** — must use `COUNT(DISTINCT field)` |
| SQL view name annotation | Required `@AbapCatalog.sqlViewName` | Forbidden — no SQL view generated |
| Client-handling annotation | `@ClientHandling.algorithm` | Same, but defaults differ |
| Chained association in ON-clause | Limited | **Forbidden** — see Rule #9 |

**Default to `define view entity` for all new CDS work** unless the user explicitly needs a classic view for compatibility.

## 2. Parameter passing — always use `$parameters.<name>`

❌ Classic-style in a view entity:
```
as select from Src( P_KeyDate : :p_keydate ) as a
```
Activation error: *"Use expression `$parameters` instead of `:`"*.

✅ Correct in a view entity:
```
as select from Src( P_KeyDate : $parameters.p_keydate ) as a
```

When self-joining a parameterized source, **both** join sides must pass the parameter with the same expression. Same applies to parameterized associations:
```
association [0..1] to I_ClfnCharcDescForKeyDate( P_KeyDate : $parameters.p_keydate ) as _CharcDesc
  on _CharcDesc.CharcInternalID = v.CharcInternalID
```

## 3. `COUNT(field)` requires `DISTINCT` in view entities

❌
```
count( b.CharcInternalID ) as Seq
```
Activation error: *"Keyword DISTINCT required for COUNT(DISTINCT CharcInternalID)"*.

✅
```
count( distinct b.CharcInternalID ) as Seq
```

For composite keys, use `concat()` to keep multi-component uniqueness:
```
count( distinct concat( b.field1, b.field2 ) )
```

`count(*)` is allowed and counts every joined row including null-side rows of a left join — so it's usually NOT what you want for ranking.

## 4. Pivot / ROW_NUMBER — pure CDS limits

Pure CDS DDL (both classic and view entity) **does not support `ROW_NUMBER() OVER PARTITION BY`**. To rank rows you have three options, in order of preference:

1. **External sequence source** — find a field SAP already maintains (e.g. `CharcPositionNumber` from `I_ClfnClassCharcBasic` = KSML.POSNR). Best — no ranking needed, just lookup via association.
2. **Table Function + AMDP class** (`IF_AMDP_MARKER_HDB` + `FOR HDB LANGUAGE SQLSCRIPT`). Best performance for true dynamic ranking but requires ABAP class.
3. **Self-join with `count(distinct …)`** in pure CDS. Last resort — slow on >1M rows, requires `WHERE` filter at consumption time.

For wide pivots (`>30` slot columns) generate the boilerplate from a template (PowerShell/Python loop) — never hand-write `Cod001..Cod200`.

## 5. SAP standard CDS — verify the exact name before referencing

SE16N/SE11 table-search names sometimes differ from the `define view` name inside the DDL source (camelCase preservation, abbreviations, etc.). When citing a standard view:

1. Open the DDL source in ADT (F3 or *Open Definition*).
2. Use the name on the `define view …` line — that is the canonical reference.
3. If activation fails with *"view not found"*, search ADT (Ctrl+Shift+A) for the variant spelling.

**Real example burnt me:** SE16N displayed `I_CLFNOBJECTCHARCVALFORKEYDATE` (with extra `C` between `CHAR` and `VAL`). The actual `define view` line was `I_ClfnObjectCharValForKeyDate` (NO extra C). Trust the DDL source, not SE16N's display.

## 6. Performance — always plan the filter contract

A pivot/flatten CDS over a multi-million-row source is unusable without `WHERE` filters at the call site. Document the **required filter** in `@EndUserText.label` or a comment, and consider:

- `@ObjectModel.usageType.serviceQuality: #C` if intended for analytics consumption.
- `@AccessControl.authorizationCheck: #NOT_REQUIRED` only when the source view already enforces auth and the wrapper adds no new exposure.

## 7. Default current date for date parameters

For `sydate` parameters, default to system date so callers and Data Preview can run without entering a value:

```
with parameters
  @Environment.systemField: #SYSTEM_DATE
  p_keydate : sydate
```

This is a **default**, not a constant — callers can still override.

## 8. Naming for /ILG/ CDS objects — PascalCase

- View entity: `/ILG/I_<Area>_<Id>` with **first letter of each word capitalized** — e.g. `/ILG/I_Obj_Chars_Flat`, `/ILG/I_Mat_Class_Desc`
- The `/ILG/` namespace itself is always ALL UPPERCASE
- Table function: same pattern; the AMDP backing class uses `/ILG/CL_<Id>`
- AMDP method: snake_case (`by_key_date`), matches `FOR TABLE FUNCTION /ilg/i_<id>` (lowercase OK inside AMDP)
- Parameters: lowercase with `p_` prefix (`p_keydate`, `p_matnr`)
- Result fields: `CamelCase` preserved via the DDL source — this is the SAP standard for view entities

## 9. Chained associations in ON clauses — NOT allowed

You cannot reference one association's field from another association's `ON` clause:

❌
```
association [0..1] to A as _a on _a.k = v.k
association [0..1] to B as _b on _b.k = _a.k    -- _a.k forbidden here
```

**Fix pattern — split into TWO views**, materializing the bridge field in the first:

✅ Layer 1 (`/ILG/I_Pre`):
```
as select from Src as v
association [0..1] to A as _a on _a.k = v.k
{
  ...,
  _a.bridge_field as BridgeField    -- materialize it
}
```

✅ Layer 2 (`/ILG/I_Main`):
```
as select from /ILG/I_Pre as p
association [0..1] to B as _b on _b.k = p.BridgeField   -- now a regular column
```

This is mandatory for any classification work that goes Object → Class → Characteristic-position.

## 10. Language-dependent text — `$session.system_language`

Standard pattern for joining a text view in the user's logon language:

```
association [0..1] to I_SomeText as _txt
  on  _txt.Key      = v.Key
  and _txt.Language = $session.system_language
```

`$session.system_language` returns `SY-LANGU` of the current session. There is no `$session.user_language`. Some text views are also parameterized with `P_KeyDate` — pass it the same way as for the main view.

## 11. Classification model — released CDS reference

Cheat-sheet for SAP standard CDS that replace the classic CABN/KLAH/KSSK/KSML/AUSP tables. Verified against S/4HANA 2022/2023.

| Classic table | Released CDS view | Key fields | Notes |
|---|---|---|---|
| AUSP (values, key-date) | `I_ClfnObjectCharValForKeyDate` | `ClfnObjectID, ClfnObjectTable, CharcInternalID, CharcValuePositionNumber, ClfnObjectType, ClassType` | Parameter `P_KeyDate : sydate`. NO extra `C` between `Char` and `Val`. |
| KSSK (object→class) | `I_ClfnObjectClassBasic` | `ClfnObjectID, ClfnObjectType, ClassType, ClassInternalID, TimeIntervalNumber` | **Does NOT expose `ClfnObjectInternalID`** — join on the EXTERNAL `ClfnObjectID`. Object can be in multiple classes of same type → use `[0..*]` if not pre-filtered, or `[0..1]` and document the assumption. Also exposes `ClfnStatus, ValidityStartDate, ValidityEndDate, IsDeleted, ClassPositionNumber, ClassIsStandardClass, BOMIsRecursive`. |
| KSML (class→char + POSNR) | `I_ClfnClassCharcBasic` | `ClassInternalID, CharcInternalID, CharcPositionNumber` | `CharcPositionNumber` = KSML.POSNR. |
| CABN (char master, key-date) | `I_ClfnCharacteristicForKeyDate` | `CharcInternalID` | Parameter `P_KeyDate`. |
| Char description (text) | `I_ClfnCharcDescForKeyDate` | `CharcInternalID, Language` → `CharcDescription` | Parameter `P_KeyDate`. |
| Class description (text) | `I_ClfnClassDescription` | `ClassInternalID, Language` → `ClassDescription` | Successor of deprecated `I_ClassText`. |

**Deprecated — do not use in new code:** `I_ClassText` (use `I_ClfnClassDescription` instead).

## 12. `CharcValuePositionNumber` is NOT a characteristic position

Common confusion. In `I_ClfnObjectCharValForKeyDate`:
- `CharcValuePositionNumber` = position of one **value** within a multi-value characteristic (e.g. ranges, multi-select)
- The position of the **characteristic** within its class is `CharcPositionNumber` on `I_ClfnClassCharcBasic` (= KSML.POSNR)

Use the latter for stable pivot slot assignment.
