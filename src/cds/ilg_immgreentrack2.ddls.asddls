@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Green Path Tracking v2 - live status per notification'
/*
 * /ILG/IMMGreenTrack2
 * -------------------
 * View חי למעקב מסלול ירוק / בקרה מפצה - מחליף את /ILG/IMMGreenTrack.
 * בנוי באסוציאציות: כל מקור נגיש גם לניווט (Fiori / Views צורכים).
 * מקורות: Views משוחררים של SAP (VDM) ו-Views של ILG בלבד - אפס טבלאות.
 *
 * שרשרת הנתונים:
 *   /ILG/IMMGpSetDocs  (הסט + מסמכי ההמשך מוכרעים: GreenPathSet / NotifPaymentInvoice / PO history)
 *   -> _Status      /ILG/IMMGpQmmaStatus       קודי 50/60/70/80 (קבוצה 'ZPU')
 *   -> _Invoice     I_SupplierInvoiceAPI01     מצב החשבונית (5=נרשמה, 2=נמחקה), קוד חברה
 *   -> _FiDoc       I_JournalEntry             OriginalReferenceDocument = BELNR+GJAHR,
 *                                              ReferenceDocumentType = 'RMRP', מוצמד ל-CompanyCode
 *                                              (תנאי ה-join הרשמי מתיעוד I_SupplierInvoiceAPI01)
 *   -> _ReversalDoc I_JournalEntry             OriginalReferenceDocument = ReversalReferenceDocument
 *                                              + ReversalReferenceDocumentCntxt של המסמך המקורי
 *                                              (AWREF_REV / AWORG_REV, שניהם CHAR10 - אומת ב-api.sap.com;
 *                                              STBLG/STJAH ריקים בסטורנו MR8M)
 *   -> _StgrdText   I_ReversalReasonText       טקסט סיבת הסטורנו בשפת המשתמש
 *                                              (Basic / Released: Language, ReversalReason, ReversalReasonName)
 *   -> _Clearing    /ILG/IMMGpClearing         תשלום בפועל (I_JournalEntryItem, סילוק '2%')
 *
 * כל תנאי ON משתמש בשדות $projection רגילים או שהוגדרו בשכבה קודמת
 * של השרשרת (ללא מעגליות). הענף הראשון שמתקיים בעץ ההחלטות קובע.
 * דרישה: S/4HANA 2020 FPS01 ומעלה (I_QltyNotificationActivity).
 */
define view entity /ILG/IMMGreenTrack2
  as select from /ILG/IMMGpSetDocs as sd

  // קודי הסטטוס של הסט (קבוצת ZPU, ללא פעילויות שנמחקו)
  association [0..1] to /ILG/IMMGpQmmaStatus as _Status
    on $projection.Qmnum = _Status.Qmnum

  // מצב החשבונית הלוגיסטית (מפתח SupplierInvoice + FiscalYear)
  association [0..1] to I_SupplierInvoiceAPI01 as _Invoice
    on  $projection.BelnrMm = _Invoice.SupplierInvoice
    and $projection.GjahrMm = _Invoice.FiscalYear

  // המסמך הפיננסי; הצמדת CompanyCode מונעת כפילות ברישום חוצה-חברות
  association [0..1] to I_JournalEntry as _FiDoc
    on  $projection.AwKey        = _FiDoc.OriginalReferenceDocument
    and _FiDoc.ReferenceDocumentType = 'RMRP'
    and $projection.Bukrs        = _FiDoc.CompanyCode

  // מסמך הסטורנו - המצביע אליו יושב על המסמך המקורי
  association [0..1] to I_JournalEntry as _ReversalDoc
    on  $projection.ReversalAwKey = _ReversalDoc.OriginalReferenceDocument
    and _ReversalDoc.ReferenceDocumentType = 'RMRP'
    and $projection.Bukrs         = _ReversalDoc.CompanyCode

  // טקסט סיבת סטורנו בשפת המשתמש
  association [0..1] to I_ReversalReasonText as _StgrdText
    on  $projection.Stgrd  = _StgrdText.ReversalReason
    and _StgrdText.Language = $session.system_language

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
      // בוטלה = IsReversed='X' או SupplierInvoiceStatus='2'
      // הושלמו מסמכי המשך = Mblnr + BelnrMm מלאים וגם SupplierInvoiceStatus='5'
      // עיסוק ידני = קוד 70/80, או MmGrDocInd 2/4, או מסמך שלא
      //              נרשם במסלול הירוק (InvoiceSource 'P' / GrSource 'E')
      // ---------------------------------------------------------------
      @EndUserText.label: 'קוד סטטוס לוגי'
      cast(
        case
          when _Status.Has50 = 'X' and _Status.Has60 = 'X' then
            case
              when _FiDoc.IsReversed = 'X' or _Invoice.SupplierInvoiceStatus = '2'
                or _Clearing.Augbl is null                 then '01' // נדחה לאחר אישור ובוטל
              else                                              '02' // נדחה לאחר אישור ושולם
            end
          when _Status.Has60 = 'X' then
            case
              when _FiDoc.IsReversed = 'X' or _Invoice.SupplierInvoiceStatus = '2' then '03' // נדחה לאחר אישור דורש
              when sd.Mblnr <> '' and sd.BelnrMm <> ''
                and _Invoice.SupplierInvoiceStatus = '5' then
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
              when _FiDoc.IsReversed = 'X' or _Invoice.SupplierInvoiceStatus = '2'
                or _Clearing.Augbl is null
                then 'נדחה לאחר אישור ובוטל'
              else 'נדחה לאחר אישור ושולם'
            end
          when _Status.Has60 = 'X' then
            case
              when _FiDoc.IsReversed = 'X' or _Invoice.SupplierInvoiceStatus = '2'
                then 'נדחה לאחר אישור דורש'
              when sd.Mblnr <> '' and sd.BelnrMm <> ''
                and _Invoice.SupplierInvoiceStatus = '5' then
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

      // מפתח המסמך הפיננסי - BELNR+GJAHR (OriginalReferenceDocument); שדה עזר לאסוציאציה _FiDoc
      @EndUserText.label: 'מפתח ייחוס (AWKEY)'
      concat( sd.BelnrMm, cast( sd.GjahrMm as abap.char(4) ) ) as AwKey,

      // מצב החשבונית הלוגיסטית (5=נרשמה, 2=נמחקה, ריק=אין חשבונית)
      @EndUserText.label: 'מצב חשבונית'
      _Invoice.SupplierInvoiceStatus                            as Rbstat,

      // פרטי המסמך הפיננסי (ריק/NULL כשלא נמצא)
      @EndUserText.label: 'קוד חברה'
      _Invoice.CompanyCode                                      as Bukrs,
      @EndUserText.label: 'מסמך פיננסי'
      _FiDoc.AccountingDocument                                 as BelnrFi,
      @EndUserText.label: 'שנת כספים - פיננסי'
      _FiDoc.FiscalYear                                         as GjahrFi,

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
        case when _FiDoc.IsReversed = 'X'
          then 'X' else ''
        end as abap.char(1) )                                   as IsReversed,

      // מפתח מסמך הסטורנו - ReversalReferenceDocument+Cntxt של המקורי; שדה עזר ל-_ReversalDoc
      @EndUserText.label: 'מפתח ייחוס מסמך סטורנו'
      concat( _FiDoc.ReversalReferenceDocument,
              _FiDoc.ReversalReferenceDocumentCntxt )            as ReversalAwKey,

      // סיבת ביטול - עמודות רוחביות; COALESCE מבטיח ריק ולא NULL
      @EndUserText.label: 'סיבת סטורנו'
      coalesce(
        case when _FiDoc.IsReversed = 'X' then _ReversalDoc.ReversalReason else '' end,
        cast( '' as abap.char(2) ) )                            as Stgrd,
      @EndUserText.label: 'תיאור סיבת סטורנו'
      coalesce(
        case when _FiDoc.IsReversed = 'X' then _StgrdText.ReversalReasonName else '' end,
        cast( '' as abap.char(40) ) )                           as StgrdTxt,

      // ---------------- מקור המסמכים וההזמנה ----------------
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
