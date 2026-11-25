@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Green Path - set with resolved follow-on documents'
/*
 * /ILG/IMMGpSetDocs  -  שכבת הבסיס של /ILG/IMMGreenTrack2
 * ---------------------------------------------------------
 * שורה אחת לכל סט ב-/ILG/I_GreenPathSet, עם מסמכי ההמשך מוכרעים
 * משלושה מקורות לפי סדר עדיפות קבוע (הראשון שמלא קובע):
 *
 *   חשבונית:  GreenPathSet.Belnr -> NotifPaymentInvoice.Belnr (Inv='X') -> PO history (type 2)
 *   טובין:    GreenPathSet.Mblnr -> PO history (type 1)
 *
 * InvoiceSource / GrSource - מאיפה הגיע כל מסמך:
 *   'G' המסלול הירוק (GRPO_DET)   'P' חשבונית לתשלום (PM_NOTIF_BP)
 *   'E' היסטוריית ההזמנה (EKBE)    ''  לא נמצא
 *
 * ההכרעה מתבצעת כאן פעם אחת, כדי ש-/ILG/IMMGreenTrack2 יקשר
 * I_SupplierInvoiceAPI01 / I_JournalEntry / I_JournalEntryItem לפי
 * שדות רגילים - ולא יחזור על ה-CASE. NULL (אין שורה במקור) נופל
 * אוטומטית לענף הבא. כל המקורות הם Views של ILG - אפס טבלאות ישירות.
 */
define view entity /ILG/IMMGpSetDocs
  as select from /ILG/I_GreenPathSet as grpo

  // חשבונית לתשלום שנרשמה על ההודעה (מפתח QMNUM בלבד - לכל היותר שורה אחת)
  association [0..1] to /ILG/I_NotifPaymentInvoice as _PaymentInvoice
    on  $projection.Qmnum    = _PaymentInvoice.Qmnum
    and _PaymentInvoice.Inv  = 'X'

  // מסמכי ההמשך מהיסטוריית ההזמנה (View מסכם - שורה אחת לסט)
  association [0..1] to /ILG/IMMGpPoDocs as _PoDocs
    on $projection.Qmnum = _PoDocs.Qmnum

{
      @EndUserText.label: 'מספר סט (הודעה)'
  key grpo.Qmnum                                              as Qmnum,

      grpo.MonitorIndicator                                   as MonitorIndicator,
      grpo.ExtraValueInd                                      as ExtraValueInd,
      grpo.MmGrDocInd                                         as MmGrDocInd,

      // ---------------- חשבונית לוגיסטית ----------------
      @EndUserText.label: 'חשבונית לוגיסטית'
      case
        when grpo.Belnr             <> '' then grpo.Belnr
        when _PaymentInvoice.Belnr  <> '' then _PaymentInvoice.Belnr
        when _PoDocs.IrBelnr        <> '' then _PoDocs.IrBelnr
        else ''
      end                                                     as BelnrMm,

      @EndUserText.label: 'שנת כספים - חשבונית'
      case
        when grpo.Belnr             <> '' then grpo.Gjahr
        when _PaymentInvoice.Belnr  <> '' then _PaymentInvoice.Gjahr
        when _PoDocs.IrBelnr        <> '' then _PoDocs.IrGjahr
        else '0000'
      end                                                     as GjahrMm,

      @EndUserText.label: 'מקור החשבונית'
      cast(
        case
          when grpo.Belnr             <> '' then 'G'
          when _PaymentInvoice.Belnr  <> '' then 'P'
          when _PoDocs.IrBelnr        <> '' then 'E'
          else ''
        end as abap.char(1) )                                 as InvoiceSource,

      // ---------------- קבלת טובין ----------------
      @EndUserText.label: 'מסמך קבלת טובין'
      case
        when grpo.Mblnr      <> '' then grpo.Mblnr
        when _PoDocs.GrBelnr <> '' then _PoDocs.GrBelnr
        else ''
      end                                                     as Mblnr,

      @EndUserText.label: 'מקור מסמך הטובין'
      cast(
        case
          when grpo.Mblnr      <> '' then 'G'
          when _PoDocs.GrBelnr <> '' then 'E'
          else ''
        end as abap.char(1) )                                 as GrSource,

      @EndUserText.label: 'הזמנה'
      coalesce( _PoDocs.Ebeln, cast( '' as abap.char(10) ) )  as Ebeln,

      // חשיפה לניווט
      _PaymentInvoice,
      _PoDocs
}
