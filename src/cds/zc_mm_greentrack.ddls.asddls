@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Green Path Tracking - live view (repl. ZMM_GREEN_TRACK)'
@Metadata.ignorePropagatedAnnotations: true
/*
 * ZC_MM_GREENTRACK
 * ----------------
 * CDS View Entity שמחזיר בדיוק את אותם נתונים שהתוכנית ZMM_PROCESS_GREEN_PATH
 * רושמת לטבלת ZMM_GREEN_TRACK - אבל בזמן אמת, ללא ריצת Batch וללא טבלת יעד.
 *
 * מיפוי לסעיפי התוכנית המקורית:
 *   א. is_monitor / mblnr_handled_manually  - ביטויי CASE על שדות /ILG/MM_GRPO_DET
 *   ב. קודי סטטוס QMMA (50/60/70/80)        - ZI_MM_GP_QMMASTATUS (אגרגציה)
 *   ג. קישור BKPF דרך AWKEY, סטורנו ותשלום  - join-ים fi / rev / clr למטה
 *   ד. עץ ההחלטות של הסטטוס הלוגי           - logical_status / logical_status_code
 *   ה. הרישום לטבלה מתייתר - ה-View חי
 *
 * דרישות מערכת: S/4HANA 2020 ומעלה (view entity + ביטויים בתנאי ON).
 *
 * מבנה /ILG/MM_GRPO_DET אומת מול צילום SE11 (26.08.2026):
 *   - מפתח: MANDT + QMNUM (שורה אחת להודעה); BELNR CHAR10 (RE_BELNR),
 *     GJAHR NUMC4, MONITOR_INDICATOR / EXTRA_VLUE_IND / MM_GR_DOC_IND שדות CHAR1.
 *   - שם השדה בטבלה הוא MM_GR_DOC_IND - בתוכנית המקורית נכתב בטעות
 *     mn_gr_doc_ind (שגיאת קומפילציה נוספת שם).
 *
 * אושר על ידי הלקוח (26.08.2026): סביבת S/4HANA 2020 ומעלה;
 * סינון AWTYP = 'RMRP' נשאר (בקוד המקורי לא סונן AWTYP - הסינון כאן
 * מונע התאמה שגויה לאובייקט אחר); טבלת ZMM_GREEN_TRACK לא תוקם -
 * ה-View הזה הוא התוצר הסופי. ראו docs/cds_green_track_spec.md.
 */
define view entity ZC_MM_GREENTRACK
  as select from /ilg/mm_grpo_det as grpo

    // סעיף ב': קודי הסטטוס של הסט מ-QMMA
    left outer join ZI_MM_GP_QMMASTATUS as stat
      on stat.qmnum = grpo.qmnum

    // סעיף ג': המסמך הפיננסי דרך AWKEY = BELNR + GJAHR
    // (מקביל ל: CONCATENATE belnr gjahr INTO lv_awkey + SELECT SINGLE FROM bkpf)
    left outer join bkpf as fi
      on  fi.awkey     = concat( grpo.belnr, cast( grpo.gjahr as abap.char(4) ) )
      and fi.awtyp     = 'RMRP'
      and grpo.belnr  <> ''
      and grpo.gjahr  <> '0000'

    // ג'.1: מסמך הסטורנו - לשליפת סיבת הביטול (STGRD)
    // (מקביל ל: CONCATENATE awref_rev aworg_rev INTO lv_rev_awkey)
    left outer join bkpf as rev
      on  rev.awkey     = concat( fi.awref_rev, fi.aworg_rev )
      and fi.xreversed  = 'X'
      and fi.awref_rev <> ''

    // סעיף 3 בתוכנית: טקסט סיבת סטורנו מ-T041CT בשפת המשתמש
    left outer join t041ct as stx
      on  stx.stgrd = rev.stgrd
      and stx.spras = $session.system_language

    // ג'.2: תשלום בפועל - סילוק שורת ספק ב-ACDOCA
    left outer join ZI_MM_GP_CLEARING as clr
      on  clr.bukrs = fi.bukrs
      and clr.belnr = fi.belnr
      and clr.gjahr = fi.gjahr

{
  key grpo.qmnum                                            as qmnum,

      // ---------------------------------------------------------------
      // סעיף ד': עץ ההחלטות - קוד סטטוס (מומלץ לשימוש תוכניתי/סינון)
      // ---------------------------------------------------------------
      cast(
        case
          when stat.has_50 = 'X' and stat.has_60 = 'X' then
            case
              when fi.xreversed = 'X' or clr.augbl is null then '01' // נדחה לאחר אישור ובוטל
              else                                              '02' // נדחה לאחר אישור ושולם
            end
          when stat.has_60 = 'X' then
            case
              when fi.xreversed = 'X'                      then '03' // נדחה לאחר אישור דורש
              when stat.has_70 = 'X' or stat.has_80 = 'X'
                or grpo.mm_gr_doc_ind = '2'
                or grpo.mm_gr_doc_ind = '4'                then '04' // אושר והושלם לאחר עיסוק ידני
              else                                              '05' // אושר והושלם ללא תקלה
            end
          when stat.has_50 = 'X'                           then '06' // נדחה על ידי דורש
          else                                                  '99' // בתהליך
        end as abap.char(2) )                                as logical_status_code,

      // ---------------------------------------------------------------
      // סעיף ד': עץ ההחלטות - טקסט זהה 1:1 לתוכנית המקורית
      // ---------------------------------------------------------------
      cast(
        case
          when stat.has_50 = 'X' and stat.has_60 = 'X' then
            case
              when fi.xreversed = 'X' or clr.augbl is null
                then 'נדחה לאחר אישור ובוטל'
              else 'נדחה לאחר אישור ושולם'
            end
          when stat.has_60 = 'X' then
            case
              when fi.xreversed = 'X'
                then 'נדחה לאחר אישור דורש'
              when stat.has_70 = 'X' or stat.has_80 = 'X'
                or grpo.mm_gr_doc_ind = '2'
                or grpo.mm_gr_doc_ind = '4'
                then 'אושר והושלם לאחר עיסוק ידני'
              else 'אושר והושלם ללא תקלה'
            end
          when stat.has_50 = 'X'
            then 'נדחה על ידי דורש'
          else 'בתהליך'
        end as abap.char(40) )                               as logical_status,

      // ---------------------------------------------------------------
      // סעיף א': אינדיקטור בקרה ידנית
      // ---------------------------------------------------------------
      cast(
        case
          when grpo.monitor_indicator <> '' or grpo.extra_vlue_ind <> ''
            then 'X' else ''
        end as abap.char(1) )                                as is_monitor,

      grpo.mblnr                                             as mblnr,

      // סעיף א': אינדיקטור טובין ידני (ערכים 2 או 4)
      cast(
        case
          when grpo.mm_gr_doc_ind = '2' or grpo.mm_gr_doc_ind = '4'
            then 'X' else ''
        end as abap.char(1) )                                as mblnr_handled_manually,

      grpo.belnr                                             as belnr_mm,
      grpo.gjahr                                             as gjahr_mm,

      // סעיף ג': פרטי המסמך הפיננסי (ריק/NULL כשלא נמצא - כמו בתוכנית)
      fi.bukrs                                               as bukrs,
      fi.belnr                                               as belnr_fi,
      fi.gjahr                                               as gjahr_fi,

      // ג'.2: תשלום בפועל
      cast(
        case when clr.augbl is not null
          then 'X' else ''
        end as abap.char(1) )                                as is_paid,
      clr.augbl                                              as augbl,
      clr.augdt                                              as augdt,

      // ג'.1: סטורנו
      cast(
        case when fi.xreversed = 'X'
          then 'X' else ''
        end as abap.char(1) )                                as is_reversed,

      case when fi.xreversed = 'X' then rev.stgrd else '' end as stgrd,
      case when fi.xreversed = 'X' then stx.txt20 else '' end as stgrd_txt,

      // AEDAT בתוכנית = sy-datum בזמן הריצה; ב-View חי = תאריך השאילתה
      $session.system_date                                   as aedat

      // AEZET (שעת ריצה) הושמט: אין משתנה שעת-מערכת ב-CDS,
      // וב-View חי הנתונים תמיד עדכניים לרגע השאילתה - ראו מסמך האפיון
}
