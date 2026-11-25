@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Green Path - follow-on documents from PO history'
/*
 * /ILG/IMMGpPoDocs
 * ----------------
 * מסמכי ההמשך של הסט מהיסטוריית ההזמנה - המקור הרשמי, ללא תלות
 * במה שנרשם ידנית ב-/ILG/MM_GRPO_DET.
 *
 * מקורות (VDM בלבד):
 *   /ILG/I_NotifPurchaseOrder    הזמנות הסט (QMNUM + EBELN; ייתכנו כמה הזמנות לסט)
 *   I_PurchaseOrderHistoryAPI01  היסטוריית ההזמנה (EKBE/EKBEH), API view משוחרר
 *
 * מיפוי EKBE -> VDM (help.sap.com, API CDS Views for Purchase Order):
 *   VGABE = PurchasingHistoryDocumentType  '1' קבלת טובין, '2' חשבונית
 *   SHKZG = DebitCreditCode                'S' תנועות חיוב בלבד - ביטולים (H) אינם נספרים
 *   BELNR = PurchasingHistoryDocument      מסמך חומרים / חשבונית (שדה אחד לשניהם)
 *   GJAHR = PurchasingHistoryDocumentYear
 *
 * MAX( ) דטרמיניסטי; בכמה מסמכים נלקח הגבוה. שורה אחת לכל סט.
 * ה-DCL של I_PurchaseOrderHistoryAPI01 (ארגון/קבוצת רכש, סוג מסמך, אתר)
 * חל גם בקריאה דרך View זה.
 */
define view entity /ILG/IMMGpPoDocs
  as select from /ILG/I_NotifPurchaseOrder     as po
    inner join   I_PurchaseOrderHistoryAPI01   as hist on hist.PurchaseOrder = po.Ebeln
{
      @EndUserText.label: 'מספר סט (הודעה)'
  key po.Qmnum                                                     as Qmnum,

      @EndUserText.label: 'הזמנה'
      max( po.Ebeln )                                              as Ebeln,

      @EndUserText.label: 'מסמך קבלת טובין (היסטוריית הזמנה)'
      max( case when hist.PurchasingHistoryDocumentType = '1'
                 and hist.DebitCreditCode               = 'S'
                then hist.PurchasingHistoryDocument end )          as GrBelnr,
      @EndUserText.label: 'שנת מסמך טובין'
      max( case when hist.PurchasingHistoryDocumentType = '1'
                 and hist.DebitCreditCode               = 'S'
                then hist.PurchasingHistoryDocumentYear end )      as GrGjahr,

      @EndUserText.label: 'חשבונית לוגיסטית (היסטוריית הזמנה)'
      max( case when hist.PurchasingHistoryDocumentType = '2'
                 and hist.DebitCreditCode               = 'S'
                then hist.PurchasingHistoryDocument end )          as IrBelnr,
      @EndUserText.label: 'שנת כספים - חשבונית'
      max( case when hist.PurchasingHistoryDocumentType = '2'
                 and hist.DebitCreditCode               = 'S'
                then hist.PurchasingHistoryDocumentYear end )      as IrGjahr
}
group by
  po.Qmnum
