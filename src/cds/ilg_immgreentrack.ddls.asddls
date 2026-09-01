@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Green Path Tracking - live status per notification'
/*
 * /ILG/IMMGreenTrack
 * ------------------
 * View חי למעקב מסלול ירוק / בקרה מפצה - מחליף את התוכנית
 * ZMM_PROCESS_GREEN_PATH ואת טבלת היעד המתוכננת (שלא הוקמה).
 * האפיון העסקי גובר על התוכנית בכל סתירה; פירוט מלא, סטטוס אימות
 * והחלטות פתוחות: docs/cds/cds_spec.md במאגר הפרויקט.
 *
 * שרשרת הנתונים:
 *   /ILG/MM_GRPO_DET (הסט) -> QMMA (קודי סטטוס, MNGRP='ZPU')
 *   -> RBKP (מצב החשבונית: RBSTAT 5=נרשמה, 2=נמחקה)
 *   -> BKPF דרך AWKEY=BELNR+GJAHR + AWTYP='RMRP', מוצמד ל-BUKRS של RBKP
 *   -> סטורנו: XREVERSED='X'; מסמך הסטורנו נקרא לפי BUKRS+STBLG+STJAH
 *      (לא דרך AWREF_REV - הוא מאוכלס על מסמך הסטורנו, לא על המקור)
 *   -> T041CT (טקסט סיבת ביטול, TXT40) ; ACDOCA (תשלום, AUGBL '2%')
 *
 * דרישה: S/4HANA 2020 ומעלה (view entity + ביטויים בתנאי ON).
 * כל שמות השדות אומתו מול צילומי SE11 מהמערכת.
 */
define view entity /ILG/IMMGreenTrack
  as select from /ilg/mm_grpo_det as grpo

    // קודי הסטטוס של הסט (קבוצת ZPU, ללא פעילויות שנמחקו)
    left outer join /ILG/IMMGpQmmaStatus as stat
      on stat.Qmnum = grpo.qmnum

    // מצב החשבונית הלוגיסטית (מפתח BELNR+GJAHR)
    left outer join rbkp as inv
      on  inv.belnr   = grpo.belnr
      and inv.gjahr   = grpo.gjahr
      and grpo.belnr <> ''

    // המסמך הפיננסי; הצמדת BUKRS מונעת כפילות ברישום חוצה-חברות
    left outer join bkpf as fi
      on  fi.awkey     = concat( grpo.belnr, cast( grpo.gjahr as abap.char(4) ) )
      and fi.awtyp     = 'RMRP'
      and fi.bukrs     = inv.bukrs
      and grpo.belnr  <> ''
      and grpo.gjahr  <> '0000'

    // מסמך הסטורנו לפי המפתח המלא - לשליפת סיבת הביטול (STGRD)
    left outer join bkpf as rev
      on  rev.bukrs  = fi.bukrs
      and rev.belnr  = fi.stblg
      and rev.gjahr  = fi.stjah
      and fi.stblg  <> ''

    // טקסט סיבת סטורנו בשפת המשתמש
    left outer join t041ct as stx
      on  stx.stgrd = rev.stgrd
      and stx.spras = $session.system_language

    // תשלום בפועל - סילוק שורת ספק במסמך תשלום
    left outer join /ILG/IMMGpClearing as clr
      on  clr.Bukrs = fi.bukrs
      and clr.Belnr = fi.belnr
      and clr.Gjahr = fi.gjahr

{
      @EndUserText.label: 'מספר סט (הודעה)'
  key grpo.qmnum                                            as Qmnum,

      // ---------------------------------------------------------------
      // עץ ההחלטות לפי האפיון העסקי - קוד סטטוס
      // בוטלה = XREVERSED='X' או RBSTAT='2'
      // הושלמו מסמכי המשך = MBLNR + BELNR מלאים וגם RBSTAT='5'
      // ---------------------------------------------------------------
      @EndUserText.label: 'קוד סטטוס לוגי'
      cast(
        case
          when stat.Has50 = 'X' and stat.Has60 = 'X' then
            case
              when fi.xreversed = 'X' or inv.rbstat = '2'
                or clr.Augbl is null                     then '01' // נדחה לאחר אישור ובוטל
              else                                            '02' // נדחה לאחר אישור ושולם
            end
          when stat.Has60 = 'X' then
            case
              when fi.xreversed = 'X' or inv.rbstat = '2'    then '03' // נדחה לאחר אישור דורש
              when grpo.mblnr <> '' and grpo.belnr <> ''
                and inv.rbstat = '5' then
                case
                  when stat.Has70 = 'X' or stat.Has80 = 'X'
                    or grpo.mm_gr_doc_ind = '2'
                    or grpo.mm_gr_doc_ind = '4'          then '04' // אושר והושלם לאחר עיסוק ידני
                  else                                        '05' // אושר והושלם ללא תקלה
                end
              else                                            '07' // אושר - טרם הושלמו מסמכי המשך
            end
          when stat.Has50 = 'X'                          then '06' // נדחה על ידי דורש
          else                                                '99' // בתהליך
        end as abap.char(2) )                                as LogicalStatusCode,

      // ---------------------------------------------------------------
      // עץ ההחלטות - טקסט (ניסוחי האפיון העסקי)
      // ---------------------------------------------------------------
      @EndUserText.label: 'סטטוס לוגי'
      cast(
        case
          when stat.Has50 = 'X' and stat.Has60 = 'X' then
            case
              when fi.xreversed = 'X' or inv.rbstat = '2'
                or clr.Augbl is null
                then 'נדחה לאחר אישור ובוטל'
              else 'נדחה לאחר אישור ושולם'
            end
          when stat.Has60 = 'X' then
            case
              when fi.xreversed = 'X' or inv.rbstat = '2'
                then 'נדחה לאחר אישור דורש'
              when grpo.mblnr <> '' and grpo.belnr <> ''
                and inv.rbstat = '5' then
                case
                  when stat.Has70 = 'X' or stat.Has80 = 'X'
                    or grpo.mm_gr_doc_ind = '2'
                    or grpo.mm_gr_doc_ind = '4'
                    then 'אושר והושלם לאחר עיסוק ידני'
                  else 'אושר והושלם ללא תקלה'
                end
              else 'אושר - טרם הושלמו מסמכי המשך'
            end
          when stat.Has50 = 'X'
            then 'נדחה על ידי דורש'
          else 'בתהליך'
        end as abap.char(40) )                               as LogicalStatus,

      // אינדיקטור בקרה ידנית (MONITOR_INDICATOR או חשבונית מעל 10 אלש"ח)
      @EndUserText.label: 'בקרה ידנית'
      cast(
        case
          when grpo.monitor_indicator <> '' or grpo.extra_vlue_ind <> ''
            then 'X' else ''
        end as abap.char(1) )                                as IsMonitor,

      @EndUserText.label: 'מסמך קבלת טובין'
      grpo.mblnr                                             as Mblnr,

      // טובין ידני (2 = מסמך אחד על כל הכמות, 4 = מספר מסמכים)
      @EndUserText.label: 'טובין נוצר ידנית'
      cast(
        case
          when grpo.mm_gr_doc_ind = '2' or grpo.mm_gr_doc_ind = '4'
            then 'X' else ''
        end as abap.char(1) )                                as MblnrHandledManually,

      @EndUserText.label: 'חשבונית לוגיסטית'
      grpo.belnr                                             as BelnrMm,
      @EndUserText.label: 'שנת כספים - חשבונית'
      grpo.gjahr                                             as GjahrMm,

      // מצב החשבונית הלוגיסטית (5=נרשמה, 2=נמחקה, ריק=אין חשבונית)
      @EndUserText.label: 'מצב חשבונית'
      inv.rbstat                                             as Rbstat,

      // פרטי המסמך הפיננסי (ריק/NULL כשלא נמצא)
      @EndUserText.label: 'קוד חברה'
      fi.bukrs                                               as Bukrs,
      @EndUserText.label: 'מסמך פיננסי'
      fi.belnr                                               as BelnrFi,
      @EndUserText.label: 'שנת כספים - פיננסי'
      fi.gjahr                                               as GjahrFi,

      // תשלום בפועל - אינדיקטור בוליאני רוחבי (החלטת דיון 4/8)
      @EndUserText.label: 'שולם בפועל'
      cast(
        case when clr.Augbl is not null
          then 'X' else ''
        end as abap.char(1) )                                as IsPaid,
      @EndUserText.label: 'מסמך תשלום'
      clr.Augbl                                              as Augbl,
      @EndUserText.label: 'תאריך תשלום'
      clr.Augdt                                              as Augdt,

      // סטורנו פיננסי; חשבונית שנמחקה נראית דרך Rbstat = '2'
      @EndUserText.label: 'בוצע סטורנו'
      cast(
        case when fi.xreversed = 'X'
          then 'X' else ''
        end as abap.char(1) )                                as IsReversed,

      // סיבת ביטול - עמודות רוחביות; COALESCE מבטיח ריק ולא NULL
      @EndUserText.label: 'סיבת סטורנו'
      coalesce(
        case when fi.xreversed = 'X' then rev.stgrd else '' end,
        cast( '' as abap.char(2) ) )                         as Stgrd,
      @EndUserText.label: 'תיאור סיבת סטורנו'
      coalesce(
        case when fi.xreversed = 'X' then stx.txt40 else '' end,
        cast( '' as abap.char(40) ) )                        as StgrdTxt,

      // תאריך ושעת יצירת הסט - מטבלת המקור
      // (AEDAT/AEZET שמורים לטבלת הטעינה - מועד ה-snapshot)
      @EndUserText.label: 'תאריך יצירת סט'
      grpo.datum                                             as Datum,

      @EndUserText.label: 'שעת יצירת סט'
      grpo.uzeit                                             as Uzeit
}
