@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Green Path - vendor payment clearing from ACDOCA'
/*
 * בדיקת תשלום בפועל - שורת ספק (KOART = 'K') שסולקה במסמך תשלום.
 *
 * RBUKRS          - שם שדה קוד החברה ב-ACDOCA (אין BUKRS).
 * RLDNR = '0L'    - ledger מוביל בלבד; אם שונה אצלכם - לעדכן.
 * AUGBL LIKE '2%' - לפי האפיון: מסמך תשלום מתחיל ב-2; סטורנו שמסלק
 *                   את שורת הספק אינו תשלום.
 * MAX( )          - דטרמיניסטי; בסילוק במספר מסמכים AUGBL/AUGDT עלולים
 *                   להגיע משורות שונות (ראו סעיף 11 באפיון).
 */
define view entity /ILG/I_MM_Gp_Clearing
  as select from acdoca
{
  key rbukrs        as Bukrs,
  key belnr         as Belnr,
  key gjahr         as Gjahr,

      max( augbl )  as Augbl,
      max( augdt )  as Augdt
}
where
      rldnr = '0L'
  and koart = 'K'
  and augbl like '2%'
group by
  rbukrs,
  belnr,
  gjahr
