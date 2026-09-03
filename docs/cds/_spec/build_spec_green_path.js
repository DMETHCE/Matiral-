const fs = require("fs");
const path = require("path");
const {
  Document, Packer, Paragraph, TextRun, Table, TableRow, TableCell,
  AlignmentType, BorderStyle, WidthType, ShadingType, VerticalAlign,
  ImageRun, PageBreak, Header, Footer, PageNumber, HeadingLevel
} = require("docx");

const REF = __dirname;
const OUTNAME = "אפיון_מסלול_ירוק.docx";
const CW = 9026;
const GREY = "D9D9D9", BLUE = "1F3864";
const LRM = "‎";

const bd = { style: BorderStyle.SINGLE, size: 4, color: "000000" };
const B = { top: bd, bottom: bd, left: bd, right: bd };

function hasHeb(s) { return /[֐-׿]/.test(s); }

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
    C(r[1], { w: W[2], mono: !hasHeb(r[1]) }),
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

// ===== CONTENT — EDIT PER SPEC =====

const META_DESC = "מעקב מסלול ירוק / בקרה מפצה: שלושה CDS Views המחשבים בזמן אמת את הסטטוס הלוגי של כל סט מסמכים, טבלת תמונת מצב לשמירת התוצאה, ותוכנית טעינה המרעננת את הטבלה. המערך מחליף את התוכנית ZMM_PROCESS_GREEN_PATH.";

const body = [];

// ===================== 4. תיאור טכני =====================
body.push(new Paragraph({ children: [new PageBreak()] }));
body.push(H("4", "תיאור טכני מפורט", 36));

body.push(H("4.2", "יצירת CDS Views חדשים לטובת דוח הבקרה המפצה למסלול הירוק", 30));
body.push(tableOf([3200, 5826], [ new TableRow({ children: [
  C("/ILG/IMMGreenTrack", { w: 5826, mono: true, center: true }),
  C("שם ה-View הראשי", { w: 3200, fill: GREY, bold: true }) ] }) ]));
body.push(spc(60));
body.push(tableOf([3200, 5826], [ new TableRow({ children: [
  C("/ILG/IMMGpQmmaStatus", { w: 5826, mono: true, center: true }),
  C("View עזר - קודי סטטוס", { w: 3200, fill: GREY, bold: true }) ] }) ]));
body.push(spc(60));
body.push(tableOf([3200, 5826], [ new TableRow({ children: [
  C("/ILG/IMMGpClearing", { w: 5826, mono: true, center: true }),
  C("View עזר - תשלומים", { w: 3200, fill: GREY, bold: true }) ] }) ]));
body.push(spc(120));
body.push(bullet("❖", [new TextRun({ text: "אובייקטים מסוג ", bold: true }), tok("CDS View Entity"),
  new TextRun({ text: " - לטובת חישוב חי של הסטטוס הלוגי של כל סט במסלול הירוק", bold: true })]));

body.push(H("4.2.1", "מקורות הנתונים של ה-View :", 26));
body.push(bullet("✓", "טבלאות / Views :", { bold: true }));
body.push(paramTbl(["מקור", "קישור", "אורך", "חובה", "תיאור"], [
  ["/ILG/MM_GRPO_DET", "בסיס", "", "כן", "טבלת המסלול הירוק - שורה אחת לכל סט (QMNUM)"],
  ["QMMA", "QMNUM", "", "לא", "קודי הסטטוס של הסט (50/60/70/80) בקבוצה ZPU, דרך ה-View העזר"],
  ["RBKP", "BELNR + GJAHR", "", "לא", "מצב החשבונית הלוגיסטית (RBSTAT: 5=נרשמה, 2=נמחקה)"],
  ["BKPF", "AWKEY + AWTYP + BUKRS", "", "לא", "המסמך הפיננסי של החשבונית ומסמך הסטורנו שלו"],
  ["T041CT", "STGRD + SPRAS", "", "לא", "טקסט סיבת הסטורנו בשפת המשתמש (TXT40)"],
  ["ACDOCA", "RBUKRS + BELNR + GJAHR", "", "לא", "סילוק שורת הספק - בדיקת תשלום בפועל, דרך ה-View העזר"],
]));
body.push(P("כלל קובע: ה-View מחזיר את כל הרשומות הקיימות בטבלה /ILG/MM_GRPO_DET - סט שאינו מופיע בה אינו רלוונטי לדוח. כל שאר החיבורים הם LEFT OUTER JOIN ולכן אינם מסננים שורות."));

body.push(H("4.2.2", "מבנה הפלט של ה-View :", 26));
body.push(bullet("✓", "עמודות:", { bold: true }));
body.push(paramTbl(["שדה", "סוג שדה", "אורך", "חובה", "תיאור"], [
  ["Qmnum", "QMNUM", "12", "מפתח", "מספר הסט (הודעה)"],
  ["LogicalStatusCode", "CHAR", "2", "", "קוד הסטטוס הלוגי (01-07, 99) - לסינון תוכניתי"],
  ["LogicalStatus", "CHAR", "40", "", "הסטטוס הלוגי בעברית כניסוח האפיון העסקי"],
  ["IsMonitor", "CHAR", "1", "", "'X' - הסט בבקרה ידנית (סט 10 או חשבונית מעל 10 אלש\"ח)"],
  ["Mblnr", "MBLNR", "10", "", "מסמך קבלת הטובין"],
  ["MblnrHandledManually", "CHAR", "1", "", "'X' - הטובין נוצר ידנית (MM_GR_DOC_IND = 2 או 4)"],
  ["BelnrMm", "RE_BELNR", "10", "", "מספר החשבונית הלוגיסטית"],
  ["GjahrMm", "GJAHR", "4", "", "שנת כספים של החשבונית הלוגיסטית"],
  ["Rbstat", "RBSTAT", "1", "", "מצב החשבונית (5=נרשמה, 2=נמחקה, ריק=אין חשבונית)"],
  ["Bukrs", "BUKRS", "4", "", "קוד חברה של המסמך הפיננסי"],
  ["BelnrFi", "BELNR_D", "10", "", "מספר המסמך הפיננסי"],
  ["GjahrFi", "GJAHR", "4", "", "שנת כספים של המסמך הפיננסי"],
  ["IsPaid", "CHAR", "1", "", "'X' - החשבונית שולמה בפועל (אינדיקטור רוחבי, החלטת דיון 4/8)"],
  ["Augbl", "AUGBL", "10", "", "מסמך התשלום (מתחיל ב-2)"],
  ["Augdt", "AUGDT", "8", "", "תאריך התשלום"],
  ["IsReversed", "CHAR", "1", "", "'X' - בוצע סטורנו למסמך הפיננסי"],
  ["Stgrd", "STGRD", "2", "", "קוד סיבת הסטורנו (מעמודה רוחבית, החלטת דיון 4/8)"],
  ["StgrdTxt", "TXT40", "40", "", "טקסט סיבת הסטורנו בשפת המשתמש"],
]));
body.push(P("ה-View אינו כולל עמודת תאריך. חותמת מועד הטעינה נשמרת אך ורק בטבלת תמונת המצב ( סעיף 4.3 ), שכן ל-View החי אין מועד עדכון."));

// ===================== 4.3 הטבלה =====================
body.push(H("4.3", "הקמת טבלת תמונת המצב", 30));
body.push(tableOf([3200, 5826], [ new TableRow({ children: [
  C("/ILG/MM_GP_TRK", { w: 5826, mono: true, center: true }),
  C("שם הטבלה החדשה", { w: 3200, fill: GREY, bold: true }) ] }) ]));
body.push(spc(120));
body.push(bullet("❖", [new TextRun({ text: "טבלה מסוג ", bold: true }), tok("Transparent Table"),
  new TextRun({ text: " - לטובת שמירת תמונת המצב של ה-View לנקודת זמן, לצורכי דוחות והשוואה", bold: true })]));
body.push(bullet("✓", [new TextRun({ text: "מאפיינים: " }), tok("Delivery Class = A"),
  new TextRun({ text: " · " }), tok("Data Class = APPL1"), new TextRun({ text: " · " }),
  tok("Size Category = 2"), new TextRun({ text: " · ללא Buffering ( הנתונים מוחלפים בכל ריצה )." })]));
body.push(bullet("✓", "מפתח הטבלה: MANDT + QMNUM - שורה אחת בדיוק לכל סט.", {}));

body.push(H("4.3.1", "מבנה הטבלה :", 26));
body.push(bullet("✓", "שדות:", { bold: true }));
body.push(paramTbl(["שדה", "סוג שדה", "אורך", "חובה", "תיאור"], [
  ["MANDT", "MANDT", "3", "מפתח", "מנדנט"],
  ["QMNUM", "QMNUM", "12", "מפתח", "מספר סט (הודעה)"],
  ["LOGICAL_STATUS_C", "CHAR", "2", "", "קוד סטטוס לוגי (01-07, 99)"],
  ["LOGICAL_STATUS", "CHAR", "40", "", "סטטוס לוגי"],
  ["IS_MONITOR", "CHAR", "1", "", "בקרה ידנית"],
  ["MBLNR", "MBLNR", "10", "", "מסמך קבלת טובין"],
  ["MBLNR_HANDLED_MA", "CHAR", "1", "", "טובין נוצר ידנית"],
  ["BELNR_MM", "RE_BELNR", "10", "", "חשבונית לוגיסטית"],
  ["GJAHR_MM", "GJAHR", "4", "", "שנת כספים - חשבונית"],
  ["RBSTAT", "RBSTAT", "1", "", "מצב חשבונית"],
  ["BUKRS", "BUKRS", "4", "", "קוד חברה"],
  ["BELNR_FI", "BELNR_D", "10", "", "מסמך פיננסי"],
  ["GJAHR_FI", "GJAHR", "4", "", "שנת כספים - פיננסי"],
  ["IS_PAID", "CHAR", "1", "", "שולם בפועל"],
  ["AUGBL", "AUGBL", "10", "", "מסמך תשלום"],
  ["AUGDT", "AUGDT", "8", "", "תאריך תשלום"],
  ["IS_REVERSED", "CHAR", "1", "", "בוצע סטורנו"],
  ["STGRD", "STGRD", "2", "", "סיבת סטורנו"],
  ["STGRD_TXT", "CHAR", "40", "", "תיאור סיבת סטורנו"],
  ["AEDAT", "AEDAT", "8", "", "תאריך הטעינה לטבלה"],
  ["AEZET", "AEZET", "6", "", "שעת הטעינה לטבלה"],
]));
body.push(P("שמות השדות מוגבלים ל-16 תווים ( LOGICAL_STATUS_C , MBLNR_HANDLED_MA ). השדות הגנריים הוגדרו כ- Built-In Type ולא באמצעות אלמנט נתונים, כדי לאפשר תיאור עמודה ייעודי ב-SE16N ללא הקמת אלמנטים חדשים."));
body.push(P("סדר השדות זהה לסדר עמודות ה-View, בתוספת שני שדות החותמת בסוף."));

// ===================== 4.4 התוכנית =====================
body.push(H("4.4", "יצירת תוכנית הטעינה", 30));
body.push(tableOf([3200, 5826], [ new TableRow({ children: [
  C("/ILG/MM_GP_SNAP", { w: 5826, mono: true, center: true }),
  C("שם התוכנית החדשה", { w: 3200, fill: GREY, bold: true }) ] }) ]));
body.push(spc(120));
body.push(bullet("❖", [new TextRun({ text: "תוכנית מסוג ", bold: true }), tok("Executable Report"),
  new TextRun({ text: " - לטובת רענון תמונת המצב בטבלה מתוך ה-View, לריצה ידנית או בעבודת רקע", bold: true })]));
body.push(bullet("✓", [new TextRun({ text: "מבנה: " }), tok("/ILG/MM_GP_SNAP_DAT"),
  new TextRun({ text: " הצהרות · " }), tok("/ILG/MM_GP_SNAP_SEL"),
  new TextRun({ text: " מסך בחירה · " }), tok("/ILG/MM_GP_SNAP_F01"),
  new TextRun({ text: " לוגיקה. אירוע " }), tok("START-OF-SELECTION"),
  new TextRun({ text: " מכיל שתי קריאות בלבד." })]));

body.push(H("4.4.1", "מסך הבחירה של התוכנית :", 26));
body.push(bullet("✓", "פרמטרים:", { bold: true }));
body.push(paramTbl(["פרמטר", "סוג / אלמנט נתונים", "אורך", "חובה", "תיאור"], [
  ["CB_TEST", "CHECKBOX", "1", "לא", "הרצת בדיקה - מציגה את מספר הרשומות שיישלפו ללא שינוי בטבלה"],
]));
body.push(P("מסך הבחירה אינו כולל פרמטרים נוספים - התוכנית תמיד מרעננת את כלל הרשומות."));

// ===================== 5. מהלך ה-View =====================
body.push(H("5", "מהלך ה-View:", 30));

body.push(H("5.1", "תחילה יש לאסוף עבור כל סט את קודי הסטטוס מטבלת QMMA ( ב-View העזר /ILG/IMMGpQmmaStatus ), באופן הבא:", 24));
body.push(mapTbl("שם שדה ב /ILG/IMMGpQmmaStatus", "אופן האכלוס", [
  ["Qmnum", "QMMA-QMNUM"],
  ["Has50", "'X' במידה וקיימת שורה עם MNCOD = '50'"],
  ["Has60", "'X' במידה וקיימת שורה עם MNCOD = '60'"],
  ["Has70", "'X' במידה וקיימת שורה עם MNCOD = '70'"],
  ["Has80", "'X' במידה וקיימת שורה עם MNCOD = '80'"],
]));
body.push(P("יש לכלול רק שורות בקבוצת הקודים MNGRP = 'ZPU' ושלא סומנו למחיקה ( KZLOESCH ריק )."));
body.push(spc());

body.push(H("5.2", "לאחר מכן יש לקרוא את מצב החשבונית הלוגיסטית מטבלת RBKP, באופן הבא:", 24));
body.push(mapTbl("שם שדה ב RBKP", "אופן האכלוס", [
  ["BELNR", "/ILG/MM_GRPO_DET-BELNR"],
  ["GJAHR", "/ILG/MM_GRPO_DET-GJAHR"],
]));
body.push(P("יש לשלוף את השדות BUKRS ו-RBSTAT. במידה ואין לסט חשבונית ( BELNR ריק ) - הקריאה אינה מתבצעת."));
body.push(spc());

body.push(H("5.3", "לאחר מכן יש לאתר את המסמך הפיננסי של החשבונית בטבלת BKPF, באופן הבא:", 24));
body.push(mapTbl("שם שדה ב BKPF", "אופן האכלוס", [
  ["AWKEY", "שרשור BELNR + GJAHR מתוך /ILG/MM_GRPO_DET"],
  ["AWTYP", "'RMRP'"],
  ["BUKRS", "RBKP-BUKRS"],
]));
body.push(P("הצמדת קוד החברה של החשבונית ( RBKP-BUKRS ) מונעת כפילות שורות ברישום חוצה-חברות - AWKEY אינו ייחודי."));
body.push(spc());

body.push(H("5.4", "יש לבדוק האם בוצע סטורנו למסמך הפיננסי ( XREVERSED = 'X' ). במידה וכן, יש לקרוא את מסמך הסטורנו מטבלת BKPF לפי המפתח המלא ולשלוף את סיבת הביטול, באופן הבא:", 24));
body.push(mapTbl("שם שדה ב BKPF ( מסמך הסטורנו )", "אופן האכלוס", [
  ["BUKRS", "BKPF-BUKRS ( המסמך המקורי )"],
  ["BELNR", "BKPF-STBLG ( המסמך המקורי )"],
  ["GJAHR", "BKPF-STJAH ( המסמך המקורי )"],
]));
body.push(P("אין לאתר את מסמך הסטורנו דרך AWREF_REV - שדה זה מאוכלס על מסמך הסטורנו ולא על המקור. את קוד הסיבה ( STGRD ) יש לתרגם לטקסט מטבלת T041CT ( TXT40 ) בשפת המשתמש."));
body.push(spc());

body.push(H("5.5", "בנוסף יש לבדוק האם החשבונית שולמה בפועל ( ב-View העזר /ILG/IMMGpClearing מעל ACDOCA ), באופן הבא:", 24));
body.push(mapTbl("שם שדה ב ACDOCA", "אופן האכלוס", [
  ["RLDNR", "'0L' ( ledger מוביל )"],
  ["RBUKRS", "BKPF-BUKRS"],
  ["BELNR", "BKPF-BELNR"],
  ["GJAHR", "BKPF-GJAHR"],
  ["KOART", "'K' ( שורת ספק )"],
  ["AUGBL", "מלא ומתחיל ב-'2' ( מסמך תשלום )"],
]));
body.push(P("סילוק של מסמך סטורנו אינו נחשב תשלום - רק מסמך סילוק המתחיל בספרה 2. במידה ונמצא - IsPaid = 'X' והשדות Augbl / Augdt מאוכלסים."));
body.push(spc());

body.push(H("5.6", "בסיום יש לחשב את הסטטוס הלוגי של הסט לפי עץ ההחלטות - הענף הראשון שמתקיים קובע - באופן הבא:", 24));
body.push(mapTbl("LogicalStatusCode", "התנאי ( בוטלה = XREVERSED='X' או RBSTAT='2' )", [
  ["'01'", "Has50 וגם Has60, וגם ( בוטלה או לא שולם ) - נדחה לאחר אישור ובוטל"],
  ["'02'", "Has50 וגם Has60, שולם ולא בוטלה - נדחה לאחר אישור ושולם"],
  ["'03'", "Has60 ( ללא Has50 ) וגם בוטלה - נדחה לאחר אישור דורש"],
  ["'04'", "Has60, לא בוטלה, MBLNR + BELNR מלאים וגם RBSTAT='5', וגם ( Has70 או Has80 או MM_GR_DOC_IND = 2/4 ) - אושר והושלם לאחר עיסוק ידני"],
  ["'05'", "כנ\"ל ללא סממני עיסוק ידני - אושר והושלם ללא תקלה"],
  ["'07'", "Has60, לא בוטלה, אך מסמכי ההמשך חסרים או שהחשבונית אינה במצב 'נרשמה' - אושר, טרם הושלמו מסמכי המשך"],
  ["'06'", "Has50 בלבד - נדחה על ידי דורש"],
  ["'99'", "אף קוד לא קיים - בתהליך"],
]));
body.push(P("ה-View מחזיר שורה אחת בדיוק לכל סט ( QMNUM )."));
body.push(spc());

// ===================== 6. מהלך התוכנית =====================
body.push(H("6", "מהלך תוכנית הטעינה:", 30));

body.push(H("6.1", "תחילה יש לבדוק את הרשאת המשתמש לעדכון טבלת היעד, באופן הבא:", 24));
body.push(mapTbl("שם הפרמטר ב AUTHORITY-CHECK", "אופן האכלוס", [
  ["OBJECT", "'S_TABU_NAM'"],
  ["TABLE", "'/ILG/MM_GP_TRK'"],
  ["ACTVT", "'02' ( שינוי )"],
]));
body.push(P("במידה והבדיקה נכשלת ( SY-SUBRC שונה מאפס ) - יש להנפיק הודעת שגיאה מסוג E ולסיים את התוכנית."));
body.push(spc());

body.push(H("6.2", "לאחר מכן יש לשלוף את כל הרשומות מה-View /ILG/IMMGreenTrack לטבלה הפנימית GT_TRK, באופן הבא:", 24));
body.push(mapTbl("שם שדה ב /ILG/MM_GP_TRK", "אופן האכלוס", [
  ["QMNUM", "Qmnum"],
  ["LOGICAL_STATUS_C", "LogicalStatusCode"],
  ["LOGICAL_STATUS", "LogicalStatus"],
  ["IS_MONITOR", "IsMonitor"],
  ["MBLNR", "Mblnr"],
  ["MBLNR_HANDLED_MA", "MblnrHandledManually"],
  ["BELNR_MM", "BelnrMm"],
  ["GJAHR_MM", "GjahrMm"],
  ["RBSTAT", "Rbstat"],
  ["BUKRS", "Bukrs"],
  ["BELNR_FI", "BelnrFi"],
  ["GJAHR_FI", "GjahrFi"],
  ["IS_PAID", "IsPaid"],
  ["AUGBL", "Augbl"],
  ["AUGDT", "Augdt"],
  ["IS_REVERSED", "IsReversed"],
  ["STGRD", "Stgrd"],
  ["STGRD_TXT", "StgrdTxt"],
]));
body.push(P("השליפה מתבצעת עם כינוי ( AS ) לכל עמודה, כך שהכינוי יהיה זהה לשם השדה בטבלה. שם כינוי שאינו זהה גורם לכך שהעמודה אינה מתמלאת. הטבלה נשלפת ממוינת לפי QMNUM."));
body.push(spc());

body.push(H("6.3", "בנוסף עבור כל שורה בטבלה הפנימית יש לייצר את חותמת מועד הטעינה, באופן הבא:", 24));
body.push(mapTbl("שם שדה ב /ILG/MM_GP_TRK", "אופן האכלוס", [
  ["AEDAT", "SY-DATUM"],
  ["AEZET", "SY-UZEIT"],
]));
body.push(P("החותמת מייצגת את מועד הרצת התוכנית ולא את מועד יצירת הסט - זו הסיבה שהיא אינה קיימת ב-View."));
body.push(spc());

body.push(H("6.4", "יש לבדוק האם סומנה תיבת הרצת הבדיקה ( CB_TEST ).", 24));
body.push(P("במידה וכן - יש להציג את מספר הרשומות שנשלפו ולסיים, ללא כל שינוי בטבלה."));
body.push(P("במידה ולא - יש למחוק את כל הרשומות הקיימות בטבלה ולרשום את התמונה החדשה, באופן הבא:"));
body.push(mapTbl("פעולה בטבלה /ILG/MM_GP_TRK", "אופן האכלוס", [
  ["DELETE", "כל הרשומות ( תנאי QMNUM אינו ריק - המפתח לעולם מלא )"],
  ["MODIFY FROM TABLE", "GT_TRK"],
]));
body.push(P("המחיקה והרישום מהווים יחידה לוגית אחת: בסיום מוצלח ( SY-SUBRC אפס ) יש לבצע COMMIT WORK AND WAIT יחיד, ובכשלון ROLLBACK WORK - כדי שלא תיווצר טבלה ריקה או חלקית."));
body.push(spc());

body.push(H("6.5", "בסיום יש להציג למשתמש את תוצאת הריצה, באופן הבא:", 24));
body.push(mapTbl("סמל טקסט", "אופן האכלוס", [
  ["TEXT-011", "הודעת הצלחה, כולל מספר הרשומות שנרשמו"],
  ["TEXT-012", "הודעת כשלון בעת רישום לטבלה"],
  ["TEXT-013", "הודעת הרצת בדיקה, כולל מספר הרשומות שנשלפו"],
  ["TEXT-014", "הודעת חוסר הרשאה"],
]));
body.push(P("יש לסיים את התוכנית ולהחזיר את הודעת הסיכום למשתמש."));
body.push(spc(160));

// סוף + היסטוריה
body.push(new Paragraph({ bidirectional: true, alignment: AlignmentType.RIGHT, spacing: { before: 200, after: 200 },
  children: [new TextRun({ text: "סוף.", bold: true, size: 40, color: "000000" })] }));
body.push(P([new TextRun({ text: "היסטוריה של המסמך", bold: true, size: 30 })], { after: 160 }));
body.push(tableOf([3326, 1900, 1900, 1900], [
  new TableRow({ tableHeader: true, children: [
    C("תמצית העדכון", { w: 3326, fill: GREY, bold: true, center: true }),
    C("מבצע", { w: 1900, fill: GREY, bold: true, center: true }),
    C("תאריך", { w: 1900, fill: GREY, bold: true, center: true }),
    C("גירסה", { w: 1900, fill: GREY, bold: true, center: true }) ] }),
  new TableRow({ children: [ C("גרסה ראשונה - שלושת ה-Views", { w: 3326 }), C("", { w: 1900 }), C("30.08.2026", { w: 1900, center: true }), C("1.0", { w: 1900, center: true }) ] }),
  new TableRow({ children: [ C("הוספת טבלת תמונת המצב ותוכנית הטעינה; ביטול עמודת התאריך ב-View", { w: 3326 }), C("", { w: 1900 }), C("03.09.2026", { w: 1900, center: true }), C("2.0", { w: 1900, center: true }) ] }),
]));

// ===== END CONTENT =====

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
  const out = path.join(__dirname, OUTNAME);
  fs.writeFileSync(out, buf);
  console.log("WROTE " + out);
});
