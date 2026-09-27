create database if not exists olist_cohort;
use olist_cohort;


set global local_infile = 1;

create table if not exists olist_customers (
    customer_id char(32) primary key,
    customer_unique_id char(32) not null,
    customer_zip_code_prefix char(5),
    customer_city varchar(100),
    customer_state char(2),
    index idx_unique_customer (customer_unique_id)
);
create table if not exists olist_orders (
    order_id char(32) primary key,
    customer_id char(32) not null,
    order_status varchar(20) not null,
    order_purchase_timestamp datetime,
    order_approved_at datetime,
    order_delivered_carrier_date datetime,
    order_delivered_customer_date datetime,
    order_estimated_delivery_date datetime,
    index idx_order_customer (customer_id),
    index idx_order_status_date (order_status, order_purchase_timestamp)
);
create table if not exists olist_order_items (
    order_id char(32) not null,
    order_item_id smallint unsigned not null,
    product_id char(32),
    seller_id char(32),
    shipping_limit_date datetime,
    price decimal(12,2),
    freight_value decimal(12,2),
    primary key (order_id, order_item_id)
);
create table if not exists olist_order_reviews (
    review_id char(32) not null,
    order_id char(32) not null,
    review_score tinyint unsigned,
    review_comment_title text,
    review_comment_message text,
    review_creation_date datetime,
    review_answer_timestamp datetime,
    index idx_review_order (order_id)
);
create table if not exists olist_order_payments (
    order_id char(32) not null,
    payment_sequential smallint unsigned not null,
    payment_type varchar(30),
    payment_installments smallint unsigned,
    payment_value decimal(12,2),
    primary key (order_id, payment_sequential)
);

load data local infile 'C:/Users/your_name/Downloads/olist_customers_dataset.csv'
into table olist_customers
character set utf8mb4 fields terminated by ',' optionally enclosed by '"'
lines terminated by '\n' ignore 1 lines
(@customer_id, @customer_unique_id, @zip, @city, @state)
set customer_id = @customer_id, customer_unique_id = @customer_unique_id,
    customer_zip_code_prefix = @zip, customer_city = @city,
    customer_state = trim(trailing '\r' from @state);

load data local infile 'C:/Users/your_name/Downloads/olist_orders_dataset.csv'
into table olist_orders
character set utf8mb4 fields terminated by ',' optionally enclosed by '"'
lines terminated by '\n' ignore 1 lines
(@id, @customer, @status, @purchased, @approved, @carrier, @delivered, @estimated)
set order_id = @id, customer_id = @customer, order_status = @status,
    order_purchase_timestamp = nullif(@purchased, ''), order_approved_at = nullif(@approved, ''),
    order_delivered_carrier_date = nullif(@carrier, ''),
    order_delivered_customer_date = nullif(@delivered, ''),
    order_estimated_delivery_date = nullif(trim(trailing '\r' from @estimated), '');

load data local infile 'C:/Users/your_name/Downloads/olist_order_items_dataset.csv'
into table olist_order_items
character set utf8mb4 fields terminated by ',' optionally enclosed by '"'
lines terminated by '\n' ignore 1 lines
(@order, @item, @product, @seller, @limit, @price, @freight)
set order_id = @order, order_item_id = @item, product_id = @product,
    seller_id = @seller, shipping_limit_date = nullif(@limit, ''),
    price = nullif(@price, ''), freight_value = nullif(trim(trailing '\r' from @freight), '');

load data local infile 'C:/Users/your_name/Downloads/olist_order_reviews_dataset.csv'
into table olist_order_reviews
character set utf8mb4 fields terminated by ',' optionally enclosed by '"'
lines terminated by '\n' ignore 1 lines
(@review, @order, @score, @title, @message, @created, @answered)
set review_id = @review, order_id = @order, review_score = nullif(@score, ''),
    review_comment_title = nullif(@title, ''), review_comment_message = nullif(@message, ''),
    review_creation_date = nullif(@created, ''),
    review_answer_timestamp = nullif(trim(trailing '\r' from @answered), '');

load data local infile 'C:/Users/your_name/Downloads/olist_order_payments_dataset.csv'
into table olist_order_payments
character set utf8mb4 fields terminated by ',' optionally enclosed by '"'
lines terminated by '\n' ignore 1 lines
(@order, @sequence, @type, @installments, @value)
set order_id = @order, payment_sequential = @sequence, payment_type = @type,
    payment_installments = @installments,
    payment_value = nullif(trim(trailing '\r' from @value), '');

-- check the import before running q1
select (select count(*) from olist_orders) as orders_loaded,
       (select count(*) from olist_customers) as customers_loaded,
       (select count(*) from olist_order_items) as items_loaded,
       (select count(*) from olist_order_reviews) as reviews_loaded,
       (select count(*) from olist_order_payments) as payments_loaded;
