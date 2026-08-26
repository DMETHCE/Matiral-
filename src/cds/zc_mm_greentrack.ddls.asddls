@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Green Path Tracking - live view (repl. ZMM_GREEN_TRACK)'
@Metadata.ignorePropagatedAnnotations: true
/*
 * ZC_MM_GREENTRACK
 * ----------------
 * CDS View Entity למעקב מסלול ירוק / בקרה מפצה - מחליף את התוכנית
 * ZMM_PROCESS_GREEN_PATH ואת טבלת היעד המתוכננת ZMM_GREEN_TRACK.
 *
 * עקרון מנחה (הנחיית הלקוח, 26.08.2026): האפיון העסקי (מסמך ה-Word)
 * גובר על קוד ה-ABAP של התוכנית בכל מקום שבו הם סותרים.
 * הפערים מתועדים בסעיף 10 של docs/cds_green_track_spec.md.
 *
 * שרשרת הנתונים לפי האפיון:
 *   /ILG/MM_GRPO_DET (הסט) -> QMMA (קודי סטטוס, MNGRP='ZPU')
 *   -> RBKP (מצב החשבונית הלוגיסטית, RBSTAT: 5=נרשמה, 2=נמחקה/סטורנו)
 *   -> BKPF דרך AWKEY=BELNR+GJAHR (מסמך פיננסי, XREVERSED)
 *   -> BKPF של מסמך הסטורנו דרך AWREF_REV+AWORG_REV (סיבת ביטול STGRD)
 *   -> T041CT (טקסט סיבת הביטול) ; ACDOCA (תשלום בפועל, AUGBL מתחיל ב-2)
 *
 * דרישות מערכת: S/4HANA 2020 ומעלה (view entity + ביטויים בתנאי ON) -
 * אושר על ידי הלקוח 26.08.2026.
 *
 * מבנה /ILG/MM_GRPO_DET אומת מול צילום SE11 (26.08.2026):
 *   מפתח MANDT + QMNUM (שורה אחת להודעה); BELNR CHAR10 (RE_BELNR),
 *   GJAHR NUMC4, MONITOR_INDICATOR / EXTRA_VLUE_IND / MM_GR_DOC_IND CHAR1.
 */
define view entity ZC_MM_GREENTRACK
  as select from /ilg/mm_grpo_det as grpo

    // קודי הסטטוס של הסט מ-QMMA (קבוצת קודים ZPU)
    left outer join ZI_MM_GP_QMMASTATUS as stat
      on stat.qmnum = grpo.qmnum

    // מצב החשבונית הלוגיסטית - RBKP (לפי האפיון: 5=נרשמה, 2=נמחקה/סטורנו)
    left outer join rbkp as inv
      on  inv.belnr   = grpo.belnr
      and inv.gjahr   = grpo.gjahr
      and grpo.belnr <> ''

    // המסמך הפיננסי דרך AWKEY = BELNR + GJAHR
    left outer join bkpf as fi
      on  fi.awkey     = concat( grpo.belnr, cast( grpo.gjahr as abap.char(4) ) )
      and fi.awtyp     = 'RMRP'
      and grpo.belnr  <> ''
      and grpo.gjahr  <> '0000'

    // מסמך הסטורנו - לשליפת סיבת הביטול (STGRD)
    left outer join bkpf as rev
      on  rev.awkey     = concat( fi.awref_rev, fi.aworg_rev )
      and fi.xreversed  = 'X'
      and fi.awref_rev <> ''

    // טקסט סיבת סטורנו מ-T041CT בשפת המשתמש
    left outer join t041ct as stx
      on  stx.stgrd = rev.stgrd
      and stx.spras = $session.system_language

    // תשלום בפועל - סילוק שורת ספק ב-ACDOCA במסמך תשלום (מתחיל ב-2)
    left outer join ZI_MM_GP_CLEARING as clr
      on  clr.bukrs = fi.bukrs
      and clr.belnr = fi.belnr
      and clr.gjahr = fi.gjahr

{
  key grpo.qmnum                                            as qmnum,

      // ---------------------------------------------------------------
      // עץ ההחלטות לפי האפיון העסקי - קוד סטטוס
      // ביטול = סטורנו פיננסי (XREVERSED) או חשבונית שנמחקה (RBSTAT='2')
      // "הושלם" מחייב מסמכי המשך: MBLNR + BELNR + חשבונית רשומה (RBSTAT='5')
      // ---------------------------------------------------------------
      cast(
        case
          when stat.has_50 = 'X' and stat.has_60 = 'X' then
            case
              when fi.xreversed = 'X' or inv.rbstat = '2'
                or clr.augbl is null                     then '01' // נדחה לאחר אישור ובוטל
              else                                            '02' // נדחה לאחר אישור ושולם
            end
          when stat.has_60 = 'X' then
            case
              when fi.xreversed = 'X' or inv.rbstat = '2' then '03' // נדחה לאחר אישור דורש
              when grpo.mblnr <> '' and grpo.belnr <> ''
                and inv.rbstat = '5' then
                case
                  when stat.has_70 = 'X' or stat.has_80 = 'X'
                    or grpo.mm_gr_doc_ind = '2'
                    or grpo.mm_gr_doc_ind = '4'          then '04' // אושר והושלם לאחר עיסוק ידני
                  else                                        '05' // אושר והושלם ללא תקלה
                end
              else                                            '07' // אושר - טרם הושלמו מסמכי המשך
            end
          when stat.has_50 = 'X'                         then '06' // נדחה על ידי דורש
          else                                                '99' // בתהליך
        end as abap.char(2) )                                as logical_status_code,

      // ---------------------------------------------------------------
      // עץ ההחלטות - טקסט (זהה לניסוחי האפיון העסקי)
      // ---------------------------------------------------------------
      cast(
        case
          when stat.has_50 = 'X' and stat.has_60 = 'X' then
            case
              when fi.xreversed = 'X' or inv.rbstat = '2'
                or clr.augbl is null
                then 'נדחה לאחר אישור ובוטל'
              else 'נדחה לאחר אישור ושולם'
            end
          when stat.has_60 = 'X' then
            case
              when fi.xreversed = 'X' or inv.rbstat = '2'
                then 'נדחה לאחר אישור דורש'
              when grpo.mblnr <> '' and grpo.belnr <> ''
                and inv.rbstat = '5' then
                case
                  when stat.has_70 = 'X' or stat.has_80 = 'X'
                    or grpo.mm_gr_doc_ind = '2'
                    or grpo.mm_gr_doc_ind = '4'
                    then 'אושר והושלם לאחר עיסוק ידני'
                  else 'אושר והושלם ללא תקלה'
                end
              else 'אושר - טרם הושלמו מסמכי המשך'
            end
          when stat.has_50 = 'X'
            then 'נדחה על ידי דורש'
          else 'בתהליך'
        end as abap.char(40) )                               as logical_status,

      // ---------------------------------------------------------------
      // אינדיקטור בקרה ידנית (MONITOR_INDICATOR או חשבונית מעל 10 אלש"ח)
      // ---------------------------------------------------------------
      cast(
        case
          when grpo.monitor_indicator <> '' or grpo.extra_vlue_ind <> ''
            then 'X' else ''
        end as abap.char(1) )                                as is_monitor,

      grpo.mblnr                                             as mblnr,

      // אינדיקטור טובין ידני (2 = מסמך אחד על כל הכמות, 4 = מספר מסמכים)
      cast(
        case
          when grpo.mm_gr_doc_ind = '2' or grpo.mm_gr_doc_ind = '4'
            then 'X' else ''
        end as abap.char(1) )                                as mblnr_handled_manually,

      grpo.belnr                                             as belnr_mm,
      grpo.gjahr                                             as gjahr_mm,

      // מצב החשבונית הלוגיסטית מ-RBKP (5=נרשמה, 2=נמחקה, ריק=אין חשבונית)
      inv.rbstat                                             as rbstat,

      // פרטי המסמך הפיננסי (ריק/NULL כשלא נמצא)
      fi.bukrs                                               as bukrs,
      fi.belnr                                               as belnr_fi,
      fi.gjahr                                               as gjahr_fi,

      // תשלום בפועל - אינדיקטור בוליאני רוחבי (החלטת דיון 4/8)
      cast(
        case when clr.augbl is not null
          then 'X' else ''
        end as abap.char(1) )                                as is_paid,
      clr.augbl                                              as augbl,
      clr.augdt                                              as augdt,

      // סטורנו פיננסי (XREVERSED); חשבונית שנמחקה נראית דרך rbstat = '2'
      cast(
        case when fi.xreversed = 'X'
          then 'X' else ''
        end as abap.char(1) )                                as is_reversed,

      // סיבת הביטול - עמודה רוחבית (החלטת דיון 4/8), קיימת רק לסטורנו פיננסי
      case when fi.xreversed = 'X' then rev.stgrd else '' end as stgrd,
      case when fi.xreversed = 'X' then stx.txt20 else '' end as stgrd_txt,

      // תאריך השאילתה (במקור: sy-datum של ריצת ה-Batch)
      $session.system_date                                   as aedat

      // AEZET הושמט: אין משתנה שעת-מערכת ב-CDS, וב-View חי הנתונים
      // תמיד עדכניים לרגע השאילתה
}
