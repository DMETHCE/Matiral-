# מבני טבלאות — ייחוס גלובלי לפרויקט מסלול ירוק

רישום מרכזי של מבני הטבלאות כפי שאומתו מול צילומי SE11 מהמערכת של הלקוח.
כל שינוי ב-CDS חייב להיבדק מול המסמך הזה.

**מקרא:** ✅ אומת מצילום SE11 | ⏳ ממתין לצילום (מבוסס הגדרות סטנדרט)

---

## ✅ /ILG/MM_GRPO_DET — טבלת המסלול הירוק (צולם 26.08.2026, 2 מסכים)

31 שדות. תיאור: "נתוני מסמכים שעברו במסלול הירוק בפורטל הספקים".

| שדה | אלמנט נתונים | סוג | אורך | מפתח | הערה |
|------|---------------|-----|------|------|------|
| MANDT | MANDT | CLNT | 3 | ✔ | |
| QMNUM | QMNUM | CHAR | 12 | ✔ | מספר הסט — **שורה אחת לסט** |
| DATUM | DATUM | DATS | 8 | | |
| UZEIT | UZEIT | TIMS | 6 | | |
| REQUISITIONER | /ILG/REQUISITION.. | CHAR | 12 | | דורש |
| XBLNR1 | XBLNR1 | CHAR | 16 | | מסמך סימוכין |
| BLDAT | INVDT | DATS | 8 | | תאריך חשבונית |
| WRBTR | WRBTR | CURR | 23.2 | | סכום |
| WAERS | WAERS | CUKY | 5 | | |
| REFERENCE | /ILG/REFERENCE | CHAR | 10 | | |
| MBLNR | MBLNR | CHAR | 10 | | מסמך טובין |
| MJAHR | MJAHR | NUMC | 4 | | שנת מסמך טובין |
| MM_GR_DOC_IND | /ILG/MM_GR_DOC_I.. | CHAR | 1 | | טובין ידני: 2=מסמך אחד, 4=כמה. **לא MN_!** |
| MM_GR_MT / MM_GR_MC / MM_GR_MN / MM_GR_TXT | /ILG/.. | CHAR/NUMC | 1/20/3/220 | | הודעת קבלת טובין |
| MM_GR_AUT | /ILG/MM_GR_AUT | CHAR | 1 | | אינדיקטור יצירה אוטומטית |
| BELNR | RE_BELNR | CHAR | 10 | | חשבונית לוגיסטית |
| GJAHR | GJAHR | NUMC | 4 | | שנת כספים |
| MM_IR_MT / MM_IR_MC / MM_IR_MN / MM_IR_TXT | /ILG/.. | CHAR/NUMC | 1/20/3/220 | | הודעת חשבונית |
| BUKRS | BUKRS | CHAR | 4 | | קוד חברה |
| COMPANY_NUMERTAO | /ILG/MM_BUK_NUM.. | NUMC | 15 | | נומרטור לקוד חברה |
| MONITOR_INDICATOR | /ILG/MM_MO_IND | CHAR | 1 | | בקרה ידנית (סט 10) |
| COMPANY_CS_NUMER | /ILG/MM_CS_BUK_N.. | NUMC | 15 | | |
| MONITOR_CS_INDIC | /ILG/MM_CS_MO_IN.. | CHAR | 1 | | |
| ZLSPR | DZLSPR | CHAR | 1 | | מפתח חסימת תשלום |
| EXTRA_VLUE_IND | CHAR1 | CHAR | 1 | | חשבונית מעל 10 אלש"ח (כולל מע"מ) |

## ✅ QMMA — פעילויות הודעת איכות (צולם היום, 2 מסכים)

תיאור: "הודעת איכות — פעילויות". שדות רלוונטיים ל-CDS:

| שדה | אלמנט נתונים | סוג | אורך | מפתח | שימוש ב-CDS |
|------|---------------|-----|------|------|--------------|
| MANDT | MANDT | CLNT | 3 | ✔ | |
| QMNUM | QMNUM | CHAR | 12 | ✔ | קישור לסט |
| MANUM | AKNUM | NUMC | 4 | ✔ | מונה פעילות — **כמה פעילויות להודעה** ⇒ האגרגציה נדרשת |
| MNKAT | MFKAT | CHAR | 1 | | סוג קטלוג (חיזוק אופציונלי לסינון) |
| MNGRP | MFGRP | CHAR | 8 | | ✔ סינון `= 'ZPU'` |
| MNCOD | MFCOD | CHAR | 4 | | ✔ קודי 50/60/70/80 |
| ERDAT / ERZEIT | ERDAT/ERZEIT | DATS/TIMS | 8/6 | | קיימים (נשלפו בתוכנית, לא בשימוש) |
| KZLOESCH | KZLOESCH | CHAR | 1 | | ✔ סינון `= ''` (פעילות שנמחקה) |

שדות נוספים שנצפו: FENUM, URNUM, MNVER, MATXT, ERNAM, AENAM, AEDAT, MAKLS,
KLAKZ, PSTER/PETER, INDTX, KZMLA, MNGFA, PSTUR/PETUR, AEZEIT, QMANUM,
AUTKZ, KZACTIONBOX, FUNKTION, CHANGEDDATETIME, QMMA_INCL_EEW_PS (include).

## ✅ RBKP — כותרת מסמך קבלת חשבונית (צולם היום, 3 מסכים; 228 שדות)

שדות רלוונטיים ל-CDS:

| שדה | אלמנט נתונים | סוג | אורך | מפתח | שימוש ב-CDS |
|------|---------------|-----|------|------|--------------|
| MANDT | MANDT | CLNT | 3 | ✔ | |
| BELNR | RE_BELNR | CHAR | 10 | ✔ | ✔ קישור מ-grpo.belnr |
| GJAHR | GJAHR | NUMC | 4 | ✔ | ✔ קישור מ-grpo.gjahr |
| BUKRS | BUKRS | CHAR | 4 | | ✔ הצמדת BKPF (`fi.bukrs = inv.bukrs`) |
| RBSTAT | RBSTAT | CHAR | 1 | | ✔ מצב חשבונית: 5=נרשמה, 2=נמחקה |
| STBLG | RE_STBLG | CHAR | 10 | | מסמך סטורנו **לוגיסטי** — לא בשימוש כרגע, שמור לעתיד |
| STJAH | RE_STJAH | NUMC | 4 | | שנת סטורנו לוגיסטי |
| XRECH | XRECH | CHAR | 1 | | סימן: רישום חשבונית |
| ZLSPR / ZLSCH | DZLSPR/DZLSCH | CHAR | 1 | | חסימת/שיטת תשלום |

ערכי RBSTAT (מהאפיון העסקי): 1=לאישור רקע, 2=נמחק, 3=עם שגיאות,
4=נכון (לא מושלם), 5=נרשם, A=בהמתנה, B=ממתין ומושלם, C=ממתין ומוחזק,
D=מוזן ומוחזק, E=ממתין ומשוחרר.

## ✅ VIQMMA (צולם 26.08.2026)

View תצוגה מעל QMMA; אישר `MNGRP = 'ZPU'` כקבוצת הקודים של המסלול הירוק.

## ⏳ BKPF — כותרת מסמך פיננסי (ממתין לצילום)

שדות שה-CDS משתמש בהם (לפי הגדרות סטנדרט): BUKRS, BELNR, GJAHR (מפתח),
AWKEY, AWTYP, **STBLG, STJAH** (מסמך הסטורנו — קריטי לאימות), STGRD.

## ⏳ T041CT — טקסטים לסיבות סטורנו (ממתין לצילום)

שדות: SPRAS, STGRD (מפתח), **TXT40** (לאימות — בתוכנית הישנה נכתב TXT20
שאינו קיים).

## ⏳ ACDOCA — היומן האוניברסלי (ממתין לצילום)

שדות: RLDNR, RBUKRS, GJAHR, BELNR (מפתח), KOART, AUGBL, AUGDT.
בנוסף רצוי: שורת דוגמה של תשלום (SE16) לאימות ש-AUGBL מתחיל ב-'2'
ושה-ledger המוביל הוא '0L'.
