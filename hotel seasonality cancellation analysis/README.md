# Rooms fill. Plans change.

> **36,275 reservations → 11,885 cancellations → one question:** where does booking pressure become revenue exposure?

This is not a generic hotel EDA. The analysis follows a pressure chain:

```text
seasonality → room mix → cancellation pressure → lead-time risk
            ↓                              ↓
         pricing                       channel exposure
            └────────────→ revenue decisions ←──────────┘
```

## Signal board

| Signal | Reading | Why it matters |
|---|---:|---|
| Overall cancellation | **32.8%** | one in three reservations does not survive |
| Volume peak | **October · 5,317** | capacity pressure |
| Risk peak | **July · 45.0%** | cancellation pressure |
| Canceled lead time | **139.2 days avg** | risk enters early |
| 181+ day cancellation | **73.9%** | clear intervention threshold |
| Online share | **64.0%** | largest acquisition dependency |
| Online cancellations | **8,475** | highest-leverage channel problem |
| Repeat-guest cancellation | **1.7%** | strong stability signal |

## The brief had to be translated — not imitated

The original Week 3 task suggested the **Hotel Booking Demand** dataset. That dataset had already been used in an earlier task, so this project uses **Hotel Reservations / INN Hotels** instead.

The replacement does not contain `hotel` or `country`. Rather than inventing those fields:

| Original requirement | Dataset-equivalent used here |
|---|---|
| Month × hotel pivot | Month × room-type pivot |
| Cancellation rate per hotel | Month × room-type cancellation heatmap |
| ADR | `avg_price_per_room` as the closest rate measure |
| Top-country analysis | replaced with room-type exposure because country is unavailable |
| Market segment analysis | completed directly |
| Lead-time comparison | completed directly |
| Lowest-cancellation segment | completed directly |
| 4 revenue insights | decision matrix in notebook + `note.md` |

The notebook explicitly shows this mapping so the substitutions cannot be mistaken for missing work.

## Visual route

**Demand first:**

![seasonal demand](visuals/01%20seasonal%20demand%20heatmap.png)

**Then risk:**

![lead time risk](visuals/05%20lead%20time%20risk%20curve.png)

**Then commercial exposure:**

![segment risk](visuals/06%20market%20segment%20risk%20map.png)

## Files

```text
week 3 task 2/
├── hotel reservation seasonal analysis.ipynb
├── README.md
├── note.md
└── visuals/
    ├── 01 seasonal demand heatmap.png
    ├── 02 monthly cancellation pressure.png
    ├── 03 room cancellation heatmap.png
    ├── 04 lead time distribution.png
    ├── 05 lead time risk curve.png
    ├── 06 market segment risk map.png
    ├── 07 cancellation value at risk.png
    ├── 08 room type 1 demand and price.png
    └── 09 repeat guest reliability.png
```

No extra CSV exports and no `outputs/` folder are created.

## Run

The notebook already checks your current dataset location first:

```text
C:\Users\anarrasulzada\Desktop\archive (13)\Hotel Reservations.csv
```

If the CSV is later moved beside the notebook, that location also works automatically.

Dependencies:

```bash
pip install pandas matplotlib seaborn
```

## Dataset

**Hotel Reservations Dataset / INN Hotels**  
https://www.kaggle.com/datasets/ahsan81/hotel-reservations-classification-dataset
