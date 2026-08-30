const fs = require("fs");
const path = require("path");
const {
  Document, Packer, Paragraph, TextRun, Table, TableRow, TableCell,
  AlignmentType, BorderStyle, WidthType, ShadingType, VerticalAlign,
  ImageRun, PageBreak, Header, Footer, PageNumber, HeadingLevel
} = require("docx");

const REF = __dirname;
const OUTNAME = "אפיון_GREEN_TRACK.docx";
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

const META_DESC = "ה-View יציג בזמן אמת את תמונת המצב המלאה של כל סט מסמכים במסלול הירוק / בקרה מפצה: סטטוס לוגי לפי עץ ההחלטות העסקי, אינדיקטור בקרה ידנית, מצב החשבונית, סטורנו וסיבתו, ותשלום בפועל — ללא תוכנית Batch וללא טבלת יעד.";

const body = [];

// ===== 4. =====
body.push(new Paragraph({ children: [new PageBreak()] }));
body.push(H("4", "תיאור טכני מפורט", 36));
body.push(H("4.2", "יצירת CDS Views חדשים לטובת דוח הבקרה המפצה למסלול הירוק", 30));
body.push(tableOf([3200, 5826], [ new TableRow({ children: [
  C("/ILG/I_MM_Green_Track", { w: 5826, mono: true, center: true }),
  C("שם ה-View הראשי", { w: 3200, fill: GREY, bold: true }) ] }) ]));
body.push(spc(60));
body.push(tableOf([3200, 5826], [ new TableRow({ children: [
  C("/ILG/I_MM_Gp_Qmma_Status", { w: 5826, mono: true, center: true }),
  C("View עזר - קודי סטטוס", { w: 3200, fill: GREY, bold: true }) ] }) ]));
body.push(spc(60));
body.push(tableOf([3200, 5826], [ new TableRow({ children: [
  C("/ILG/I_MM_Gp_Clearing", { w: 5826, mono: true, center: true }),
  C("View עזר - תשלומים", { w: 3200, fill: GREY, bold: true }) ] }) ]));
body.push(spc(120));
body.push(bullet("❖", [new TextRun({ text: "אובייקט מסוג ", bold: true }), tok("CDS View Entity"),
  new TextRun({ text: " - לטובת מעקב חי אחר סטים במסלול הירוק (מחליף את התוכנית ואת טבלת היעד שתוכננו)", bold: true })]));

// 4.2.1 sources
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

// 4.2.2 output
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
  ["Aedat", "DATS", "8", "", "תאריך השאילתה (View חי)"],
]));

// ===== 5. =====
body.push(H("5", "מהלך ה-View:", 30));

body.push(H("5.1", "תחילה יש לאסוף עבור כל סט את קודי הסטטוס מטבלת QMMA (ב-View העזר /ILG/I_MM_Gp_Qmma_Status), באופן הבא:", 24));
body.push(mapTbl("שם שדה ב /ILG/I_MM_Gp_Qmma_Status", "אופן האכלוס", [
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

body.push(H("5.5", "בנוסף יש לבדוק האם החשבונית שולמה בפועל ( ב-View העזר /ILG/I_MM_Gp_Clearing מעל ACDOCA ), באופן הבא:", 24));
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
body.push(spc());

// ===== 6. =====
body.push(H("6", "לאחר מכן יש לאכלס את עמודות הפלט של ה-View.", 26));
body.push(H("6.1", "יש למלא את עמודות הפלט באופן הבא:", 24));
body.push(mapTbl("שם שדה ב /ILG/I_MM_Green_Track", "אופן האכלוס", [
  ["Qmnum", "/ILG/MM_GRPO_DET-QMNUM"],
  ["LogicalStatusCode", "תוצאת עץ ההחלטות ( 5.6 )"],
  ["LogicalStatus", "הטקסט העברי המקביל לקוד"],
  ["IsMonitor", "'X' במידה ו-MONITOR_INDICATOR או EXTRA_VLUE_IND מלאים"],
  ["MblnrHandledManually", "'X' במידה ו-MM_GR_DOC_IND = '2' או '4'"],
  ["Rbstat", "RBKP-RBSTAT"],
  ["IsPaid / Augbl / Augdt", "תוצאת בדיקת התשלום ( 5.5 )"],
  ["IsReversed / Stgrd / StgrdTxt", "תוצאת בדיקת הסטורנו ( 5.4 ); ריק ולא NULL"],
  ["Aedat", "תאריך המערכת בעת השאילתה"],
]));
body.push(spc());
body.push(H("6.2", "יש לוודא שה-View מחזיר בדיוק שורה אחת לכל סט ( QMNUM ) ולהחזיר את התוצאה למשתמש.", 24));
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
  new TableRow({ children: [ C("גרסה ראשונה", { w: 3326 }), C("", { w: 1900 }), C("30.08.2026", { w: 1900, center: true }), C("1.0", { w: 1900, center: true }) ] }),
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
  const out = path.join(process.cwd(), OUTNAME);
  fs.writeFileSync(out, buf);
  console.log("WROTE " + out);
});
