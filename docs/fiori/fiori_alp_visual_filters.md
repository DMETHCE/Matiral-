# סרגל סינון חזותי (Visual Filter Bar) ב-ALP

מדריך מאומת מול קוד המקור של `sap.suite.ui.generic.template` 1.136.1
ומול תיעוד SAP הרשמי (SAPUI5 → SAP Fiori Elements → Analytical List Page →
Configuring the Visual Filter Bar / Visual Filters, גרסת OData V2).

---

## מה זה בעצם

בתמונה של SAP יש **שתי שכבות שונות** בראש המסך:

| שכבה | מה זה | מה יש לנו |
|---|---|---|
| השורה העליונה (`RBQ 98.0M`, `PBK 162,711%`) | **KPI Tags** — מספרים בלבד | ✅ יש (467, 8.0, 57.0, 12.0, 131) |
| השורה שמתחת — תרשימי מיני | **Visual Filter Bar** | ❌ חסר — זה מה שנוסיף |

הפילטר החזותי מחליף את שדות הטקסט של סרגל הסינון בתרשימים קטנים אינטראקטיביים.
לחיצה על עמודה/פרוסה = בחירת ערך הסינון. הערכים מסונכרנים אוטומטית עם המצב
ה"קומפקטי" (שדות הטקסט), ואפשר לעבור בין שני המצבים בכפתור.

---

## מה זה דורש — שלושה חלקים לכל פילטר

```
Common.ValueList#<Q>  על השדה      ← המתג שמפעיל את הכל
        │  PresentationVariantQualifier = <Q>
        ▼
UI.PresentationVariant#<Q>          ← SortOrder + הפניה לתרשים
        │  Visualizations → @UI.Chart#<Q>
        ▼
UI.Chart#<Q>                        ← ChartType + Dimension + Measure
```

הטריגר היחיד (`VisualFilterProvider.js:505`): שדה שיש עליו annotation שהמונח שלו
מכיל `com.sap.vocabularies.Common.v1.ValueList` **וגם** יש ברשומה
`PresentationVariantQualifier`. אין שום דגל ב-manifest שיוצר את הסרגל.

---

## דרישת הסף הקשיחה

`VisualFilterProvider.js:1109`:

> The dimension … or the measure … or both have NO 'sap:aggregation-role'
> defined in metadata. Corresponding chart cannot be displayed as VisualFilter.

כלומר ה-EntitySet ש-`CollectionPath` מצביע עליו **חייב להיות אנליטי** — המימד עם
`sap:aggregation-role="dimension"` והמדד עם `="measure"`.

- ✅ אצלנו: `xILGxIMMGREENALP` (מ-`@Analytics.query: true`) עומד בזה.
- ❌ ה-Views המסכמים של ה-OVP (`AggStat` וכו') **לא** מתאימים כאן — הם על שירות
  SADL רגיל בלי aggregation-role.

לכן `CollectionPath` מצביע על ה-EntitySet של ה-ALP עצמו — בדיוק כמו באפליקציית
הדגם של SAP (`SEPMRA_C_ALP_SlsOrdItemCubeALPResults`).

---

## למה זה יעבוד אצלנו למרות שה-OVP נכשל

הפילטר החזותי קורא נתונים ב-`model.read()` פשוט עם `$select` + `$top` בלבד,
**בלי `$inlinecount`** (`FilterItemMicroChart.js:635-640`).
כרטיסי ה-OVP נכשלו כי כרטיס הדונאט כפה `$inlinecount=allpages` על המודל המשותף
(`VizAnnotationManager.js:102-104`), וזה מה שהשירות האנליטי לא בולע.

---

## מגבלות שחשוב לדעת מראש

| נושא | המגבלה |
|---|---|
| סוגי תרשים | **Bar / Donut / Line בלבד**. `#COLUMN` נופל בשקט ל-Bar |
| כמות רשומות | Bar = 3 העליונות, Donut = 2 + "אחרים", Line = 6 נקודות |
| שדות טווח | פילטר מסוג `interval` לעולם לא יהפוך לחזותי |
| תאריכים סמנטיים | לא נתמכים (Semantic dates / date ranges) |
| מדדים | מדד אחד לכל מימד. אותו מימד עם שני מדדים = לא, זה תפקידו של OVP |
| יחידות מידה | אם השרת מחזיר יותר מיחידת מידה אחת התרשים לא יוצג כלל |

---

## מה בוצע במאגר

**`src/fiori/greeninvalp/annotation.xml`** — נוספו:

| Qualifier | שדה | סוג תרשים | מימד | מדד |
|---|---|---|---|---|
| `VFStat` | `LogicalStatusCode` | Bar | LogicalStatusCode | SetsCount |
| `VFComp` | `Bukrs` | Donut | Bukrs | SetsCount |
| `VFYear` | `GjahrMm` | Bar | GjahrMm | SetsCount |

לכל אחד: `UI.Chart#<Q>` + `UI.PresentationVariant#<Q>` (מיון לפי SetsCount יורד)
+ `Common.ValueList#<Q>` על השדה, עם `ValueListParameterInOut` שממפה את השדה
לעצמו (זה מה שהופך את הלחיצה בתרשים לסינון בפועל — `VisualFilterProvider.js:907`).

**`src/fiori/greeninvalp/manifest.json`** — נוספו תחת הגדרות הדף:

```json
"defaultFilterMode": "visual",
"lazyLoadVisualFilter": false,
```

(`defaultFilterMode` הוא ממילא ברירת המחדל; מפורש = ברור יותר.
`lazyLoadVisualFilter: false` טוען את התרשימים מיד ולא רק במעבר למצב חזותי.)

שאר הפילטרים שאין להם הגדרה חזותית (מספר סט, בקרה ידנית, שולם) ממשיכים להופיע
כשדות רגילים במצב הקומפקטי — זו התנהגות תקנית.

---

## הפעלה

1. להחליף ב-BAS את `webapp/annotations/annotation.xml` ואת `webapp/manifest.json`
   בגרסאות מהמאגר (העתקה דרך **Raw** בלבד).
2. Preview Application.
3. הצפוי: מתחת לתגיות ה-KPI מופיעה שורת תרשימים — עמודות אופקיות לפי סטטוס,
   דונאט לפי חברה, עמודות לפי שנה. לחיצה על עמודה מסננת את הטבלה והתרשים הראשי.

**אין שינוי ב-CDS ואין צורך להפעיל מחדש את השירות** — הכל ב-annotations המקומיים.

---

## אבחון תקלות

| מה רואים | הסיבה | הפתרון |
|---|---|---|
| הסרגל לא מופיע כלל | ה-ValueList בלי `PresentationVariantQualifier` | לבדוק את הקובץ שהודבק |
| בקונסול: `have NO 'sap:aggregation-role'` | ה-`CollectionPath` מצביע על EntitySet לא אנליטי | לוודא `xILGxIMMGREENALP` |
| תרשים בודד חסר | השדה מוגדר כ-interval או `sap:filterable="false"` | להוסיף `@Consumption.filter: { selectionType: #SINGLE, multipleSelections: true }` לשדה ב-CDS |
| התרשים מוצג אבל לחיצה לא מסננת | חסר `ValueListParameterInOut` תואם | LocalDataProperty = השדה, ValueListProperty = המימד |
| Column הפך ל-Bar | `#COLUMN` לא נתמך | להשתמש ב-Bar / Donut / Line |

---

## מקורות

- SAPUI5 Documentation → SAP Fiori Elements → Analytical List Page (OData V2)
  `analytical-list-page-ff056b4`, `configuring-the-visual-filter-bar-b44fe77`,
  `visual-filters-5ea9bb1`, `enhancing-valuelist-annotations-for-visual-filters-bcfc085`,
  `configuring-the-manifest-for-the-analytical-list-page-c4ebbae`
  (מאגר `SAP-docs/sapui5`).
- קוד מקור `@sapui5/sap.suite.ui.generic.template` 1.136.1:
  `AnalyticalListPage/control/visualfilterbar/VisualFilterProvider.js`,
  `FilterItemMicroChart.js`, `SmartVisualFilterBar.js`,
  `AnalyticalListPage/Component.js`, `controller/ControllerImplementation.js`.

---

# נספח: למה הטקסט ב-KPI כל כך קטן, ולמה הוא לא מנתב לרשומות

## 1. הטקסט על התגית תמיד מקוצר — זו התנהגות מובנית

`SmartKpiTag.js:967-982` מקצר כל כותרת דרך היוריסטיקה:

| מבנה הכותרת | מה מוצג |
|---|---|
| מילה אחת | 3 האותיות הראשונות (`word.substr(0,3).toUpperCase()`) |
| שתי מילים | אות ראשונה של כל מילה |
| שלוש מילים ומעלה | אות ראשונה של שלוש המילים הראשונות |

לכן `'סה"כ סטים'` הפך ל-**סה**, ו-`'ממתינים למסמכים'` הפך ל-**ממ**.
אי אפשר להציג כותרת מלאה על התגית — לא דרך `@UI.dataPoint.title`, ולא דרך
`ShortDescription` ב-`UI.KPI` (גם היא עוברת את אותה היוריסטיקה).

**מה כן אפשר לשלוט בו:** אם נותנים `shortDescription` של **מילה אחת** ב-
`manifest.json`, היוריסטיקה מחזירה את 3 האותיות הראשונות שלה — כלומר אנחנו
בוחרים אילו אותיות יופיעו במקום להסתמך על ראשי תיבות אקראיים.
(הנתיב: `KPITagList.fragment.xml:8` מקשר `shortDescription="{kpi>shortDescription}"`
מהגדרות ה-KPI ב-manifest → `SmartKpiTag.setShortDescription`.)

| KPI | לפני | אחרי |
|---|---|---|
| סה"כ סטים | סה | **סהכ** |
| שולמו בפועל | שב | **שול** |
| בבקרה ידנית | בי | **בקר** |
| בוצע סטורנו | בס | **סטו** |
| ממתינים למסמכים | ממ | **ממת** |

הכותרת המלאה זמינה תמיד ב-tooltip (ריחוף) ובראש כרטיס ה-KPI (לחיצה).

## 2. KPI לעולם לא מנתב לרשומות של הטבלה שלו

`KpiTagController.js:167-180` — כפתור הניווט בכרטיס ה-KPI מוצג רק אם קיים אחד משניים:

1. `Detail.SemanticObject` + `Action` בתוך annotation ה-`UI.KPI`, או
2. `detailNavigation` ב-manifest, שמצביע על ערך תחת
   `sap.app/crossNavigation/outbounds`.

אחרת הקוד מפורשות מסתיר אותו: *"Have to hide the button, no where to navigate"*.

**וגם כשמגדירים** — הניווט הוא **חוצה-אפליקציות** דרך ה-Fiori Launchpad
(Semantic Object + Action), כלומר אל אפליקציה **אחרת**. אין ב-ALP מנגנון של
"לחץ על KPI → סנן את הטבלה". זה פשוט לא קיים בתבנית.

בסביבת Preview אין Launchpad, ולכן גם ניווט מוגדר לא יעבוד שם.

## 3. מה כן פותר את הצורך

| הצורך | הפתרון הנכון |
|---|---|
| "לחיצה תסנן לי את הרשומות" | **סרגל הסינון החזותי** (התרשימים) — זה בדיוק תפקידו |
| "המספר יתייחס למה שאני רואה" | **KPI מסוג filterable** |
| "להבין מה כל מספר" | `shortDescription` + tooltip + כרטיס ה-KPI |

### KPI מסוג Filterable

`"filterable": true` על KPI ב-manifest מעביר אותו מהשורה העליונה (KPI גלובלי,
תמיד הסכום המלא) לסרגל שמעל אזור התוכן — ושם הוא **מתעדכן לפי המסננים**.
זה מה שמחבר את המספר לרשומות שעל המסך.

מקור: `AnnotationHelper.js:335-349` מפצל בין `filterableKPIs` ל-`globalKPIs`;
`SmartKpiTag.js:482` מסמן את התגית כ-filterable רק כשהיא מקבלת `smartFilterId`,
מה שקורה רק במיכל של ה-filterable.

> ⚠️ תלות חשובה: אם `showGoButtonOnFilterBar` הוא `true`, ה-KPI מסוג filterable
> **מוסתר עד שלוחצים Go**. לכן שונה ל-`false` — הסינון מוחל אוטומטית
> וה-KPI נראה כבר בטעינה.

## מה בוצע במאגר

`src/fiori/greeninvalp/manifest.json`:
- לכל אחד מ-5 ה-KPI נוספו `"shortDescription"` (מילה אחת → 3 אותיות קריאות)
  ו-`"filterable": true`.
- `"showGoButtonOnFilterBar"` שונה מ-`true` ל-`false`.

לביטול: להסיר את `filterable` ולהחזיר את `showGoButtonOnFilterBar` ל-`true`.
