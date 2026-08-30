@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Green Path - Analytics Cube'
@Analytics.dataCategory: #CUBE
/*
 * שכבת ה-Cube לאפליקציית ה-ALP: ממדים + מדדים (ספירות) מעל ה-View
 * הראשי /ILG/IMMGreenTrack. כל שורה = סט אחד; המדדים הם ספירות 0/1
 * שמסתכמות באגרגציה (SUM) לכל חתך.
 */
define view entity /ILG/IMMGreenCube
  as select from /ILG/IMMGreenTrack
{
      // ---------- ממדים ----------
      @EndUserText.label: 'מספר סט'
  key Qmnum,

      @EndUserText.label: 'קוד סטטוס לוגי'
      @ObjectModel.text.element: [ 'LogicalStatus' ]
      LogicalStatusCode,

      @EndUserText.label: 'סטטוס לוגי'
      @Semantics.text: true
      LogicalStatus,

      @EndUserText.label: 'בקרה ידנית'
      IsMonitor,

      @EndUserText.label: 'שולם בפועל'
      IsPaid,

      @EndUserText.label: 'בוצע סטורנו'
      IsReversed,

      @EndUserText.label: 'מצב חשבונית'
      Rbstat,

      @EndUserText.label: 'קוד חברה'
      Bukrs,

      @EndUserText.label: 'שנת כספים'
      GjahrMm,

      @EndUserText.label: 'טובין ידני'
      MblnrHandledManually,

      // ---------- מדדים (KPIs) ----------
      @EndUserText.label: 'מספר סטים'
      @DefaultAggregation: #SUM
      cast( 1 as abap.int4 )                               as SetsCount,

      @EndUserText.label: 'סטים ששולמו'
      @DefaultAggregation: #SUM
      cast( case when IsPaid = 'X'
             then 1 else 0 end as abap.int4 )              as PaidCount,

      @EndUserText.label: 'סטים בבקרה ידנית'
      @DefaultAggregation: #SUM
      cast( case when IsMonitor = 'X'
             then 1 else 0 end as abap.int4 )              as MonitorCount,

      @EndUserText.label: 'סטים עם סטורנו'
      @DefaultAggregation: #SUM
      cast( case when IsReversed = 'X'
             then 1 else 0 end as abap.int4 )              as ReversedCount,

      @EndUserText.label: 'סטים בעיסוק ידני'
      @DefaultAggregation: #SUM
      cast( case when MblnrHandledManually = 'X'
             then 1 else 0 end as abap.int4 )              as ManualCount,

      @EndUserText.label: 'ממתינים למסמכי המשך'
      @DefaultAggregation: #SUM
      cast( case when LogicalStatusCode = '07'
             then 1 else 0 end as abap.int4 )              as OpenDocsCount,

      @EndUserText.label: 'נדחו ובוטלו'
      @DefaultAggregation: #SUM
      cast( case when LogicalStatusCode = '01'
             then 1 else 0 end as abap.int4 )              as CancelledCount
}
