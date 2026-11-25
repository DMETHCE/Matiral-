@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Green Path - set with resolved follow-on documents'
/*
 * /ILG/IMMGpSetDocs  -  שכבת הבסיס של /ILG/IMMGreenTrack2
 * ---------------------------------------------------------
 * שורה אחת לכל סט ב-/ILG/MM_GRPO_DET, עם מסמכי ההמשך מוכרעים
 * משלושה מקורות לפי סדר עדיפות קבוע (הראשון שמלא קובע):
 *
 *   חשבונית:  GRPO_DET.BELNR -> PM_NOTIF_BP.BELNR (INV='X') -> EKBE (VGABE=2)
 *   טובין:    GRPO_DET.MBLNR -> EKBE (VGABE=1)
 *
 * InvoiceSource / GrSource - מאיפה הגיע כל מסמך:
 *   'G' GRPO_DET (המסלול הירוק)   'P' PM_NOTIF_BP (חשבונית לתשלום)
 *   'E' EKBE (היסטוריית ההזמנה)    ''  לא נמצא
 *
 * ההכרעה מתבצעת כאן פעם אחת, כדי ש-/ILG/IMMGreenTrack2 יקשר
 * RBKP / BKPF / ACDOCA לפי שדות רגילים - ולא יחזור על ה-CASE.
 * NULL (אין שורה במקור) נופל אוטומטית לענף הבא.
 */
define view entity /ILG/IMMGpSetDocs
  as select from /ilg/mm_grpo_det as grpo

  // חשבונית לתשלום שנרשמה על ההודעה (מפתח QMNUM בלבד - לכל היותר שורה אחת)
  association [0..1] to /ilg/pm_notif_bp as _PaymentInvoice
    on  $projection.Qmnum    = _PaymentInvoice.qmnum
    and _PaymentInvoice.inv  = 'X'

  // מסמכי ההמשך מהיסטוריית ההזמנה (View מסכם - שורה אחת לסט)
  association [0..1] to /ILG/IMMGpPoDocs as _PoDocs
    on $projection.Qmnum = _PoDocs.Qmnum

{
      @EndUserText.label: 'מספר סט (הודעה)'
  key grpo.qmnum                                              as Qmnum,

      grpo.monitor_indicator                                  as MonitorIndicator,
      grpo.extra_vlue_ind                                     as ExtraValueInd,
      grpo.mm_gr_doc_ind                                      as MmGrDocInd,

      // ---------------- חשבונית לוגיסטית ----------------
      @EndUserText.label: 'חשבונית לוגיסטית'
      case
        when grpo.belnr             <> '' then grpo.belnr
        when _PaymentInvoice.belnr  <> '' then _PaymentInvoice.belnr
        when _PoDocs.IrBelnr        <> '' then _PoDocs.IrBelnr
        else ''
      end                                                     as BelnrMm,

      @EndUserText.label: 'שנת כספים - חשבונית'
      case
        when grpo.belnr             <> '' then grpo.gjahr
        when _PaymentInvoice.belnr  <> '' then _PaymentInvoice.gjahr
        when _PoDocs.IrBelnr        <> '' then _PoDocs.IrGjahr
        else '0000'
      end                                                     as GjahrMm,

      @EndUserText.label: 'מקור החשבונית'
      cast(
        case
          when grpo.belnr             <> '' then 'G'
          when _PaymentInvoice.belnr  <> '' then 'P'
          when _PoDocs.IrBelnr        <> '' then 'E'
          else ''
        end as abap.char(1) )                                 as InvoiceSource,

      // ---------------- קבלת טובין ----------------
      @EndUserText.label: 'מסמך קבלת טובין'
      case
        when grpo.mblnr      <> '' then grpo.mblnr
        when _PoDocs.GrBelnr <> '' then _PoDocs.GrBelnr
        else ''
      end                                                     as Mblnr,

      @EndUserText.label: 'מקור מסמך הטובין'
      cast(
        case
          when grpo.mblnr      <> '' then 'G'
          when _PoDocs.GrBelnr <> '' then 'E'
          else ''
        end as abap.char(1) )                                 as GrSource,

      @EndUserText.label: 'הזמנה'
      coalesce( _PoDocs.Ebeln, cast( '' as abap.char(10) ) )  as Ebeln,

      // חשיפה לניווט
      _PaymentInvoice,
      _PoDocs
}
