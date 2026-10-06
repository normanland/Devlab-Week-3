# NYC Taxi Demand Pattern Analysis

This project analyzes time-based demand patterns in the NYC Taxi Trip Duration dataset to identify peak demand windows, weekday behavior, trip-duration patterns, and operational opportunities for fleet planning.

The analysis was built with `pandas`, `matplotlib`, and `seaborn`, and includes the required time-based aggregations together with additional validation, normalization, and operational KPI improvements.

## Dataset

- Source: Kaggle — NYC Taxi Trip Duration
- Dataset link: https://www.kaggle.com/datasets/yasserh/nyc-taxi-trip-duration
- File used: `NYC.csv` / `train.csv` equivalent
- Rows: 1,458,644
- Columns: 11
- Missing values: 0
- Coverage: January–June 2016
- `trip_duration` is stored in seconds and converted to minutes during preprocessing

## Project Objectives

The main goals are to:

- extract time components from `pickup_datetime`
- identify peak and off-peak taxi demand
- compare weekday and weekend behavior
- analyze trip-duration patterns
- evaluate the effect of outlier filtering
- identify monthly demand changes
- compare vendor-level trip duration
- translate analytical results into operational fleet recommendations

## Data Preparation

The analysis follows these preprocessing steps:

1. Load the taxi trip dataset.
2. Convert `pickup_datetime` to datetime format.
3. Convert `trip_duration` from seconds to minutes.
4. Remove trips shorter than 1 minute or longer than 120 minutes.
5. Extract:
   - pickup hour
   - weekday
   - month
   - calendar date
6. Build hourly, weekday, monthly, and vendor summary tables.
7. Export reusable analytical outputs.
8. Run final integrity and reconciliation checks.

After filtering, 10,848 trips are removed, representing approximately 0.74% of the original dataset.

## Main Findings

- Peak hourly demand occurs at **18:00–19:00**, with **90,022 trips**.
- The lowest-demand period is **05:00–06:00**, with **14,767 trips**.
- **Friday** records the highest total weekday demand with **221,870 trips**.
- **Monday** has the lowest total weekday demand with **186,051 trips**.
- Cleaned average trip duration is approximately **14.01 minutes**.
- Cleaned median trip duration is approximately **11.08 minutes**.
- The busiest hour-day combination is **Friday at 19:00**, with **14,087 trips**.
- Vendor 1 and Vendor 2 show very similar average trip durations: approximately **13.93 vs 14.08 minutes**.
- March has the highest raw monthly trip count.
- April has the highest average trips per observed day.
- June has the highest average trip duration among the observed months.

## Operational KPI Summary

To make the analysis more actionable, several fleet-management KPIs were added:

| KPI | Result |
|---|---:|
| Peak / off-peak demand ratio | 6.10× |
| Weekday vs weekend average daily demand difference | 0.27% |
| Rows removed by duration filtering | 0.74% |
| Mean duration reduction after filtering | 12.36% |
| Share of trips between 17:00 and 20:00 | 17.66% |

These metrics make it easier to move from descriptive analysis to measurable operational decisions.

## Weekday vs Weekend Improvement

A direct comparison of total weekday and weekend trips would be misleading because there are five weekdays and only two weekend days.

To avoid this bias, demand is normalized by observed calendar day.

- Average weekday demand: approximately **7,961 trips per day**
- Average weekend demand: approximately **7,940 trips per day**
- Difference: approximately **0.27%**

This shows that typical daily demand is very similar across the two groups, even though raw weekday totals are naturally much larger.

## Outlier Impact Analysis

Filtering is not treated only as a cleaning step.

The notebook compares duration statistics before and after removing trips outside the 1–120 minute range. Although only around **0.74%** of rows are removed, the mean trip duration falls by approximately **12.36%**.

This demonstrates that a small number of extreme observations can materially distort average-based metrics.

## Visualizations

The project includes seven visualizations:

1. `01_hourly_demand.png` — hourly taxi demand line chart
2. `02_weekday_demand.png` — weekday trip count bar chart
3. `03_trip_duration_distribution.png` — trip-duration histogram with distribution shape
4. `04_avg_duration_by_hour.png` — average trip duration by pickup hour
5. `05_monthly_trip_count.png` — monthly trip count comparison
6. `06_hour_weekday_heatmap.png` — annotated hour × weekday demand heatmap
7. `07_vendor_duration_comparison.png` — vendor duration dot comparison

The heatmap includes both a color scale and numeric annotations so exact demand values can be read directly.

The vendor comparison uses a dot-based design rather than a truncated bar chart to avoid exaggerating the small difference between vendor averages.

## Improvements Beyond the Base Task

The project goes beyond the mandatory requirements through:

- outlier-impact quantification
- weekday/weekend demand normalization
- monthly demand normalization using average trips per observed day
- annotated hour × weekday heatmap
- vendor duration comparison
- operational KPI summary
- evening-rush concentration analysis
- reusable summary CSV exports
- stricter double validation and reconciliation checks

The notebook was also executed from start to finish to confirm that all cells run successfully without runtime errors.

## Project Structure

```text
NYC_Taxi_Demand_Task_3/
├── nyc_taxi_demand_analysis.ipynb
├── README.md
├── note.md
├── visuals/
│   ├── 01_hourly_demand.png
│   ├── 02_weekday_demand.png
│   ├── 03_trip_duration_distribution.png
│   ├── 04_avg_duration_by_hour.png
│   ├── 05_monthly_trip_count.png
│   ├── 06_hour_weekday_heatmap.png
│   └── 07_vendor_duration_comparison.png
└── outputs/
    ├── hourly_summary.csv
    ├── weekday_summary.csv
    ├── monthly_summary.csv
    ├── vendor_summary.csv
    ├── weekday_vs_weekend_daily_summary.csv
    └── operational_kpi_summary.csv
```

## Tools

`pandas` · `numpy` · `matplotlib` · `seaborn` · `jupyter`

## Final Note

The project is designed not only to describe taxi demand, but also to support operational decisions through normalized comparisons, measurable KPIs, visual clarity, and independent validation.
