---
name: merkava-spec
description: >-
  כתיבת אפיון פונקציונאלי ל-SAP/ABAP בפורמט "מרכבה" (גרסה רזה לפי העדפת המשתמש). TRIGGER when the user asks to write/produce an "אפיון", "אפיון פונקציונאלי", "מסמך אפיון", a SAP/ABAP functional specification, or a spec for a Function Module / report / CDS — especially for /ILG/ objects. Produces a Hebrew RTL .docx in the user's lean format: NO government header/footer/logo and NO metadata table — opens with a "מסמכים" heading + a ✓ description bullet, then sections 4 (תיאור טכני) / 5 (מהלך הפונקציה) / 6, and ends with "סוף." + טבלת היסטוריה. CRITICAL: documents every function/BAPI/SELECT call as a step ("…יש ל… באופן הבא:") followed by a 3-column mapping table (שם שדה = אופן האכלוס). Do NOT invent prose-style specs; always use this mapping-table logic pattern.
---

# Merkava Functional Spec (אפיון פונקציונאלי — תבנית מרכבה)

מטרת הסקיל: לייצר מסמך אפיון פונקציונאלי ב-`.docx` עברית (RTL) **זהה 1:1** לתבנית מרכבה של משרד האוצר, כולל דפוס תיעוד הלוגיקה הייחודי (צעדים + טבלאות מיפוי). יישם תמיד גם את תקני **abap-ilg** (קונבנציית שמות, כללי HANA) לתוכן.

## חוק הזהב — דפוס תיעוד הלוגיקה
**אסור** לכתוב את הלוגיקה כפסקאות פרוזה. כל קריאה לפונקציה/BAPI, כל שליפה (SELECT) וכל מילוי מבנה מתועדים כך:

> `X.Y` **משפט הוראה** המסתיים ב־**"באופן הבא:"** ← ואז **טבלת מיפוי בת 3 עמודות**:
> עמודה ימנית = שם השדה/הפרמטר ביעד, עמודה אמצעית = `=`, עמודה שמאלית כותרת **"אופן האכלוס"** = הערך/המקור.

ביטויי הפתיחה הקבועים (להעתיק מילה במילה): `תחילה יש לשמור את … באופן הבא:` · `לאחר מכן יש לקרוא לפונקציה … באופן הבא:` · `בנוסף עבור כל שורה ב… יש לייצר …` · `בסיום יש להעביר …` · `יש לבדוק האם …` · `במידה וכן …` · `במידה ולא …` · `יש לסיים את הפונקציה ולהחזיר את … למשתמש.` בסוף המסמך: `סוף.` ואז טבלת `היסטוריה של המסמך`.

פירוט מלא של המבנה, הטבלאות, הטרמינולוגיה והשמות נמצא ב-`style.md` — **קרא אותו לפני כתיבה**.

## תהליך העבודה (Workflow)

1. **אסוף קלט** מהמשתמש: שם האובייקט (`/ILG/...`), סוג (FM/RFC/דוח/CDS), מטרה, פרמטרי קלט/פלט, טבלאות, והלוגיקה שלב-אחר-שלב (אילו פונקציות/BAPI/שליפות).
2. **קרא** את `style.md` (מבנה + טרמינולוגיה + פורמט טבלאות).
3. **בנה את ה-docx** עם המחולל המוכן:
   - העתק את `assets/build_spec_template.js` ואת `assets/logo_magen.png` לתיקיית עבודה (למשל `_spec/` בפרויקט).
   - ערוך **רק** את בלוק התוכן המסומן `// ===== CONTENT — EDIT PER SPEC =====` … `// ===== END CONTENT =====`: מלא את `META`, פרמטרים, טבלאות, וצעדי הלוגיקה (קריאות ל-`H`, `paramTbl`, `mapTbl`, `P`). אל תיגע בעוזרים, בכותרת/פוטר ובטבלאות הבסיס.
   - הרץ: `export NODE_PATH="$(npm root -g)"; node _spec/build_spec_template.js`
     (דרישות: `node`, חבילת `docx` גלובלית — `npm install -g docx` אם חסר).
4. **בדוק ויזואלית** (עברית RTL רגישה לבאגים): המר ל-PDF ורנדר עמודים —
   `"/c/Program Files/LibreOffice/program/soffice.exe" --headless --convert-to pdf --outdir _spec <out>.docx`
   ואז `python -c "import fitz;d=fitz.open('_spec/<out>.pdf');[d[i].get_pixmap(dpi=110).save(f'_spec/p{i+1}.png') for i in range(d.page_count)]"` → קרא את ה-PNG-ים.
   ודא: טבלאות בכיוון RTL נכון, מזהי קוד שמתחילים ב-`/` מוצגים נכון (העוזר `tok()` עוטף ב-LRM), ושאין כותרת/פוטר ממשלתי או טבלת מטא-דאטה (הוסרו לבקשת המשתמש).
5. **נקה** קבצי ביניים (PDF/PNG), והשאר את ה-`.docx` הסופי. אם המשתמש עובד מול תיקייה ספציפית — העתק לשם.

## הערות חשובות
- **תמיד RTL**: כל פסקה `bidirectional:true` + יישור לימין; כל טבלה `visuallyRightToLeft:true`. מילה עברית בודדת מתהפכת ללא `bidirectional:true`.
- **ללא boilerplate ממשלתי**: אין כותרת עליונה (לוגו/מדינת ישראל/מרכבה), אין פוטר (מספרי עמוד/פרטי קשר) ואין טבלת מטא-דאטה — הוסרו לבקשת המשתמש. המסמך נפתח בכותרת "מסמכים" + בולט ✓ של תיאור הפונקציה.
- **מזהים טכניים** (שמות שדות/פרמטרים/`/ILG/...`) — עטוף ב-`tok()` (פונט Consolas + LRM) כדי לשמור LTR וסדר לוכסנים נכון.
- **ערכים קבועים** בגרשיים בודדים: `'MARA'`, `'001'`, `'X'`, `'W'`. ערכי מערכת ללא גרשיים: `SY-DATUM`.
- **שמות משתנים** לפי abap-ilg: `LV_` סקלר זמני, `LT_` טבלה זמנית, `IV_/EV_/IT_/ET_` פרמטרים, `LWA_/GWA_` work area.
- **אל תוסיף תרשים זרימה** למסמך אלא אם המשתמש ביקש — התבנית המקורית לא כוללת אחד.
- שמור על הפורמט גם כשהשגיאה "MATIRAL" (במקום MATERIAL) מופיעה בשם — זה האיות שבשימוש בפרויקט.

## דוגמת ייחוס
`example_FIND_SIMILAR.md` מתאר אפיון שנכתב בסקיל זה (פונקציית `/ILG/MM_MATIRAL_FIND_SIMILAR`) — השתמש בו כתבנית-על לסדר הסעיפים והצעדים.
