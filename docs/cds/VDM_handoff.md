# מעבר ל-VDM — מה אומת, מה פתוח, ומה לבדוק ב-ADT

מסמך מסירה לסשן העבודה הבא (מקומי, עם ADT). הקובץ `VDM_בדיקת_Views.xlsx`
מכיל את הפירוט המלא (כולל גיליון "מקורות אימות" עם קישורים); כאן התמצית.

## 1. מה נכתב

כל חמשת ה-Views ב-`src/cds/` נכתבו מחדש על Views משוחררים של SAP (VDM)
ועל Views בסיס של ILG בלבד — אפס טבלאות ישירות:

| View | מקור קודם | מקור חדש |
|------|-----------|----------|
| `/ILG/I_GreenPathSet` (חדש) | — | `/ILG/MM_GRPO_DET` |
| `/ILG/I_NotifPaymentInvoice` (חדש) | — | `/ILG/PM_NOTIF_BP` |
| `/ILG/I_NotifPurchaseOrder` (חדש) | — | `/ILG/PM_NOTIF_PO` |
| `/ILG/IMMGpPoDocs` | `/ILG/PM_NOTIF_PO` + `EKBE` | `/ILG/I_NotifPurchaseOrder` + `I_PurchaseOrderHistoryAPI01` |
| `/ILG/IMMGpQmmaStatus` | `QMMA` | `I_QltyNotificationActivity` |
| `/ILG/IMMGpClearing` | `ACDOCA` | `I_JournalEntryItem` (`ClearingJournalEntry`) |
| `/ILG/IMMGpSetDocs` | `/ILG/MM_GRPO_DET` + `/ILG/PM_NOTIF_BP` | `/ILG/I_GreenPathSet` + `/ILG/I_NotifPaymentInvoice` |
| `/ILG/IMMGreenTrack2` | `RBKP`, `BKPF`×2, `T041CT` | `I_SupplierInvoiceAPI01`, `I_JournalEntry`×2, `I_ReversalReasonText` |

הלוגיקה (עץ ההחלטות, סדר העדיפות של מסמכי ההמשך, אסוציאציות) זהה לגרסה
הקודמת; השתנו רק המקורות ושמות השדות.

**סדר אקטיבציה ב-ADT:** `I_GreenPathSet`, `I_NotifPaymentInvoice`,
`I_NotifPurchaseOrder` → `IMMGpPoDocs`, `IMMGpQmmaStatus`, `IMMGpClearing` →
`IMMGpSetDocs` → `IMMGreenTrack2`.

## 2. מה אומת מהאינטרנט

### רשמי (help.sap.com)

- **`I_SupplierInvoiceAPI01`** — Released, Basic. שדות: `SupplierInvoice`,
  `FiscalYear`, `CompanyCode`, `SupplierInvoiceStatus` (= RBSTAT), ועוד.
  `I_SupplierInvoice` ללא `API01` אינו מתועד כמשוחרר — לא בשימוש.
- **תנאי ה-join הרשמי חשבונית → מסמך פיננסי** (מתיעוד `I_SupplierInvoiceAPI01`):
  `I_JournalEntry.ReferenceDocumentType = 'RMRP'`
  `and OriginalReferenceDocument = concat(SupplierInvoice, FiscalYear)`
  `and CompanyCode = CompanyCode`.
  כלומר **AWKEY = `OriginalReferenceDocument`** (לא `ReferenceDocument` כפי שהנחנו).
- **`I_PurchaseOrderHistoryAPI01`** — API view על EKBE/EKBEH, מיפוי מלא:
  `VGABE = PurchasingHistoryDocumentType`, `SHKZG = DebitCreditCode`,
  `BELNR = PurchasingHistoryDocument`, `GJAHR = PurchasingHistoryDocumentYear`,
  `BEWTP = PurchasingHistoryCategory`, `LFBNR/LFGJA = ReferenceDocument/ReferenceDocumentFiscalYear`.
- **`I_QltyNotificationActivity`** — Released (2020 FPS01), Transactional, על
  QMMA. שדות מתועדים: `QualityNotification`, `NotificationActivity`,
  `NotificationItem`.
- **`I_JournalEntry`** — Dimension על BKPF; **`I_JournalEntryItem`** — Cube על
  ACDOCA (לא חושף תקופה 000).
- **`I_ReversalReason`** + `I_ReversalReasonValueHelp` — C1 Released (רשימת GL
  בענן). **`I_MaintNotificationActyData`** — Released, אך SAP ממליצה רק ל-BW.

### משני (paspas.io דרך תוצאות חיפוש, MuleSoft, SAP Community)

- `I_JournalEntry`: `IsReversed`, `ReverseDocument`, `ReversalReason`
  (join ל-T041C.STGRD), **`ReversalReferenceDocument`**,
  **`ReversalReferenceDocumentCntxt`** (דומיין AWORG) — paspas.io מציג אותם על
  `I_JournalEntry` עצמו, כלומר השאלה המכריעה נענתה חיובית, אך ממקור משני.
- `I_JournalEntryItem`: `Ledger`, `CompanyCode`, `FiscalYear`,
  `AccountingDocument`, `FinancialAccountType`, `ClearingAccountingDocument`,
  `ClearingDate`.

## 3. סטטוס הפערים (אומתו ידנית ב-api.sap.com)

1. ✅ **`I_JournalEntry`** (Basic, Released) — `ReversalReferenceDocument`
   (AWREF_REV) ו-`ReversalReferenceDocumentCntxt` (AWORG_REV) קיימים בכותרת,
   שניהם CHAR10. AWKEY = `OriginalReferenceDocument`. הקוד תואם.
2. ✅ **`I_QltyNotificationActivity`** (Composite, Released) —
   `QualityNotification` / `NotifActivityCodeGroup` / `NotifActivityCode` /
   `IsDeleted`. הקוד תואם.
   ⚠️ **נותר לבדוק ב-ADT:** SAP מתעדת את ה-View להודעות איכות, והודעות
   המסלול הירוק הן PM. Data Preview על QMNUM מוכר חייב להחזיר שורות; אם לא —
   לעבור ל-`C_MaintNotifActivityDEX` (Consumption, Released, View הודעות PM —
   נמצא בקטלוג api.sap.com; `MaintenanceNotification` / `MaintNotifActivityCodeGroup` /
   `MaintNotificationActivityCode` / `IsDeleted`). `I_MaintNotificationActyData`
   לא קיים בקטלוג.
3. ✅ **`I_ReversalReasonText`** (Basic, Released) — `Language`,
   `ReversalReason`, `ReversalReasonName`. הקוד תואם.

4. ✅ **כל שדה VDM בשימוש ב-`src/cds` נבדק מול `sap-vdm-catalog/fields.tsv`** —
   כולם קיימים. תיקון אחד: `I_JournalEntryItem.ClearingAccountingDocument` מסומן
   Deprecated; `/ILG/IMMGpClearing` עבר ליורש `ClearingJournalEntry`.

## 3א. מה נשאר לבדוק ב-ADT

1. Data Preview על `/ILG/IMMGpQmmaStatus` (סעיף 3.2).
2. **`/ILG/PM_NOTIF_BP`** — שמות השדות `TAXINV` / `CREDITINVOICE` לפי גיליון 4;
   לאמת מול SE11.
3. **DCL** — `I_PurchaseOrderHistoryAPI01` ו-`I_JournalEntryItem` כפופים ל-DCL
   של SAP; ב-Data Preview ייתכן שחסרות שורות למשתמש ללא הרשאות
   (M_BEST_EKO/EKG/BSA/WRK, F_BKPF_BUK, ledger).
4. `R_PURCRECORDER` — לא נמצא באינטרנט; EKKO/EKPO = `I_PurchaseOrderAPI01` /
   `I_PurchaseOrderItemAPI01`.

## 3ב. קטלוג VDM

שמות Views ושדות נבדקים מעכשיו רק מול `sap-vdm-catalog/` בשורש המאגר
(כל קטלוג ה-Views המשוחררים של SAP + מיפוי טבלה→View מאומת). פירוט ב-README שם.

## 4. עבודה על המאגר מסשן מקומי

```
git clone https://github.com/DMETHCE/Matiral-.git
cd Matiral-
git checkout claude/analyze-create-cds-k48pte
```
(אם המאגר כבר משוכפל: `git fetch origin && git checkout claude/analyze-create-cds-k48pte && git pull`.)
השלב הבא הוא אקטיבציה ב-ADT לפי סדר סעיף 1 ובדיקות סעיף 3א.
