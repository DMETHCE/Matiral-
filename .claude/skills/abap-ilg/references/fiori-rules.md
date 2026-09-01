# Fiori Elements (ALP / OVP) on CDS — Hard-Won Rules

Battle-tested rules from the Green-Path project (ALP + OVP on `/ILG/IMMGreenTrack`).
Every rule here cost real debugging time. **Read BEFORE generating any CDS
consumption view, OData exposure, BAS project, manifest.json or annotation.xml.**

## 1. CDS layering for analytics — the ONLY combination that works

```
Base I-views (joins, logic)          → no analytics annotations
Cube view   @Analytics.dataCategory: #CUBE + @DefaultAggregation: #SUM on measures
Consumption @Analytics.query: true   + @OData.publish: true + @UI.* annotations
```

- The consumption view must be **`@Analytics.query: true`** — NOT
  `@Analytics.dataCategory: #CUBE`. Only `query: true` makes the published V2
  service carry `sap:semantics="aggregate"` + `sap:aggregation-role` attributes.
- Without it, ALP KPI tags die with
  `KPI Error details: TypeError: Cannot read properties of undefined (reading 'getEntitySet')`
  (SmartKpiTag → odata4analytics `findQueryResultByName` returns undefined) and
  the ALP main chart stays empty. Verified in `sap.suite.ui.generic.template`
  1.136.1 sources (SmartKpiTag.js:248, KpiAnnotationHelper.js:130).

## 2. Changing analytics annotations on an already-published view

Switching `#CUBE` → `query: true` on a view that already had `@OData.publish: true`
leaves stale generated artifacts → ADT error
**"Wrong DPC class CL_SADL_GTK_EXPOSURE_DPC [OData Exposure]"** and the service
answers 400. Recovery sequence (in order, stop when clean):
1. Delete the `@OData.publish: true` line → activate.
2. Re-add the line → activate.
3. If still broken: `/IWFND/MAINT_SERVICE` → select service → Delete Service;
   then re-Add Service (System Alias LOCAL, **ICF node = Standard Mode**, package
   or Local Object).
4. `/IWFND/CACHE_CLEANUP` — ALWAYS after any of the above.

## 3. Entity names change when the view becomes a query

After `@Analytics.query: true`, the service regenerates with **different names**:
e.g. `xILGxIMMGreenAlp` → `xILGxIMMGREENALP` (upper-cased), type
`xILGxIMMGREENALPType`, plus value-help sets and an `AdditionalMetadata` set
(marker of the MDX/analytics adapter). Therefore:
- After ANY exposure change, fetch `$metadata` and copy the **exact**
  EntitySet / EntityType / Namespace into manifest.json and annotation.xml.
- The BAS annotation LSP validates against the **stale** copy in
  `webapp/localService/mainService/metadata.xml` — its red
  "name-case-issue" error is WRONG after regeneration. Trust live $metadata,
  not the editor. Refresh the local copy (Service Manager) to silence it.

## 4. ALP specifics (sap.ui.generic.app, V2)

- Main chart/table config: CDS `@UI.presentationVariant` with qualifier
  (e.g. 'Default') is only picked up when manifest settings contain
  `"qualifier": "Default"` — **exact case match**, else
  "Not SelectionPresentationVariant or PresentationVariant found".
- KPI tags need BOTH:
  - manifest: named model (e.g. `"kpi": {"dataSource": "mainService", "preload": true}`)
    + `keyPerformanceIndicators` under the page component settings
    (`model` / `entitySet` / `qualifier` per KPI);
  - local annotation.xml: `UI.KPI` per qualifier with **`Path=`** (NOT
    `AnnotationPath=` — the vocabulary types these as record refs), full record:
    `ID` (String) + `SelectionVariant` + `DataPoint` + `Detail` with
    `DefaultPresentationVariant`.
- KPI *card* (click on a tag) renders only a chart → give Detail a
  **chart-only** PresentationVariant (visualizations = the chart alone, no
  `#AS_LINEITEM`), not the page's Default PV.
- KPI tag labels are auto-abbreviated (2 letters) — by design; hover/click
  shows full title. Don't fight it.

## 5. OVP specifics (sap.ovp, V2) — THE BIG ONE

- OVP analytical chart cards demand **full local Chart definitions**:
  `Dimensions` + `DimensionAttributes` + `Measures` + `MeasureAttributes`
  (else console: "OVP-AC: ... DimensionAttributes are mandatory"). The
  CDS-generated VAN chart annotations are NOT enough. Also add an empty
  `UI.Identification` per targeted type to silence
  "Identification is not found".
- **OVP chart cards CANNOT aggregate against the `@Analytics.query` (MDX)
  service**: their plain `GET set?$select=Dim,Measure,Measure_F&$inlinecount=allpages`
  returns `{"results":[]}` (or 400) even though ALP works on the same service
  (ALP uses AnalyticalBinding; OVP does not). Removing `$inlinecount`
  (model `defaultCountMode: "None"`) is not sufficient.
- **The working architecture: pre-aggregate in CDS.** One small
  `GROUP BY`+`count(*)` view per chart card, all exposed via a **plain**
  Service Definition + Service Binding (OData V2 - UI). Cards then just draw
  ready rows. Table card + global filter bind the detail view from the same
  service. See `docs/fiori/fiori_ovp_setup.md` for the full recipe
  (`/ILG/IMMGreenAggStat` / `AggBukrs` / `AggYear` + `/ILG/GREENOVP`).
- OVP filter bar fields come from `UI.SelectionFields` on the global filter
  entity type (verified: `sap/ovp/app/Component.js:697`); live filter
  propagates per card only for same-named properties (verified:
  `FilterUtils.js` → `getEntityRelevantFilters`).
- **Donut trap (verified `VizAnnotationManager.js:102-104`):** a Donut card
  silently calls `dataModel.setDefaultCountMode(Inline)` on the SHARED model —
  it overrides manifest `defaultCountMode: "None"` for ALL cards. Harmless on
  plain SADL (supports `$inlinecount`), fatal on the MDX/`@Analytics.query`
  service. This is the final reason OVP + MDX service cannot be mixed.
- On a plain (non-analytical) service, tag each measure property locally with
  `com.sap.vocabularies.Analytics.v1.Measure` (Bool true) — OVP recognizes
  measures by this annotation too (`OVPVizDataHandler.js:78`), which keeps the
  Donut "Others" aggregation correct without `sap:aggregation-role` metadata.
- OVP chart cards do NOT require an analytical service at all: the only
  `sap:semantics === 'aggregate'` check in sap.ovp
  (`cards/MetadataAnalyser.js:123`) is for parameterized-entityset detection
  (Insights/parameters), not a card prerequisite. Pre-aggregated entity sets
  on a plain service are the classic, community-standard pattern.

## 6. BAS Fiori generator wizard traps

- ALP/OVP templates live INSIDE the "SAP Fiori generator" tile (no separate card).
- **Module Name = plain name (`greeninvalp`), Application Namespace = `ilg`
  ONLY.** No dots in either field; the generator concatenates them itself.
  (This was gotten wrong 5 times: name in both fields, swapped fields,
  trailing dot — the id must come out `ilg.<module>`, not `ilg.x.x`.)
- "Authentication incorrect" at system selection = BTP destination problem
  (BasicAuth credentials / `WebIDEEnabled` / `WebIDEUsage=odata_abap,dev_abap` /
  `HTML5.DynamicDestination`) — Basis territory, retry login first.
- Preview: `npm run start` / right-click → Preview Application; ignore 404s on
  `changes-bundle.json` / `flexibility-bundle.json` and i18n fallback warnings —
  harness noise, never the real problem.

## 7. Debugging data problems — the ONLY reliable loop in this landscape

1. F12 → Network → filter `batch` → F5.
2. `$batch` row → **Payload** tab = the real inner GETs (with `$select`…);
   **Response** tab = per-part `HTTP/1.1 xxx` + bodies. `results":[]` with 200
   means the server answered "no rows" — compare the Payload against a query
   shape that is known to work (e.g. ALP's `?$select=SetsCount&$top=1`).
3. **GW_CLIENT cannot test query strings here**: the Merkava ICM/WebDispatcher
   rejects any URI containing `?` with a generic "400 Bad HTTP Request
   (Error is logged with tag …)" and `/IWFND/ERROR_LOG` stays EMPTY. Only
   plain paths (`…/$metadata`, service doc) work there. Don't burn time on it.
4. `$metadata` spelling: `/$metadata` appended to the service path — typos
   (`$matadata`, `/?$metadata`) silently return the service document instead.

## 8. File-handling rules for the user's workflow

- GitHub repo layout: app files live under `src/fiori/<app>/`; `webapp/…`
  exists ONLY inside the BAS project. Never link the user to
  `webapp/...` paths on GitHub (recurring 404).
- Copy from GitHub with **Raw / Copy raw file** only — the browser's rendered
  XML view prepends "This XML file does not appear to have any style
  information…" which breaks the file.
- XML content (`<edmx…`) → annotation.xml; JSON (`{…`) → manifest.json —
  state this pairing explicitly every time both files are delivered (they were
  swapped once).
- When BAS refuses to save ("Failed to save … newer version"), choose
  Overwrite or delete-and-recreate the file; an unsaved manifest (⚫ on the tab)
  is a silent killer.

## 9. SE16N / snapshot table

- Data Browser/Table View Editing for snapshot Z-tables:
  **"Display/Maintenance Allowed with Restrictions"** — plain "Allowed" opens
  SE16N in edit mode; "Not Allowed" blocks even display (MO408).
