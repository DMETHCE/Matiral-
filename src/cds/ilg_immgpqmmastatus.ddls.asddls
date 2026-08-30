@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Green Path - QMMA status codes per notification'
/*
 * איסוף קודי סטטוס 50/60/70/80 מטבלת QMMA לכל הודעה (QMNUM)
 * באמצעות אגרגציית MAX על ביטויי CASE (במקום לולאה עם דגלים).
 *
 * MNGRP = 'ZPU'  - קבוצת הפעילויות של המסלול הירוק (אומת מול VIQMMA).
 * KZLOESCH = ''  - פעילות שסומנה למחיקה בהודעה אינה נספרת.
 */
define view entity /ILG/IMMGpQmmaStatus
  as select from qmma
{
      @EndUserText.label: 'מספר סט (הודעה)'
  key qmnum                                            as Qmnum,

      @EndUserText.label: 'קיים קוד 50 - נדחה'
      max( case mncod when '50' then 'X' else '' end ) as Has50,
      @EndUserText.label: 'קיים קוד 60 - אושר'
      max( case mncod when '60' then 'X' else '' end ) as Has60,
      @EndUserText.label: 'קיים קוד 70 - טובין ידני'
      max( case mncod when '70' then 'X' else '' end ) as Has70,
      @EndUserText.label: 'קיים קוד 80 - חשבונית ידנית'
      max( case mncod when '80' then 'X' else '' end ) as Has80
}
where
      mngrp    = 'ZPU'
  and kzloesch = ''
group by
  qmnum
