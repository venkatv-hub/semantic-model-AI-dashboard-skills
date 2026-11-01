# Report Layer (PBIR) and Build Sheets

## PBIR folder layout

```
<Name>.Report/
  definition.pbir                 # points to the semantic model (byPath or byConnection)
  definition/
    report.json                   # report-level settings, theme reference
    version.json
    pages/
      pages.json                  # pageOrder + activePageName
      overview/
        page.json
        visuals/
          kpi_total_ar/visual.json
          trend_dso/visual.json
      customer_detail/
        page.json
        visuals/...
  StaticResources/RegisteredResources/<theme>.json
```

`definition.pbir` for a local semantic model:

```json
{
  "version": "4.0",
  "datasetReference": { "byPath": { "path": "../<Name>.SemanticModel" } }
}
```

## Working rules

PBIR JSON schemas are versioned and change between Power BI Desktop releases. To stay safe:

1. If the project already has visuals, **copy the `$schema` URL and structure from an
   existing `visual.json` of the same visual type** and change only names, positions and
   field bindings.
2. If starting from scratch, generate the page and visual folders below, then tell the user
   to open the `.pbip` in Power BI Desktop; Desktop validates and upgrades the files. Fix any
   errors it reports rather than guessing.
3. Use `pbi-cli` report commands or the PBIR validator if available.
4. Folder names for pages and visuals must be unique identifiers (letters, digits, `_`).

## page.json

```json
{
  "$schema": "https://developer.microsoft.com/json-schemas/fabric/item/report/definition/page/2.0.0/schema.json",
  "name": "overview",
  "displayName": "AR Overview",
  "displayOption": "FitToPage",
  "height": 720,
  "width": 1280
}
```

## visual.json (card example)

```json
{
  "$schema": "https://developer.microsoft.com/json-schemas/fabric/item/report/definition/visualContainer/2.0.0/schema.json",
  "name": "kpi_total_ar",
  "position": { "x": 16, "y": 80, "z": 1000, "width": 192, "height": 112 },
  "visual": {
    "visualType": "card",
    "query": {
      "queryState": {
        "Values": {
          "projections": [
            {
              "field": {
                "Measure": {
                  "Expression": { "SourceRef": { "Entity": "_Measures" } },
                  "Property": "Total AR"
                }
              },
              "queryRef": "_Measures.Total AR"
            }
          ]
        }
      }
    }
  }
}
```

Common `visualType` values: `card`, `cardVisual` (new card), `kpi`, `lineChart`,
`clusteredBarChart`, `clusteredColumnChart`, `hundredPercentStackedBarChart`, `waterfallChart`,
`tableEx`, `pivotTable` (matrix), `funnel`, `slicer`, `textbox`, `shape`, `actionButton`,
`filledMap`, `azureMap`.

Column bindings use `"Column": {"Expression": {"SourceRef": {"Entity": "Customer"}},
"Property": "Region"}` in a role such as `Category`, `Rows`, `Y`, `Values`.

## Drill-through, bookmarks, tooltips

- Create the L3 page, then configure drill-through fields (e.g. `Customer[Customer Name]`).
  Hand-editing drill-through bindings is error-prone: configure it once in Desktop and copy
  that `page.json` pattern for later pages.
- Add a "Reset filters" bookmark (data + display state captured with default slicers) and a
  button bound to it on every L1/L2 page.
- Use report-page tooltips for definitions on KPI cards (a small 320×240 page with the
  metric definition text and a mini trend).

## Mode C: build sheet format

When you cannot produce files, give the developer a build sheet per page:

```
PAGE: AR Overview (L1) — canvas 1280×720, theme: BI Domain Skills Neutral
FILTERS: Period (dropdown, default = last closed month, synced), Business Unit (dropdown, synced)

# | Visual            | x,y,w,h            | Fields                                   | Format notes
1 | Card (new)        | 16,80,192,112      | Total AR; ref label: Total AR PM delta    | Callout 28pt; ref label colored by [AR Status Color]
2 | Card (new)        | 224,80,192,112     | DSO; ref label: vs target 45              | Lower is better
...
DRILL-THROUGH: Customer Detail (on Customer Name)
ALT TEXT: one sentence per visual
```

Follow it with the full DAX measure script (one block, ready to paste into a TMDL view or
Tabular Editor) and the theme JSON.
