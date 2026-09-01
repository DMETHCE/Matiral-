# הקמת דשבורד Fiori — Overview Page (OVP) למסלול הירוק — הדרך הנכונה

**סטטוס:** מדריך מתוקן לאחר תחקיר. הניסיון הראשון (כרטיסים אנליטיים ישירות מול
השירות של `@Analytics.query`) נכשל — התיעוד המלא של הכשל בסוף המסמך ובקובץ
`.claude/skills/abap-ilg/references/fiori-rules.md`.

## העיקרון המנחה (מסקנת התחקיר)

כרטיסי גרף של OVP שולחים שאילתת `$select` פשוטה של ממד+מדד ומצפים שהשרת
יסכם. **השירות שנוצר מ-`@Analytics.query: true` (אדפטר ה-MDX) לא עונה על
הצורה הזאת בסביבה שלנו** — הוא מחזיר `results:[]` בלי שגיאה (ולעיתים 400).
ה-ALP עובד כי הוא משתמש במנגנון קשירה אנליטי ייעודי; ה-OVP לא.

**הפתרון היציב: לסכם ב-CDS, לא בשירות.** לכל כרטיס גרף מכינים View מסכם קטן
(`GROUP BY` + `count(*)`), חושפים את כולם בשירות SADL רגיל (Service
Definition + Binding V2-UI), והכרטיס רק מצייר שורות מוכנות. אין תלות באדפטר
אנליטי, אין הפתעות. (זו גם הפרקטיקה הנפוצה בקהילה לכרטיסי OVP מול CDS —
ראו מקורות בסוף.)

## ארכיטקטורה

```
/ILG/IMMGreenTrack (קיים, חי)
   ├── /ILG/IMMGreenAggStat   (GROUP BY סטטוס)   → כרטיס עמודות
   ├── /ILG/IMMGreenAggBukrs  (GROUP BY חברה)    → כרטיס דונאט
   ├── /ILG/IMMGreenAggYear   (GROUP BY שנה)     → כרטיס עמודות
   └── (עצמו)                                    → כרטיס טבלה + פילטר גלובלי
            ↓ כולם דרך:
   Service Definition /ILG/GREENOVP + Binding /ILG/UI_GREENOVP_V2 (V2-UI)
            ↓
   פרויקט BAS ‏greeninvovp (קיים) עם manifest+annotation חדשים
```

חשוב: **לא נוגעים** בשירות `IMMGREENALP_CDS` של ה-ALP — הוא נשאר כמו שהוא
וה-ALP ממשיך לעבוד.

## שלב א' — ADT: שלושה Views מסכמים

הקבצים מוכנים ב-`src/cds/`:

| DDLS | קובץ |
|---|---|
| `/ILG/IMMGreenAggStat` | `ilg_immgreenaggstat.ddls.asddls` |
| `/ILG/IMMGreenAggBukrs` | `ilg_immgreenaggbukrs.ddls.asddls` |
| `/ILG/IMMGreenAggYear` | `ilg_immgreenaggyear.ddls.asddls` |

יצירה: New → Data Definition → הדבקה → Ctrl+F3 (לכל אחד). דרישה מוקדמת:
`/ILG/IMMGreenTrack` פעיל (קיים).

## שלב ב' — ADT: שירות OData רגיל (לא אנליטי!)

לפי ההוראות המלאות ב-`src/fiori/ilg_greenovp_srvd.txt`:
1. Service Definition ‏`/ILG/GREENOVP` — חושף את 4 ה-Views עם שמות נקיים
   (GreenTrack / AggStat / AggBukrs / AggYear) → אקטיבציה.
2. Service Binding ‏`/ILG/UI_GREENOVP_V2` — סוג **OData V2 - UI** → אקטיבציה
   → **Publish**.
3. שמרו את ה-**Service URL** מהמסך, ובדקו Preview על GreenTrack.
4. פתחו את `$metadata` ורשמו: Namespace של ה-Schema + שמות ה-EntityType.

לקח מהתחקיר: אם אי פעם משנים אנוטציות אנליטיות על View שכבר פורסם עם
`@OData.publish` ומקבלים "Wrong DPC class CL_SADL_GTK_EXPOSURE_DPC" —
מוחקים את השורה `@OData.publish`, מאקטבים, מחזירים, מאקטבים; ואם צריך גם
מוחקים ורושמים מחדש את השירות ב-`/IWFND/MAINT_SERVICE` (צומת ICF:
Standard Mode) ואז `/IWFND/CACHE_CLEANUP`. כאן זה לא רלוונטי כי השירות חדש
ורגיל.

## שלב ג' — BAS: החלפת הקבצים בפרויקט greeninvovp

הקבצים המוכנים ב-`src/fiori/greeninvovp2/` (שימו לב — תיקייה **2**):

1. **manifest.json** → מחליף את `webapp/manifest.json`.
   - ודאו ששדה ה-URI של `mainService` תואם ל-Service URL מהשלב הקודם
     (ברירת מחדל בקובץ: `/sap/opu/odata/ilg/UI_GREENOVP_V2/`).
2. **annotation.xml** → מחליף את `webapp/annotations/annotation.xml`.
   - **חובה:** החלפה גורפת (Ctrl+H) של `ZZNAMESPACE` ב-Namespace האמיתי
     מה-$metadata, והתאמת שמות ה-Type אם שונים (`GreenTrackType`,
     `AggStatType`, `AggBukrsType`, `AggYearType`).
3. שמירה → Preview Application → `start-noflp`.

בפרויקט ה-BAS ייתכן שנשארה הפניה ל-datasource ישן
(`ILG_IMMGREENALP_CDS_VAN`) בקבצי `localService` — לא מפריעה; ה-manifest
החדש כבר לא מפנה אליה.

## שלב ד' — למה זה יעבוד (ומה לבדוק אם לא)

הכרטיסים ישלחו `GET AggStat` פשוט — בלי סיכום דינמי, בלי `$inlinecount`
(המודל מוגדר `defaultCountMode: None`), בלי שדות `_F`. השירות SADL רגיל
עונה על זה תמיד.

אם כרטיס ריק בכל זאת — F12 → Network → `$batch` → **Payload** (מה נשלח) +
**Response** (מה חזר, כולל הסטטוסים הפנימיים `HTTP/1.1 ...`). בסביבה שלנו
אי אפשר לבדוק שאילתות עם `?` ישירות ב-GW_CLIENT — התשתית חוסמת (400
"Bad HTTP Request" עם tag, ויומן `/IWFND/ERROR_LOG` ריק). בודקים רק דרך
ה-batch של האפליקציה.

## קטלוג הכשלים מהסשן (ALP + OVP) — לא לחזור עליהם

הרשימה המלאה והמחייבת: `.claude/skills/abap-ilg/references/fiori-rules.md`.
תמצית:

| # | כשל | תיקון/כלל |
|---|------|-----------|
| 1 | ALP: ‏KPI ותרשים מתים עם `Cannot read... getEntitySet` | שכבת הצריכה חייבת `@Analytics.query: true` (לא `@Analytics.dataCategory: #CUBE`) כדי שהשירות יסומן `sap:semantics="aggregate"` |
| 2 | אחרי שינוי האנוטציה: "Wrong DPC class CL_SADL_GTK_EXPOSURE_DPC" | טוגל `@OData.publish` (מחיקה→אקטיבציה→החזרה→אקטיבציה) + מחיקה/רישום מחדש ב-MAINT_SERVICE + CACHE_CLEANUP |
| 3 | שמות ה-Entity השתנו אחרי המעבר ל-query ‏(`xILGxIMMGREENALP` באותיות גדולות) | תמיד לאמת מול `$metadata` לפני עדכון manifest/annotation; הוולידטור של BAS משווה למטא-דאטה ישן ב-localService — האזהרה שלו לא קובעת |
| 4 | ‏UI.KPI: ‏`AnnotationPath=` נדחה | בתוך UI.KPI כותבים `Path=`; מבנה מלא: ID + SelectionVariant + DataPoint + Detail/DefaultPresentationVariant |
| 5 | תרשים ה-ALP לא הופיע | ‏manifest: ‏`"qualifier": "Default"` — תואם אחד-לאחד (רישיות!) ל-qualifier שב-CDS |
| 6 | כרטיסי OVP: ‏"DimensionAttributes are mandatory" | הגדרת Chart מקומית מלאה עם DimensionAttributes + MeasureAttributes (ה-VAN מה-CDS לא מספיק ל-OVP) |
| 7 | כרטיסי OVP מחזירים `results:[]` מול שירות `@Analytics.query` | לא נלחמים: עוברים ל-Views מסכמים + שירות SADL רגיל (המדריך הזה) |
| 8 | אשף BAS: ‏Namespace | ‏Module = השם, ‏Namespace = ‏`ilg` בלבד, בלי נקודות |
| 9 | העתקות מ-GitHub | רק Raw/Copy raw file — תצוגת הדפדפן מוסיפה שורת זבל שוברת XML |
| 10 | ‏SE11 Data Browser | ‏"Display/Maintenance Allowed with Restrictions" — ‏"Not Allowed" חוסם גם תצוגה (MO408) |

## מקורות

- [SAP-docs — Creating KPI Tags (sapui5)](https://github.com/SAP-docs/sapui5/blob/main/docs/06_SAP_Fiori_Elements/creating-key-performance-indicator-tags-in-analytical-services-d80a360.md)
- [SAP Help — Creating Key Performance Indicator Tags](https://help.sap.com/docs/ABAP_PLATFORM_NEW/468a97775123488ab3345a0c48cadd8f/d80a360638ad4cf193cc55eee92bff2e.html)
- [SAP Community — ALP "aggregate based entities" (חובת @Analytics.query)](https://community.sap.com/t5/technology-q-a/sap-bas-analytic-list-page-error-quot-aggregate-based-entities-quot/qaq-p/14144549)
- [Fiori OVP — Analytical Card (Donut) — techippo](https://www.techippo.com/2017/07/fiori-ovp-application-analytic-card-donut-chart.html)
- ניתוח קוד מקור `sap.suite.ui.generic.template` ‏1.136.1 (SmartKpiTag / KpiAnnotationHelper) — בוצע בסשן זה
