@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Green Path Tracking v2 - live status per notification'
/*
 * /ILG/IMMGreenTrack2
 * -------------------
 * View חי למעקב מסלול ירוק / בקרה מפצה - יורש של /ILG/IMMGreenTrack
 * (שנשאר כרפרנס). בנוי באסוציאציות על Views משוחררים (VDM) ועל
 * טבלאות ILG בלבד - אפס טבלאות סטנדרט.
 *
 * מה השתנה מול הגרסה הראשונה:
 *   - מסמכי ההמשך מאותרים בעצמנו, ולא רק ממה שנרשם ב-GRPO_DET:
 *       חשבונית:  GRPO_DET.BELNR -> PM_NOTIF_BP.BELNR (INV='X') -> היסטוריית ההזמנה
 *       טובין:    GRPO_DET.MBLNR -> היסטוריית ההזמנה
 *     InvoiceSource / GrSource: 'G' GRPO_DET · 'P' PM_NOTIF_BP · 'E' היסטוריית הזמנה
 *   - מסמך הסטורנו נקרא דרך ReversalReferenceDocument + ...Cntxt
 *     (AWREF_REV + AWORG_REV) של המסמך המקורי - אומת מול BKPF 07.09.2026.
 *   - מסמך שנמצא מחוץ למסלול הירוק נחשב "עיסוק ידני" (סטטוס 04).
 *
 * שרשרת האסוציאציות (כל תנאי ON על שדה $projection מהשכבה שלפניו):
 *   _Facts          /ILG/IMMGpSetFacts        קודי 50/60/70/80 + מסמכי ההזמנה
 *   _PaymentInvoice /ILG/PM_NOTIF_BP          חשבונית לתשלום (מפתח QMNUM - שורה אחת)
 *   _Invoice        I_SupplierInvoiceAPI01    מצב חשבונית, קוד חברה
 *   _FiDoc          I_JournalEntry            OriginalReferenceDocument = BELNR+GJAHR, 'RMRP'
 *   _ReversalDoc    I_JournalEntry            מסמך הסטורנו
 *   _StgrdText      I_ReversalReasonText      טקסט סיבת סטורנו
 *   _Clearing       /ILG/IMMGpClearing2       תשלום בפועל
 * שמות השדות של ה-VDM אומתו מול api.sap.com (25.11.2026).
 */
define view entity /ILG/IMMGreenTrack2
  as select from /ilg/mm_grpo_det as grpo

  association [0..1] to /ILG/IMMGpSetFacts as _Facts
    on $projection.Qmnum = _Facts.Qmnum

  association [0..1] to /ilg/pm_notif_bp as _PaymentInvoice
    on  $projection.Qmnum   = _PaymentInvoice.qmnum
    and _PaymentInvoice.inv = 'X'

  association [0..1] to I_SupplierInvoiceAPI01 as _Invoice
    on  $projection.BelnrMm = _Invoice.SupplierInvoice
    and $projection.GjahrMm = _Invoice.FiscalYear

  association [0..1] to I_JournalEntry as _FiDoc
    on  $projection.AwKey            = _FiDoc.OriginalReferenceDocument
    and _FiDoc.ReferenceDocumentType = 'RMRP'
    and $projection.Bukrs            = _FiDoc.CompanyCode

  association [0..1] to I_JournalEntry as _ReversalDoc
    on  $projection.ReversalAwKey          = _ReversalDoc.OriginalReferenceDocument
    and _ReversalDoc.ReferenceDocumentType = 'RMRP'
    and $projection.Bukrs                  = _ReversalDoc.CompanyCode

  association [0..1] to I_ReversalReasonText as _StgrdText
    on  $projection.Stgrd   = _StgrdText.ReversalReason
    and _StgrdText.Language = $session.system_language

  association [0..1] to /ILG/IMMGpClearing2 as _Clearing
    on  $projection.Bukrs   = _Clearing.Bukrs
    and $projection.BelnrFi = _Clearing.Belnr
    and $projection.GjahrFi = _Clearing.Gjahr

{
      @EndUserText.label: 'מספר סט (הודעה)'
  key grpo.qmnum                                              as Qmnum,

      // ---------------------------------------------------------------
      // עץ ההחלטות לפי האפיון העסקי - קוד סטטוס. הענף הראשון שמתקיים קובע.
      // בוטלה            = IsReversed='X' או SupplierInvoiceStatus='2'
      // יש חשבונית       = GRPO_DET או PM_NOTIF_BP או היסטוריית הזמנה
      // יש טובין         = GRPO_DET או היסטוריית הזמנה
      // הושלמו מסמכי המשך = יש טובין וגם יש חשבונית וגם SupplierInvoiceStatus='5'
      // עיסוק ידני       = קוד 70/80, או MM_GR_DOC_IND 2/4, או מסמך שלא
      //                    נרשם ב-GRPO_DET (חשבונית מ-BP / טובין מההזמנה)
      // ---------------------------------------------------------------
      @EndUserText.label: 'קוד סטטוס לוגי'
      cast(
        case
          when _Facts.Has50 = 'X' and _Facts.Has60 = 'X' then
            case
              when _FiDoc.IsReversed = 'X' or _Invoice.SupplierInvoiceStatus = '2'
                or _Clearing.Augbl is null                        then '01' // נדחה לאחר אישור ובוטל
              else                                                     '02' // נדחה לאחר אישור ושולם
            end
          when _Facts.Has60 = 'X' then
            case
              when _FiDoc.IsReversed = 'X' or _Invoice.SupplierInvoiceStatus = '2'
                                                                    then '03' // נדחה לאחר אישור דורש
              when ( grpo.mblnr <> '' or _Facts.GrBelnr <> '' )
               and ( grpo.belnr <> '' or _PaymentInvoice.belnr <> '' or _Facts.IrBelnr <> '' )
               and _Invoice.SupplierInvoiceStatus = '5' then
                case
                  when _Facts.Has70 = 'X' or _Facts.Has80 = 'X'
                    or grpo.mm_gr_doc_ind = '2' or grpo.mm_gr_doc_ind = '4'
                    or grpo.belnr = ''                              // חשבונית שלא נרשמה במסלול
                    or grpo.mblnr = ''                              // טובין שלא נרשם במסלול
                                                                    then '04' // אושר והושלם לאחר עיסוק ידני
                  else                                                   '05' // אושר והושלם ללא תקלה
                end
              else                                                       '07' // אושר - טרם הושלמו מסמכי המשך
            end
          when _Facts.Has50 = 'X'                                   then '06' // נדחה על ידי דורש
          else                                                           '99' // בתהליך
        end as abap.char(2) )                                       as LogicalStatusCode,

      // ---------------------------------------------------------------
      // עץ ההחלטות - טקסט (ניסוחי האפיון העסקי)
      // ---------------------------------------------------------------
      @EndUserText.label: 'סטטוס לוגי'
      cast(
        case
          when _Facts.Has50 = 'X' and _Facts.Has60 = 'X' then
            case
              when _FiDoc.IsReversed = 'X' or _Invoice.SupplierInvoiceStatus = '2'
                or _Clearing.Augbl is null
                then 'נדחה לאחר אישור ובוטל'
              else 'נדחה לאחר אישור ושולם'
            end
          when _Facts.Has60 = 'X' then
            case
              when _FiDoc.IsReversed = 'X' or _Invoice.SupplierInvoiceStatus = '2'
                then 'נדחה לאחר אישור דורש'
              when ( grpo.mblnr <> '' or _Facts.GrBelnr <> '' )
               and ( grpo.belnr <> '' or _PaymentInvoice.belnr <> '' or _Facts.IrBelnr <> '' )
               and _Invoice.SupplierInvoiceStatus = '5' then
                case
                  when _Facts.Has70 = 'X' or _Facts.Has80 = 'X'
                    or grpo.mm_gr_doc_ind = '2' or grpo.mm_gr_doc_ind = '4'
                    or grpo.belnr = ''
                    or grpo.mblnr = ''
                    then 'אושר והושלם לאחר עיסוק ידני'
                  else 'אושר והושלם ללא תקלה'
                end
              else 'אושר - טרם הושלמו מסמכי המשך'
            end
          when _Facts.Has50 = 'X'
            then 'נדחה על ידי דורש'
          else 'בתהליך'
        end as abap.char(40) )                                      as LogicalStatus,

      // אינדיקטור בקרה ידנית (MONITOR_INDICATOR או חשבונית מעל 10 אלש"ח)
      @EndUserText.label: 'בקרה ידנית'
      cast(
        case
          when grpo.monitor_indicator <> '' or grpo.extra_vlue_ind <> ''
            then 'X' else ''
        end as abap.char(1) )                                       as IsMonitor,

      // ---------------- קבלת טובין: GRPO_DET, אחרת היסטוריית ההזמנה ----------------
      @EndUserText.label: 'מסמך קבלת טובין'
      case
        when grpo.mblnr     <> '' then grpo.mblnr
        when _Facts.GrBelnr <> '' then _Facts.GrBelnr
        else ''
      end                                                           as Mblnr,

      @EndUserText.label: 'טובין נוצר ידנית'
      cast(
        case
          when grpo.mm_gr_doc_ind = '2' or grpo.mm_gr_doc_ind = '4'
            or ( grpo.mblnr = '' and _Facts.GrBelnr <> '' )
            then 'X' else ''
        end as abap.char(1) )                                       as MblnrHandledManually,

      // ---------------- חשבונית: GRPO_DET, אחרת PM_NOTIF_BP, אחרת היסטוריית ההזמנה ----------------
      @EndUserText.label: 'חשבונית לוגיסטית'
      case
        when grpo.belnr            <> '' then grpo.belnr
        when _PaymentInvoice.belnr <> '' then _PaymentInvoice.belnr
        when _Facts.IrBelnr        <> '' then _Facts.IrBelnr
        else ''
      end                                                           as BelnrMm,

      @EndUserText.label: 'שנת כספים - חשבונית'
      case
        when grpo.belnr            <> '' then grpo.gjahr
        when _PaymentInvoice.belnr <> '' then _PaymentInvoice.gjahr
        when _Facts.IrBelnr        <> '' then _Facts.IrGjahr
        else '0000'
      end                                                           as GjahrMm,

      // מפתח המסמך הפיננסי (AWKEY = BELNR+GJAHR) - שדה עזר ל-_FiDoc
      @EndUserText.label: 'מפתח ייחוס (AWKEY)'
      concat(
        case
          when grpo.belnr            <> '' then grpo.belnr
          when _PaymentInvoice.belnr <> '' then _PaymentInvoice.belnr
          when _Facts.IrBelnr        <> '' then _Facts.IrBelnr
          else ''
        end,
        cast(
          case
            when grpo.belnr            <> '' then grpo.gjahr
            when _PaymentInvoice.belnr <> '' then _PaymentInvoice.gjahr
            when _Facts.IrBelnr        <> '' then _Facts.IrGjahr
            else '0000'
          end as abap.char(4) ) )                                   as AwKey,

      // מצב החשבונית הלוגיסטית (5=נרשמה, 2=נמחקה, ריק=אין חשבונית)
      @EndUserText.label: 'מצב חשבונית'
      _Invoice.SupplierInvoiceStatus                                as Rbstat,

      // פרטי המסמך הפיננסי (ריק/NULL כשלא נמצא)
      @EndUserText.label: 'קוד חברה'
      _Invoice.CompanyCode                                          as Bukrs,
      @EndUserText.label: 'מסמך פיננסי'
      _FiDoc.AccountingDocument                                     as BelnrFi,
      @EndUserText.label: 'שנת כספים - פיננסי'
      _FiDoc.FiscalYear                                             as GjahrFi,

      // תשלום בפועל - אינדיקטור בוליאני רוחבי (החלטת דיון 4/8)
      @EndUserText.label: 'שולם בפועל'
      cast(
        case when _Clearing.Augbl is not null
          then 'X' else ''
        end as abap.char(1) )                                       as IsPaid,
      @EndUserText.label: 'מסמך תשלום'
      _Clearing.Augbl                                               as Augbl,
      @EndUserText.label: 'תאריך תשלום'
      _Clearing.Augdt                                               as Augdt,

      // סטורנו פיננסי; חשבונית שנמחקה נראית דרך Rbstat = '2'
      @EndUserText.label: 'בוצע סטורנו'
      cast(
        case when _FiDoc.IsReversed = 'X'
          then 'X' else ''
        end as abap.char(1) )                                       as IsReversed,

      // מפתח מסמך הסטורנו (AWREF_REV + AWORG_REV של המקורי) - שדה עזר ל-_ReversalDoc
      @EndUserText.label: 'מפתח ייחוס מסמך סטורנו'
      concat( _FiDoc.ReversalReferenceDocument,
              _FiDoc.ReversalReferenceDocumentCntxt )               as ReversalAwKey,

      // סיבת ביטול - עמודות רוחביות; COALESCE מבטיח ריק ולא NULL
      @EndUserText.label: 'סיבת סטורנו'
      coalesce(
        case when _FiDoc.IsReversed = 'X' then _ReversalDoc.ReversalReason else '' end,
        cast( '' as abap.char(2) ) )                                as Stgrd,
      @EndUserText.label: 'תיאור סיבת סטורנו'
      coalesce(
        case when _FiDoc.IsReversed = 'X' then _StgrdText.ReversalReasonName else '' end,
        cast( '' as abap.char(40) ) )                               as StgrdTxt,

      // ---------------- חדש: מקור המסמכים וההזמנה ----------------
      @EndUserText.label: 'מקור החשבונית (G/P/E)'
      cast(
        case
          when grpo.belnr            <> '' then 'G'
          when _PaymentInvoice.belnr <> '' then 'P'
          when _Facts.IrBelnr        <> '' then 'E'
          else ''
        end as abap.char(1) )                                       as InvoiceSource,
      @EndUserText.label: 'מקור מסמך הטובין (G/E)'
      cast(
        case
          when grpo.mblnr     <> '' then 'G'
          when _Facts.GrBelnr <> '' then 'E'
          else ''
        end as abap.char(1) )                                       as GrSource,
      @EndUserText.label: 'הזמנה'
      coalesce( _Facts.Ebeln, cast( '' as abap.char(10) ) )         as Ebeln,

      // חשיפה לניווט
      _Facts,
      _PaymentInvoice,
      _Invoice,
      _FiDoc,
      _ReversalDoc,
      _StgrdText,
      _Clearing
}
