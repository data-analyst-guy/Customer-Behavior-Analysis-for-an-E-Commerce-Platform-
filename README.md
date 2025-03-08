# Explore-Ecommerce-Dataset-SQL-in-BigQuery-

Data set
https://support.google.com/analytics/answer/3437719?hl=en 
Link Bigquery
https://console.cloud.google.com/bigquery?sq=1002252523164:4ced6907f6cb4a94a1508f16a3d92de2

## 📌 Dataset Schema

| Field Name                         | Data Type | Description |
|-------------------------------------|----------|-------------|
| `fullVisitorId`                    | STRING   | The unique visitor ID. |
| `date`                              | STRING   | The date of the session in YYYYMMDD format. |
| `totals`                            | RECORD   | Contains aggregate values across the session. |
| `totals.bounces`                    | INTEGER  | Total bounces (for convenience). 1 if bounced, otherwise null. |
| `totals.hits`                       | INTEGER  | Total number of hits within the session. |
| `totals.pageviews`                  | INTEGER  | Total number of pageviews within the session. |
| `totals.visits`                     | INTEGER  | The number of sessions (for convenience). |
| `totals.transactions`               | INTEGER  | Total number of eCommerce transactions. |
| `trafficSource.source`              | STRING   | The traffic source (e.g., search engine, referrer, UTM source). |
| `hits`                              | RECORD   | Contains all types of hits. |
| `hits.eCommerceAction`              | RECORD   | Stores eCommerce hits within the session. |
| `hits.eCommerceAction.action_type`  | STRING   | Type of action (e.g., 1 = Click, 2 = Product View, 6 = Purchase). |
| `hits.product`                      | RECORD   | Stores Enhanced eCommerce product data. |
| `hits.product.productQuantity`      | INTEGER  | Quantity of product purchased. |
| `hits.product.productRevenue`       | INTEGER  | Product revenue (value * 10^6). |
| `hits.product.productSKU`           | STRING   | Product SKU. |
| `hits.product.v2ProductName`        | STRING   | Product Name. |

# 📌 Query 01: calculate total visit, pageview, transaction for Jan, Feb and March 2017 (order by month)

```sql
SELECT 
    FORMAT_DATE('%Y%m', PARSE_DATE('%Y%m%d', _TABLE_SUFFIX)) AS month,
    SUM(totals.visits) AS visits,
    SUM(totals.pageviews) AS pageviews,
    SUM(totals.transactions) AS transactions
FROM 
    `bigquery-public-data.google_analytics_sample.ga_sessions_*` 
WHERE 
    _TABLE_SUFFIX BETWEEN '20170101' AND '20170331'
GROUP BY 
    month
ORDER BY 
    month;
### 📊 Query Result
| Month  | Visits | Pageviews | Transactions |
|--------|--------|-----------|-------------|
| 201701 | 64694  | 257708    | 713         |
| 201702 | 62192  | 233373    | 733         |
| 201703 | 69931  | 259522    | 993         |

# 📌 Query 02: Bounce rate per traffic source in July 2017 (Bounce_rate = num_bounce/total_visit) (order by total_visit DESC)
``` sql
SELECT 
      trafficSource.source as source,
      SUM(totals.visits) AS total_visits,
      SUM(totals.bounces) AS total_bounces,
      SUM(totals.bounces)/SUM(totals.visits)*100 AS bounce_rate
  FROM 
      `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  WHERE 
      _TABLE_SUFFIX BETWEEN '20170701' AND '20170731'
  GROUP BY 
      source
  ORDER BY 
      total_visits DESC
### 📊 Query Result
| Source                 | Total Visits | Total Bounces | Bounce Rate (%) |
|------------------------|-------------|--------------|-----------------|
| google                | 38,400      | 19,798       | 51.56%          |
| (direct)              | 19,891      | 8,606        | 43.27%          |
| youtube.com           | 6,351       | 4,238        | 66.73%          |
| analytics.google.com  | 1,972       | 1,064        | 53.96%          |
| Partners             | 1,788       | 936          | 52.35%          |
| ...                    | ...         | ...          | ...             |
| google.es            | 1           | 1            | 100.00%         |
| google.ca            | 1           | -            | -               |

# 📌 Query 03: Revenue by traffic source by week, by month in June 2017
``` sql
WITH week_table AS (
  SELECT 
    'week' AS time_type,
    FORMAT_DATE('%Y%W', PARSE_DATE('%Y%m%d', date)) AS time_detail,
    trafficSource.source AS source_group,
    SUM(product.productRevenue)/1000000 AS total_revenue
  FROM 
    `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
    UNNEST(hits) AS hit,
    UNNEST(hit.product) AS product
  WHERE 
    _TABLE_SUFFIX BETWEEN '20170601' AND '20170630'
    AND product.productRevenue IS NOT NULL  
  GROUP BY 
    time_detail, time_type, source_group
),
month_table AS (
  SELECT 
    'month' AS time_type,
    FORMAT_DATE('%Y%m', PARSE_DATE('%Y%m%d', date)) AS time_detail,
    trafficSource.source AS source_group,
    SUM(product.productRevenue)/1000000 AS total_revenue
  FROM 
    `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
    UNNEST(hits) AS hit,
    UNNEST(hit.product) AS product
  WHERE 
    _TABLE_SUFFIX BETWEEN '20170601' AND '20170630'
    AND product.productRevenue IS NOT NULL  
  GROUP BY 
    time_detail, time_type, source_group
)
SELECT * FROM week_table
UNION ALL
SELECT * FROM month_table;

### 📊 **Query Result (Top 5 & Bottom 5)**
| Time Type | Time Detail | Source Group       | Total Revenue  |
|-----------|------------|--------------------|---------------|
| month     | 201706     | bing              | 13.98        |
| month     | 201706     | youtube.com       | 16.99        |
| month     | 201706     | yahoo             | 20.39        |
| month     | 201706     | sites.google.com  | 39.17        |
| month     | 201706     | phandroid.com     | 52.95        |
| ...       | ...        | ...               | ...          |
| week      | 201725     | google.com        | 23.99        |
| week      | 201724     | l.facebook.com    | 12.48        |
| week      | 201725     | mail.aol.com      | 64.85        |
| week      | 201724     | dealspotr.com     | 72.95        |

# 📌 Query 04: Average number of pageviews by purchaser type (purchasers vs non-purchasers) in June, July 2017.

```sql
WITH p as (SELECT 
    FORMAT_DATE('%Y%m', PARSE_DATE('%Y%m%d', date)) AS month,
    SUM(totals.pageviews)/COUNT(DISTINCT fullVisitorId) AS avg_pageviews_purchase
FROM  
    `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
    UNNEST(hits) AS hit,
    UNNEST(hit.product) AS product
WHERE 
    _TABLE_SUFFIX BETWEEN '20170601' AND '20170731'
    AND totals.transactions >= 1  
    AND product.productRevenue IS NOT NULL 
GROUP BY 
    month)

, non_p as (SELECT 
    FORMAT_DATE('%Y%m', PARSE_DATE('%Y%m%d', date)) AS month,
    SUM(totals.pageviews)/COUNT(DISTINCT fullVisitorId) AS avg_pageviews_purchase
FROM  
    `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
    UNNEST(hits) AS hit,
    UNNEST(hit.product) AS product
WHERE 
    _TABLE_SUFFIX BETWEEN '20170601' AND '20170731'
    AND totals.transactions IS NULL  
    AND product.productRevenue IS NULL 
GROUP BY 
    month)
SELECT * FROM p
FULL JOIN non_p  --> full join
USING(month)
### 📊 **Query Result: Average Pageviews (Purchasers vs. Non-Purchasers)**

| Month  | Avg Pageviews (Purchasers) | Avg Pageviews (Non-Purchasers) |
|--------|---------------------------|--------------------------------|
| 201706 | 94.02                      | 316.87                         |
| 201707 | 124.24                     | 334.06                         |

