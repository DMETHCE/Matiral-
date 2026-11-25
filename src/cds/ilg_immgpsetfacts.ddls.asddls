@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Green Path - per-set facts: activity codes + PO history documents'
/*
 * /ILG/IMMGpSetFacts
 * ------------------
 * שורה אחת לכל סט ב-/ILG/MM_GRPO_DET עם שני סיכומים שאי אפשר לקבל
 * דרך אסוציאציה (GROUP BY):
 *
 *   1) קודי הפעילות של ההודעה (QMMA דרך I_QltyNotificationActivity):
 *      Has50 נדחה · Has60 אושר · Has70 טובין ידני · Has80 חשבונית ידנית
 *      קבוצה 'ZPU' בלבד, ללא פעילויות שנמחקו.
 *      ⚠ ה-View מתועד להודעות איכות; הודעות המסלול הירוק הן PM.
 *        אם Data Preview ריק - החלופה: C_MaintNotifActivityDEX
 *        (MaintenanceNotification / MaintNotifActivityCodeGroup /
 *         MaintNotificationActivityCode / IsDeleted).
 *
 *   2) מסמכי ההמשך מהיסטוריית ההזמנה (EKBE דרך I_PurchaseOrderHistoryAPI01),
 *      להזמנות הסט ב-/ILG/PM_NOTIF_PO:
 *      PurchasingHistoryDocumentType '1' = קבלת טובין, '2' = חשבונית
 *      DebitCreditCode 'S' = חיוב בלבד (ביטולים H אינם נספרים)
 *
 * MAX( ) דטרמיניסטי - בכמה מסמכים נלקח הגבוה. אומת מול api.sap.com 25.11.2026.
 */
define view entity /ILG/IMMGpSetFacts
  as select from /ilg/mm_grpo_det as grpo

    left outer join I_QltyNotificationActivity as act
      on  act.QualityNotification    = grpo.qmnum
      and act.NotifActivityCodeGroup = 'ZPU'
      and act.IsDeleted              = ''

    left outer join /ilg/pm_notif_po as po
      on po.qmnum = grpo.qmnum

    left outer join I_PurchaseOrderHistoryAPI01 as hist
      on  hist.PurchaseOrder   = po.ebeln
      and hist.DebitCreditCode = 'S'

{
      @EndUserText.label: 'מספר סט (הודעה)'
  key grpo.qmnum                                                      as Qmnum,

      // ---------------- קודי פעילות ----------------
      @EndUserText.label: 'קיים קוד 50 - נדחה'
      max( case act.NotifActivityCode when '50' then 'X' else '' end ) as Has50,
      @EndUserText.label: 'קיים קוד 60 - אושר'
      max( case act.NotifActivityCode when '60' then 'X' else '' end ) as Has60,
      @EndUserText.label: 'קיים קוד 70 - טובין ידני'
      max( case act.NotifActivityCode when '70' then 'X' else '' end ) as Has70,
      @EndUserText.label: 'קיים קוד 80 - חשבונית ידנית'
      max( case act.NotifActivityCode when '80' then 'X' else '' end ) as Has80,

      // ---------------- היסטוריית ההזמנה ----------------
      @EndUserText.label: 'הזמנה'
      max( po.ebeln )                                                 as Ebeln,

      @EndUserText.label: 'מסמך קבלת טובין (היסטוריית הזמנה)'
      max( case when hist.PurchasingHistoryDocumentType = '1'
                then hist.PurchasingHistoryDocument end )             as GrBelnr,
      @EndUserText.label: 'שנת מסמך טובין'
      max( case when hist.PurchasingHistoryDocumentType = '1'
                then hist.PurchasingHistoryDocumentYear end )         as GrGjahr,

      @EndUserText.label: 'חשבונית לוגיסטית (היסטוריית הזמנה)'
      max( case when hist.PurchasingHistoryDocumentType = '2'
                then hist.PurchasingHistoryDocument end )             as IrBelnr,
      @EndUserText.label: 'שנת כספים - חשבונית'
      max( case when hist.PurchasingHistoryDocumentType = '2'
                then hist.PurchasingHistoryDocumentYear end )         as IrGjahr
}
group by
  grpo.qmnum
