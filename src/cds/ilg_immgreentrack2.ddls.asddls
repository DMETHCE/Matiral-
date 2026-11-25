@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Green Path Tracking v2 - live status per notification'
/*
 * /ILG/IMMGreenTrack2
 * -------------------
 * View חי למעקב מסלול ירוק / בקרה מפצה - מחליף את /ILG/IMMGreenTrack.
 * בנוי באסוציאציות: כל מקור נגיש גם לניווט (Fiori / Views צורכים).
 *
 * שרשרת הנתונים:
 *   /ILG/IMMGpSetDocs  (הסט + מסמכי ההמשך מוכרעים: GRPO_DET / PM_NOTIF_BP / EKBE)
 *   -> _Status      /ILG/IMMGpQmmaStatus  קודי 50/60/70/80 (MNGRP='ZPU')
 *   -> _Invoice     RBKP                  מצב החשבונית (5=נרשמה, 2=נמחקה), קוד חברה
 *   -> _FiDoc       BKPF                  AWKEY=BELNR+GJAHR, AWTYP='RMRP', מוצמד ל-BUKRS
 *   -> _ReversalDoc BKPF                  AWKEY=AWREF_REV+AWORG_REV של המסמך המקורי
 *                                         (STBLG/STJAH ריקים בסטורנו MR8M - אומת 07.09.2026)
 *   -> _StgrdText   T041CT                טקסט סיבת הסטורנו בשפת המשתמש
 *   -> _Clearing    /ILG/IMMGpClearing    תשלום בפועל (ACDOCA, AUGBL '2%')
 *
 * כל תנאי ON משתמש בשדות $projection רגילים או שהוגדרו בשכבה קודמת
 * של השרשרת (ללא מעגליות). הענף הראשון שמתקיים בעץ ההחלטות קובע.
 * דרישה: S/4HANA 2020 ומעלה.
 */
define view entity /ILG/IMMGreenTrack2
  as select from /ILG/IMMGpSetDocs as sd

  // קודי הסטטוס של הסט (קבוצת ZPU, ללא פעילויות שנמחקו)
  association [0..1] to /ILG/IMMGpQmmaStatus as _Status
    on $projection.Qmnum = _Status.Qmnum

  // מצב החשבונית הלוגיסטית (מפתח BELNR+GJAHR)
  association [0..1] to rbkp as _Invoice
    on  $projection.BelnrMm = _Invoice.belnr
    and $projection.GjahrMm = _Invoice.gjahr

  // המסמך הפיננסי; הצמדת BUKRS מונעת כפילות ברישום חוצה-חברות
  association [0..1] to bkpf as _FiDoc
    on  $projection.AwKey = _FiDoc.awkey
    and _FiDoc.awtyp      = 'RMRP'
    and $projection.Bukrs = _FiDoc.bukrs

  // מסמך הסטורנו - המצביע אליו יושב על המסמך המקורי (AWREF_REV + AWORG_REV)
  association [0..1] to bkpf as _ReversalDoc
    on  $projection.ReversalAwKey = _ReversalDoc.awkey
    and _ReversalDoc.awtyp        = 'RMRP'
    and $projection.Bukrs         = _ReversalDoc.bukrs

  // טקסט סיבת סטורנו בשפת המשתמש
  association [0..1] to t041ct as _StgrdText
    on  $projection.Stgrd = _StgrdText.stgrd
    and _StgrdText.spras  = $session.system_language

  // תשלום בפועל - סילוק שורת ספק במסמך תשלום
  association [0..1] to /ILG/IMMGpClearing as _Clearing
    on  $projection.Bukrs   = _Clearing.Bukrs
    and $projection.BelnrFi = _Clearing.Belnr
    and $projection.GjahrFi = _Clearing.Gjahr

{
      @EndUserText.label: 'מספר סט (הודעה)'
  key sd.Qmnum                                                as Qmnum,

      // ---------------------------------------------------------------
      // עץ ההחלטות לפי האפיון העסקי - קוד סטטוס
      // בוטלה = XREVERSED='X' או RBSTAT='2'
      // הושלמו מסמכי המשך = MBLNR + BELNR מלאים וגם RBSTAT='5'
      // עיסוק ידני = קוד 70/80, או MM_GR_DOC_IND 2/4, או מסמך שלא
      //              נרשם במסלול הירוק (InvoiceSource 'P' / GrSource 'E')
      // ---------------------------------------------------------------
      @EndUserText.label: 'קוד סטטוס לוגי'
      cast(
        case
          when _Status.Has50 = 'X' and _Status.Has60 = 'X' then
            case
              when _FiDoc.xreversed = 'X' or _Invoice.rbstat = '2'
                or _Clearing.Augbl is null                 then '01' // נדחה לאחר אישור ובוטל
              else                                              '02' // נדחה לאחר אישור ושולם
            end
          when _Status.Has60 = 'X' then
            case
              when _FiDoc.xreversed = 'X' or _Invoice.rbstat = '2' then '03' // נדחה לאחר אישור דורש
              when sd.Mblnr <> '' and sd.BelnrMm <> ''
                and _Invoice.rbstat = '5' then
                case
                  when _Status.Has70 = 'X' or _Status.Has80 = 'X'
                    or sd.MmGrDocInd   = '2'
                    or sd.MmGrDocInd   = '4'
                    or sd.InvoiceSource = 'P'
                    or sd.GrSource      = 'E'                then '04' // אושר והושלם לאחר עיסוק ידני
                  else                                            '05' // אושר והושלם ללא תקלה
                end
              else                                                '07' // אושר - טרם הושלמו מסמכי המשך
            end
          when _Status.Has50 = 'X'                             then '06' // נדחה על ידי דורש
          else                                                      '99' // בתהליך
        end as abap.char(2) )                                   as LogicalStatusCode,

      // ---------------------------------------------------------------
      // עץ ההחלטות - טקסט (ניסוחי האפיון העסקי)
      // ---------------------------------------------------------------
      @EndUserText.label: 'סטטוס לוגי'
      cast(
        case
          when _Status.Has50 = 'X' and _Status.Has60 = 'X' then
            case
              when _FiDoc.xreversed = 'X' or _Invoice.rbstat = '2'
                or _Clearing.Augbl is null
                then 'נדחה לאחר אישור ובוטל'
              else 'נדחה לאחר אישור ושולם'
            end
          when _Status.Has60 = 'X' then
            case
              when _FiDoc.xreversed = 'X' or _Invoice.rbstat = '2'
                then 'נדחה לאחר אישור דורש'
              when sd.Mblnr <> '' and sd.BelnrMm <> ''
                and _Invoice.rbstat = '5' then
                case
                  when _Status.Has70 = 'X' or _Status.Has80 = 'X'
                    or sd.MmGrDocInd   = '2'
                    or sd.MmGrDocInd   = '4'
                    or sd.InvoiceSource = 'P'
                    or sd.GrSource      = 'E'
                    then 'אושר והושלם לאחר עיסוק ידני'
                  else 'אושר והושלם ללא תקלה'
                end
              else 'אושר - טרם הושלמו מסמכי המשך'
            end
          when _Status.Has50 = 'X'
            then 'נדחה על ידי דורש'
          else 'בתהליך'
        end as abap.char(40) )                                  as LogicalStatus,

      // אינדיקטור בקרה ידנית (MONITOR_INDICATOR או חשבונית מעל 10 אלש"ח)
      @EndUserText.label: 'בקרה ידנית'
      cast(
        case
          when sd.MonitorIndicator <> '' or sd.ExtraValueInd <> ''
            then 'X' else ''
        end as abap.char(1) )                                   as IsMonitor,

      @EndUserText.label: 'מסמך קבלת טובין'
      sd.Mblnr                                                  as Mblnr,

      // טובין ידני (2 = מסמך אחד על כל הכמות, 4 = מספר מסמכים, או טובין שלא נרשם במסלול)
      @EndUserText.label: 'טובין נוצר ידנית'
      cast(
        case
          when sd.MmGrDocInd = '2' or sd.MmGrDocInd = '4' or sd.GrSource = 'E'
            then 'X' else ''
        end as abap.char(1) )                                   as MblnrHandledManually,

      @EndUserText.label: 'חשבונית לוגיסטית'
      sd.BelnrMm                                                as BelnrMm,
      @EndUserText.label: 'שנת כספים - חשבונית'
      sd.GjahrMm                                                as GjahrMm,

      // מפתח המסמך הפיננסי - BELNR+GJAHR; שדה עזר לאסוציאציה _FiDoc
      @EndUserText.label: 'מפתח ייחוס (AWKEY)'
      concat( sd.BelnrMm, cast( sd.GjahrMm as abap.char(4) ) ) as AwKey,

      // מצב החשבונית הלוגיסטית (5=נרשמה, 2=נמחקה, ריק=אין חשבונית)
      @EndUserText.label: 'מצב חשבונית'
      _Invoice.rbstat                                           as Rbstat,

      // פרטי המסמך הפיננסי (ריק/NULL כשלא נמצא)
      @EndUserText.label: 'קוד חברה'
      _Invoice.bukrs                                            as Bukrs,
      @EndUserText.label: 'מסמך פיננסי'
      _FiDoc.belnr                                              as BelnrFi,
      @EndUserText.label: 'שנת כספים - פיננסי'
      _FiDoc.gjahr                                              as GjahrFi,

      // תשלום בפועל - אינדיקטור בוליאני רוחבי (החלטת דיון 4/8)
      @EndUserText.label: 'שולם בפועל'
      cast(
        case when _Clearing.Augbl is not null
          then 'X' else ''
        end as abap.char(1) )                                   as IsPaid,
      @EndUserText.label: 'מסמך תשלום'
      _Clearing.Augbl                                           as Augbl,
      @EndUserText.label: 'תאריך תשלום'
      _Clearing.Augdt                                           as Augdt,

      // סטורנו פיננסי; חשבונית שנמחקה נראית דרך Rbstat = '2'
      @EndUserText.label: 'בוצע סטורנו'
      cast(
        case when _FiDoc.xreversed = 'X'
          then 'X' else ''
        end as abap.char(1) )                                   as IsReversed,

      // מפתח מסמך הסטורנו - AWREF_REV+AWORG_REV של המקורי; שדה עזר ל-_ReversalDoc
      @EndUserText.label: 'מפתח ייחוס מסמך סטורנו'
      concat( _FiDoc.awref_rev, _FiDoc.aworg_rev )              as ReversalAwKey,

      // סיבת ביטול - עמודות רוחביות; COALESCE מבטיח ריק ולא NULL
      @EndUserText.label: 'סיבת סטורנו'
      coalesce(
        case when _FiDoc.xreversed = 'X' then _ReversalDoc.stgrd else '' end,
        cast( '' as abap.char(2) ) )                            as Stgrd,
      @EndUserText.label: 'תיאור סיבת סטורנו'
      coalesce(
        case when _FiDoc.xreversed = 'X' then _StgrdText.txt40 else '' end,
        cast( '' as abap.char(40) ) )                           as StgrdTxt,

      // ---------------- חדש: מקור המסמכים וההזמנה ----------------
      @EndUserText.label: 'מקור החשבונית (G/P/E)'
      sd.InvoiceSource                                          as InvoiceSource,
      @EndUserText.label: 'מקור מסמך הטובין (G/E)'
      sd.GrSource                                               as GrSource,
      @EndUserText.label: 'הזמנה'
      sd.Ebeln                                                  as Ebeln,

      // חשיפה לניווט
      _Status,
      _Invoice,
      _FiDoc,
      _ReversalDoc,
      _StgrdText,
      _Clearing,
      sd._PaymentInvoice,
      sd._PoDocs
}
