# Theme Tokens

Neutral, brand-swappable tokens. Replace the accent with the customer's brand color and keep
the semantic colors unless the customer has an accessibility-tested alternative.

```yaml
color:
  canvas: "#FFFFFF"
  surface: "#F7F7F8"          # card / container background
  border: "#E4E4E7"
  text_primary: "#252423"
  text_secondary: "#605E5C"
  accent: "#2563EB"           # actual / current period
  comparison: "#A1A1AA"       # prior year, budget, forecast lines
  good: "#1A7F37"
  warning: "#B7791F"
  bad: "#C62828"
  categorical: ["#2563EB", "#EA580C", "#0D9488", "#7C3AED", "#6B7280", "#DB2777"]
  sequential: ["#EFF6FF", "#BFDBFE", "#60A5FA", "#2563EB", "#1E3A8A"]
  diverging: ["#C62828", "#F4A3A3", "#F5F5F5", "#9FD3AE", "#1A7F37"]
font:
  family: "Segoe UI, Helvetica Neue, Arial, sans-serif"
  title: 18
  subtitle: 11
  kpi_value: 28
  label: 11
  axis: 9
spacing:
  gutter_px: 16
  card_radius_px: 6
  padding_px: 12
```

## Platform conversion

**Power BI** – produce a report theme JSON:

```json
{
  "name": "BI Domain Skills Neutral",
  "dataColors": ["#2563EB", "#EA580C", "#0D9488", "#7C3AED", "#6B7280", "#DB2777"],
  "foreground": "#252423",
  "background": "#FFFFFF",
  "tableAccent": "#2563EB",
  "good": "#1A7F37",
  "neutral": "#B7791F",
  "bad": "#C62828",
  "textClasses": {
    "title": {"fontFace": "Segoe UI Semibold", "fontSize": 14, "color": "#252423"},
    "label": {"fontFace": "Segoe UI", "fontSize": 11, "color": "#605E5C"},
    "callout": {"fontFace": "Segoe UI Semibold", "fontSize": 28, "color": "#252423"}
  }
}
```

**Tableau** – add a custom categorical palette to `Preferences.tps` and set workbook
formatting (Format ▸ Workbook) fonts to the tokens:

```xml
<color-palette name="BI Domain Skills Neutral" type="regular">
  <color>#2563EB</color><color>#EA580C</color><color>#0D9488</color>
  <color>#7C3AED</color><color>#6B7280</color><color>#DB2777</color>
</color-palette>
```

**Looker** – set `series_colors` on elements and use dashboard-level `embed_style` /
`background_color` where supported; define the categorical palette as a custom color
collection in Admin ▸ Visualizations if the user has admin rights.
