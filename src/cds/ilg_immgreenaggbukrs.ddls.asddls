@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Green Path - Sets per Company'
/*
 * View מסכם: מספר סטים לכל קוד חברה (עבור כרטיס דונאט ב-OVP).
 */
define view entity /ILG/IMMGreenAggBukrs
  as select from /ILG/IMMGreenTrack
{
      @EndUserText.label: 'קוד חברה'
  key Bukrs,
      @EndUserText.label: 'מספר סטים'
      count( * ) as SetsCount
}
group by
  Bukrs
