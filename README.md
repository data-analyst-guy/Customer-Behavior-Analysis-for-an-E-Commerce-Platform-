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

