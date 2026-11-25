@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Green Path - purchase orders of a notification'
/*
 * /ILG/I_NotifPurchaseOrder
 * -------------------------
 * View בסיס לטבלה /ILG/PM_NOTIF_PO - הזמנות הרכש של הסט.
 * מפתח QMNUM + EBELN: ייתכנו כמה הזמנות לסט, לכן הצרכן
 * (/ILG/IMMGpPoDocs) מסכם לשורה אחת לסט.
 */
define view entity /ILG/I_NotifPurchaseOrder
  as select from /ilg/pm_notif_po
{
      @EndUserText.label: 'מספר סט (הודעה)'
  key qmnum as Qmnum,
      @EndUserText.label: 'הזמנה'
  key ebeln as Ebeln
}
