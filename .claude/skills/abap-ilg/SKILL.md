---
name: abap-ilg
description: >-
  ABAP and CDS development conventions for the ILG SAP S/4HANA environment
  (namespace /ILG/). Use this skill WHENEVER writing, reviewing, or naming ANY
  ABAP or CDS object in this environment - CDS views, reports, tables, data
  elements - even if the user does not mention conventions explicitly. Also use
  it when analyzing existing ILG code, building anything that reads
  /ILG/MM_GRPO_DET, QMMA, RBKP, BKPF, T041CT or ACDOCA, or when the user
  mentions "מסלול ירוק", green path, ILG, or SAP development. Contains naming
  rules, verified environment facts, and hard-won field-name corrections.
---

# ABAP-ILG — קונבנציות פיתוח בסביבת ILG

סקיל זה מרכז את כללי הפיתוח של סביבת ה-SAP הארגונית (namespace `/ILG/`).
נוצר מתוך פרויקט "מסלול ירוק / בקרה מפצה" (08/2026) על בסיס מבני טבלאות
שאומתו מצילומי SE11 אמיתיים מהמערכת.

> גרסה 1.0 — נגזר מהפרויקט. אם קיימת גרסה מקומית מעודכנת של הסקיל
> (C:\Users\...\.claude\skills\abap-ilg) — היא הקובעת; מזג אותה לכאן.

## שמות אובייקטים (Naming)

הפיתוח נעשה ב-namespace הרשום **`/ILG/`** — לא ב-Z. עדות: הטבלאות
`/ILG/MM_GRPO_DET`, ה-Appends `/ILG/RBKP`, `/ILG/ADD_HEADER`,
`/ILG/SERVICE_COD`, ואלמנטי נתונים כמו `/ILG/REQUISITION`.

| סוג אובייקט | תבנית | דוגמה |
|--------------|--------|--------|
| CDS Interface/Basic View | `/ILG/I_<תחום>_<שם>` | `/ILG/I_MM_GP_QMMASTAT` |
| CDS Consumption View | `/ILG/C_<תחום>_<שם>` | `/ILG/C_MM_GREENTRACK` |
| טבלה שקופה | `/ILG/<תחום>_<שם>` | `/ILG/MM_GRPO_DET` |
| אלמנט נתונים | `/ILG/<שם>` | `/ILG/MM_GR_DOC_I` |
| תוכנית/Report | `/ILG/<תחום>_<שם>` | |

- אורך שם כולל ה-namespace: עד 30 תווים (`/ILG/` = 5 תווים).
- תחומים בשימוש: `MM` (רכש/מלאי), `CS`, `PUR`.
- לפני קיבוע שם חדש — בקש מהמשתמש אישור לדוגמת שם אחת, או דוגמה של
  אובייקט קיים באותו סוג. אל תניח תבנית בלי עדות.

## עובדות סביבה מאומתות (אל תנחש - אלה נבדקו מול SE11)

- **S/4HANA 2020 ומעלה** — `define view entity` וביטויים בתנאי `ON` זמינים.
- **תשלומים:** ACDOCA בלבד (אין fallback ל-BSEG). ledger מוביל `0L`.
  מסמך תשלום מתחיל בספרה **'2'** (`AUGBL LIKE '2%'`); סילוק של סטורנו
  אינו תשלום.
- **חשבוניות לוגיסטיות:** נרשמות ב-BKPF עם `AWTYP = 'RMRP'`,
  `AWKEY = BELNR(10) + GJAHR(4)`.
- **QMMA:** קודי המסלול הירוק (50/60/70/80) בקבוצת `MNGRP = 'ZPU'`;
  סנן תמיד `KZLOESCH = ''`. מפתח: QMNUM+MANUM (כמה פעילויות להודעה).
- **RBKP:** `RBSTAT` — '5'=נרשמה, '2'=נמחקה. מפתח BELNR+GJAHR בלבד.

## מלכודות שמות שדות (שגיאות אמיתיות שנתפסו בפרויקט)

| טעות נפוצה | הנכון | הערה |
|-------------|--------|------|
| `MN_GR_DOC_IND` | **`MM_GR_DOC_IND`** | ב-/ILG/MM_GRPO_DET; הטעות הופיעה גם באפיון העסקי |
| `T041CT-TXT20` | **`TXT40`** | אין TXT20 בטבלה |
| `ACDOCA-BUKRS` | **`RBUKRS`** | אין BUKRS ב-ACDOCA |
| קישור סטורנו דרך `AWREF_REV`+`AWORG_REV` מהמסמך המקורי | **`STBLG`/`STJAH`** במפתח מלא (BUKRS+STBLG+STJAH) | AWREF_REV מאוכלס על מסמך הסטורנו, לא על המקור |

`BKPF.XREVERSED` (אלמנט CO_STOKZ) **קיים** במערכת — תקף לזיהוי "בוצע
סטורנו". `XSTOV` הוא רק "מסומן לסטורנו" — לא ביטול בפועל.

## כללי עבודה

1. **אימות לפני קוד:** כל שדה של טבלה לא-סטנדרטית (או שדה נדיר בטבלה
   סטנדרטית) מאומת מול צילום SE11 או מול מסמך `docs/tables/table_structures.md`
   במאגר לפני שכותבים אותו. אם אין אימות — שאל את המשתמש, אל תנחש.
2. **האפיון העסקי גובר** על קוד קיים בכל סתירה; כל סטייה מהאפיון מתועדת
   עם תאריך וסיבה.
3. **CDS מעל snapshot:** דוחות מצב דינמיים נבנים כ-View חי, לא כתוכנית
   Batch שרושמת לטבלת Z.
4. **הערות ותיאורים:** הערות קוד ותוויות (`@EndUserText.label`) —
   עברית מותרת ומקובלת; שמות טכניים — אנגלית בלבד.
5. **Joins ב-CDS:** ודא כל join הוא לכל היותר 1:1 (מפתח מלא או אגרגציה);
   ברישום חוצה-חברות הצמד `BUKRS` (למשל BKPF ↔ RBKP.BUKRS).
6. אחרי כתיבת CDS — הרץ ביקורת כפולה: סינטקס/אקטיבציה + לוגיקה מול
   האפיון (כפי שנעשה בפרויקט עם סוכני ביקורת).

## הפניות

- מבני הטבלאות המאומתים: `docs/tables/table_structures.md` במאגר Matiral-.
- דוגמת עבודה מלאה לפי הכללים: `src/cds/` באותו מאגר.
- כתיבת מסמך האפיון עצמו — לפי הסקיל `merkava-spec`.
