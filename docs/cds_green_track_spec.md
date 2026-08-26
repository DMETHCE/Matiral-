# אפיון מפורט — CDS למעקב מסלול ירוק / בקרה מפצה

**מחליף את:** התוכנית `ZMM_PROCESS_GREEN_PATH` + טבלת היעד המתוכננת `ZMM_GREEN_TRACK` (שלא הוקמה — ה-CDS הוא התוצר)
**תאריך:** 26.08.2026
**סטטוס:** ✅ מאושר סופית — כל סעיפי האימות נסגרו (ראו סעיף 8); מוכן להעתקה ל-ADT ואקטיבציה

---

## 1. רקע והחלטה ארכיטקטונית

התוכנית המקורית רצה כ-Batch: שולפת סטים מ`/ILG/MM_GRPO_DET`, מחשבת סטטוס לוגי
לכל הודעה (QMNUM), ורושמת snapshot לטבלת `ZMM_GREEN_TRACK`. בנוסף לשגיאות
הקומפילציה (סעיף 2), לגישה זו חסרון מובנה: הנתונים נכונים רק לרגע הריצה.

הפתרון: **CDS View Entity חי** — `ZC_MM_GREENTRACK` — שמחזיר בדיוק את אותן
עמודות ואותה לוגיקה, מחושבות בזמן השאילתה. אין צורך בתוכנית, ב-Job, בטבלת
יעד, ב-`p_clear` או ב-`COMMIT WORK`.

## 2. שגיאות קומפילציה שאותרו בתוכנית המקורית

| # | מיקום | שגיאה |
|---|-------|--------|
| 1 | הצהרת `lt_target_db` / `ls_target_db` | ההצהרה בהערה (`*DATA:`) בעוד הקוד משתמש ב-`ls_target_db` בכל הלולאה → `Field LS_TARGET_DB is unknown`. הסיבה: טבלת `ZMM_GREEN_TRACK` טרם נוצרה ב-SE11 |
| 2 | `SELECT ... FROM acdoca WHERE bukrs = ...` | ב-ACDOCA אין שדה `BUKRS` — שם השדה הוא `RBUKRS` → שגיאת קומפילציה גם לאחר תיקון #1 |
| 3 | `TYPES ty_target` | `logical_status TYPE string` — טיפוס `STRING` אינו חוקי כעמודה רגילה בטבלה שקופה; ה-TYPE כלל אינו בשימוש |
| 4 | `TEXT-001` | אלמנט טקסט לא מוגדר (אזהרה) |
| 10 | `SELECT ... mn_gr_doc_ind FROM /ilg/mm_grpo_det` | בטבלה השדה נקרא `MM_GR_DOC_IND` (אומת מול צילום SE11) — `mn_gr_doc_ind` (עם N) אינו קיים → שגיאת קומפילציה נוספת |

**באגים לוגיים (מתקמפלים אך שגויים):**

| # | מיקום | באג |
|---|-------|-----|
| 5 | `DATA lv_has_50 ... VALUE abap_false` בתוך `LOOP` | `DATA` מאותחל פעם אחת בלבד — הדגלים **לא מתאפסים בין סטים**, וסט "יורש" סטטוסים מהסט הקודם. ב-CDS נפתר באגרגציה לכל QMNUM |
| 6 | `SELECT SINGLE ... FROM bkpf WHERE awkey =` ללא `AWTYP` | עלול לתפוס מסמך של אובייקט אחר עם אותו מפתח. ב-CDS נוסף סינון `awtyp = 'RMRP'` (לאימות — סעיף 8) |
| 7 | `SELECT SINGLE` על ACDOCA | מחזיר שורה שרירותית כשיש כמה שורות ספק; ב-CDS — `MAX( )` דטרמיניסטי |
| 8 | ~~ריבוי שורות `GRPO` לאותו QMNUM~~ | **ירד מהפרק** — צילום SE11 אימת שמפתח `/ILG/MM_GRPO_DET` הוא `MANDT + QMNUM` בלבד, כלומר שורה אחת להודעה |
| 9 | `SELECT ... FROM qmma` ללא סינון `MNGRP` | הקודים 50/60/70/80 שייכים לקבוצת `ZPU` (אומת מול צילום VIQMMA); בלי הסינון, קוד זהה מקבוצה אחרת היה נתפס בטעות. ב-CDS נוסף `WHERE mngrp = 'ZPU'` |

## 3. אובייקטים שנוצרו

| אובייקט | סוג | תפקיד |
|---------|-----|--------|
| `ZI_MM_GP_QMMASTATUS` | View Entity (אגרגציה) | דגלי has_50/60/70/80 לכל QMNUM מ-QMMA, מסונן לקבוצת פעילויות `MNGRP = 'ZPU'` (אומת מול צילום VIQMMA, 26.08.2026) |
| `ZI_MM_GP_CLEARING` | View Entity (אגרגציה) | AUGBL/AUGDT משורות ספק (`KOART='K'`) ב-ACDOCA |
| `ZC_MM_GREENTRACK` | View Entity ראשי | חיבור הכל + עץ ההחלטות |

**דרישת מערכת:** S/4HANA 2020 ומעלה (`define view entity` + ביטויים בתנאי `ON`
כגון `concat`) — **אושר על ידי הלקוח ב-26.08.2026** שהסביבה עומדת בדרישה.

## 4. מקורות נתונים ותנאי קישור

| מקור | Alias | קישור | מקביל בתוכנית |
|------|-------|--------|----------------|
| `/ILG/MM_GRPO_DET` | `grpo` | בסיס | סעיף 1 — שליפת הסטים |
| `ZI_MM_GP_QMMASTATUS` (QMMA, `MNGRP='ZPU'`) | `stat` | `qmnum = grpo.qmnum` | סעיף ב' — קודי 50/60/70/80 |
| `BKPF` | `fi` | `awkey = concat(belnr, gjahr)` + `awtyp='RMRP'`, רק כאשר belnr/gjahr מלאים | סעיף ג' — `CONCATENATE` + `SELECT SINGLE` |
| `BKPF` | `rev` | `awkey = concat(fi.awref_rev, fi.aworg_rev)`, רק כאשר `fi.xreversed='X'` | ג'.1 — מסמך הסטורנו |
| `T041CT` | `stx` | `stgrd = rev.stgrd`, `spras = $session.system_language` | סעיף 3 — טקסט סיבת סטורנו |
| `ZI_MM_GP_CLEARING` (ACDOCA) | `clr` | `bukrs/belnr/gjahr = fi.*` | ג'.2 — בדיקת תשלום |

כל הקישורים `LEFT OUTER JOIN` — שיחזור מדויק של התנהגות "לא נמצא → נשאר ריק"
של `SELECT SINGLE` עם `sy-subrc <> 0`.

הערה על `concat`: גם `CONCATENATE` ב-ABAP וגם `CONCAT` ב-CDS מסירים רווחים
נגררים — ההתנהגות זהה.

## 5. מיפוי עמודות (View מול טבלת היעד המתוכננת)

| עמודת View | מקור/נוסחה | הערה |
|------------|------------|------|
| `qmnum` (key) | `grpo.qmnum` | |
| `logical_status_code` | עץ ההחלטות → קוד 01–06/99 | תוספת על המקור — לסינון יציב שאינו תלוי טקסט |
| `logical_status` | עץ ההחלטות → טקסט עברי **זהה 1:1** | ראו סעיף 6 |
| `is_monitor` | `'X'` אם `monitor_indicator` או `extra_vlue_ind` לא ריקים | סעיף א' |
| `mblnr` | `grpo.mblnr` | |
| `mblnr_handled_manually` | `'X'` אם `mm_gr_doc_ind` ∈ {2,4} | סעיף א' |
| `belnr_mm`, `gjahr_mm` | `grpo.belnr`, `grpo.gjahr` | |
| `bukrs`, `belnr_fi`, `gjahr_fi` | `fi.bukrs/belnr/gjahr` | NULL כשאין מסמך FI (שקול ל-initial) |
| `is_paid` | `'X'` אם נמצא `clr.augbl` | ג'.2 |
| `augbl`, `augdt` | `MAX(augbl)`, `MAX(augdt)` מ-ACDOCA (`koart='K'`, `augbl<>''`) | ראו באג #7 |
| `is_reversed` | `'X'` אם `fi.xreversed = 'X'` | ג'.1 |
| `stgrd` | `rev.stgrd` רק כאשר reversed | כמו במקור — נשלף רק בענף הסטורנו |
| `stgrd_txt` | `stx.txt20` רק כאשר reversed | בשפת המשתמש (`sy-langu` ↔ `$session.system_language`) |
| `aedat` | `$session.system_date` | במקור `sy-datum` של ריצת ה-Batch; ב-View חי — תאריך השאילתה |
| `aezet` | **הושמט** | אין משתנה שעת-מערכת ב-CDS; ב-View חי אין משמעות ל"שעת עדכון" |
| `mandt` | — | טיפול Client אוטומטי ב-CDS |

## 6. עץ ההחלטות (סעיף ד') — שיחזור מדויק

סדר הבדיקות זהה לחלוטין ל-`IF/ELSEIF` המקורי:

| קוד | טקסט | תנאי |
|-----|------|------|
| 01 | נדחה לאחר אישור ובוטל | has_50 **וגם** has_60, וגם (reversed **או** לא שולם) |
| 02 | נדחה לאחר אישור ושולם | has_50 **וגם** has_60, וגם שולם ולא reversed |
| 03 | נדחה לאחר אישור דורש | has_60 (בלי has_50), וגם reversed |
| 04 | אושר והושלם לאחר עיסוק ידני | has_60, לא reversed, וגם (has_70 או has_80 או mm_gr_doc_ind ∈ {2,4}) |
| 05 | אושר והושלם ללא תקלה | has_60 בלבד, ללא אף אחד מהתנאים לעיל |
| 06 | נדחה על ידי דורש | has_50 בלבד |
| 99 | בתהליך | אף אחד מהקודים |

דיוק שיחזור: במקור `is_paid = abap_false` פירושו `augbl` ריק → ב-CDS
`clr.augbl IS NULL` (ה-View של הסילוק מסנן `augbl <> ''`, לכן NULL ⇔ לא שולם).
בתנאי 04 הוחלף `mblnr_handled_manually = 'X'` בביטוי המקורי שלו
(`mm_gr_doc_ind` ∈ {2,4}) — זהות לוגית מלאה.

## 7. הבדלים מודעים מהתוכנית המקורית

1. **Fallback ל-BSEG הושמט.** התוכנית ניסתה ACDOCA ואז BSEG. הסביבה אושרה
   כ-S/4HANA (26.08.2026) — נתוני הסילוק של שורות ספק קיימים ב-ACDOCA
   וה-fallback מיותר.
2. **סינון `AWTYP = 'RMRP'`** נוסף בקישור ל-BKPF (באג #6) — **אושר להשארה**
   על ידי הלקוח (26.08.2026).
3. **ריבוי שורות לאותו QMNUM — ירד מהפרק:** צילום SE11 (26.08.2026) אימת
   שמפתח `/ILG/MM_GRPO_DET` הוא `MANDT + QMNUM` בלבד — שורה אחת להודעה,
   ולכן ה-View מחזיר בדיוק שורה אחת לכל QMNUM כמו טבלת היעד המתוכננת.
4. **`aedat`/`aezet`** — ראו סעיף 5.
5. **מסך הבחירה** (`s_qmnum`, `p_clear`) מתייתר — הסינון נעשה ב-`WHERE` של
   הצרכן (SE16H / ALV / OData), ואין נתונים ישנים למחוק.
6. **סינון `MNGRP = 'ZPU'`** נוסף באגרגציית QMMA (באג #9) — על פי צילום
   VIQMMA שסופק ב-26.08.2026.

## 8. סטטוס אימות

**אומת (צילומי SE11 / VIQMMA מ-26.08.2026):**

- **`/ILG/MM_GRPO_DET`** — מפתח `MANDT + QMNUM`; `QMNUM` CHAR12;
  `BELNR` CHAR10 (`RE_BELNR`); `GJAHR` NUMC4; `MBLNR` CHAR10; `MJAHR` NUMC4;
  `MM_GR_DOC_IND` / `MONITOR_INDICATOR` / `EXTRA_VLUE_IND` שדות CHAR1.
  שם השדה הנכון הוא `MM_GR_DOC_IND` (לא `MN_GR_DOC_IND` כפי שנכתב בתוכנית —
  שגיאה #10).
- **קבוצת קודי QMMA** — `MNGRP = 'ZPU'` (באג #9).

**אושר על ידי הלקוח (26.08.2026):**

1. **סביבה** — S/4HANA 2020 ומעלה ✓ (view entity + ACDOCA ללא fallback ל-BSEG).
2. **`AWTYP = 'RMRP'`** — הסינון נשאר כפי שהוא ✓.
3. **`ZMM_GREEN_TRACK`** — לא הוקמה ולא תוקם; ה-CDS הוא התוצר הסופי ✓.

**אין סעיפי אימות פתוחים.**

## 9. בדיקות קבלה מוצעות

לכל אחד מ-7 הסטטוסים: לאתר QMNUM מייצג, להריץ את התוכנית המתוקנת (אם תתוקן)
מול `SELECT * FROM zc_mm_greentrack WHERE qmnum = ...` ולוודא זהות בכל
העמודות. מקרי קצה: סט ללא חשבונית (belnr ריק), חשבונית ללא מסמך FI, סטורנו
ללא `awref_rev`, סילוק בכמה שורות ספק, QMNUM עם קודי QMMA כפולים.
