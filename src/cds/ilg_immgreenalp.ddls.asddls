@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Green Path - ALP Consumption'
@Analytics.query: true
@OData.publish: true
@UI.headerInfo: { typeName: 'סט', typeNamePlural: 'סטים',
                  title: { value: 'Qmnum' } }
// תרשים ברירת המחדל של ה-ALP: עמודות של מספר סטים לפי סטטוס
@UI.chart: [ { qualifier: 'StatusChart',
               title: 'סטים לפי סטטוס',
               chartType: #COLUMN,
               dimensions: [ 'LogicalStatus' ],
               measures:   [ 'SetsCount' ] },
             // תרשימי Visual Filter לסרגל הסינון החזותי
             { qualifier: 'VFStatus',  chartType: #BAR,
               dimensions: [ 'LogicalStatusCode' ], measures: [ 'SetsCount' ] },
             { qualifier: 'VFBukrs',   chartType: #DONUT,
               dimensions: [ 'Bukrs' ],  measures: [ 'SetsCount' ] },
             { qualifier: 'VFGjahr',   chartType: #COLUMN,
               dimensions: [ 'GjahrMm' ], measures: [ 'SetsCount' ] } ]
@UI.presentationVariant: [ { qualifier: 'Default',
                             visualizations: [ { type: #AS_CHART, qualifier: 'StatusChart' },
                                               { type: #AS_LINEITEM } ] } ]
/*
 * שכבת ה-Consumption לאפליקציית ה-ALP (Analytical List Page).
 * חשיפה: Service Definition + Binding (מומלץ) או @OData.publish.
 * ראו docs/fiori/fiori_alp_setup.md להנחיות המלאות.
 */
define view entity /ILG/IMMGreenAlp
  as select from /ILG/IMMGreenCube
{
      @EndUserText.label: 'מספר סט'
      @UI.lineItem:       [ { position: 10, importance: #HIGH } ]
      @UI.selectionField: [ { position: 10 } ]
  key Qmnum,

      @EndUserText.label: 'קוד סטטוס'
      @UI.selectionField: [ { position: 20 } ]
      @UI.lineItem:       [ { position: 20 } ]
      @Consumption.filter: { selectionType: #SINGLE, multipleSelections: true }
      @ObjectModel.text.element: [ 'LogicalStatus' ]
      LogicalStatusCode,

      @EndUserText.label: 'סטטוס לוגי'
      @UI.lineItem:       [ { position: 30, importance: #HIGH } ]
      @Semantics.text: true
      LogicalStatus,

      @EndUserText.label: 'בקרה ידנית'
      @UI.lineItem:       [ { position: 40 } ]
      @UI.selectionField: [ { position: 40 } ]
      IsMonitor,

      @EndUserText.label: 'שולם בפועל'
      @UI.lineItem:       [ { position: 50 } ]
      @UI.selectionField: [ { position: 50 } ]
      IsPaid,

      @EndUserText.label: 'בוצע סטורנו'
      @UI.lineItem:       [ { position: 60 } ]
      IsReversed,

      @EndUserText.label: 'מצב חשבונית'
      @UI.lineItem:       [ { position: 70 } ]
      Rbstat,

      @EndUserText.label: 'קוד חברה'
      @UI.selectionField: [ { position: 30 } ]
      @UI.lineItem:       [ { position: 80 } ]
      Bukrs,

      @EndUserText.label: 'שנת כספים'
      @UI.selectionField: [ { position: 60 } ]
      @UI.lineItem:       [ { position: 90 } ]
      GjahrMm,

      @EndUserText.label: 'טובין ידני'
      MblnrHandledManually,

      // ---------- מדדים + KPI DataPoints ----------
      @EndUserText.label: 'מספר סטים'
      @UI.dataPoint: { title: 'סה"כ סטים' }
      @UI.lineItem:  [ { position: 100 } ]
      SetsCount,

      @EndUserText.label: 'סטים ששולמו'
      @UI.dataPoint: { title: 'שולמו בפועל' }
      PaidCount,

      @EndUserText.label: 'סטים בבקרה ידנית'
      @UI.dataPoint: { title: 'בבקרה ידנית' }
      MonitorCount,

      @EndUserText.label: 'סטים עם סטורנו'
      @UI.dataPoint: { title: 'בוצע סטורנו' }
      ReversedCount,

      @EndUserText.label: 'סטים בעיסוק ידני'
      ManualCount,

      @EndUserText.label: 'ממתינים למסמכי המשך'
      @UI.dataPoint: { title: 'ממתינים למסמכים', criticality: 'OpenDocsCount' }
      OpenDocsCount,

      @EndUserText.label: 'נדחו ובוטלו'
      CancelledCount
}
