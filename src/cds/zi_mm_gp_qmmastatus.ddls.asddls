@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Green Path - QMMA status codes per notification'
@Metadata.ignorePropagatedAnnotations: true
/*
 * מקביל לסעיף ב' בתוכנית ZMM_PROCESS_GREEN_PATH:
 * איסוף קודי סטטוס 50/60/70/80 מטבלת QMMA לכל הודעה (QMNUM).
 * במקום לולאה עם דגלים - אגרגציית MAX על ביטויי CASE.
 * (בכך גם נפתר הבאג בתוכנית המקורית: הדגלים lv_has_xx לא אופסו בין סטים)
 */
define view entity ZI_MM_GP_QMMASTATUS
  as select from qmma
{
  key qmnum,

      max( case mncod when '50' then 'X' else '' end ) as has_50,
      max( case mncod when '60' then 'X' else '' end ) as has_60,
      max( case mncod when '70' then 'X' else '' end ) as has_70,
      max( case mncod when '80' then 'X' else '' end ) as has_80
}
group by
  qmnum
