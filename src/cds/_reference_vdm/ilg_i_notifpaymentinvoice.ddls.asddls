@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Green Path - payment invoice recorded on notification'
/*
 * /ILG/I_NotifPaymentInvoice
 * --------------------------
 * View בסיס לטבלה /ILG/PM_NOTIF_BP - החשבונית לתשלום שנרשמה על ההודעה.
 * מפתח QMNUM בלבד - לכל היותר שורה אחת לסט.
 *
 * INV = 'X' מסמן חשבונית (לעומת מסמך זיכוי / חשבונית מס). משמעות
 * TAXINV / CREDITINVOICE טרם הובררה עסקית - נחשפים כפי שהם, לא בשימוש
 * בעץ ההחלטות. שמות השדות לפי גיליון 4 בקובץ האימות - לאמת מול SE11.
 */
define view entity /ILG/I_NotifPaymentInvoice
  as select from /ilg/pm_notif_bp
{
      @EndUserText.label: 'מספר סט (הודעה)'
  key qmnum         as Qmnum,

      @EndUserText.label: 'חשבונית לוגיסטית'
      belnr         as Belnr,
      @EndUserText.label: 'שנת כספים'
      gjahr         as Gjahr,

      @EndUserText.label: 'חשבונית'
      inv           as Inv,
      @EndUserText.label: 'חשבונית מס'
      taxinv        as TaxInv,
      @EndUserText.label: 'חשבונית זיכוי'
      creditinvoice as CreditInvoice
}
