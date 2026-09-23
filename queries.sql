-- cohort retention | mysql 8.0+
-- run setup_mysql.sql once, then run these queries one at a time.
-- p0 is 100%; null means the month is not yet observable.


-- Q1: checking delivered orders and the number of unique customers.
select count(*) as delivered_orders,
       count(distinct c.customer_unique_id) as unique_customers,
       min(o.order_purchase_timestamp) as first_purchase,
       max(o.order_purchase_timestamp) as last_purchase
from olist_orders o
join olist_customers c on c.customer_id = o.customer_id
where o.order_status = 'delivered';
-- output: 96,478 delivered orders, 93,358 unique customers.


-- Q2: finding each customer's first purchase month.
-- first_order: window min gives the first purchase for every person
with first_order as (
    select c.customer_unique_id,
           min(o.order_purchase_timestamp) over (
               partition by c.customer_unique_id
           ) as first_purchase
    from olist_orders o
    join olist_customers c on c.customer_id = o.customer_id
    where o.order_status = 'delivered'
)
select date_format(first_purchase, '%Y-%m-01') as cohort_month,
       count(distinct customer_unique_id) as cohort_size
from first_order
group by date_format(first_purchase, '%Y-%m-01')
order by cohort_month;

-- output: 23 cohorts; 2017-11 is largest (7,060).


-- Q3: grouping customer activity by purchase month.

-- activity: one record per delivered order, with its purchase month
with activity as (
    select o.order_id, c.customer_unique_id,
           date_format(o.order_purchase_timestamp, '%Y-%m-01') as order_month
    from olist_orders o
    join olist_customers c on c.customer_id = o.customer_id
    where o.order_status = 'delivered'
)
select order_month, count(*) as orders,
       count(distinct customer_unique_id) as active_customers
from activity
group by order_month
order by order_month;

-- output: 23 purchase months; 96,478 delivered orders in total.


-- Q4: calculating the number of months since the first purchase.

-- delivered_orders: keep one row per order and attach the stable person id
with delivered_orders as (
    select o.order_id, o.customer_id, c.customer_unique_id,
           c.customer_state, o.order_purchase_timestamp,
           o.order_delivered_customer_date, o.order_estimated_delivery_date
    from olist_orders o
    join olist_customers c on c.customer_id = o.customer_id
    where o.order_status = 'delivered'
      and o.order_purchase_timestamp is not null
),
-- cohorts: first delivered purchase month for each real customer
cohorts as (
    select customer_unique_id,
           date_format(min(order_purchase_timestamp), '%Y-%m-01') as cohort_month
    from delivered_orders
    group by customer_unique_id
),
-- activity: each delivered order's calendar month
activity as (
    select order_id, customer_unique_id,
           date_format(order_purchase_timestamp, '%Y-%m-01') as order_month
    from delivered_orders
),
-- periods: whole calendar months since the customer's first purchase
periods as (
    select a.order_id, a.customer_unique_id, c.cohort_month, a.order_month,
           (year(a.order_month) - year(c.cohort_month)) * 12
           + month(a.order_month) - month(c.cohort_month) as period_number
    from activity a
    join cohorts c on c.customer_unique_id = a.customer_unique_id
),
-- monthly_customers: multiple orders by one person in the same month count once
monthly_customers as (
    select cohort_month, period_number,
           count(distinct customer_unique_id) as active_customers
    from periods
    group by cohort_month, period_number
),
-- cohort_sizes: the month-0 customer count is the denominator
cohort_sizes as (
    select cohort_month, active_customers as cohort_size
    from monthly_customers
    where period_number = 0
),
-- period_list: compare cohorts on the same first seven calendar months
period_list as (
    select 0 as period_number union all select 1 union all select 2
    union all select 3 union all select 4 union all select 5 union all select 6
),
-- observed: a period beyond the last available order month is unknown, not zero
observed as (
    select s.cohort_month, s.cohort_size, n.period_number,
           case when n.period_number <=
               (year(a.last_month) - year(s.cohort_month)) * 12
               + month(a.last_month) - month(s.cohort_month)
                then coalesce(max(m.active_customers), 0)
                else null end as active_customers
    from cohort_sizes s
    cross join period_list n
    cross join (select max(order_month) as last_month from activity) a
    left join monthly_customers m on m.cohort_month = s.cohort_month
                                 and m.period_number = n.period_number
    group by s.cohort_month, s.cohort_size, n.period_number, a.last_month
),
-- retention: always divide by that cohort's own month-0 size
retention as (
    select cohort_month, period_number, cohort_size, active_customers,
           round(100.0 * active_customers / cohort_size, 4) as retention_pct
    from observed
)
select period_number, count(*) as orders,
       count(distinct customer_unique_id) as customers
from periods
group by period_number
order by period_number;
-- output: period 0 has 94,579 orders; period 1 has 433.


-- Q5: building the returning customer matrix by cohort and period.

-- delivered_orders: keep one row per order and attach the stable person id
with delivered_orders as (
    select o.order_id, o.customer_id, c.customer_unique_id,
           c.customer_state, o.order_purchase_timestamp,
           o.order_delivered_customer_date, o.order_estimated_delivery_date
    from olist_orders o
    join olist_customers c on c.customer_id = o.customer_id
    where o.order_status = 'delivered'
      and o.order_purchase_timestamp is not null
),
-- cohorts: first delivered purchase month for each real customer
cohorts as (
    select customer_unique_id,
           date_format(min(order_purchase_timestamp), '%Y-%m-01') as cohort_month
    from delivered_orders
    group by customer_unique_id
),
-- activity: each delivered order's calendar month
activity as (
    select order_id, customer_unique_id,
           date_format(order_purchase_timestamp, '%Y-%m-01') as order_month
    from delivered_orders
),
-- periods: whole calendar months since the customer's first purchase
periods as (
    select a.order_id, a.customer_unique_id, c.cohort_month, a.order_month,
           (year(a.order_month) - year(c.cohort_month)) * 12
           + month(a.order_month) - month(c.cohort_month) as period_number
    from activity a
    join cohorts c on c.customer_unique_id = a.customer_unique_id
),
-- monthly_customers: multiple orders by one person in the same month count once
monthly_customers as (
    select cohort_month, period_number,
           count(distinct customer_unique_id) as active_customers
    from periods
    group by cohort_month, period_number
),
-- cohort_sizes: the month-0 customer count is the denominator
cohort_sizes as (
    select cohort_month, active_customers as cohort_size
    from monthly_customers
    where period_number = 0
),
-- period_list: compare cohorts on the same first seven calendar months
period_list as (
    select 0 as period_number union all select 1 union all select 2
    union all select 3 union all select 4 union all select 5 union all select 6
),
-- observed: a period beyond the last available order month is unknown, not zero
observed as (
    select s.cohort_month, s.cohort_size, n.period_number,
           case when n.period_number <=
               (year(a.last_month) - year(s.cohort_month)) * 12
               + month(a.last_month) - month(s.cohort_month)
                then coalesce(max(m.active_customers), 0)
                else null end as active_customers
    from cohort_sizes s
    cross join period_list n
    cross join (select max(order_month) as last_month from activity) a
    left join monthly_customers m on m.cohort_month = s.cohort_month
                                 and m.period_number = n.period_number
    group by s.cohort_month, s.cohort_size, n.period_number, a.last_month
),
-- retention: always divide by that cohort's own month-0 size
retention as (
    select cohort_month, period_number, cohort_size, active_customers,
           round(100.0 * active_customers / cohort_size, 4) as retention_pct
    from observed
)
select cohort_month,
       sum(case when period_number = 0 then active_customers end) as p0,
       sum(case when period_number = 1 then active_customers end) as p1,
       sum(case when period_number = 2 then active_customers end) as p2,
       sum(case when period_number = 3 then active_customers end) as p3,
       sum(case when period_number = 4 then active_customers end) as p4,
       sum(case when period_number = 5 then active_customers end) as p5,
       sum(case when period_number = 6 then active_customers end) as p6
from retention
group by cohort_month
order by cohort_month;

-- output: 23 cohort rows; p0 contains each cohort's full starting count.


-- Q6: extracting the initial size of each cohort.

-- delivered_orders: keep one row per order and attach the stable person id
with delivered_orders as (
    select o.order_id, o.customer_id, c.customer_unique_id,
           c.customer_state, o.order_purchase_timestamp,
           o.order_delivered_customer_date, o.order_estimated_delivery_date
    from olist_orders o
    join olist_customers c on c.customer_id = o.customer_id
    where o.order_status = 'delivered'
      and o.order_purchase_timestamp is not null
),
-- cohorts: first delivered purchase month for each real customer
cohorts as (
    select customer_unique_id,
           date_format(min(order_purchase_timestamp), '%Y-%m-01') as cohort_month
    from delivered_orders
    group by customer_unique_id
),
-- activity: each delivered order's calendar month
activity as (
    select order_id, customer_unique_id,
           date_format(order_purchase_timestamp, '%Y-%m-01') as order_month
    from delivered_orders
),
-- periods: whole calendar months since the customer's first purchase
periods as (
    select a.order_id, a.customer_unique_id, c.cohort_month, a.order_month,
           (year(a.order_month) - year(c.cohort_month)) * 12
           + month(a.order_month) - month(c.cohort_month) as period_number
    from activity a
    join cohorts c on c.customer_unique_id = a.customer_unique_id
),
-- monthly_customers: multiple orders by one person in the same month count once
monthly_customers as (
    select cohort_month, period_number,
           count(distinct customer_unique_id) as active_customers
    from periods
    group by cohort_month, period_number
),
-- cohort_sizes: the month-0 customer count is the denominator
cohort_sizes as (
    select cohort_month, active_customers as cohort_size
    from monthly_customers
    where period_number = 0
),
-- period_list: compare cohorts on the same first seven calendar months
period_list as (
    select 0 as period_number union all select 1 union all select 2
    union all select 3 union all select 4 union all select 5 union all select 6
),
-- observed: a period beyond the last available order month is unknown, not zero
observed as (
    select s.cohort_month, s.cohort_size, n.period_number,
           case when n.period_number <=
               (year(a.last_month) - year(s.cohort_month)) * 12
               + month(a.last_month) - month(s.cohort_month)
                then coalesce(max(m.active_customers), 0)
                else null end as active_customers
    from cohort_sizes s
    cross join period_list n
    cross join (select max(order_month) as last_month from activity) a
    left join monthly_customers m on m.cohort_month = s.cohort_month
                                 and m.period_number = n.period_number
    group by s.cohort_month, s.cohort_size, n.period_number, a.last_month
),
-- retention: always divide by that cohort's own month-0 size
retention as (
    select cohort_month, period_number, cohort_size, active_customers,
           round(100.0 * active_customers / cohort_size, 4) as retention_pct
    from observed
)
select cohort_month, cohort_size
from cohort_sizes
order by cohort_month;

-- output: 93,358 customers across 23 cohorts.


-- Q7: calculating retention as a percentage of each cohort's size.

-- delivered_orders: keep one row per order and attach the stable person id
with delivered_orders as (
    select o.order_id, o.customer_id, c.customer_unique_id,
           c.customer_state, o.order_purchase_timestamp,
           o.order_delivered_customer_date, o.order_estimated_delivery_date
    from olist_orders o
    join olist_customers c on c.customer_id = o.customer_id
    where o.order_status = 'delivered'
      and o.order_purchase_timestamp is not null
),
-- cohorts: first delivered purchase month for each real customer
cohorts as (
    select customer_unique_id,
           date_format(min(order_purchase_timestamp), '%Y-%m-01') as cohort_month
    from delivered_orders
    group by customer_unique_id
),
-- activity: each delivered order's calendar month
activity as (
    select order_id, customer_unique_id,
           date_format(order_purchase_timestamp, '%Y-%m-01') as order_month
    from delivered_orders
),
-- periods: whole calendar months since the customer's first purchase
periods as (
    select a.order_id, a.customer_unique_id, c.cohort_month, a.order_month,
           (year(a.order_month) - year(c.cohort_month)) * 12
           + month(a.order_month) - month(c.cohort_month) as period_number
    from activity a
    join cohorts c on c.customer_unique_id = a.customer_unique_id
),
-- monthly_customers: multiple orders by one person in the same month count once
monthly_customers as (
    select cohort_month, period_number,
           count(distinct customer_unique_id) as active_customers
    from periods
    group by cohort_month, period_number
),
-- cohort_sizes: the month-0 customer count is the denominator
cohort_sizes as (
    select cohort_month, active_customers as cohort_size
    from monthly_customers
    where period_number = 0
),
-- period_list: compare cohorts on the same first seven calendar months
period_list as (
    select 0 as period_number union all select 1 union all select 2
    union all select 3 union all select 4 union all select 5 union all select 6
),
-- observed: a period beyond the last available order month is unknown, not zero
observed as (
    select s.cohort_month, s.cohort_size, n.period_number,
           case when n.period_number <=
               (year(a.last_month) - year(s.cohort_month)) * 12
               + month(a.last_month) - month(s.cohort_month)
                then coalesce(max(m.active_customers), 0)
                else null end as active_customers
    from cohort_sizes s
    cross join period_list n
    cross join (select max(order_month) as last_month from activity) a
    left join monthly_customers m on m.cohort_month = s.cohort_month
                                 and m.period_number = n.period_number
    group by s.cohort_month, s.cohort_size, n.period_number, a.last_month
),
-- retention: always divide by that cohort's own month-0 size
retention as (
    select cohort_month, period_number, cohort_size, active_customers,
           round(100.0 * active_customers / cohort_size, 4) as retention_pct
    from observed
)
select cohort_month, max(cohort_size) as cohort_size,
       max(case when period_number = 0 then retention_pct end) as p0,
       max(case when period_number = 1 then retention_pct end) as p1,
       max(case when period_number = 2 then retention_pct end) as p2,
       max(case when period_number = 3 then retention_pct end) as p3,
       max(case when period_number = 4 then retention_pct end) as p4,
       max(case when period_number = 5 then retention_pct end) as p5,
       max(case when period_number = 6 then retention_pct end) as p6
from retention
group by cohort_month
order by cohort_month;

-- output: 23 cohort rows; every p0 = 100%; future months are null.


-- Q8: calculating average retention across observable periods.

-- delivered_orders: keep one row per order and attach the stable person id
with delivered_orders as (
    select o.order_id, o.customer_id, c.customer_unique_id,
           c.customer_state, o.order_purchase_timestamp,
           o.order_delivered_customer_date, o.order_estimated_delivery_date
    from olist_orders o
    join olist_customers c on c.customer_id = o.customer_id
    where o.order_status = 'delivered'
      and o.order_purchase_timestamp is not null
),
-- cohorts: first delivered purchase month for each real customer
cohorts as (
    select customer_unique_id,
           date_format(min(order_purchase_timestamp), '%Y-%m-01') as cohort_month
    from delivered_orders
    group by customer_unique_id
),
-- activity: each delivered order's calendar month
activity as (
    select order_id, customer_unique_id,
           date_format(order_purchase_timestamp, '%Y-%m-01') as order_month
    from delivered_orders
),
-- periods: whole calendar months since the customer's first purchase
periods as (
    select a.order_id, a.customer_unique_id, c.cohort_month, a.order_month,
           (year(a.order_month) - year(c.cohort_month)) * 12
           + month(a.order_month) - month(c.cohort_month) as period_number
    from activity a
    join cohorts c on c.customer_unique_id = a.customer_unique_id
),
-- monthly_customers: multiple orders by one person in the same month count once
monthly_customers as (
    select cohort_month, period_number,
           count(distinct customer_unique_id) as active_customers
    from periods
    group by cohort_month, period_number
),
-- cohort_sizes: the month-0 customer count is the denominator
cohort_sizes as (
    select cohort_month, active_customers as cohort_size
    from monthly_customers
    where period_number = 0
),
-- period_list: compare cohorts on the same first seven calendar months
period_list as (
    select 0 as period_number union all select 1 union all select 2
    union all select 3 union all select 4 union all select 5 union all select 6
),
-- observed: a period beyond the last available order month is unknown, not zero
observed as (
    select s.cohort_month, s.cohort_size, n.period_number,
           case when n.period_number <=
               (year(a.last_month) - year(s.cohort_month)) * 12
               + month(a.last_month) - month(s.cohort_month)
                then coalesce(max(m.active_customers), 0)
                else null end as active_customers
    from cohort_sizes s
    cross join period_list n
    cross join (select max(order_month) as last_month from activity) a
    left join monthly_customers m on m.cohort_month = s.cohort_month
                                 and m.period_number = n.period_number
    group by s.cohort_month, s.cohort_size, n.period_number, a.last_month
),
-- retention: always divide by that cohort's own month-0 size
retention as (
    select cohort_month, period_number, cohort_size, active_customers,
           round(100.0 * active_customers / cohort_size, 4) as retention_pct
    from observed
)
select period_number, count(*) as observed_cohorts,
       round(avg(retention_pct), 4) as average_all_cohorts_pct,
       sum(case when cohort_month >= '2017-01-01' and cohort_size >= 500
                then 1 else 0 end) as stable_cohorts,
       round(avg(case when cohort_month >= '2017-01-01' and cohort_size >= 500
                 then retention_pct end), 4) as average_retention_pct,
       round(100.0 * sum(case when cohort_month >= '2017-01-01'
                                and cohort_size >= 500 then active_customers end)
                     / sum(case when cohort_month >= '2017-01-01'
                                      and cohort_size >= 500 then cohort_size end), 4)
           as weighted_retention_pct
from retention
where active_customers is not null
group by period_number
order by period_number;

-- output: p1 = 0.4757% across 19 stable cohorts; full-sample average is also shown.


-- Q9: comparing the strongest and weakest cohorts in month 1.

-- delivered_orders: keep one row per order and attach the stable person id
with delivered_orders as (
    select o.order_id, o.customer_id, c.customer_unique_id,
           c.customer_state, o.order_purchase_timestamp,
           o.order_delivered_customer_date, o.order_estimated_delivery_date
    from olist_orders o
    join olist_customers c on c.customer_id = o.customer_id
    where o.order_status = 'delivered'
      and o.order_purchase_timestamp is not null
),
-- cohorts: first delivered purchase month for each real customer
cohorts as (
    select customer_unique_id,
           date_format(min(order_purchase_timestamp), '%Y-%m-01') as cohort_month
    from delivered_orders
    group by customer_unique_id
),
-- activity: each delivered order's calendar month
activity as (
    select order_id, customer_unique_id,
           date_format(order_purchase_timestamp, '%Y-%m-01') as order_month
    from delivered_orders
),
-- periods: whole calendar months since the customer's first purchase
periods as (
    select a.order_id, a.customer_unique_id, c.cohort_month, a.order_month,
           (year(a.order_month) - year(c.cohort_month)) * 12
           + month(a.order_month) - month(c.cohort_month) as period_number
    from activity a
    join cohorts c on c.customer_unique_id = a.customer_unique_id
),
-- monthly_customers: multiple orders by one person in the same month count once
monthly_customers as (
    select cohort_month, period_number,
           count(distinct customer_unique_id) as active_customers
    from periods
    group by cohort_month, period_number
),
-- cohort_sizes: the month-0 customer count is the denominator
cohort_sizes as (
    select cohort_month, active_customers as cohort_size
    from monthly_customers
    where period_number = 0
),
-- period_list: compare cohorts on the same first seven calendar months
period_list as (
    select 0 as period_number union all select 1 union all select 2
    union all select 3 union all select 4 union all select 5 union all select 6
),
-- observed: a period beyond the last available order month is unknown, not zero
observed as (
    select s.cohort_month, s.cohort_size, n.period_number,
           case when n.period_number <=
               (year(a.last_month) - year(s.cohort_month)) * 12
               + month(a.last_month) - month(s.cohort_month)
                then coalesce(max(m.active_customers), 0)
                else null end as active_customers
    from cohort_sizes s
    cross join period_list n
    cross join (select max(order_month) as last_month from activity) a
    left join monthly_customers m on m.cohort_month = s.cohort_month
                                 and m.period_number = n.period_number
    group by s.cohort_month, s.cohort_size, n.period_number, a.last_month
),
-- retention: always divide by that cohort's own month-0 size
retention as (
    select cohort_month, period_number, cohort_size, active_customers,
           round(100.0 * active_customers / cohort_size, 4) as retention_pct
    from observed
)
, -- first_orders: checking each customer's first order
first_orders as (
    select d.order_id, d.customer_unique_id, c.cohort_month,
           d.order_delivered_customer_date, d.order_estimated_delivery_date,
           row_number() over (
               partition by d.customer_unique_id
               order by d.order_purchase_timestamp, d.order_id
           ) as first_rank
    from delivered_orders d
    join cohorts c on c.customer_unique_id = d.customer_unique_id
),
-- review_by_order: avoid multiplying orders with more than one review
review_by_order as (
    select order_id, avg(review_score) as review_score
    from olist_order_reviews
    group by order_id
),
-- cohort_experience: comparing cohort experience																																
cohort_experience as (
    select f.cohort_month,
           round(avg(r.review_score), 3) as first_order_review,
           round(100.0 * avg(case
               when f.order_delivered_customer_date > f.order_estimated_delivery_date
               then 1.0 else 0.0 end), 2) as late_delivery_pct
    from first_orders f
    left join review_by_order r on r.order_id = f.order_id
    where f.first_rank = 1
    group by f.cohort_month
)
select r.cohort_month, r.cohort_size, r.active_customers as returning_customers,
       r.retention_pct as month_1_pct, e.first_order_review, e.late_delivery_pct
from retention r
join cohort_experience e on e.cohort_month = r.cohort_month
where r.period_number = 1 and r.cohort_month >= '2017-01-01'
  and r.cohort_size >= 500 and r.active_customers is not null
order by month_1_pct desc, r.cohort_month;

-- output: best: 2017-10 (0.7163%); worst: 2017-02 (0.1843%).


-- Q10: calculating cohort revenue from delivered order items.

-- delivered_orders: keep one row per order and attach the stable person id
with delivered_orders as (
    select o.order_id, o.customer_id, c.customer_unique_id,
           c.customer_state, o.order_purchase_timestamp,
           o.order_delivered_customer_date, o.order_estimated_delivery_date
    from olist_orders o
    join olist_customers c on c.customer_id = o.customer_id
    where o.order_status = 'delivered'
      and o.order_purchase_timestamp is not null
),

-- cohorts: first delivered purchase month for each real customer
cohorts as (
    select customer_unique_id,
           date_format(min(order_purchase_timestamp), '%Y-%m-01') as cohort_month
    from delivered_orders
    group by customer_unique_id
),

-- activity: each delivered order's calendar month
activity as (
    select order_id, customer_unique_id,
           date_format(order_purchase_timestamp, '%Y-%m-01') as order_month
    from delivered_orders
),
-- periods: whole calendar months since the customer's first purchase
periods as (
    select a.order_id, a.customer_unique_id, c.cohort_month, a.order_month,
           (year(a.order_month) - year(c.cohort_month)) * 12
           + month(a.order_month) - month(c.cohort_month) as period_number
    from activity a
    join cohorts c on c.customer_unique_id = a.customer_unique_id
),

-- monthly_customers: multiple orders by one person in the same month count once
monthly_customers as (
    select cohort_month, period_number,
           count(distinct customer_unique_id) as active_customers
    from periods
    group by cohort_month, period_number
),

-- cohort_sizes: the month-0 customer count is the denominator
cohort_sizes as (
    select cohort_month, active_customers as cohort_size
    from monthly_customers
    where period_number = 0
),

-- period_list: compare cohorts on the same first seven calendar months
period_list as (
    select 0 as period_number union all select 1 union all select 2
    union all select 3 union all select 4 union all select 5 union all select 6
),

-- observed: a period beyond the last available order month is unknown, not zero
observed as (
    select s.cohort_month, s.cohort_size, n.period_number,
           case when n.period_number <=
               (year(a.last_month) - year(s.cohort_month)) * 12
               + month(a.last_month) - month(s.cohort_month)
                then coalesce(max(m.active_customers), 0)
                else null end as active_customers
    from cohort_sizes s
    cross join period_list n
    cross join (select max(order_month) as last_month from activity) a
    left join monthly_customers m on m.cohort_month = s.cohort_month
                                 and m.period_number = n.period_number
    group by s.cohort_month, s.cohort_size, n.period_number, a.last_month
),
-- retention: always divide by that cohort's own month-0 size
retention as (
    select cohort_month, period_number, cohort_size, active_customers,
           round(100.0 * active_customers / cohort_size, 4) as retention_pct
    from observed
)
, -- item_totals: summing item revenue by order
item_totals as (
    select order_id, sum(price) as item_revenue
    from olist_order_items
    group by order_id
),
-- monthly_revenue: calculating monthly cohort revenue
monthly_revenue as (
    select p.cohort_month, p.period_number,
           round(sum(i.item_revenue), 2) as revenue_brl
    from periods p
    join item_totals i on i.order_id = p.order_id
    group by p.cohort_month, p.period_number
),
-- revenue_grid: keeping unobserved periods as null
revenue_grid as (
    select r.cohort_month, r.period_number, r.cohort_size,
           case when r.active_customers is not null
                then coalesce(m.revenue_brl, 0) end as revenue_brl
    from retention r
    left join monthly_revenue m on m.cohort_month = r.cohort_month
                               and m.period_number = r.period_number
)
select cohort_month, period_number, cohort_size, revenue_brl,
       round(revenue_brl / cohort_size, 4) as revenue_per_original_customer_brl,
       case when revenue_brl is not null then round(sum(revenue_brl) over (
           partition by cohort_month order by period_number
       ) / cohort_size, 4) end as cumulative_revenue_per_customer_brl
from revenue_grid
order by cohort_month, period_number;

-- output: 161 cohort-period cells; price revenue excludes freight.


-- Addition 1: checking the relationship between delivery delays and customer reviews.

-- review_by_order: averaging reviews by order.
with review_by_order as (
    select order_id, avg(review_score) as review_score
    from olist_order_reviews
    group by order_id
)
select case when o.order_delivered_customer_date > o.order_estimated_delivery_date
                 then 'late' else 'on time' end as delivery_group,
       count(*) as reviewed_orders,
       round(avg(r.review_score), 3) as average_review,
       round(100.0 * avg(case when r.review_score <= 2 then 1.0 else 0.0 end), 2)
           as low_review_pct
from olist_orders o
join review_by_order r on r.order_id = o.order_id
where o.order_status = 'delivered'
  and o.order_delivered_customer_date is not null
  and o.order_estimated_delivery_date is not null
group by delivery_group
order by delivery_group;

-- output: late: 7,661 reviews, mean 2.567; on time: 88,163 reviews, mean 4.294.


-- Addition 2: identifying the main payment method for delivered orders.

-- payment_rank: ranking payment methods by order
with payment_rank as (
    select order_id, payment_type, payment_value,
           row_number() over (
               partition by order_id order by payment_value desc, payment_sequential
           ) as rn
    from olist_order_payments
)
select p.payment_type, count(*) as delivered_orders,
       round(100.0 * count(*) / sum(count(*)) over (), 2) as order_share_pct
from olist_orders o
join payment_rank p on p.order_id = o.order_id and p.rn = 1
where o.order_status = 'delivered'
group by p.payment_type
order by delivered_orders desc;

-- output: credit_card 75.48%; boleto 19.89%; voucher 3.09%; debit_card 1.54%.
