@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Green Path - vendor clearing info from ACDOCA'
@Metadata.ignorePropagatedAnnotations: true
/*
 * מקביל לסעיף ג'.2 בתוכנית ZMM_PROCESS_GREEN_PATH:
 * בדיקת תשלום בפועל - שורת ספק (KOART = 'K') עם מסמך סילוק (AUGBL).
 *
 * הערות מול הקוד המקורי:
 * 1. בקוד המקורי נכתב WHERE bukrs = ... אבל ב-ACDOCA השדה הוא RBUKRS
 *    (שגיאת קומפילציה בקוד המקורי). כאן תוקן ל-RBUKRS.
 * 2. SELECT SINGLE בקוד המקורי מחזיר שורה שרירותית; כאן MAX( ) - דטרמיניסטי.
 *    כאשר קיים סילוק אחד לשורות הספק (המקרה הרגיל) התוצאה זהה.
 * 3. ה-fallback ל-BSEG אינו נדרש: בסביבת S/4HANA (שבה קיימת ACDOCA)
 *    נתוני הסילוק קיימים ב-ACDOCA. ראו מסמך האפיון.
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
      koart = 'K'
  and augbl <> ''
group by
  rbukrs,
  belnr,
  gjahr
