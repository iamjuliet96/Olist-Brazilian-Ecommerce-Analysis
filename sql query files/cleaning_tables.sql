/* ============================================================
   03_clean_tables.sql
   Purpose: Build the final _clean tables used by Power BI.
   - Replaces hashed IDs with surrogate keys (via dim_*_key)
   - Casts date/time columns properly
   - Fills or flags nulls deliberately (never silently dropped)
   - Normalizes text (trim/lowercase city names)
   Run 01 and 02 before this script.
   ============================================================ */

-- ------------------------------------------------------------
-- customer_clean
-- Grain: one row per order-customer record (matches orders_clean 1:1)
-- ------------------------------------------------------------
DROP TABLE IF EXISTS customer_clean;
SELECT
    ok.order_key,
    ck.customer_key,
    c.customer_zip_code_prefix,
    LOWER(LTRIM(RTRIM(c.customer_city))) AS customer_city,         
    c.customer_state,
    c.customer_id,
    c.customer_unique_id
INTO customer_clean
FROM [olist_customers_dataset (1)] c
JOIN olist_orders_dataset o ON c.customer_id = o.customer_id
JOIN dim_order_key ok ON o.order_id = ok.order_id
JOIN dim_customer_key ck ON c.customer_unique_id = ck.customer_unique_id;

CREATE NONCLUSTERED INDEX IX_customers_clean_order_key ON customer_clean(order_key);
CREATE NONCLUSTERED INDEX IX_customers_clean_customer_key ON customer_clean(customer_key);

-- ------------------------------------------------------------
-- order_clean
-- Grain: one row per order
-- ------------------------------------------------------------
DROP TABLE IF EXISTS order_clean;select
        ok.order_key,
        o.order_status,
        o.order_approved_at,
        o.order_delivered_carrier_date,
        o.order_delivered_customer_date,
        o.order_estimated_delivery_date,
        o.order_id,
        o.customer_id
        INTO Order_clean 
        from olist_orders_dataset o
        join dim_order_key ok on o.order_id= ok.order_id
--(Created order_purchase_date on power bi)
ALTER TABLE order_clean ADD order_purchase_timestamp DATETIME2 NULL;
UPDATE oc
SET oc.order_purchase_timestamp = TRY_CONVERT(DATETIME2, o.order_purchase_timestamp, 101)
FROM olist_orders_dataset o
JOIN order_clean oc ON oc.order_id = o.order_id;

CREATE NONCLUSTERED INDEX IX_order_clean_order_key ON order_clean(order_key);

-- ------------------------------------------------------------
-- order_items_clean
-- Grain: one row per line item within an order
-- ------------------------------------------------------------
DROP TABLE IF EXISTS orders_item_clean;

SELECT
    ok.order_key,
    oi.order_item_id,
    pk.product_key,
    sk.seller_key,
    oi.shipping_limit_date,
    oi.price,
    oi.freight_value,
    oi.order_id,
    oi.product_id,
    oi.seller_id
INTO orders_item_clean
FROM olist_order_items_dataset oi
JOIN dim_order_key ok ON oi.order_id = ok.order_id
JOIN dim_product_key pk ON oi.product_id = pk.product_id
JOIN dim_seller_key sk ON oi.seller_id = sk.seller_id;

CREATE NONCLUSTERED INDEX IX_order_items_clean_order_key ON orders_item_clean(order_key);
CREATE NONCLUSTERED INDEX IX_order_items_clean_product_key ON orders_item_clean(product_key);
CREATE NONCLUSTERED INDEX IX_order_items_clean_seller_key ON orders_item_clean(seller_key);

-- ------------------------------------------------------------
-- payments_clean
-- Grain: one row per payment installment/method used on an order
-- ------------------------------------------------------------
DROP TABLE IF EXISTS payment_clean;

SELECT
    ok.order_key,
    p.payment_sequential,
    p.payment_type,
    p.payment_installments,
    p.payment_value,
    p.order_id
INTO payment_clean
FROM olist_order_payments_dataset p
JOIN dim_order_key ok ON p.order_id = ok.order_id;

CREATE NONCLUSTERED INDEX IX_payment_clean_order_key ON payment_clean(order_key);

-- ------------------------------------------------------------
-- products_clean
-- Grain: one row per product
-- Category nulls filled with 'unknown' to preserve real revenue;
-- the 2 rows missing dimensions are dropped (no safe fill value).
-- ------------------------------------------------------------
DROP TABLE IF EXISTS product_clean;

SELECT
    pk.product_key,
    COALESCE(pr.product_category_name, 'unknown') AS product_category_name,
    pr.product_name_lenght,
    pr.product_description_lenght,
    pr.product_photos_qty,
    pr.product_weight_g,
    pr.product_length_cm,
    pr.product_height_cm,
    pr.product_width_cm,
    pr.product_id
INTO product_clean
FROM olist_products_dataset pr
JOIN dim_product_key pk ON pr.product_id = pk.product_id;

DELETE FROM product_clean WHERE product_weight_g IS NULL;

CREATE NONCLUSTERED INDEX IX_product_clean_product_key ON product_clean(product_key);

-- ------------------------------------------------------------
-- seller_clean
-- Grain: one row per seller
-- ------------------------------------------------------------
DROP TABLE IF EXISTS seller_clean;

SELECT
    sk.seller_key,
    s.seller_zip_code_prefix,
    LOWER(LTRIM(RTRIM(s.seller_city))) AS seller_city,
    s.seller_state,
    s.seller_id
INTO seller_clean
FROM olist_sellers_dataset s
JOIN dim_seller_key sk ON s.seller_id = sk.seller_id;

CREATE NONCLUSTERED INDEX IX_sellers_clean_seller_key ON seller_clean(seller_key);

-- ------------------------------------------------------------
-- Final verification: row counts should match expected values
-- ------------------------------------------------------------
SELECT 'customers_clean' AS table_name, COUNT(*) AS row_count FROM customer_clean   -- expect 99441
UNION ALL
SELECT 'orders_clean', COUNT(*) FROM order_clean                                     -- expect 99441
UNION ALL
SELECT 'order_items_clean', COUNT(*) FROM orders_item_clean                           -- expect 112650
UNION ALL
SELECT 'payments_clean', COUNT(*) FROM payment_clean                                 -- expect 103886
UNION ALL
SELECT 'products_clean', COUNT(*) FROM product_clean                                 -- expect ~32949
UNION ALL
SELECT 'sellers_clean', COUNT(*) FROM seller_clean;                                  -- expect 3095
