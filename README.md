# Olist-Brazilian-Ecommerce-Analysis
## Table Of Contents
-	[Project Overview](#project-overview)
-	[Live Dashboard](#live-dashboard)
-	[Business Problem](#business-problem)
-	[Dataset](#dataset)
-	[Tools](#tools)
-	[Data-Cleaning-Process](#data-cleaning-process)
-	[Key Findings](#Key-findings)
-	[Recommendations](#recommendations)
-	[Limitations](#limitations)
-	[How to Reproduce](#how-to-reproduce)
-	[Dashboard Pages](#dashboard-pages)

### Project Overview
This  is an End-to-end data analysis project covering data cleaning, SQL analysis, and an interactive Power BI dashboard, built on the Olist Brazilian E-Commerce public dataset. This project aims to provide insights into the sales performance of olist Brazilian company, over the years by analzying various aspect of the sales data, we seek to identify trends, make data driven recommendations and gain better understanding of the company’s performance.

### Dashboard screenshots

<img width="827" height="460" alt="Screenshot 2026-10-03 111158 1" src="https://github.com/user-attachments/assets/6f160e8b-d3bf-4f0a-a846-2901addfd7c0" />
<img width="870" height="488" alt="Screenshot 2026-10-02 043718 2" src="https://github.com/user-attachments/assets/d8866ee3-d8b2-44b6-9471-fcc38a92c865" />
<img width="831" height="496" alt="Screenshot 2026-10-02 044720 7" src="https://github.com/user-attachments/assets/7c6c4500-983e-4b5b-9024-7002173b1c2e" />

Full 7 screenshots available in dashboard screenshots file

### 🔗 Live Dashboard

[View the interactive Power BI dashboard](https://drive.google.com/file/d/1FZiVoCng0e0qu6IIU6bRVHX9VdaKKWEU/view?usp=sharing)

*(If the link above doesn't load, see the screenshots in the dashboard screenshots file.)*

---
### Business Problem

Olist is a Brazilian e-commerce marketplace connecting small businesses to major online marketplaces. This project analyzes ~100,000 orders (2016–2018) to answer five business questions:

1. How does actual delivery time compare to the estimated delivery date, and does it vary by customers state or sellers seller?
2. How has order volume and average order value changed month over month?
3. Which product categories drive the most revenue, and how does freight cost vary by category?
4. What payment methods do customers use, and does installment usage relate to order value?
5. Where are customers concentrated geographically, and what share are repeat buyers?

### Dataset

Source: [Olist Brazilian E-Commerce Public Dataset (Kaggle)](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)

Tables used: `orders`, `order_items`, `order_payments`, `customers`, `products`, `sellers`. The `geolocation` file was excluded due to a corrupted download; it is not required for the five questions above.

Raw CSVs are not included in this repo due to file size and dataset licensing — see `/data/README.md` for the download link.


### Tools

- **SQL Server / SSMS** — data cleaning, surrogate key generation, analysis queries
- **Power BI** — data modeling (star schema) and interactive dashboard
- **Excel** — initial exploration

### Data Cleaning Process

Full scripts are in `/sql`. Summary of the approach:

1. **Grain identification** — determined what one row represents in each table before writing any uniqueness checks (e.g., `orders` = one row per order; `order_items` = one row per line item, requiring a composite key of `order_id + order_item_id`).
2. **Duplicate checks** — full-row and key-level checks per table, using the correct grain-specific key for each.
3. **Null handling** — nulls were evaluated individually, not dropped by default:
   - `orders.order_approved_at` / delivery dates: left as `NULL` (genuinely never happened for canceled/undelivered orders), with boolean flag columns added instead.
   - `products.product_category_name`: filled with `'unknown'` (610 rows) rather than dropped, to preserve real revenue tied to those products.
   - `products` dimension nulls (2 rows): dropped, since no safe fill value exists for physical weight/dimensions.
4. **Surrogate keys** — replaced hashed IDs (`order_id`, `product_id`, `seller_id`, `customer_unique_id`) with clean integer keys via `dim_*_key` mapping tables, joined consistently across all dependent tables.
5. **Import fixes** — resolved SQL Server import errors caused by non-ISO date formats (`M/D/YYYY`), `NOT NULL` mismatches, and `SMALLINT` overflow on `product_weight_g`.
6. **Indexing** — added nonclustered indexes on all surrogate keys after diagnosing several slow-query issues traced to `SELECT INTO` producing unindexed heap tables.

## Key Findings

**1. Delivery Performance**
Olist  has a strong delivery performance overall. out of 96k delivered orders, only 6.7%  arrived late, meaning that 92.23% were on time. on average orders 12 days earlier that the estimated date of delivery, so customer expectation is being exceeded. Identified also that late deliveries are concentrated in specific customers and sellers states highlighting key regions for logistics optimization to further improve the 92% on time rate. High lateness in Northern states AL, MA, SE and seller states AM suggests logistical challenges in the North/Northeast Brazil; possibly longer distance from distribution centers, limited carrier coverage  or infrastructural  issues.

**2. Revenue & Order Trends**
Order volume grew roughly 25x from the platform's early months to its peak (late 2017), while average order value stayed flat in the R$150–170 range throughout. Growth was driven by acquisition, not bigger baskets. November 2017 shows a clear spike (~+53–61%), consistent with Black Friday.

**3. Category Performance**
Health & beauty, watches & gifts, and bed/bath/table products are the top revenue categories. The average Freight cost  varies meaningfully by category — bulkier goods (home appliances and computers) carry proportionally higher freight than smaller high-value items (kids wear).

**4. Payment Behavior**
Credit card is used in ~86% of payment records and is the only method supporting installments. Installment count rises steadily with order value — larger purchases are reliably split into more installments.

**5. Geography & Repeat Purchases**
São Paulo alone accounts for ~42% of Olist's customer base. The overall repeat purchase rate is ~3%, which is low for a marketplace — though the ~2-year observation window may understate true retention.

## Recommendations 

Based on the analysis results, we recommend the following actions;
1. Audit carrier SLAs and shipping routes  for states; AL, MA, SE And AM to reduce the remaining 6.7% late deliveries to protect customers satisfaction in those region.
2. Plan inventory  for high volume  AOV in Q4. Mom growth  fell in <5% in 2018, so drive growth by reactivating 2017 cohorts, 20% repeat from Nov cohort = $241k extra  with no acquisition cost. Push AOV from $161 to $180 via bundles/free shipping threshold to grow revenue without new customers 
3. Build retention across top 10 categories per  revenue to boost growth
4. Push credit card installments  further, offer 3x-6x interest free on top categories.
5. Run state specific ads across south  states (RJ, MG, RS), Fix retention not acquisition by sending  monthly/bi-weekly targeted  emails and ads to active buyers(last 60 days) to lift repeat customers from 3% to 5%.

### Limitations

- The dataset spans Sept 2016 – Aug 2018; 2016 has very little data (under 300 orders total) and was excluded from month-over-month growth analysis.
- Category names are in Portuguese; the Kaggle translation file was not used in this version.
- No courier/logistics-partner data exists, so delivery-delay root causes (distance, carrier, weather) can't be tested directly.

### How to Reproduce

1. Download the dataset from Kaggle (link above).
2. Run the SQL scripts in `/sql` in order (01 → 05) against a SQL Server database.
3. Open `powerbi/olist_dashboard.pbix` in Power BI Desktop, connect it to your database, and refresh.

### Dashboard Pages

| Page | Contents |
|---|---|
| 1. Overview | Headline KPIs, revenue trend|
| 2. Delivery Performance | Late rate by customer state, by seller state, delivery gap analysis |
| 3. Revenue & Order Trends | Monthly volume, revenue, and AOV over time |
| 4. Category Performance | Revenue and freight cost by product category |
| 5. Payment Behavior | Payment type share, installments by order value |
| 6. Geography & Repeat Purchases | Customer distribution by state, repeat purchase rate |




