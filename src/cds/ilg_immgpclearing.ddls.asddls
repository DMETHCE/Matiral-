@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Green Path - vendor payment clearing (journal entry items)'
/*
 * /ILG/IMMGpClearing
 * ------------------
 * בדיקת תשלום בפועל - שורת ספק שסולקה במסמך תשלום.
 *
 * מקור (VDM): I_JournalEntryItem - View משוחרר (Cube) על ACDOCA.
 *   Ledger                     = RLDNR   '0L' ledger מוביל בלבד; אם שונה אצלכם - לעדכן
 *   FinancialAccountType       = KOART   'K' = ספק
 *   ClearingJournalEntry       = AUGBL   מסמך הסילוק; לפי האפיון מסמך תשלום מתחיל
 *                                        ב-'2' - סטורנו שמסלק את שורת הספק אינו תשלום.
 *                                        (ClearingAccountingDocument מסומן Deprecated
 *                                        בקטלוג - היורש הוא ClearingJournalEntry)
 *   ClearingDate               = AUGDT
 *   CompanyCode / AccountingDocument / FiscalYear = RBUKRS / BELNR / GJAHR
 *
 * MAX( ) דטרמיניסטי; בסילוק במספר מסמכים Augbl/Augdt עלולים להגיע
 * משורות שונות (סעיף 6 באפיון ה-CDS).
 * ה-DCL של I_JournalEntryItem (ledger, קוד חברה, סוג חשבון, סגמנט) חל
 * גם בקריאה דרך View זה.
 */
define view entity /ILG/IMMGpClearing
  as select from I_JournalEntryItem
{
      @EndUserText.label: 'קוד חברה'
  key CompanyCode                        as Bukrs,
      @EndUserText.label: 'מסמך פיננסי'
  key AccountingDocument                 as Belnr,
      @EndUserText.label: 'שנת כספים'
  key FiscalYear                         as Gjahr,

      @EndUserText.label: 'מסמך תשלום'
      max( ClearingJournalEntry )        as Augbl,
      @EndUserText.label: 'תאריך תשלום'
      max( ClearingDate )                as Augdt
}
where
      Ledger                     = '0L'
  and FinancialAccountType       = 'K'
  and ClearingJournalEntry       like '2%'
group by
  CompanyCode,
  AccountingDocument,
  FiscalYear
