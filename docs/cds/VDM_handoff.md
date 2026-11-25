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
| `/ILG/IMMGpClearing` | `ACDOCA` | `I_JournalEntryItem` |
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

## 3. מה לא נמצא / לבדוק ב-ADT (Ctrl+Shift+A → Outline)

1. **`I_JournalEntry`** — לאשר שקיימים `ReversalReferenceDocument` ו-
   `ReversalReferenceDocumentCntxt` בכותרת (מקור משני בלבד). אם לא — להחליף
   ל-`ReverseDocument`/`ReverseDocumentFiscalYear` ולזכור שבסטורנו MR8M הם
   ריקים (הבעיה המקורית).
2. **`I_QltyNotificationActivity`** — שלושה שמות לא מתועדים, נכתבו לפי קונבנציה:
   `NotifActivityCodeGroup` (MNGRP), `NotifActivityCode` (MNCOD),
   `IsDeleted` (KZLOESCH). לתקן ב-`ilg_immgpqmmastatus` לפי ה-Outline.
   בנוסף: אם הודעות המסלול הירוק הן הודעות **PM** ולא QM, ה-View עלול להחזיר
   0 שורות (Data Preview על QMNUM מוכר) — אז לעבור ל-`I_MaintNotificationActyData`.
3. **טקסט סיבת סטורנו** — `I_ReversalReasonText` עם `ReversalReason`,
   `Language`, `ReversalReasonName` לא נמצא באינטרנט; נכתב לפי קונבנציה.
   חלופות: `I_ReversalReason._Text`, או לוותר על `StgrdTxt` בשלב ראשון.
4. **`/ILG/PM_NOTIF_BP`** — שמות השדות `TAXINV` / `CREDITINVOICE` לפי גיליון 4;
   לאמת מול SE11.
5. **DCL** — `I_PurchaseOrderHistoryAPI01` ו-`I_JournalEntryItem` כפופים ל-DCL
   של SAP; ב-Data Preview ייתכן שחסרות שורות למשתמש ללא הרשאות
   (M_BEST_EKO/EKG/BSA/WRK, F_BKPF_BUK, ledger).
6. `R_PURCRECORDER` — לא נמצא באינטרנט; EKKO/EKPO = `I_PurchaseOrderAPI01` /
   `I_PurchaseOrderItemAPI01`.

## 4. הנחיה מוכנה לסשן מקומי (להדביק ב-Claude Desktop → Claude Code, תיקיית המאגר)

```
ענף claude/analyze-create-cds-k48pte. קרא docs/cds/VDM_handoff.md ו-.claude/skills/abap-ilg/SKILL.md.
פתח בדפדפן api.sap.com (אני אתחבר) ואמת את שלושת הפערים בסעיף 3: שדות I_JournalEntry
(ReversalReferenceDocument / ReversalReferenceDocumentCntxt), שמות השדות של
I_QltyNotificationActivity (MNGRP/MNCOD/KZLOESCH), ו-View הטקסט של I_ReversalReason.
תקן את src/cds לפי הממצאים, עדכן את docs/cds/VDM_בדיקת_Views.xlsx, commit + push.
```
