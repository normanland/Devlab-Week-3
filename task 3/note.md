# Methodology and Operational Insights

## Methodology

The analysis uses the NYC Taxi Trip Duration training dataset containing 1,458,644 rows and 11 columns.

`pickup_datetime` is converted to datetime format, then hour, weekday, month, and calendar date are extracted to support time-based aggregation.

Trip duration is originally recorded in seconds and is converted to minutes. Trips shorter than 1 minute or longer than 120 minutes are excluded according to the task requirement.

This removes 10,848 records, or approximately 0.74% of the original dataset.

The filtering step is evaluated rather than applied silently. Raw and cleaned duration statistics are compared to measure how strongly extreme trips affect average duration.

Demand is defined as trip count.

Hourly aggregation is used to identify peak and off-peak demand, while weekday aggregation is used to compare recurring weekly patterns. Average trip duration is also calculated for each pickup hour to understand how vehicle occupancy changes throughout the day.

Monthly trip count is calculated to identify changes across the January–June 2016 period.

Because raw monthly totals can be affected by the number of observed days in each month, average trips per observed day are also calculated as an additional normalized measure.

## Weekday vs Weekend Method

A direct comparison of weekday and weekend totals would be biased because weekdays represent five days of the week while weekends represent only two.

To produce a fair comparison, trips are first aggregated at the calendar-date level and then average daily demand is compared.

The resulting averages are:

- Weekday: approximately **7,961 trips per observed day**
- Weekend: approximately **7,940 trips per observed day**
- Difference: approximately **0.27%**

This indicates that the typical daily demand level is very similar between weekdays and weekends, even though raw weekday totals are much larger.

## Outlier Impact

Only around **0.74%** of rows are removed by the 1–120 minute duration filter.

However, the mean trip duration decreases by approximately **12.36%** after filtering.

This confirms that a relatively small number of extreme values can substantially influence the mean and supports the decision to use a controlled duration range for the operational analysis.

## Validated Findings

- Peak hourly demand occurs at **18:00–19:00**, with **90,022 trips**.
- The quietest hour is **05:00–06:00**, with **14,767 trips**.
- Peak demand is approximately **6.10 times** the off-peak level.
- **Friday** records the highest total weekday volume with **221,870 trips**.
- **Monday** records the lowest total weekday volume with **186,051 trips**.
- Cleaned average trip duration is approximately **14.01 minutes**.
- Cleaned median trip duration is approximately **11.08 minutes**.
- The busiest hour-day combination is **Friday at 19:00**, with **14,087 trips**.
- Vendor 1 averages approximately **13.93 minutes** per trip.
- Vendor 2 averages approximately **14.08 minutes** per trip.
- March has the highest raw monthly trip count.
- April has the highest average trips per observed day.
- June shows the highest average trip duration among the observed months.
- Approximately **17.66%** of all cleaned trips occur between **17:00 and 20:00**.

The dataset does not contain weather data, so seasonal or weather-related changes are described as observed patterns rather than causal effects.

## Operational KPI Summary

The following KPIs were added to make the results directly usable for fleet management:

| KPI | Value | Operational Meaning |
|---|---:|---|
| Peak / off-peak demand ratio | 6.10× | Evening supply requirements are substantially higher than early-morning requirements |
| Weekday vs weekend daily demand difference | 0.27% | Daily demand is almost equal after normalization |
| Filtered-row share | 0.74% | Only a small fraction of trips is removed |
| Mean-duration reduction after filtering | 12.36% | Extreme trips materially distort the raw mean |
| 17:00–20:00 demand concentration | 17.66% | A large share of daily demand is concentrated in the evening window |

## Operational Insights

### 1. Pre-position vehicles before the evening peak

Demand reaches its maximum around 18:00–19:00, and 17:00–20:00 alone accounts for approximately 17.66% of cleaned trips.

Fleet capacity should therefore be increased before the peak begins instead of reacting once queues or shortages are already visible.

Shift overlap, driver availability, and dispatch coverage should be strongest from late afternoon into the early evening.

### 2. Use the 05:00 demand trough for maintenance

The lowest demand occurs around 05:00.

This period is the most suitable operational window for activities that temporarily remove vehicles from service, including:

- refueling or charging
- cleaning
- inspections
- minor maintenance

Scheduling these activities during peak periods would create a higher opportunity cost.

### 3. Plan Friday evening separately from an average weekday

Friday is the highest-volume weekday, and Friday at 19:00 is the busiest individual hour-day combination.

A scheduling model based only on average weekday demand could therefore under-allocate vehicles during the strongest weekly demand concentration.

Friday evening should be treated as a distinct staffing and fleet-allocation window.

### 4. Consider trip duration together with trip volume

Trip count alone does not fully describe fleet pressure.

When average trip duration rises, vehicles remain occupied for longer and become unavailable for the next pickup.

Dispatch planning should therefore combine demand volume with expected trip duration rather than relying only on request counts.

## Visualization Improvements

The project uses different chart types for different analytical questions rather than repeating the same visual structure.

The hour × weekday heatmap includes:

- a continuous color scale
- numeric cell annotations
- ordered weekday labels
- ordered 24-hour rows

This makes both pattern recognition and exact-value comparison possible.

The vendor comparison uses a dot chart instead of a truncated bar chart. Since the two average durations differ only slightly, this design reduces the risk of visually overstating the difference.

## Improvement Summary

The final version extends the base requirements through:

- normalized weekday/weekend comparison
- normalized monthly demand
- quantified outlier impact
- annotated demand heatmap
- vendor duration comparison
- evening-rush concentration KPI
- operational KPI summary
- reusable CSV outputs
- strict reconciliation checks

