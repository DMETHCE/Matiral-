@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Green Path - set (one row per notification)'
/*
 * /ILG/I_GreenPathSet
 * -------------------
 * View בסיס לטבלת המסלול הירוק /ILG/MM_GRPO_DET - שורה אחת לכל סט
 * (מפתח MANDT+QMNUM). חושף רק את השדות שמעקב המסלול הירוק צורך,
 * בשמות CamelCase, כדי ששאר השרשרת (/ILG/IMMGpSetDocs ומעלה)
 * לא תיגע בטבלת ILG ישירות.
 */
define view entity /ILG/I_GreenPathSet
  as select from /ilg/mm_grpo_det
{
      @EndUserText.label: 'מספר סט (הודעה)'
  key qmnum             as Qmnum,

      @EndUserText.label: 'קוד חברה'
      bukrs             as Bukrs,
      @EndUserText.label: 'תאריך רישום הסט'
      datum             as Datum,

      // מסמך קבלת טובין שנרשם במסלול הירוק
      @EndUserText.label: 'מסמך קבלת טובין'
      mblnr             as Mblnr,
      @EndUserText.label: 'שנת מסמך טובין'
      mjahr             as Mjahr,
      // 2 = מסמך אחד על כל הכמות, 4 = מספר מסמכים (טובין ידני)
      @EndUserText.label: 'אינדיקטור טובין ידני'
      mm_gr_doc_ind     as MmGrDocInd,

      // חשבונית לוגיסטית שנרשמה במסלול הירוק
      @EndUserText.label: 'חשבונית לוגיסטית'
      belnr             as Belnr,
      @EndUserText.label: 'שנת כספים - חשבונית'
      gjahr             as Gjahr,

      // בקרה ידנית: סט 10 / חשבונית מעל 10 אלש"ח
      @EndUserText.label: 'אינדיקטור בקרה ידנית'
      monitor_indicator as MonitorIndicator,
      @EndUserText.label: 'חשבונית מעל סף הסכום'
      extra_vlue_ind    as ExtraValueInd
}
