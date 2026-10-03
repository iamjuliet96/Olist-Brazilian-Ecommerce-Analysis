/* ============================================================
   05_analysis_queries.sql
   Purpose: The final query for each of the 5 business questions.
   ============================================================ */

-- ============================================================
-- QUESTION 1: Delivery Performance
-- How does actual delivery compare to the estimate, and does it
-- vary by customer state, seller state, or individual seller?
-- ============================================================
--question 1:How does actual delivery time compare to the 
--estimated delivery date, and does it vary by state or seller?
--for customer state 

WITH delivery_calc AS (
select
o.order_key,
c.customer_state,
DATEDIFF(day, o.order_estimated_delivery_date, o.order_delivered_customer_date) as delivery_gap_days,
Case 
   when DATEDIFF(day, o.order_estimated_delivery_date, o.order_delivered_customer_date)> 0 then 'late'
   when  DATEDIFF(day, o.order_estimated_delivery_date, o.order_delivered_customer_date) =0 then 'on_time'
                  else 'early'
                  end as delivery_status
from order_clean o
join customer_clean c on o.order_key= c.order_key
where o.order_delivered_customer_date is not null
and o.order_status ='Delivered'
)

select
customer_state,
count(*) as total_orders,
Round(AVG(cast(delivery_gap_days as float)),2) AS Avg_delivery_gap_days,
Round(sum(case when  delivery_status= 'late' then 1.0 else 0 end) / count(*) * 100, 2) as pct_late
from delivery_calc
group by customer_state
order by Avg_delivery_gap_days desc

-- for the seller_state

WITH delivery_calc_sellers AS (
select Distinct
o.order_key,
s.seller_key,
s.seller_state,
DATEDIFF(day, o.order_estimated_delivery_date, o.order_delivered_customer_date) as delivery_gap_days,
Case 
   when DATEDIFF(day, o.order_estimated_delivery_date, o.order_delivered_customer_date)> 0 then 'late'
   when  DATEDIFF(day, o.order_estimated_delivery_date, o.order_delivered_customer_date) =0 then 'on_time'
                  else 'early'
                  end as delivery_status
from order_clean o
join ORDERS_ITEM_CLEAN oi  on o.order_key= oi.order_key
join seller_clean s on oi.seller_key = s.seller_key
where o.order_delivered_customer_date is not null
and o.order_status ='Delivered'
)

select
seller_state,
count(*) as total_orders,
Round(AVG(cast(delivery_gap_days as float)),2) AS Avg_delivery_gap_days,
Round(sum(case when  delivery_status= 'late' then 1.0 else 0 end) / count(*) * 100, 2) as pct_late
from delivery_calc_sellers
group by seller_state
order by pct_late desc


-- ============================================================
-- QUESTION 2: Revenue & Order Value Trends
-- Month-over-month order volume, revenue, and AOV
-- ============================================================

WITH order_totals AS (
    SELECT
        o.order_key,
        MONTH(o.order_approved_at) AS order_month,
        DATENAME(month, o.order_approved_at) AS order_month_name,
        YEAR(o.order_approved_at) AS order_year,
        ROUND(SUM(p.payment_value), 2) AS total_order
    FROM order_clean o
    JOIN payment_clean p ON o.order_key = p.order_key
    WHERE o.order_approved_at IS NOT NULL
      AND o.order_status = 'delivered'
    GROUP BY o.order_key, MONTH(o.order_approved_at), YEAR(o.order_approved_at), DATENAME(month, o.order_approved_at)
),
monthly_summary AS (
    SELECT
        order_month,
        order_month_name,
        order_year,
        COUNT(*) AS order_volume,
        ROUND(SUM(total_order), 2) AS total_revenue,
        ROUND(AVG(total_order), 2) AS avg_order_value
    FROM order_totals
    GROUP BY order_month, order_year, order_month_name
)
SELECT
    order_month_name,
    order_year,
    order_volume,
    total_revenue,
    avg_order_value,
    LAG(order_volume) OVER (ORDER BY order_year, order_month) AS prev_month_vol,
    ROUND(100.0 * (order_volume - LAG(order_volume) OVER (ORDER BY order_year, order_month))
        / LAG(order_volume) OVER (ORDER BY order_year, order_month), 2) AS vol_mom_pct,
    LAG(avg_order_value) OVER (ORDER BY order_year, order_month) AS prev_month_aov,
    ROUND(100.0 * (avg_order_value - LAG(avg_order_value) OVER (ORDER BY order_year, order_month))
        / LAG(avg_order_value) OVER (ORDER BY order_year, order_month), 2) AS aov_mom_pct
FROM monthly_summary
ORDER BY order_year, order_month;

-- ============================================================
-- QUESTION 3: Category Performance
-- Revenue, item count, and freight cost by product category
-- ============================================================
select
    p.product_category_name,
    count(*) as total_items_sold,
   Round(sum(oi.price),2) as total_revenue,
    Round(AVG(oi.price),2) as avg_price,
    count(distinct oi.order_key) as total_orders,
    Round(avg(oi.freight_value),2) as avg_freight
from orders_item_clean oi
    join product_clean p on oi.product_key=p.product_key
group by p.product_category_name
order by total_revenue desc

-- ============================================================
-- QUESTION 4: Payment Behavior
-- Payment type breakdown and installments by order value tier
-- ============================================================
--4a
select 
payment_type,
count (*) as payment_count,
sum(payment_value) as sum_payment_value,
avg(payment_value) as avg_payment_value,
avg(payment_installments) as avg_installments,
count (Distinct order_key) as total_orders
from payment_clean
group by payment_type 
order by payment_count desc

--4b: installments by order_value

with order_totals as( 
select 
order_key,
Round(sum(payment_value),2) as order_value,
max(payment_installments) as installments
from payment_clean
group by order_key
)
select 
  case
    when order_value < 50 then '0-50'
    when order_value < 100 then '50-100'
    when order_value < 200 then '100-200'
    when order_value < 500 then '200-500'
    else '500'
  end as value_tier,
  Round(avg(cast(installments as float)),2) as avg_installments
  from order_totals
  group by 
  case
    when order_value < 50 then '0-50'
    when order_value < 100 then '50-100'
    when order_value < 200 then '100-200'
    when order_value < 500 then '200-500'
    else '500'
  end
  order by avg_installments

-- ============================================================
-- QUESTION 5: Customer Geography & Repeat Purchases
-- ============================================================

-- 5a. Unique customers by state
select
count(distinct customer_key) as customers_total,
customer_state
from customer_clean
group by customer_state
order by customers_total desc

--Part B; What share of them come back to buy    

WITH customer_order_counts AS (
    SELECT
        customer_key,
        COUNT(DISTINCT order_key) AS num_orders
    FROM customer_clean
    GROUP BY customer_key
)
SELECT
    COUNT(*) AS total_customers,
    SUM(CASE WHEN num_orders > 1 THEN 1 ELSE 0 END) AS repeat_customers,
   ROUND(
    CAST(SUM(CASE WHEN num_orders > 1 THEN 1 ELSE 0 END) AS FLOAT) 
    / COUNT(*) * 100, 
2) AS repeat_rate_pct
FROM customer_order_counts;

--THE END.


