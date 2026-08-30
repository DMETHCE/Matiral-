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

## ✅ RBKP — כותרת מסמך קבלת חשבונית (צולם במלואו — כל 228 השדות)

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

נצפו גם ה-Appends (לא בשימוש ה-CDS): RBKP_1TIME (ספק חד-פעמי),
WRF_PREPAY (תשלום מראש), FAC_BKPF_EXT_GLO / GLO_REF (סימוכין גלובליים),
ATL/ILE (Annexation), **`/ILG/RBKP/` — Append לקוח עם `PUR_CODE`
("קוד מהות תשלום", CHAR10)**, J_1IG, SAFM.

## ✅ VIQMMA (צולם 26.08.2026)

View תצוגה מעל QMMA; אישר `MNGRP = 'ZPU'` כקבוצת הקודים של המסלול הירוק.

## ✅ BKPF — כותרת מסמך פיננסי (צולם במלואו — כל 210 השדות; כולל Append לקוח /ILG/ADD_HEADER)

| שדה | אלמנט נתונים | סוג | אורך | מפתח | שימוש ב-CDS |
|------|---------------|-----|------|------|--------------|
| MANDT | MANDT | CLNT | 3 | ✔ | |
| BUKRS | BUKRS | CHAR | 4 | ✔ | ✔ הצמדה ל-RBKP.BUKRS |
| BELNR | BELNR_D | CHAR | 10 | ✔ | ✔ |
| GJAHR | GJAHR | NUMC | 4 | ✔ | ✔ |
| STBLG | STBLG | CHAR | 10 | | ✔ מסמך סטורנו — זיהוי "בוטלה" + קישור rev |
| STJAH | STJAH | NUMC | 4 | | ✔ שנת מסמך הסטורנו |
| AWTYP | AWTYP | CHAR | 5 | | ✔ סינון 'RMRP' |
| AWKEY | AWKEY | CHAR | 20 | | ✔ קישור מהחשבונית הלוגיסטית |
| STGRD | STGRD | CHAR | 2 | | ✔ סיבת הסטורנו (נקראת ממסמך הסטורנו) |
| **XREVERSED** | CO_STOKZ | CHAR | 1 | | ✔ "סמן: בוצע סטורנו למסמך" — זיהוי "בוטלה" (כלשון האפיון) |
| XREVERSING | CO_STFLG | CHAR | 1 | | לא בשימוש (מזהה את מסמך הסטורנו עצמו) |
| AWREF_REV | AWREF_REV | CHAR | 10 | | לא בשימוש — מאוכלס על מסמך הסטורנו, לא על המקור (הבאג הלוגי בתוכנית); הקישור נעשה דרך STBLG |
| AWORG_REV | AWORG_REV | CHAR | 10 | | לא בשימוש (כנ"ל) |
| XSTOV | XSTOV | CHAR | 1 | | לא בשימוש (רק "מסומן לסטורנו", לא ביטול בפועל) |
| XREVERSAL | XREVERSAL | CHAR | 1 | | לא בשימוש |
| RLDNR | FINS_LEDGER | CHAR | 2 | | לא בשימוש (ledger) |

נצפו גם: DBBLG, BSTAT, XNETB, XRUEB, STODT, PPNAM/PPDATE, XREF1/2_HD,
EXT_GLO, FDTR ועוד.

**תיקון ממצא ביקורת (26.08.2026):** סוכן ה-CDS קבע ש-XREVERSED /
AWREF_REV / AWORG_REV אינם קיימים ב-BKPF — צילום SE11 הוכיח שהם **כן
קיימים** ב-S/4 של הלקוח. לפיכך שגיאת קומפילציה #11 בוטלה, וזיהוי הביטול
ב-CDS חזר ל-`XREVERSED = 'X'` כלשון האפיון. מה שנשאר בתוקף: הקישור
למסמך הסטורנו נעשה דרך `STBLG`/`STJAH` (מפתח מלא) ולא דרך `AWREF_REV`,
שמאוכלס על מסמך הסטורנו ולא על המקור.

## ✅ T041CT — טקסטים לסיבות סטורנו (צולם במלואו — 4 שדות)

| שדה | אלמנט נתונים | סוג | אורך | מפתח | שימוש ב-CDS |
|------|---------------|-----|------|------|--------------|
| MANDT | MANDT | CLNT | 3 | ✔ | |
| SPRAS | SPRAS | LANG | 1 | ✔ | ✔ `$session.system_language` |
| STGRD | STGRD | CHAR | 2 | ✔ | ✔ קישור מסיבת הסטורנו |
| TXT40 | TXT40 | CHAR | 40 | | ✔ טקסט הסיבה. **אין TXT20** — אושרה שגיאת קומפילציה #12 בתוכנית |

## ✅ ACDOCA — היומן האוניברסלי (צולם במלואו — כל 553 השדות)

| שדה | אלמנט נתונים | סוג | אורך | מפתח | שימוש ב-CDS |
|------|---------------|-----|------|------|--------------|
| RCLNT | MANDT | CLNT | 3 | ✔ | |
| RLDNR | FINS_LEDGER | CHAR | 2 | ✔ | ✔ סינון `= '0L'` (ledger מוביל) |
| RBUKRS | BUKRS | CHAR | 4 | ✔ | ✔ קוד חברה (בתוכנית נכתב BUKRS — שגיאה #2) |
| GJAHR | GJAHR | NUMC | 4 | ✔ | ✔ |
| BELNR | BELNR_D | CHAR | 10 | ✔ | ✔ |
| DOCLN | DOCLN6 | CHAR | 6 | ✔ | |
| KOART | KOART | CHAR | 1 | | ✔ סינון `= 'K'` (שורת ספק) |
| AUGDT | AUGDT | DATS | 8 | | ✔ תאריך סילוק (תשלום) |
| AUGBL | AUGBL | CHAR | 10 | | ✔ מסמך סילוק — `LIKE '2%'` |
| AUGGJ | AUGGJ | NUMC | 4 | | לא בשימוש (שנת הסילוק) |
| XOPVW | XOPVW | CHAR | 1 | | לא בשימוש (ניהול פריטים פתוחים) |

נצפו גם: XREVERSING/XREVERSED/XTRUEREV, AWTYP_REV/AWORG_REV/AWREF_REV
(שדות הסטורנו של ACDOCA — מקור הבלבול באפיון), RACCT, KOSTL/PRCTR,
LIFNR/KUNNR/EBELN/MATNR (SUBLEDGER_SHARED), מטבעות, כמויות, נכסים (FAA),
Material Ledger.

שדות לקוח שנצפו (לא בשימוש ה-CDS, לידיעה עתידית): `ZZVENDOR` (ספק נגדי),
`ZZGSBER` (תחום עסקי נגדי), `ZZCUSTOMER` (לקוח נגדי), `ZZXDOCNR/ZZXYEAR/
ZZXDOCLN` (סימוכין ניהול קרנות), ו-Append `/ILG/SERVICE_COD/` —
`SERVICE_CODE` (קוד שירות עבור שרת התשלומים, NUMC8). כמו כן קיים
`QMNUM` ("מספר הודעה") באזור ה-CO — לא מאוכלס בתהליך חשבוניות ספק רגיל,
ולכן הקישור נשאר דרך BKPF/AWKEY.

**אימות נתונים שנותר (אופציונלי, לא חוסם):** שורת SE16 של תשלום בפועל —
לוודא ש-`AUGBL` מתחיל ב-'2' ושה-ledger הפעיל הוא '0L'.
