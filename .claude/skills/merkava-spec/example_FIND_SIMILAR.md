# דוגמת ייחוס — /ILG/MM_MATIRAL_FIND_SIMILAR

אפיון לדוגמה שנכתב בסקיל זה (פונקציית RFC לאיתור מק"טים דומים לפי מאפיינים טרם יצירה). השתמש כתבנית-על לסדר הסעיפים והצעדים. הקובץ המלא שנוצר: `build_spec_template.js` (בלוק ה-CONTENT).

## שלד הסעיפים שמולא
- **פתיחה:** כותרת `מסמכים` + בולט ✓ של תיאור הפונקציה (ללא כותרת/פוטר/מטא-דאטה ממשלתיים).
- **4.2 — שם הפונקציה** + בולט ❖ `פונקציה מסוג RFC - לטובת איתור מק"טים דומים לפי מאפיינים`.
- **4.2.1 קלט:** פרמטרים `IV_MATKL / IV_MAKTX / IV_TOP`; טבלת `IT_CHAR` (`CHARCINTERNALID` חובה, `VALUE` חובה, `CHARCDESCRIPTION` רשות — לתצוגה).
- **4.2.2 פלט:** פרמטרים `EV_MATCH_FOUND / EV_BY_TEXT`; טבלת `ET_MATCHES` (`MATNR, MATKL, MAKTX, MATCH_PCT, MATCHED_CNT, TOTAL_CNT, SOURCE`); טבלת `RETURN` (BAPIRET2).
- **5. מהלך הפונקציה** (כל צעד = משפט "…באופן הבא:" + טבלת מיפוי):
  - 5.1 שמירת קלט ל-`LV_*` ו-`LT_CHAR`.
  - 5.2 בדיקה האם `LT_CHAR` מלאה.
  - **שתי גישות משלימות שרצות תמיד** — כל אחת מחזירה עד `LV_TOP` תוצאות ל-`ET_MATCHES` (סה"כ עד פי 2):
  - 5.2.1 גישה א' (מאפיינים, אם `LT_CHAR` מלאה) — שליפה **ישירה** מ-`/ILG/i_MatiralCharacteristic` ב-`FOR ALL ENTRIES` על `LT_CHAR` (`CharcInternalID`=`LT_CHAR-CHARCINTERNALID`, `CharcValue`=`LT_CHAR-VALUE`, `PRODUCT`→`LT_MATNR`) → צבירה ל-`LT_SCORE` (`MATCH_PCT = MATCHED_CNT / TOTAL_CNT * 100`, `TOTAL_CNT`=מס' שורות `LT_CHAR`) → JOIN ל-`I_Product`(+סינון `MATKL` אם `LV_MATKL` מלא) + `MAKT` ומיון `ORDER BY MATKL, MATCH_PCT DESCENDING` → `ET_MATCHES` (`SOURCE='C'`), עד `LV_TOP`. **ללא CABN וללא טבלת צמדים** — הקלט כבר מכיל `CHARCINTERNALID`.
  - 5.2.2 גישה ב' (טקסט, אם `LV_MAKTX` מלא) — פירוק `LV_MAKTX` ל-`LT_WORDS` → `MAKT` ב-`MAKTX LIKE '%מילה%'` (`SPRAS='HE'`) → עד `LV_TOP` מועמדים ל-`LT_TEXT` (`SOURCE='T'`). אם `LV_MAKTX` ריק — גישה זו לא מתבצעת.
  - 5.2.3 **אכלוס מרוכז** — איחוד `LT_SCORE`(C)+`LT_TEXT`(T) ל-`LT_RESULT`, ו**שליפת נתוני מק״ט אחת** (JOIN ל-`I_Product`+`MAKT`, סינון `MATKL` אם `LV_MATKL` מלא) הממלאת את `ET_MATCHES`. כך נמנעת השליפה הכפולה (`I_Product`/`MAKT` נשלפים פעם אחת לשתי הגישות).
- **6.1/6.2/6.3** — בדיקת `ET_MATCHES`, מילוי `EV_MATCH_FOUND`, הודעת `RETURN` (`'W'` נמצא / `'S'` לא נמצא), סיום והחזרה למשתמש.
- **סוף.** + טבלת `היסטוריה של המסמך`.

## החלטות תכן שהוטמעו
- חישוב אחוז התאמה: **הכלה** — `תואמים / סה"כ זוגות חדש × 100`.
- מנוע: **צבירה ב-ABAP** (FOR ALL ENTRIES + COLLECT), תואם כללי HANA (שדות נבחרים, ORDER BY).
- נפילה: **LIKE פשוט** על `MAKT` + סינון `MATKL` (ללא Fuzzy/Full-Text).
- כש-`IT_CHAR` ריק — **אין שגיאה**; זורמים ישר לנפילה הטקסטואלית.
- `IV_MATKL` (קבוצת חומרים) — שדה **רשות**; אם מלא, משמש כסינון בכל שליפות נתוני המק״ט (גם במסלול המאפיינים — סינון `I_Product` לפי `MaterialGroup` — וגם בנפילה הטקסטואלית — סינון `MARA`).
