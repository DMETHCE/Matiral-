const fs = require("fs");
const path = require("path");
const {
  Document, Packer, Paragraph, TextRun, Table, TableRow, TableCell,
  AlignmentType, BorderStyle, WidthType, ShadingType, VerticalAlign,
  ImageRun, PageBreak, Header, Footer, PageNumber, HeadingLevel
} = require("docx");

const REF = __dirname;
const OUTNAME = "אפיון_טבלת_מעקב_מסלול_ירוק.docx";
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

const META_DESC = "טבלת /ILG/MM_GP_TRK שומרת תמונת מצב של מעקב המסלול הירוק / הבקרה המפצה לנקודת זמן. מסמך זה מפרט את מבנה הטבלה, את משמעותו העסקית של כל אחד משמונת הסטטוסים הלוגיים, ואת משמעותו ומקורו של כל שדה בטבלה.";

const body = [];

body.push(new Paragraph({ children: [new PageBreak()] }));
body.push(H("4", "תיאור טכני מפורט", 36));
body.push(H("4.2", "הקמת טבלת מעקב המסלול הירוק", 30));
body.push(tableOf([3200, 5826], [ new TableRow({ children: [
  C("/ILG/MM_GP_TRK", { w: 5826, mono: true, center: true }),
  C("שם הטבלה", { w: 3200, fill: GREY, bold: true }) ] }) ]));
body.push(spc(120));
body.push(bullet("❖", [new TextRun({ text: "טבלה מסוג ", bold: true }), tok("Transparent Table"),
  new TextRun({ text: " - לטובת שמירת תמונת המצב של סטי המסלול הירוק לנקודת זמן", bold: true })]));
body.push(bullet("✓", [new TextRun({ text: "מפתח הטבלה: " }), tok("MANDT + QMNUM"),
  new TextRun({ text: " - שורה אחת בדיוק לכל סט. הטבלה מוחלפת במלואה בכל ריצה של התוכנית " }),
  tok("/ILG/MM_GP_SNAP"), new TextRun({ text: " ." })]));
body.push(bullet("✓", [new TextRun({ text: "מאפיינים: " }), tok("Delivery Class = A"),
  new TextRun({ text: " · " }), tok("Data Class = APPL1"), new TextRun({ text: " · " }),
  tok("Size Category = 2"), new TextRun({ text: " · ללא Buffering · " }),
  tok("Display/Maintenance Allowed with Restrictions"), new TextRun({ text: " ." })]));
body.push(bullet("✓", "היקף התוכן: כל הרשומות הקיימות בטבלה /ILG/MM_GRPO_DET. סט שאינו מופיע שם אינו רלוונטי לדוח ואינו נרשם לטבלה.", {}));

body.push(H("4.2.1", "מבנה הטבלה :", 26));
body.push(bullet("✓", "שדות:", { bold: true }));
body.push(paramTbl(["שדה", "סוג שדה", "אורך", "מפתח", "תיאור קצר"], [
  ["MANDT", "MANDT", "3", "כן", "מנדנט"],
  ["QMNUM", "QMNUM", "12", "כן", "מספר סט (הודעה)"],
  ["LOGICAL_STATUS_C", "CHAR", "2", "", "קוד סטטוס לוגי"],
  ["LOGICAL_STATUS", "CHAR", "40", "", "סטטוס לוגי - טקסט"],
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
  ["AEDAT", "AEDAT", "8", "", "תאריך הטעינה"],
  ["AEZET", "AEZET", "6", "", "שעת הטעינה"],
]));
body.push(P("שמות השדות מוגבלים ל-16 תווים ( מכאן LOGICAL_STATUS_C ו- MBLNR_HANDLED_MA ). השדות הגנריים הוגדרו כ- Built-In Type ולא באמצעות אלמנט נתונים, כדי לאפשר תיאור עמודה ייעודי ב-SE16N ללא הקמת אלמנטי נתונים חדשים."));

body.push(H("5", "משמעות הסטטוס הלוגי:", 30));

body.push(H("5.1", "מקור הסטטוס - קודי הפעילות של הסט בטבלת QMMA, באופן הבא:", 24));
body.push(mapTbl("קוד פעילות ב QMMA-MNCOD", "המשמעות העסקית", [
  ["'50'", "הסט נדחה על ידי הדורש"],
  ["'60'", "הסט אושר"],
  ["'70'", "מסמך קבלת הטובין טופל ידנית"],
  ["'80'", "החשבונית טופלה ידנית"],
]));
body.push(P("נספרות אך ורק פעילויות בקבוצת הקודים MNGRP = 'ZPU' שלא סומנו למחיקה ( KZLOESCH ריק ). קוד שאינו קיים בסט שקול לערך ריק."));
body.push(spc());

body.push(H("5.2", "עקרון החישוב", 24));
body.push(P("הסטטוס נקבע על פי עץ החלטות - הענף הראשון שמתקיים קובע, ואין ענף נוסף אחריו. ההגדרות החוזרות בכל הענפים:"));
body.push(mapTbl("מונח", "ההגדרה הטכנית", [
  ["הסט אושר", "קיים קוד '60'"],
  ["הסט נדחה", "קיים קוד '50'"],
  ["בוטלה", "XREVERSED = 'X' בטבלת BKPF, או RBSTAT = '2' בטבלת RBKP"],
  ["הושלמו מסמכי המשך", "MBLNR וגם BELNR מלאים, וגם RBSTAT = '5'"],
  ["עיסוק ידני", "קיים קוד '70' או '80', או MM_GR_DOC_IND = '2' / '4'"],
]));
body.push(spc());

function status(num, code, title, cond, meaning, action) {
  body.push(H(num, "קוד " + code + " - " + title, 24));
  body.push(mapTbl("היבט", "התוכן", [
    ["התנאי", cond],
    ["המשמעות העסקית", meaning],
    ["הפעולה הנדרשת", action],
  ]));
  body.push(spc());
}

status("5.3", "'01'", "נדחה לאחר אישור ובוטל",
  "קיימים גם קוד '50' וגם קוד '60', והחשבונית בוטלה או שלא שולמה בפועל",
  "הסט אושר ולאחר מכן נדחה, והתהליך הכספי נעצר - לא בוצע תשלום לספק",
  "אין פעולה נדרשת. הרשומה נשמרת לתיעוד ולבקרה בלבד");

status("5.4", "'02'", "נדחה לאחר אישור ושולם",
  "קיימים גם קוד '50' וגם קוד '60', החשבונית לא בוטלה ושולמה בפועל",
  "חריג: הסט נדחה לאחר שאושר, ואף על פי כן בוצע תשלום לספק",
  "נדרשת בדיקה של גורם הבקרה - זהו הסטטוס החריג המרכזי בדוח");

status("5.5", "'03'", "נדחה לאחר אישור דורש",
  "קיים קוד '60' ללא קוד '50', והמסמך הפיננסי בוטל או שהחשבונית נמחקה",
  "הסט אושר, אך המסמך הכספי בוטל בדיעבד - ללא דחייה מצד הדורש",
  "יש לברר את סיבת הביטול המופיעה בשדה STGRD_TXT");

status("5.6", "'04'", "אושר והושלם לאחר עיסוק ידני",
  "קיים קוד '60', לא בוטל, הושלמו מסמכי המשך, וקיים סממן עיסוק ידני",
  "התהליך הושלם במלואו, אך נדרשה התערבות ידנית ולא רץ אוטומטית מקצה לקצה",
  "אין פעולה נדרשת. משמש כמדד לשיפור אוטומציית התהליך");

status("5.7", "'05'", "אושר והושלם ללא תקלה",
  "קיים קוד '60', לא בוטל, הושלמו מסמכי המשך, וללא סממן עיסוק ידני",
  "המצב הרצוי: הסט עבר את כל שלבי התהליך אוטומטית ובמלואם",
  "אין פעולה נדרשת");

status("5.8", "'06'", "נדחה על ידי דורש",
  "קיים קוד '50' בלבד, ללא קוד '60'",
  "הדורש דחה את הסט לפני שניתן אישור - לא נוצרו מסמכי המשך ולא בוצע תשלום",
  "אין פעולה נדרשת");

status("5.9", "'07'", "אושר - טרם הושלמו מסמכי המשך",
  "קיים קוד '60', לא בוטל, אך MBLNR או BELNR חסרים, או שהחשבונית אינה במצב 'נרשמה' ( RBSTAT שונה מ-'5' )",
  "הסט אושר והתהליך פתוח: ממתין לקבלת טובין, לחשבונית או לרישומה",
  "זהו סטטוס המעקב השוטף - יש לעקוב אחר הסטים שנותרו בו לאורך זמן");

status("5.10", "'99'", "בתהליך",
  "לא קיים קוד '50' ולא קוד '60'",
  "הסט טרם טופל - לא אושר ולא נדחה",
  "אין פעולה נדרשת בשלב זה");

body.push(H("6", "משמעות השדות:", 30));

body.push(H("6.1", "שדות המפתח, באופן הבא:", 24));
body.push(mapTbl("שם השדה", "המשמעות והמקור", [
  ["MANDT", "מנדנט - שדה מפתח טכני סטנדרטי"],
  ["QMNUM", "מספר הסט ( ההודעה ) - המפתח העסקי. מקור: /ILG/MM_GRPO_DET-QMNUM"],
]));
body.push(spc());

body.push(H("6.2", "שדות הסטטוס, באופן הבא:", 24));
body.push(mapTbl("שם השדה", "המשמעות והמקור", [
  ["LOGICAL_STATUS_C", "קוד הסטטוס הלוגי ( '01'-'07' , '99' ) - מיועד לסינון ולקיבוץ תוכניתי. מקור: עץ ההחלטות ( סעיף 5 )"],
  ["LOGICAL_STATUS", "אותו סטטוס כטקסט עברי, בניסוח האפיון העסקי - מיועד לתצוגה למשתמש"],
  ["IS_MONITOR", "'X' - הסט נמצא בבקרה ידנית. מקור: MONITOR_INDICATOR או EXTRA_VLUE_IND מלאים ב-/ILG/MM_GRPO_DET ( סט מדגמי או חשבונית מעל 10 אלש\"ח )"],
]));
body.push(P("שני שדות הסטטוס תמיד מאוכלסים - לכל סט יש בדיוק סטטוס אחד."));
body.push(spc());

body.push(H("6.3", "שדות מסמכי ההמשך, באופן הבא:", 24));
body.push(mapTbl("שם השדה", "המשמעות והמקור", [
  ["MBLNR", "מסמך קבלת הטובין. מקור: /ILG/MM_GRPO_DET-MBLNR. ריק - טרם נוצר"],
  ["MBLNR_HANDLED_MA", "'X' - מסמך הטובין נוצר ידנית. מקור: MM_GR_DOC_IND = '2' ( מסמך אחד לכל הכמות ) או '4' ( מספר מסמכים )"],
  ["BELNR_MM", "מספר החשבונית הלוגיסטית. מקור: /ILG/MM_GRPO_DET-BELNR. ריק - טרם נוצרה"],
  ["GJAHR_MM", "שנת הכספים של החשבונית הלוגיסטית - חלק ממפתח החשבונית"],
  ["RBSTAT", "מצב החשבונית מטבלת RBKP: '5' נרשמה · '2' נמחקה · ריק אין חשבונית"],
]));
body.push(P("שלושת השדות MBLNR , BELNR_MM ו- RBSTAT יחד קובעים האם 'הושלמו מסמכי המשך' - התנאי המבדיל בין סטטוס '07' לסטטוסים '04' ו-'05'."));
body.push(spc());

body.push(H("6.4", "שדות המסמך הפיננסי, באופן הבא:", 24));
body.push(mapTbl("שם השדה", "המשמעות והמקור", [
  ["BUKRS", "קוד החברה של המסמך הפיננסי. מקור: BKPF-BUKRS, מוצמד ל-BUKRS של החשבונית כדי למנוע כפילות ברישום חוצה-חברות"],
  ["BELNR_FI", "מספר המסמך הפיננסי שנוצר מהחשבונית. מקור: BKPF-BELNR לפי AWKEY + AWTYP = 'RMRP'"],
  ["GJAHR_FI", "שנת הכספים של המסמך הפיננסי - חלק ממפתח המסמך"],
]));
body.push(P("שלושת השדות ריקים כאשר לא נמצא מסמך פיננסי - כלומר טרם נרשמה חשבונית."));
body.push(spc());

body.push(H("6.5", "שדות התשלום, באופן הבא:", 24));
body.push(mapTbl("שם השדה", "המשמעות והמקור", [
  ["IS_PAID", "'X' - החשבונית שולמה בפועל. מקור: קיים סילוק לשורת הספק ב-ACDOCA"],
  ["AUGBL", "מסמך התשלום המסלק. מקור: ACDOCA-AUGBL, חייב להתחיל בספרה '2'"],
  ["AUGDT", "תאריך התשלום. מקור: ACDOCA-AUGDT"],
]));
body.push(P("סילוק שורת הספק על ידי מסמך סטורנו אינו נחשב תשלום - רק מסמך סילוק המתחיל בספרה 2. שדה IS_PAID הוא התנאי המבדיל בין סטטוס '01' לסטטוס '02'."));
body.push(spc());

body.push(H("6.6", "שדות הסטורנו, באופן הבא:", 24));
body.push(mapTbl("שם השדה", "המשמעות והמקור", [
  ["IS_REVERSED", "'X' - בוצע סטורנו למסמך הפיננסי. מקור: BKPF-XREVERSED"],
  ["STGRD", "קוד סיבת הביטול. מקור: BKPF-STGRD של מסמך הסטורנו, הנקרא לפי BUKRS + STBLG + STJAH של המסמך המקורי"],
  ["STGRD_TXT", "תיאור סיבת הביטול בשפת המשתמש. מקור: T041CT-TXT40"],
]));
body.push(P("שדות אלה מאוכלסים בערך ריק ולא ב-NULL כאשר לא בוצע סטורנו. מסמך הסטורנו אינו נקרא דרך AWREF_REV - שדה זה מאוכלס על מסמך הסטורנו ולא על המסמך המקורי."));
body.push(spc());

body.push(H("6.7", "שדות חותמת הטעינה, באופן הבא:", 24));
body.push(mapTbl("שם השדה", "המשמעות והמקור", [
  ["AEDAT", "תאריך הרצת תוכנית הטעינה. מקור: SY-DATUM בעת הריצה"],
  ["AEZET", "שעת הרצת תוכנית הטעינה. מקור: SY-UZEIT בעת הריצה"],
]));
body.push(P("שני השדות זהים בכל רשומות הטבלה, שכן הטבלה נכתבת במלואה בכל ריצה. הם מציינים את מועד צילום התמונה בלבד - ולא את מועד יצירת הסט או מועד ביצוע פעולה עסקית כלשהי. זו הסיבה ששדות אלה קיימים בטבלה בלבד ואינם חלק מה-View החי."));
body.push(spc(160));

body.push(new Paragraph({ bidirectional: true, alignment: AlignmentType.RIGHT, spacing: { before: 200, after: 200 },
  children: [new TextRun({ text: "סוף.", bold: true, size: 40, color: "000000" })] }));
body.push(P([new TextRun({ text: "היסטוריה של המסמך", bold: true, size: 30 })], { after: 160 }));
body.push(tableOf([3326, 1900, 1900, 1900], [
  new TableRow({ tableHeader: true, children: [
    C("תמצית העדכון", { w: 3326, fill: GREY, bold: true, center: true }),
    C("מבצע", { w: 1900, fill: GREY, bold: true, center: true }),
    C("תאריך", { w: 1900, fill: GREY, bold: true, center: true }),
    C("גירסה", { w: 1900, fill: GREY, bold: true, center: true }) ] }),
  new TableRow({ children: [ C("גרסה ראשונה", { w: 3326 }), C("", { w: 1900 }), C("03.09.2026", { w: 1900, center: true }), C("1.0", { w: 1900, center: true }) ] }),
]));

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
