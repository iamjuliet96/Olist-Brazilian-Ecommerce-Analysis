/* ============================================================
   01_data_quality_checks.sql
   Purpose: Establish the grain of each raw table, then check
   for duplicate rows, duplicate keys, and null values BEFORE
   any cleaning or transformation is done.
   ============================================================ */

-- ------------------------------------------------------------
-- STEP 1: Row counts vs. unique key counts
-- Tables where grain = "one row per entity": counts should match
-- ------------------------------------------------------------
SELECT 'olist_sellers_dataset' AS table_name, COUNT(*) AS total_rows, COUNT(DISTINCT seller_id) AS unique_keys FROM olist_sellers_dataset
UNION ALL
SELECT 'olist_products_dataset', COUNT(*), COUNT(DISTINCT product_id) FROM olist_products_dataset
UNION ALL
SELECT 'olist_orders_dataset', COUNT(*), COUNT(DISTINCT order_id) FROM olist_orders_dataset
UNION ALL
SELECT '[olist_customers_dataset(1)]', COUNT(*), COUNT(DISTINCT customer_id) FROM [olist_customers_dataset (1)];

-- ------------------------------------------------------------
-- STEP 2: Composite-key uniqueness for tables where the natural
-- key legitimately repeats (grain = "one line item" / "one payment")
-- ------------------------------------------------------------

-- order_items: grain = one line item per order -> key = (order_id, order_item_id)
SELECT order_id, order_item_id, COUNT(*) AS occurrences
FROM olist_order_items_dataset
GROUP BY order_id, order_item_id
HAVING COUNT(*) > 1;

-- order_payments: grain = one payment installment/method per order -> key = (order_id, payment_sequential)
SELECT order_id, payment_sequential, COUNT(*) AS occurrences
FROM olist_order_payments_dataset
GROUP BY order_id, payment_sequential
HAVING COUNT(*) > 1;

-- ------------------------------------------------------------
-- STEP 3: customers table -- confirm the customer_id vs
-- customer_unique_id distinction (order-grain vs person-grain)
-- ------------------------------------------------------------
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT customer_id) AS unique_customer_id,      -- expected to equal total_rows
    COUNT(DISTINCT customer_unique_id) AS unique_customer_unique_id  -- expected to be LOWER (real people)
FROM [olist_customers_dataset (1)];

-- ------------------------------------------------------------
-- STEP 4: Null checks, per table
-- Auto-generate a null-count query for any table using
-- INFORMATION_SCHEMA, so every column is checked without
-- typing each one manually.
-- ------------------------------------------------------------
DECLARE @sql NVARCHAR(MAX);

SELECT @sql = STRING_AGG(
    'SUM(CASE WHEN ' + COLUMN_NAME + ' IS NULL THEN 1 ELSE 0 END) AS null_' + COLUMN_NAME,
    ', '
)
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'olist_products_dataset';   -- change table name as needed

SET @sql = 'SELECT ' + @sql + ' FROM olist_products_dataset';
EXEC(@sql);

-- Repeat the block above with TABLE_NAME = 'products', 'olist_order_items_dataset', etc.

-- ------------------------------------------------------------
-- STEP 5: Combined null + blank/placeholder check (text columns)
-- Catches empty strings and common placeholder values that
-- IS NULL alone would miss.
-- ------------------------------------------------------------
SELECT
    SUM(CASE WHEN product_category_name IS NULL THEN 1 ELSE 0 END) AS true_nulls,
    SUM(CASE WHEN LTRIM(RTRIM(product_category_name)) = '' THEN 1 ELSE 0 END) AS empty_strings,
    SUM(CASE WHEN product_category_name IS NULL
              OR LTRIM(RTRIM(product_category_name)) = '' THEN 1 ELSE 0 END) AS total_missing
FROM olist_products_dataset;

-- ------------------------------------------------------------
-- STEP 6: Orders null breakdown by status (context check --
-- confirms whether nulls correlate with cancelled/undelivered
-- orders, which would make them expected rather than errors)
-- ------------------------------------------------------------
SELECT order_status, COUNT(*) AS order_count
FROM olist_orders_dataset
WHERE order_approved_at IS NULL
GROUP BY order_status;

