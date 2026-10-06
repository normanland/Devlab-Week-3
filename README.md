# DevLab Week 3 — Following Signals Through Time

Three datasets.  
Three operational questions.  
One recurring challenge:

**time changes the meaning of the metric.**

A customer who does not return next month,  
a reservation made 200 days in advance,  
and a taxi requested at 19:00  
all describe very different business situations — but each depends on when the event happens.

Week 3 was built around that idea.

---

## The signal map

```text
CUSTOMER
first purchase
    │
    ▼
repeat activity
    │
    ▼
RETENTION


BOOKING
reservation date
    │
    ▼
lead time
    │
    ▼
CANCELLATION RISK


TRIP
pickup time
    │
    ▼
hour / weekday / month
    │
    ▼
DEMAND PRESSURE
```

---

# 01 — Who comes back?

## Olist Cohort Retention Analysis

**Domain:** E-commerce  
**Core method:** SQL cohort analysis  
**Data scale:** 99,441 orders

The first project tracks customers from their first delivered purchase and asks a simple-looking question:

> How much acquisition actually becomes repeat activity?

The difficult part was not calculating a percentage.

It was defining the population correctly.

`customer_id` represents an order-level customer record, while `customer_unique_id` is required to follow the same person across orders.

The analysis also separates:

- observed zero retention
- periods that have not yet been observed
- very small cohorts
- stable cohorts large enough for comparison

### Signal detected

Among the stable cohorts, average month-1 retention is approximately:

```text
0.48%
```

The largest acquisition cohorts therefore do not automatically become the strongest repeat-purchase cohorts.

### Analytical lesson

```text
large acquisition ≠ strong retention
```

---

# 02 — When does a booking become risky?

## Hotel Seasonality & Cancellation Analysis

**Domain:** Hospitality  
**Core method:** Python exploratory analysis  
**Reservations:** 36,275

This project looks at hotel reservations from two perspectives:

```text
volume
vs
risk
```

The most active period is not necessarily the most dangerous one.

October records the highest booking volume.

July records the highest cancellation rate.

That difference matters because capacity planning and cancellation-risk management solve different problems.

### Lead-time signal

Cancellation risk rises sharply as reservations are made further in advance.

```text
≤ 7 days        →  8.9%
181+ days       → 73.9%
```

Long lead time therefore behaves less like a neutral booking characteristic and more like an operational risk indicator.

### Channel signal

Online reservations represent the largest booking source and also the largest cancellation exposure.

### Analytical lesson

```text
highest volume ≠ highest risk
```

---

# 03 — When does the system feel pressure?

## NYC Taxi Demand Analysis

**Domain:** Mobility / Operations  
**Core method:** Time-based demand analysis  
**Trips:** 1,458,644

The taxi dataset shifts the question from customer behavior to operational capacity.

The objective is not only:

> When are there more trips?

but:

> When does demand become operationally different enough to change fleet decisions?

### Demand signal

The strongest hourly demand appears around:

```text
18:00–19:00
```

while the lowest-demand period is around:

```text
05:00–06:00
```

The peak-to-off-peak demand ratio is approximately:

```text
6.1×
```

Friday at 19:00 is the strongest hour-day combination in the dataset.

### Normalization matters

Raw weekday totals are naturally higher because there are five weekdays and only two weekend days.

After comparing average demand per observed calendar day:

```text
Weekday ≈ 7,961 trips/day
Weekend ≈ 7,940 trips/day
```

The difference is only about:

```text
0.27%
```

### Analytical lesson

```text
larger total ≠ higher typical daily demand
```

---

# Three projects, one pattern

Each project contains a metric that can be misleading without context.

| Project | Easy conclusion | Better question |
|---|---|---|
| Olist | Which cohort is largest? | Which cohort actually returns? |
| Hotel | Which month has most bookings? | Which bookings carry the most cancellation risk? |
| NYC Taxi | Which group has more trips? | Is the difference still present after normalization? |

That shift — from reporting totals to questioning what they actually represent — was the main focus of Week 3.

---

# Analytical workflow

```text
define
  ↓
segment
  ↓
normalize
  ↓
validate
  ↓
compare
  ↓
interpret
```

The projects use different techniques, but the same rule applies:

> A metric is only useful when its denominator, observation window, and business meaning are clear.

---

# Repository

```text
01-olist-cohort-retention-analysis/
│
├── olist_cohort_retention_analysis.ipynb
├── olist_cohort_retention_queries.sql
├── olist_cohort_database_setup.sql
├── insights.md
└── README.md


02-hotel-seasonality-cancellation-analysis/
│
├── hotel_reservations.csv
├── hotel_seasonality_cancellation_analysis.ipynb
├── insights.md
├── README.md
└── visuals/


03-nyc-taxi-demand-analysis/
│
├── nyc_taxi_demand_analysis.ipynb
├── insights.md
├── README.md
├── visuals/
├── outputs/
└── .gitignore
```

---

# Stack

```text
SQL        MySQL
Python     pandas
NumPy      Matplotlib
Seaborn    Jupyter
```

---

## Week 3 in one line

**Retention asks who returns.  
Risk asks what may disappear.  
Demand asks when capacity is needed.**

The common task is deciding which signal is actually worth acting on.
