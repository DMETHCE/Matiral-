@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Green Path - notification activity codes per set'
/*
 * /ILG/IMMGpQmmaStatus
 * --------------------
 * איסוף קודי פעילות 50/60/70/80 לכל הודעה (QMNUM) באמצעות אגרגציית
 * MAX על ביטויי CASE (במקום לולאה עם דגלים).
 *
 * מקור (VDM): I_QltyNotificationActivity - View משוחרר (S/4HANA 2020 FPS01)
 * על טבלת הפעילויות QMMA. שדות מתועדים ב-help.sap.com:
 *   QualityNotification  = QMNUM    NotificationActivity = MANUM
 *
 * !! לאמת ב-ADT (Outline של I_QltyNotificationActivity) - שלושה שמות
 *    שאינם מתועדים באינטרנט ונכתבו לפי קונבנציית ה-VDM:
 *   NotifActivityCodeGroup = MNGRP   (קבוצת קודים 'ZPU' - אומת מול VIQMMA)
 *   NotifActivityCode      = MNCOD   (קוד הפעילות)
 *   IsDeleted              = KZLOESCH (פעילות שסומנה למחיקה אינה נספרת;
 *                            אם ה-View כבר מסנן מחוקות - למחוק את התנאי)
 *
 * אם הודעות המסלול הירוק הן הודעות PM (לא QM), ה-View לעיל עלול להחזיר
 * 0 שורות; החלופה המשוחררת היא I_MaintNotificationActyData (SAP ממליצה
 * עליה ל-BW בלבד) - להחליף מקור ושמות שדות בהתאם.
 */
define view entity /ILG/IMMGpQmmaStatus
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
