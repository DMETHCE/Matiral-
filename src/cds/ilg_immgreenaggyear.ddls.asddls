@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Green Path - Sets per Year'
/*
 * View מסכם: מספר סטים לכל שנת כספים (עבור כרטיס עמודות ב-OVP).
 */
define view entity /ILG/IMMGreenAggYear
  as select from /ILG/IMMGreenTrack
{
      @EndUserText.label: 'שנת כספים'
  key GjahrMm,
      @EndUserText.label: 'מספר סטים'
      count( * ) as SetsCount
}
group by
  GjahrMm
