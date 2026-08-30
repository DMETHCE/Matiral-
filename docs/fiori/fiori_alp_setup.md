# הקמת אפליקציית Fiori — Analytical List Page (ALP) למסלול הירוק

מבוסס על המתכון הסטנדרטי של SAP (כמו במדריך Mindset Consulting):
CDS Cube → CDS Consumption עם אנוטציות UI → חשיפת OData → תבנית ALP
ב-Business Application Studio (BAS).

**מה מקבלים בסוף:** אפליקציה עם כרטיסי KPI (סה"כ סטים, שולמו, בבקרה
ידנית, סטורנו, ממתינים למסמכים), תרשים עמודות "סטים לפי סטטוס",
Visual Filters (סטטוס/חברה/שנה) וטבלה אנליטית — הכל חי מ-ה-View.

---

## חלק א' — HANA Studio (ADT): שני CDS Views חדשים

| # | אובייקט | קובץ | תפקיד |
|---|---------|------|--------|
| 1 | `/ILG/IMMGreenCube` | `src/cds/ilg_immgreencube.ddls.asddls` | Cube: ממדים + 7 מדדי ספירה (`@Analytics.dataCategory: #CUBE`, `@DefaultAggregation: #SUM`) |
| 2 | `/ILG/IMMGreenAlp` | `src/cds/ilg_immgreenalp.ddls.asddls` | Consumption: אנוטציות UI מלאות (chart, selectionField, lineItem, dataPoint, presentationVariant, visual filters) |

יצירה: New → Data Definition (כמו הקודמים) → הדבקה → **Ctrl+F3 לפי
הסדר** (קודם Cube, אחר-כך Alp). דרישה מוקדמת: `/ILG/IMMGreenTrack` פעיל.

## חלק ב' — חשיפת ה-OData (בחר מסלול אחד)

### מסלול 1 (מומלץ): Service Definition + Service Binding (ב-ADT)
1. New → Other ABAP Repository Object → Business Services → **Service Definition**
   → שם: `/ILG/GREENTRACK` → הדבק:
   ```
   @EndUserText.label: 'Green Path ALP Service'
   define service /ILG/GREENTRACK {
     expose /ILG/IMMGreenAlp as GreenTrack;
   }
   ```
   → הפעל.
2. New → Business Services → **Service Binding** → שם: `/ILG/UI_GREENTRACK_V2`
   → Binding Type: **OData V2 - UI** → Service Definition: `/ILG/GREENTRACK`
   → הפעל → לחץ **Publish**.
3. במסך ה-Binding יופיע ה-**Service URL** — שמור אותו (נדרש ב-BAS).
   בדיקה: לחיצה על שם ה-Entity ‏(GreenTrack) → Preview.

### מסלול 2 (חלופי, אם Binding לא זמין): @OData.publish
ה-View `/ILG/IMMGreenAlp` כבר נושא `@OData.publish: true`. לאחר האקטיבציה:
1. טרנזקציה **`/n/IWFND/MAINT_SERVICE`** → Add Service
2. System Alias: `LOCAL` → חפש `ZILG*`/`*IMMGREENALP*` → הוסף את
   `/ILG/IMMGREENALP_CDS` עם חבילה → שמור.
3. בדיקה ב-**`/n/IWFND/GW_CLIENT`**:
   `/sap/opu/odata/sap/IMMGREENALP_CDS/$metadata` → אמור להחזיר 200.
(אם האקטיבציה מסמנת שגיאה על @OData.publish עם view entity — הגרסה שלכם
אינה תומכת בשילוב הזה; מחק את השורה והשתמש במסלול 1.)

## חלק ג' — Business Application Studio (BAS)

1. **Dev Space**: צור Dev Space מסוג **SAP Fiori** (אם אין — דרך BTP Cockpit).
2. ודא שקיים **Destination** ב-BTP למערכת ה-S/4 (Basis מגדירים פעם אחת).
3. בתוך ה-Dev Space: **File → New Project from Template →
   SAP Fiori Application** → Next.
4. **Template**: קטגוריה SAP Fiori elements → **Analytical List Page** → Next.
5. **Data Source**: Connect to a System → בחר את ה-Destination → בחר את
   השירות (`/ILG/UI_GREENTRACK_V2` או `IMMGREENALP_CDS`) → Next.
6. **Entity Selection**:
   - Main entity: **GreenTrack** (או `/ILG/IMMGreenAlp`)
   - Auto qualifier: התבנית תזהה את `StatusChart` ואת ה-presentationVariant
   - Table type: **Analytical** → Next.
7. **Project Attributes**: שם מודול `greentrack-alp`, Title: "מסלול ירוק -
   בקרה מפצה", namespace: `ilg` → Finish. הפרויקט נוצר.
8. **הרצה**: קליק ימני על הפרויקט → Preview Application → `start-noflp`.
   תראה: סרגל סינון (רגיל/חזותי), תרשים עמודות לפי סטטוס, וטבלה.

## חלק ד' — כרטיסי KPI בכותרת

ה-DataPoints כבר מוגדרים ב-CDS (סה"כ, שולמו, בקרה ידנית, סטורנו,
ממתינים). כדי להציגם ככרטיסים בכותרת ה-ALP, הוסף ב-BAS לקובץ
`webapp/annotations/annotation.xml` (דרך ה-Annotation Modeler או ידנית):

```xml
<Annotations Target="<Namespace>.GreenTrackType">
  <Annotation Term="UI.KPI" Qualifier="TotalSets">
    <Record>
      <PropertyValue Property="DataPoint"
                     AnnotationPath="@UI.DataPoint#SetsCount"/>
      <PropertyValue Property="Detail">
        <Record>
          <PropertyValue Property="DefaultPresentationVariant"
                         AnnotationPath="@UI.PresentationVariant#Default"/>
        </Record>
      </PropertyValue>
    </Record>
  </Annotation>
</Annotations>
```
חזור על הבלוק עם Qualifier ו-DataPoint שונים עבור: `PaidCount`,
`MonitorCount`, `ReversedCount`, `OpenDocsCount`. ב-Page Map של הפרויקט
(lrop editor) אפשר גם להוסיף KPI Tags ויזואלית בלי XML.

**Visual Filters**: התרשימים `VFStatus` / `VFBukrs` / `VFGjahr` כבר
מוגדרים ב-CDS; ב-Page Map → Filter Bar → הגדר Layout = Visual,
וקשר כל שדה סינון ל-qualifier המתאים.

## חלק ה' — פריסה (Deploy)

1. קליק ימני על הפרויקט → **Open Deployment Configuration** (או
   `npm run deploy`): יעד **ABAP** → Destination של המערכת → חבילה
   `/ILG/...` + Transport → Deploy. נוצר BSP בשם האפליקציה.
2. הוספה ל-Launchpad: יצירת Tile/Target Mapping בקטלוג (טרנזקציה
   `/n/UI2/FLPD_CUST` או Launchpad Content Manager) → Semantic Object
   `GreenTrack`, Action `analyze`.

## בדיקות קבלה לאפליקציה

- כרטיסי ה-KPI מציגים מספרים ומגיבים לסינון.
- לחיצה על עמודה בתרשים מסננת את הטבלה (interaction).
- Visual Filter לפי סטטוס/חברה/שנה משנה את כל המסך.
- ניווט מהטבלה: שורת סט מציגה את כל 19 העמודות.
- עברית RTL: ודא שה-FLP מוגדר he; הטקסטים מגיעים מהתוויות שב-CDS
  (זכור את עניין שפת המקור — סעיף התיאורים; תרגום SE63 חל גם כאן).

## פתרון תקלות נפוצות

| תופעה | סיבה/פתרון |
|--------|-------------|
| השירות לא נמצא ב-BAS | ה-Destination חסר `WebIDEUsage=odata_abap` — Basis |
| הטבלה ריקה אבל ה-View מלא | הרשאות; בדוק ב-GW_CLIENT עם המשתמש שלך |
| התרשים לא מופיע | ה-qualifier בתבנית לא תואם — בחר `StatusChart` ב-manifest (`chartAnnotationPath`) |
| Analytical table נכשל | ודא `@Analytics.dataCategory: #CUBE` פעיל גם ב-Alp view |
| טקסטים באנגלית/ריקים | שפת מקור EN — תרגם ב-SE63 (DDLS) כמו שעשינו ל-View הראשי |
