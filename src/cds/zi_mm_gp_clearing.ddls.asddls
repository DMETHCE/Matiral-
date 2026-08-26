@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Green Path - vendor payment clearing from ACDOCA'
/*
 * בדיקת תשלום בפועל - שורת ספק (KOART = 'K') שסולקה במסמך תשלום.
 *
 * הערות:
 * 1. RBUKRS - שם שדה קוד החברה ב-ACDOCA (בתוכנית המקורית נכתב BUKRS -
 *    שגיאת קומפילציה).
 * 2. RLDNR = '0L' - ledger מוביל בלבד; מונע כפילות שורות מ-ledgers
 *    מקבילים (ממצא סוכן הביקורת). אם ה-ledger המוביל אצלכם שונה - לעדכן.
 * 3. augbl like '2%' - לפי האפיון העסקי "מספר מסמך התשלום חייב להתחיל
 *    ב-2"; סטורנו שמסלק את שורת הספק לא ייחשב תשלום (תוקן 26.08.2026).
 * 4. MAX( ) - דטרמיניסטי (בתוכנית: SELECT SINGLE שרירותי). בסילוק במספר
 *    מסמכי תשלום שונים AUGBL ו-AUGDT עלולים להגיע משורות שונות - ראו
 *    סעיף 11 באפיון.
 */
define view entity ZI_MM_GP_CLEARING
  as select from acdoca
{
  key rbukrs        as bukrs,
  key belnr,
  key gjahr,

      max( augbl )  as augbl,
      max( augdt )  as augdt
}
where
      rldnr = '0L'
  and koart = 'K'
  and augbl like '2%'
group by
  rbukrs,
  belnr,
  gjahr
