/* ============================================================
   04_indexes.sql
   Purpose: Standalone reference for all indexes applied to the
   _clean tables. (Most are already created inline in
   03_clean_tables.sql -- this script exists so every index in
   the project is documented and re-runnable in one place.)

   Context: tables built with SELECT INTO are created as heaps
   with zero indexes. Every join/filter on them initially forced
   a full table scan, which caused several multi-minute query
   hangs during development. Adding indexes on every surrogate
   key resolved this.
   ============================================================ */

-- customers_clean
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_customers_clean_order_key')
    CREATE NONCLUSTERED INDEX IX_customer_clean_order_key ON customer_clean(order_key);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_customers_clean_customer_key')
    CREATE NONCLUSTERED INDEX IX_customer_clean_customer_key ON customer_clean(customer_key);

-- orders_clean
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_orders_clean_order_key')
    CREATE NONCLUSTERED INDEX IX_orders_clean_order_key ON order_clean(order_key);

-- order_items_clean
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_order_items_clean_order_key')
    CREATE NONCLUSTERED INDEX IX_orders_item_clean_order_key ON orders_item_clean(order_key);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_order_items_clean_product_key')
    CREATE NONCLUSTERED INDEX IX_orders_item_clean_product_key ON orders_item_clean(product_key);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_order_items_clean_seller_key')
    CREATE NONCLUSTERED INDEX IX_orders_item_clean_seller_key ON orders_item_clean(seller_key);

-- payments_clean
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_payments_clean_order_key')
    CREATE NONCLUSTERED INDEX IX_payments_clean_order_key ON payment_clean(order_key);

-- products_clean
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_product_clean_product_key')
    CREATE NONCLUSTERED INDEX IX_product_clean_product_key ON product_clean(product_key);

-- sellers_clean
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_sellers_clean_seller_key')
    CREATE NONCLUSTERED INDEX IX_seller_clean_seller_key ON seller_clean(seller_key);

-- ------------------------------------------------------------
-- Refresh statistics after bulk index creation (tables built
-- via SELECT INTO can carry stale/missing statistics)
-- ------------------------------------------------------------
UPDATE STATISTICS customers_clean WITH FULLSCAN;
UPDATE STATISTICS orders_clean WITH FULLSCAN;
UPDATE STATISTICS order_items_clean WITH FULLSCAN;
UPDATE STATISTICS payments_clean WITH FULLSCAN;
UPDATE STATISTICS products_clean WITH FULLSCAN;
UPDATE STATISTICS sellers_clean WITH FULLSCAN;

-- ------------------------------------------------------------
-- Verify indexes exist on each table
-- ------------------------------------------------------------
SELECT
    t.name AS table_name,
    i.name AS index_name,
    c.name AS column_name
FROM sys.indexes i
JOIN sys.tables t ON i.object_id = t.object_id
JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
WHERE t.name IN ('customer_clean','order_clean','orders_item_clean','payment_clean','product_clean','seller_clean')
  AND i.name IS NOT NULL
ORDER BY t.name, i.name;

