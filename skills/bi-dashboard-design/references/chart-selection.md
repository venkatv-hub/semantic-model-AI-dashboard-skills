# Chart Selection

Choose the chart from the question being asked, not from the data shape.

| Question | Use | Avoid |
|---|---|---|
| Are we on target right now? | KPI card with target delta, bullet | Gauge (wastes space, hard to compare) |
| How is it trending? | Line (continuous time) | Bar chart with > 24 time bars, area charts with many series |
| How do categories compare? | Horizontal ranked bar | Pie/donut with > 3 slices, vertical bars with long labels |
| What explains the difference between A and B? | Waterfall | Two side-by-side totals with no bridge |
| What is the composition / mix? | 100% stacked bar, treemap (≥ 8 items) | Multiple pies |
| How is a value distributed? | Histogram, box plot | Average alone |
| Is there a relationship between two measures? | Scatter (with quadrant lines) | Dual-axis lines with unrelated scales |
| Where is it happening? | Filled map + ranked bar | Map alone, bubble maps for non-geographic data |
| Which records need action? | Exception table sorted by severity | Charts with tooltips as the only way to find records |
| How do stages convert? | Bar funnel with conversion % | 3D funnels |
| Age profile (AR, AP, inventory) | Aging bucket column/bar in fixed order | Value-sorted buckets |
| Performance across two dimensions | Heat-formatted matrix | Small-multiple pies |

## Anti-patterns to refuse politely
- Dual axes with different units unless the user insists; explain the misread risk and
  offer two aligned charts instead.
- Gauges and speedometers on L1 pages (offer a KPI card with a bullet instead).
- Rainbow palettes, 3D effects, drop shadows, gradient fills.
- Showing a metric without its comparison on L1.
- Averages of ratios (e.g. averaging customer-level DSO); compute the ratio at the
  aggregated level instead.
