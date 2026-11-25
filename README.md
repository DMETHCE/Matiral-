# מסלול ירוק — מעקב ובקרה מפצה (SAP S/4HANA, /ILG/)

מאגר העבודה של משה לפרויקט **מעקב המסלול הירוק**: סטים (הודעות QMNUM) שעברו
אישור בפורטל הספקים, ומעקב חי אחרי מסמכי ההמשך שלהם — קבלת טובין, חשבונית
לוגיסטית, מסמך פיננסי, סטורנו ותשלום — עם סיווג לסטטוס לוגי לפי עץ החלטות
מהאפיון העסקי.

**כל סשן עבודה (ענן או מקומי) מתחיל כאן.** המצב המלא נמצא במאגר, לא בזיכרון
של אף סשן: `git pull`, ואז קוראים לפי הסדר בסעיף "איך ממשיכים".

## היסטוריה בקצרה

| שלב | מה קרה | איפה מתועד |
|-----|--------|-------------|
| 1. נקודת מוצא | תוכנית ABAP ישנה `ZMM_PROCESS_GREEN_PATH` שתוכננה כ-Batch לטבלת יעד. לא מתקמפלת (12 שגיאות) ומכילה באגים לוגיים. | `docs/abap/abap_program_analysis.md`, `src/abap/zmm_process_green_path.abap` |
| 2. החלטה | במקום Batch וטבלת יעד: **CDS View חי**. האפיון העסקי (Word) גובר על התוכנית בכל סתירה. | `docs/cds/cds_spec.md`, `docs/cds/אפיון_*.docx` |
| 3. אימות מבנים | כל טבלה שה-CDS נוגע בה צולמה מ-SE11 ואומתה שדה-שדה (GRPO_DET, QMMA, RBKP, BKPF, T041CT, ACDOCA). | `docs/tables/table_structures.md` |
| 4. גרסה 1 | `/ILG/IMMGreenTrack` + שני Views מסכמים, על טבלאות סטנדרט. | `src/cds/ilg_immgreentrack.ddls.asddls` |
| 5. Fiori | Cube + ALP + OVP (KPI, תרשימים, Visual Filters) ואפליקציות BAS. | `docs/fiori/*.md`, `src/fiori/` |
| 6. Snapshot | תוכנית `/ILG/MM_GP_SNAP` וטבלה `/ILG/MM_GP_TRK` לשמירת תמונת מצב. | `src/abap/snapshot/` |
| 7. גרסה 2 | `/ILG/IMMGreenStatus`: אסוציאציות, מסמכי המשך מוכרעים משלושה מקורות (GRPO_DET → PM_NOTIF_BP → EKBE), סטורנו דרך AWREF_REV/AWORG_REV. | `src/cds/ilg_immgreenstatus.ddls.asddls`, `ilg_immgpsetdocs`, `ilg_immgppodocs` |
| 8. **VDM** (נוכחי) | כל השרשרת נכתבה מחדש על Views משוחררים של SAP בלבד + שלושה Views בסיס לטבלאות ILG. כל שם View ושדה אומת מול קטלוג api.sap.com. | `docs/cds/VDM_handoff.md`, `docs/cds/VDM_בדיקת_Views.xlsx`, `sap-vdm-catalog/` |

## מה בנוי היום (ענף `claude/analyze-create-cds-k48pte`)

```
/ILG/I_GreenPathSet        /ILG/MM_GRPO_DET   -- בסיס: הסט
/ILG/I_NotifPaymentInvoice /ILG/PM_NOTIF_BP   -- בסיס: חשבונית לתשלום על ההודעה
/ILG/I_NotifPurchaseOrder  /ILG/PM_NOTIF_PO   -- בסיס: הזמנות הסט
/ILG/IMMGpPoDocs           I_PurchaseOrderHistoryAPI01  -- טובין/חשבונית מהיסטוריית ההזמנה
/ILG/IMMGpQmmaStatus       I_QltyNotificationActivity   -- קודי 50/60/70/80 (ZPU)
/ILG/IMMGpClearing         I_JournalEntryItem           -- תשלום בפועל (סילוק '2%')
/ILG/IMMGpSetDocs          GreenPathSet + NotifPaymentInvoice + PoDocs -- מסמכי המשך מוכרעים
/ILG/IMMGreenStatus        SetDocs + I_SupplierInvoiceAPI01 + I_JournalEntry x2
                           + I_ReversalReasonText + Clearing + Status -- עץ ההחלטות
```

סדר אקטיבציה ב-ADT, הממצאים והפערים: `docs/cds/VDM_handoff.md`.

## איך ממשיכים (לכל סשן)

1. `git pull`.
2. לקרוא: `CLAUDE.md` (כללי עבודה), `docs/cds/VDM_handoff.md` (מצב נוכחי),
   `docs/cds/cds_spec.md` (הלוגיקה העסקית ועץ ההחלטות).
3. שמות Views ושדות של SAP — **רק** מ-`sap-vdm-catalog/` (ראו README שם).
4. קוד ABAP/CDS — לפי `.claude/skills/abap-ilg/SKILL.md`.
5. בסוף: עדכון `VDM_handoff.md`, commit, push לאותו ענף.

## מה פתוח

ראו סעיף 3א ב-`docs/cds/VDM_handoff.md`. העיקרי: Data Preview ב-ADT על
`/ILG/IMMGpQmmaStatus` עם הודעת PM אמיתית; אם אין שורות — מעבר ל-
`C_MaintNotifActivityDEX`.
