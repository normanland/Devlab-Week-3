# Decision note — Seasonal Patterns & Cancellation Analysis

## Dataset substitution

The Week 3 task originally recommends the **Hotel Booking Demand** dataset. That dataset was **not used in this project because it had already been used in an earlier task**. The analysis therefore uses the **Hotel Reservations / INN Hotels** dataset instead: 36,275 reservations and 19 fields covering booking timing, room type, market segment, lead time, room price and booking status.

This matters for the task mapping. The replacement dataset has no `hotel`, `country`, `agent`, `company` or `adr` columns. Those fields were not fabricated. `room_type_reserved` is used for the multi-category seasonal/cancellation comparison, while `avg_price_per_room` is used as the closest available room-rate measure. The country analysis cannot be reproduced honestly and is replaced by room-type exposure.

## Requirement crosswalk

| Requirement | Treatment | Status |
|---|---|---|
| inspect data / missing values | 36,275 × 19; 0 missing values; 0 duplicate rows | Complete |
| combine year/month/day | proper `arrival_date` created | Complete |
| month × hotel booking pivot | adapted to month × room type | Complete |
| pivot heatmap | full 12 × 7 room-type heatmap | Complete |
| monthly cancellation rate | monthly rate + overall benchmark | Complete |
| cancellation rate per hotel | adapted to month × room-type cancellation heatmap | Complete |
| lead time canceled vs non-canceled | mean, median and boxplot | Complete |
| market-segment bookings/cancellations | table + risk/scale map | Complete |
| lowest cancellation market segment | Complementary, 0.0% (391 bookings) | Bonus complete |
| ADR by month/hotel type | `avg_price_per_room`; dual-axis focus on dominant Room_Type 1 | Bonus adapted |
| top 10 countries | country is absent from replacement dataset | Not reproducible; explicitly replaced |
| four revenue insights | decision matrix + four actions | Complete |

## Data-handling decisions

The source has no missing values, so no unnecessary imputation is performed. The original `arrival_date` column is actually a day-of-month integer; it is renamed to `arrival_day` before year, month and day are combined.

There are **37 rows marked 2018-02-29**, an impossible date. They become `NaT` in the constructed datetime field. They are retained because the analysis is month-level and their original year/month values remain usable.

A binary `is_canceled` flag is derived from `booking_status`. For one business extension, `booking_value_proxy = avg_price_per_room × stay_nights` is used on canceled bookings. This is an exposure proxy only; it is not claimed as recognized revenue.

## What changed once the analysis became business-led

### Demand and risk do not peak together

October is the largest demand month with **5,317 bookings**, but July has the highest cancellation rate at **45.0%**. January is only **2.4%**. High volume therefore does not automatically mean high cancellation risk.

### Lead time is the strongest operational threshold in the analysis

Canceled bookings are made **139.2 days** in advance on average; kept bookings average **58.9 days**. The cancellation curve rises from **8.9%** for bookings made within 7 days to **73.9%** for bookings made more than 180 days ahead.

### Online is the largest commercial pressure point

Online supplies **23,214 bookings (64.0%)**, produces **8,475 cancellations**, and has a **36.5% cancellation rate**. Using the booking-value proxy, canceled Online reservations represent roughly **3.32M**, compared with **0.89M** Offline.

### Room exposure needs two rankings

`Room_Type 6` has the highest overall cancellation rate at **42.0%**, but only 966 bookings. `Room_Type 1` has a lower rate at **32.3%** yet produces **9,072 cancellations** because it accounts for 28,130 reservations. Rate identifies fragility; volume identifies impact.

### Repeat guests are unusually stable

Repeat guests cancel only **1.7%** of bookings versus **33.6%** for new/non-repeat guests. This is a useful segmentation signal for differentiated booking terms or loyalty treatment.

## Revenue-management actions

| Decision | Evidence | Action |
|---|---|---|
| Long-lead controls | 181+ days → 73.9% cancellation | reconfirm, deposit or policy step-up for long-lead bookings |
| Channel intervention | Online → 8,475 cancellations | prioritize Online cancellation reduction before small channels |
| Month-specific rules | July risk peak ≠ October volume peak | separate overbooking/risk parameters from capacity planning |
| Inventory prioritization | Room_Type 1 carries 9,072 cancellations | optimize high-volume room inventory before niche categories |

## Caveats

`room_type_reserved` is encoded rather than descriptive. `avg_price_per_room` is not asserted to be identical to ADR. The dataset has no country field, so a country ranking would be invented and is deliberately excluded. Small room-type/month cells can produce volatile percentages; they should not be compared with large cells without checking booking counts.
