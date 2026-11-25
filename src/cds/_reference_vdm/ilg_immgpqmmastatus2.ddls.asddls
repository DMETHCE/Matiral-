@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Green Path - notification activity codes per set'
/*
 * /ILG/IMMGpQmmaStatus2
 * --------------------
 * איסוף קודי פעילות 50/60/70/80 לכל הודעה (QMNUM) באמצעות אגרגציית
 * MAX על ביטויי CASE (במקום לולאה עם דגלים).
 *
 * מקור (VDM): I_QltyNotificationActivity - View משוחרר (S/4HANA 2020 FPS01)
 * על טבלת הפעילויות QMMA. שדות מתועדים ב-help.sap.com:
 *   QualityNotification  = QMNUM    NotificationActivity = MANUM
 *
 * מיפוי שדות (אומת ב-api.sap.com, Composite / Released):
 *   NotifActivityCodeGroup = MNGRP    (קבוצת קודים 'ZPU' - אומת מול VIQMMA)
 *   NotifActivityCode      = MNCOD    (קוד הפעילות)
 *   IsDeleted              = KZLOESCH (פעילות שסומנה למחיקה אינה נספרת)
 *
 * סיכון פתוח: SAP מתעדת את ה-View להודעות איכות, והודעות המסלול הירוק
 * הן הודעות PM. לבדוק ב-Data Preview שהוא מחזיר שורות ל-QMNUM מוכר;
 * אם לא - החלופה המשוחררת היא C_MaintNotifActivityDEX (הודעות PM):
 * MaintenanceNotification / MaintNotifActivityCodeGroup /
 * MaintNotificationActivityCode / IsDeleted.
 */
define view entity /ILG/IMMGpQmmaStatus2
  as select from I_QltyNotificationActivity
{
      @EndUserText.label: 'מספר סט (הודעה)'
  key QualityNotification                                        as Qmnum,

      @EndUserText.label: 'קיים קוד 50 - נדחה'
      max( case NotifActivityCode when '50' then 'X' else '' end ) as Has50,
      @EndUserText.label: 'קיים קוד 60 - אושר'
      max( case NotifActivityCode when '60' then 'X' else '' end ) as Has60,
      @EndUserText.label: 'קיים קוד 70 - טובין ידני'
      max( case NotifActivityCode when '70' then 'X' else '' end ) as Has70,
      @EndUserText.label: 'קיים קוד 80 - חשבונית ידנית'
      max( case NotifActivityCode when '80' then 'X' else '' end ) as Has80
}
where
      NotifActivityCodeGroup = 'ZPU'
  and IsDeleted              = ''
group by
  QualityNotification
