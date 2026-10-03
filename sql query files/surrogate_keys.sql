/* ============================================================
   02_surrogate_keys.sql
   Purpose: Replace hashed source IDs with clean integer
   surrogate keys. Each dimension key is built ONCE and reused
   everywhere that hash appears, so joins stay consistent
   across every downstream table.
   ============================================================ */

-- ------------------------------------------------------------
-- Customer (PERSON) key -- based on customer_unique_id
-- DENSE_RANK is used because customer_unique_id genuinely
-- repeats (same person can place multiple orders).
-- ------------------------------------------------------------
DROP TABLE IF EXISTS dim_customer_key;
SELECT
    customer_unique_id,
    DENSE_RANK() OVER (ORDER BY customer_unique_id) AS customer_key
INTO dim_customer_key
FROM (SELECT DISTINCT customer_unique_id FROM [olist_customers_dataset (1)]) t;

-- Order key -- based on order_id (already unique per row)
-- ------------------------------------------------------------
DROP TABLE IF EXISTS dim_order_key;

SELECT
    order_id,
    ROW_NUMBER() OVER (ORDER BY order_id) AS order_key
INTO dim_order_key
FROM olist_orders_dataset

-- ------------------------------------------------------------
-- Product key -- based on product_id (already unique per row)
-- ------------------------------------------------------------
DROP TABLE IF EXISTS dim_product_key;

SELECT
    product_id,
    ROW_NUMBER() OVER (ORDER BY product_id) AS product_key
INTO dim_product_key
FROM  olist_products_dataset

-- ------------------------------------------------------------
-- Seller key -- based on seller_id (already unique per row)
-- ------------------------------------------------------------
DROP TABLE IF EXISTS dim_seller_key;

SELECT
    seller_id,
    ROW_NUMBER() OVER (ORDER BY seller_id) AS seller_key
INTO dim_seller_key
FROM olist_sellers_dataset

-- ------------------------------------------------------------
-- Verification: confirm every dimension key table has no
-- duplicate keys and matches the expected row count
-- ------------------------------------------------------------
SELECT 'dim_customer_key' AS table_name, COUNT(*) AS total_rows, COUNT(DISTINCT customer_key) AS unique_keys FROM dim_customer_key
UNION ALL
SELECT 'dim_order_key', COUNT(*), COUNT(DISTINCT order_key) FROM dim_order_key
UNION ALL
SELECT 'dim_product_key', COUNT(*), COUNT(DISTINCT product_key) FROM dim_product_key
UNION ALL
SELECT 'dim_seller_key', COUNT(*), COUNT(DISTINCT seller_key) FROM dim_seller_key;
