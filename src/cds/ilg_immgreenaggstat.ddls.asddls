@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Green Path - Sets per Status'
/*
 * View מסכם: מספר סטים לכל סטטוס לוגי.
 * מיועד לכרטיס גרף ב-OVP — הסיכום מבוצע כאן (GROUP BY),
 * כך שהכרטיס רק מצייר שורות מוכנות ואינו תלוי בסיכום דינמי בשרת.
 */
define view entity /ILG/IMMGreenAggStat
  as select from /ILG/IMMGreenTrack
{
      @EndUserText.label: 'קוד סטטוס'
  key LogicalStatusCode,
      @EndUserText.label: 'סטטוס לוגי'
      LogicalStatus,
      @EndUserText.label: 'מספר סטים'
      count( * ) as SetsCount
}
group by
  LogicalStatusCode,
  LogicalStatus
