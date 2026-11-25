@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Green Path - follow-on documents from PO history'
/*
 * /ILG/IMMGpPoDocs
 * ----------------
 * מסמכי ההמשך של הסט מהיסטוריית ההזמנה (EKBE) - המקור הרשמי,
 * ללא תלות במה שנרשם ידנית ב-/ILG/MM_GRPO_DET.
 *
 * הזמנות הסט:  /ILG/PM_NOTIF_PO (QMNUM + EBELN; ייתכנו כמה הזמנות לסט)
 * VGABE = '1'  קבלת טובין   -> GrBelnr / GrGjahr
 * VGABE = '2'  חשבונית      -> IrBelnr / IrGjahr
 * SHKZG = 'S'  תנועות חיוב בלבד - שורות ביטול (H) אינן נספרות
 * MAX( )       דטרמיניסטי; בכמה מסמכים נלקח הגבוה. שורה אחת לכל סט.
 */
define view entity /ILG/IMMGpPoDocs
  as select from /ilg/pm_notif_po as po
    inner join   ekbe             as hist on hist.ebeln = po.ebeln
{
      @EndUserText.label: 'מספר סט (הודעה)'
  key po.qmnum                                                 as Qmnum,

      @EndUserText.label: 'הזמנה'
      max( po.ebeln )                                          as Ebeln,

      @EndUserText.label: 'מסמך קבלת טובין (EKBE)'
      max( case when hist.vgabe = '1' and hist.shkzg = 'S'
                then hist.belnr end )                          as GrBelnr,
      @EndUserText.label: 'שנת מסמך טובין'
      max( case when hist.vgabe = '1' and hist.shkzg = 'S'
                then hist.gjahr end )                          as GrGjahr,

      @EndUserText.label: 'חשבונית לוגיסטית (EKBE)'
      max( case when hist.vgabe = '2' and hist.shkzg = 'S'
                then hist.belnr end )                          as IrBelnr,
      @EndUserText.label: 'שנת כספים - חשבונית'
      max( case when hist.vgabe = '2' and hist.shkzg = 'S'
                then hist.gjahr end )                          as IrGjahr
}
group by
  po.qmnum
