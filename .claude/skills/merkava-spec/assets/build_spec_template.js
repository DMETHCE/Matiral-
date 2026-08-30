const fs = require("fs");
const path = require("path");
const {
  Document, Packer, Paragraph, TextRun, Table, TableRow, TableCell,
  AlignmentType, BorderStyle, WidthType, ShadingType, VerticalAlign,
  ImageRun, PageBreak, Header, Footer, PageNumber, HeadingLevel
} = require("docx");

// ===== merkava-spec builder =====
// העתק קובץ זה + logo_magen.png לתיקיית עבודה, וערוך רק את בלוק ה-CONTENT למטה.
// הרצה:  export NODE_PATH="$(npm root -g)"; node build_spec_template.js
// (דרישה: npm install -g docx)
const REF = __dirname;                       // logo_magen.png חייב להיות לצד קובץ זה
const OUTNAME = "אפיון_FIND_SIMILAR.docx";   // ← שנה לשם הרצוי
const CW = 9026;
const GREY = "D9D9D9", BLUE = "1F3864";
const LRM = "‎";

const bd = { style: BorderStyle.SINGLE, size: 4, color: "000000" };
const B = { top: bd, bottom: bd, left: bd, right: bd };

function hasHeb(s) { return /[֐-׿]/.test(s); }

// generic RTL paragraph
function P(text, o = {}) {
  const arr = Array.isArray(text) ? text : [text];
  return new Paragraph({
    bidirectional: true, alignment: o.align || AlignmentType.RIGHT,
    spacing: { after: o.after === undefined ? 100 : o.after, before: o.before || 0, line: 276 },
    children: arr.map(t => typeof t === "string"
      ? new TextRun({ text: t, bold: o.bold, color: o.color, size: o.size || 22 }) : t),
  });
}
function tok(t) { return new TextRun({ text: LRM + t + LRM, font: "Consolas", size: 20, color: "0B5394" }); }

function H(num, txt, size) {
  return new Paragraph({
    bidirectional: true, alignment: AlignmentType.RIGHT,
    spacing: { before: 240, after: 120 },
    children: [new TextRun({ text: `${num}.\t${txt}`, bold: true, size, color: "000000" })],
  });
}

// a cell; content may be string or array of TextRuns
function C(content, o = {}) {
  const kids = Array.isArray(content) ? content : [content];
  return new TableCell({
    borders: B, width: { size: o.w, type: WidthType.DXA },
    columnSpan: o.span,
    shading: o.fill ? { fill: o.fill, type: ShadingType.CLEAR, color: "auto" } : undefined,
    verticalAlign: VerticalAlign.CENTER,
    margins: { top: 50, bottom: 50, left: 100, right: 100 },
    children: kids.map(c => typeof c === "string"
      ? new Paragraph({ bidirectional: true,
          alignment: o.center ? AlignmentType.CENTER : (o.left ? AlignmentType.LEFT : AlignmentType.RIGHT),
          spacing: { after: 0, line: 252 },
          children: [new TextRun({ text: o.mono ? (LRM + c + LRM) : c, bold: o.bold,
            color: o.color, size: o.size || 20, font: o.mono ? "Consolas" : undefined })] })
      : new Paragraph({ bidirectional: true, alignment: o.center ? AlignmentType.CENTER : AlignmentType.RIGHT,
          spacing: { after: 0, line: 252 }, children: [c] })),
  });
}

function tableOf(colW, rows) {
  return new Table({ width: { size: colW.reduce((a, b) => a + b, 0), type: WidthType.DXA },
    columnWidths: colW, visuallyRightToLeft: true, rows });
}

// 5-col parameter / structure table
function paramTbl(headers, data) {
  const W = [1850, 2150, 950, 950, 3176];
  const head = new TableRow({ tableHeader: true,
    children: headers.map((h, i) => C(h, { w: W[i], fill: GREY, bold: true, center: true, size: 20 })) });
  const body = data.map(r => new TableRow({ children: [
    C(r[0], { w: W[0], mono: true, center: true }),
    C(r[1], { w: W[1], mono: !hasHeb(r[1]), center: true }),
    C(r[2], { w: W[2], center: true }),
    C(r[3], { w: W[3], center: true }),
    C(r[4], { w: W[4] }),
  ] }));
  return tableOf(W, [head, ...body]);
}

// 3-col mapping table:  rightHeader | = | leftHeader ; rows [field,value]
function mapTbl(rightHeader, leftHeader, rows) {
  const W = [3650, 700, 4676];
  const head = new TableRow({ tableHeader: true, children: [
    C(rightHeader, { w: W[0], fill: GREY, bold: true, center: true, size: 20 }),
    C("=", { w: W[1], fill: GREY, bold: true, center: true }),
    C(leftHeader, { w: W[2], fill: GREY, bold: true, center: true, size: 20 }),
  ] });
  const body = rows.map(r => new TableRow({ children: [
    C(r[0], { w: W[0], mono: true, center: true }),
    C("=", { w: W[1], center: true, bold: true }),
    C(r[1], { w: W[2], mono: !hasHeb(r[1]) }),   // "אופן האכלוס" — מיושר לימין
  ] }));
  return tableOf(W, [head, ...body]);
}

function bullet(mark, runs, o = {}) {
  const arr = Array.isArray(runs) ? runs : [runs];
  return new Paragraph({ bidirectional: true, alignment: AlignmentType.RIGHT,
    spacing: { before: o.before || 80, after: o.after === undefined ? 80 : o.after, line: 276 },
    children: [new TextRun({ text: mark + "  ", bold: true, size: o.size || 22 }),
      ...arr.map(t => typeof t === "string" ? new TextRun({ text: t, bold: o.bold, size: o.size || 22 }) : t)] });
}
function spc(h = 80) { return new Paragraph({ spacing: { after: h }, children: [] }); }

// הערה: לפי בקשת המשתמש הוסרו הכותרת והפוטר הממשלתיים (לוגו / מדינת ישראל / מרכבה /
// מספרי עמוד / פרטי מרכז כלל ירושלים) וכן טבלת המטא-דאטה וטבלת "מסמכים קשורים".
// המסמך נפתח בכותרת "מסמכים" + תיאור הפונקציה (✓) ואז סעיף 4.

// ===== CONTENT — EDIT PER SPEC =====
// ערוך מכאן ועד "END CONTENT": META_DESC, פרמטרים, טבלאות וצעדי הלוגיקה.
// השתמש בעוזרים: H(num,txt,size) · paramTbl(headers,rows) · mapTbl(rightHeader,"אופן האכלוס",rows) · P(text) · bullet("✓"/"❖",text)

// תיאור הפונקציה (בולט ✓ בראש המסמך)
const META_DESC = "הפונקציה תקבל רשימת מאפיינים עבור מק״ט חדש, תאתר מק״טים קיימים בעלי מאפיינים זהים/דומים, תחשב אחוז התאמה ותחזיר את המק״טים הדומים ביותר להתרעה למשתמש.";

// ---------------- BODY ----------------
const body = [];

// ===== 4. =====
body.push(new Paragraph({ children: [new PageBreak()] }));
body.push(H("4", "תיאור טכני מפורט", 36));
body.push(H("4.2", "יצירת פונקציה חדשה לטובת תיק ההתקשרות", 30));
body.push(tableOf([3200, 5826], [ new TableRow({ children: [
  C("/ILG/MM_MATIRAL_FIND_SIMILAR", { w: 5826, mono: true, center: true }),
  C("שם הפונקציה החדשה", { w: 3200, fill: GREY, bold: true }) ] }) ]));
body.push(spc(120));
body.push(bullet("❖", [new TextRun({ text: "פונקציה מסוג ", bold: true }), tok("RFC"),
  new TextRun({ text: " - לטובת איתור מק״טים דומים לפי מאפיינים", bold: true })]));

// 4.2.1 input
body.push(H("4.2.1", "מסך הקלט של הפונקציה :", 26));
body.push(bullet("✓", "פרמטרים:", { bold: true }));
body.push(paramTbl(["פרמטר", "סוג / אלמנט נתונים", "אורך", "חובה", "תיאור"], [
  ["IV_MATKL", "MATKL", "9", "לא", "קבוצת חומרים (רשות) – אם מלא, משמש לסינון בכל שליפות נתוני המק״ט"],
  ["IV_MAKTX", "MAKTX", "40", "לא", "תיאור מוצע – משמש לחיפוש הטקסטואלי"],
  ["IV_TOP", "INT4", "10", "לא", "מספר תוצאות מקסימלי לכל גישה (ברירת מחדל 4). שתי הגישות רצות תמיד — סה״כ עד פי 2"],
]));
body.push(spc());
body.push(bullet("✓", "טבלאות:", { bold: true }));
body.push(P([new TextRun({ text: "טבלת ", bold: true }), tok("IT_CHAR")], { after: 60 }));
body.push(paramTbl(["שדה", "סוג שדה", "אורך", "חובה", "תיאור"], [
  ["CHARCINTERNALID", "ATINN", "10", "כן", "מזהה פנימי של המאפיין — להצלבה ישירה מול ה‑CDS"],
  ["VALUE", "CHAR / STRING", "70", "כן", "ערך המאפיין כפי שהועבר לפונקציה"],
  ["CHARCDESCRIPTION", "ATBEZ", "30", "לא", "תיאור המאפיין (רשות) — לתצוגה בלבד"],
]));

// 4.2.2 output
body.push(H("4.2.2", "מסך הפלט של הפונקציה :", 26));
body.push(bullet("✓", "פרמטרים:", { bold: true }));
body.push(paramTbl(["פרמטר", "סוג / אלמנט נתונים", "אורך", "חובה", "תיאור"], [
  ["EV_MATCH_FOUND", "char", "1", "", "'X' במידה ונמצאה התאמה כלשהי"],
  ["EV_BY_TEXT", "char", "1", "", "'X' במידה והתוצאה הופקה ממסלול טקסטואלי"],
]));
body.push(spc());
body.push(bullet("✓", "טבלאות:", { bold: true }));
body.push(P([new TextRun({ text: "טבלת ", bold: true }), tok("ET_MATCHES")], { after: 60 }));
body.push(paramTbl(["שדה", "סוג שדה", "אורך", "חובה", "תיאור"], [
  ["MATNR", "MATNR", "40", "", "מק״ט מועמד קיים"],
  ["MATKL", "MATKL", "9", "", "קבוצת חומרים"],
  ["MAKTX", "MAKTX", "40", "", "תיאור המק״ט (עברית)"],
  ["MATCH_PCT", "DEC", "5,2", "", "אחוז התאמה (0–100); ריק במסלול טקסט"],
  ["MATCHED_CNT", "INT4", "10", "", "מספר זוגות (מאפיין+ערך) תואמים"],
  ["TOTAL_CNT", "INT4", "10", "", "סה״כ זוגות של המק״ט החדש"],
  ["SOURCE", "char", "1", "", "מקור: 'C' מאפיינים / 'T' טקסט"],
]));
body.push(spc());
body.push(P([new TextRun({ text: "טבלה - ( ", bold: true }), tok("RETURN"), new TextRun({ text: " ( ", bold: true }), tok("LIKE BAPIRET2")], { after: 60 }));

// ===== 5. מהלך הפונקציה =====
body.push(H("5", "מהלך הפונקציה:", 30));

body.push(H("5.1", "תחילה יש לשמור את המשתנים ממסך הקלט של הפונקציה באופן הבא", 24));
body.push(mapTbl("שם שדה / מבנה בסך הקלט", "שם המשתנה / מבנה זמני", [
  ["IV_MATKL", "LV_MATKL"], ["IV_MAKTX", "LV_MAKTX"], ["IV_TOP", "LV_TOP"],
]));
body.push(spc());
body.push(P([new TextRun({ text: "שמירת טבלה זמנית", bold: true, size: 24 })], { after: 60 }));
body.push(mapTbl("שם טבלה זמנית במסך הקלט", "שם טבלה זמנית", [["IT_CHAR", "LT_CHAR"]]));
body.push(spc());

body.push(H("5.2", "האיתור מתבצע תמיד בשתי גישות משלימות — לפי מאפיינים (5.2.1) ולפי שם/טקסט (5.2.2) — כאשר כל גישה מחזירה עד LV_TOP תוצאות לטבלת ET_MATCHES.", 24));

body.push(H("5.2.1", "גישה א׳ – לפי מאפיינים: במידה ו-LT_CHAR מלאה, יש לבצע איתור לפי מאפיינים באופן הבא:", 24));
body.push(P("יש לשלוף את אוכלוסיית המק״טים בעלי צמדים תואמים (מזהה מאפיין + ערך) מתוך /ILG/i_MatiralCharacteristic לטבלה זמנית LT_MATNR, בקריאת FOR ALL ENTRIES ישירות על LT_CHAR, באופן הבא:"));
body.push(mapTbl("שם שדה ב /ILG/i_MatiralCharacteristic", "אופן האכלוס", [
  ["PRODUCT", "→ LT_MATNR (המק״ט המאותר)"],
  ["CharcInternalID", "LT_CHAR-CHARCINTERNALID"],
  ["CharcValue", "LT_CHAR-VALUE"],
]));
body.push(P("השדות CharcInternalID ו-CharcValue הם תנאי ההצלבה; PRODUCT הוא המק״ט המאוכלס לטבלה LT_MATNR. יש לשלוף את השדות PRODUCT, CharcInternalID, CharcValue בלבד, עם ORDER BY PRODUCT."));
body.push(spc());
body.push(P("בנוסף, עבור כל מק״ט (PRODUCT) בטבלה הזמנית LT_MATNR יש לספור את מספר הצמדים התואמים ולחשב את אחוז ההתאמה לטבלה זמנית LT_SCORE באופן הבא:"));
body.push(mapTbl("שם שדה ב LT_SCORE", "אופן האכלוס", [
  ["MATNR", "LT_MATNR-PRODUCT"],
  ["MATCHED_CNT", "מספר השורות התואמות ב-LT_MATNR לאותו מק״ט"],
  ["TOTAL_CNT", "מספר השורות בטבלה LT_CHAR"],
  ["MATCH_PCT", "MATCHED_CNT / TOTAL_CNT * 100"],
]));
body.push(spc());
body.push(P("יש לבחור את עד LV_TOP המק״טים בעלי הציון הגבוה ביותר (ORDER BY MATCH_PCT DESCENDING) — אלו מועמדי גישת המאפיינים, בטבלה הזמנית LT_SCORE. בשלב זה אין שליפת נתוני מק״ט (היא מתבצעת במרוכז ב-5.2.3)."));
body.push(spc());

body.push(H("5.2.2", "גישה ב׳ – לפי שם (טקסט): במידה והפרמטר LV_MAKTX מלא, יש לבצע איתור טקסטואלי לזיהוי מועמדים (אם LV_MAKTX ריק — גישה זו אינה מתבצעת):", 24));
body.push(P("תחילה יש לפרק את הערך LV_MAKTX למילים (טוקנים) ולשמור בטבלה זמנית LT_WORDS."));
body.push(P("לאחר מכן יש לשלוף מתוך טבלת MAKT את המק״טים שתיאורם מכיל אחת מהמילים, באופן הבא:"));
body.push(mapTbl("שם שדה ב MAKT", "אופן האכלוס", [
  ["SPRAS", "'HE'"],
  ["MAKTX", "MAKTX LIKE '%מילה%' עבור כל מילה ב-LT_WORDS"],
]));
body.push(P("יש לשלוף את השדה MATNR בלבד, עם ORDER BY MATNR, ולשמור את עד LV_TOP המק״טים בטבלה זמנית LT_TEXT — אלו מועמדי גישת הטקסט (גם כאן ללא שליפת נתוני מק״ט)."));
body.push(spc());

body.push(H("5.2.3", "אכלוס מרוכז של טבלת הפלט — לשתי הגישות יחד, בשליפת נתוני מק״ט אחת (ללא שליפה כפולה):", 24));
body.push(P("יש לאחד את מועמדי שתי הגישות לטבלה זמנית LT_RESULT (שורות LT_SCORE עם SOURCE='C'; שורות LT_TEXT עם SOURCE='T'). לאחר מכן, בשליפה אחת בלבד, יש לשלב עבור כל המועמדים את נתוני המק״ט מ-I_Product ומ-MAKT, ולמלא את טבלת הפלט ET_MATCHES באופן הבא:"));
body.push(mapTbl("שם שדה ב ET_MATCHES", "אופן האכלוס", [
  ["MATNR", "LT_RESULT-MATNR"],
  ["MATKL", "I_Product-MaterialGroup"],
  ["MAKTX", "MAKT-MAKTX ( SPRAS = 'HE' )"],
  ["MATCH_PCT", "LT_RESULT-MATCH_PCT ( ריק עבור מקור טקסט )"],
  ["MATCHED_CNT", "LT_RESULT-MATCHED_CNT"],
  ["TOTAL_CNT", "LT_RESULT-TOTAL_CNT"],
  ["SOURCE", "LT_RESULT-SOURCE ( 'C' מאפיינים / 'T' טקסט )"],
]));
body.push(P("השילוב מול I_Product ו-MAKT מתבצע ב-JOIN אחד לכל המועמדים יחד — שליפת נתוני המק״ט פעם אחת בלבד. במידה ו-LV_MATKL מלא — יש לסנן את ה-JOIN ל-I_Product לפי MaterialGroup = LV_MATKL."));
body.push(P("המיון: ORDER BY SOURCE, MATKL, MATCH_PCT DESCENDING. במידה ונכללו מועמדי טקסט — יש למלא את הפרמטר EV_BY_TEXT בערך 'X'."));
body.push(spc());

// ===== 6. =====
body.push(H("6", "לאחר מכן יש לבדוק האם טבלת ET_MATCHES מלאה.", 26));
body.push(H("6.1", "במידה וכן יש למלא את הפרמטר EV_MATCH_FOUND בערך 'X', ולהוסיף לטבלה RETURN הודעת אזהרה באופן הבא:", 24));
body.push(mapTbl("שם שדה ב RETURN", "אופן האכלוס", [
  ["TYPE", "'W'"],
  ["MESSAGE", "נמצאו מק״טים דומים. נא לבדוק טרם יצירה."],
]));
body.push(spc());
body.push(H("6.2", "במידה ולא יש למלא את הפרמטר EV_MATCH_FOUND בערך ' ', ולהוסיף לטבלה RETURN הודעת מידע באופן הבא:", 24));
body.push(mapTbl("שם שדה ב RETURN", "אופן האכלוס", [
  ["TYPE", "'S'"],
  ["MESSAGE", "לא נמצאו מק״טים דומים."],
]));
body.push(spc());
body.push(H("6.3", "לאחר מכן יש לסיים את הפונקציה ולהחזיר את הטבלה ET_MATCHES, הפרמטרים EV_MATCH_FOUND ו-EV_BY_TEXT והטבלה RETURN למשתמש.", 24));
body.push(spc(160));

// סוף + history
body.push(new Paragraph({ bidirectional: true, alignment: AlignmentType.RIGHT, spacing: { before: 200, after: 200 },
  children: [new TextRun({ text: "סוף.", bold: true, size: 40, color: "000000" })] }));
body.push(P([new TextRun({ text: "היסטוריה של המסמך", bold: true, size: 30 })], { after: 160 }));
body.push(tableOf([3326, 1900, 1900, 1900], [
  new TableRow({ tableHeader: true, children: [
    C("תמצית העדכון", { w: 3326, fill: GREY, bold: true, center: true }),
    C("מבצע", { w: 1900, fill: GREY, bold: true, center: true }),
    C("תאריך", { w: 1900, fill: GREY, bold: true, center: true }),
    C("גירסה", { w: 1900, fill: GREY, bold: true, center: true }) ] }),
  new TableRow({ children: [ C("", { w: 3326 }), C("", { w: 1900 }), C("", { w: 1900 }), C("1.0", { w: 1900, center: true }) ] }),
]));

// ===== END CONTENT =====

// ---------------- DOC ----------------
const doc = new Document({
  styles: { default: { document: { run: { font: "Arial", size: 22 } } } },
  sections: [{
    properties: { page: { margin: { top: 1300, right: 1200, bottom: 1300, left: 1200 } } },
    children: [
      P([new TextRun({ text: "מסמכים", bold: true, size: 26 })], { after: 100 }),
      bullet("✓", META_DESC, { bold: true }),
      ...body,
    ],
  }],
});

Packer.toBuffer(doc).then(buf => {
  const out = path.join(process.cwd(), OUTNAME);   // נכתב לתיקיית העבודה הנוכחית
  fs.writeFileSync(out, buf);
  console.log("WROTE " + out);
});
