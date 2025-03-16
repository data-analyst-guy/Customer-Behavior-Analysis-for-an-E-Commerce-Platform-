# Customer Behavior Analysis for an E-Commerce Platform 

### 🎯 **Use Cases in My Project**  
I used this dataset to analyze customer behavior and optimize e-commerce performance. Specifically, I:  

- Queried session data to understand conversion rates from different traffic sources.  
- Identified top-selling products based on revenue and purchase frequency.  
- Analyzed the customer journey to determine the most effective acquisition channels.  

### Project Overview
📌 Introduction
The Google Analytics Sample Dataset is a public dataset provided by Google through BigQuery. It contains real-world e-commerce data from the Google Merchandise Store, allowing analysts to practice SQL queries and data analysis techniques.

### Data set
📂 Dataset Overview
Source: Google Merchandise Store (Google’s official online store).  
Time Period: Data spans from August 1, 2016, to August 1, 2017.  
Tracking System: Google Analytics 360 (GA premium version).  
Hosted on: Google BigQuery (bigquery-public-data.google_analytics_sample.ga_sessions_*).  

📂 Link 
https://support.google.com/analytics/answer/3437719?hl=en 

🔍 **Key Features**  
The dataset contains detailed session-based analytics, including:  
✅ **User Behavior**: Visits, pageviews, bounce rate, session duration.  
✅ **E-commerce Transactions**: Orders, revenue, purchased products.  
✅ **Traffic Sources**: Organic search, direct, social, referral, etc.  
✅ **Product Information**: SKU, product name, quantity sold, revenue generated.  

### Link Practice Bigquery
https://console.cloud.google.com/bigquery?sq=1002252523164:4ced6907f6cb4a94a1508f16a3d92de2

## 📌 Dataset Schema

<details>
  <summary>Click to expand</summary>

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

</details>


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
```
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
```
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
```
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
```
### 📊 **Query Result: Average Pageviews (Purchasers vs. Non-Purchasers)**

| Month  | Avg Pageviews (Purchasers) | Avg Pageviews (Non-Purchasers) |
|--------|---------------------------|--------------------------------|
| 201706 | 94.02                      | 316.87                         |
| 201707 | 124.24                     | 334.06                         |

# 📌 Query 05: Average number of transactions per user that made a purchase in July 2017
```sql
SELECT 
    FORMAT_DATE('%Y%m', PARSE_DATE('%Y%m%d', date)) AS month,
    SUM(totals.transactions)/COUNT(DISTINCT fullVisitorId) AS Avg_total_transactions_per_user
FROM  
    `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
    UNNEST(hits) AS hit,
    UNNEST(hit.product) AS product
WHERE 
    _TABLE_SUFFIX BETWEEN '20170701' AND '20170731'
    AND totals.transactions >=1  
    AND product.productRevenue IS NOT NULL 
GROUP BY month
--correct
```
### 📊 Average Number of Transactions per User in July 2017

| Month  | Avg Total Transactions per User |
|--------|--------------------------------|
| 201707 | 4.16390041493776               |

# 📌 Query 06: Average amount of money spent per session. Only include purchaser data in July 2017
```sql
SELECT 
    FORMAT_DATE('%Y%m', PARSE_DATE('%Y%m%d', date)) AS month,
    ROUND(SUM(product.productRevenue)/COUNT(totals.visits)/1000000,2) AS avg_revenue_by_user_per_visit
FROM  
    `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
    UNNEST(hits) AS hit,
    UNNEST(hit.product) AS product
WHERE 
    _TABLE_SUFFIX BETWEEN '20170701' AND '20170731'
    AND totals.transactions IS NOT NULL  
    AND product.productRevenue IS NOT NULL 
GROUP BY month
```
### 📊 Query Result
| Month  | Avg Revenue by User per Visit |
|--------|------------------------------|
| 201707 | 43.86                        |

# 📌 Query 07: Other products purchased by customers who purchased product "YouTube Men's Vintage Henley" in July 2017. Output should show product name and the quantity was ordered.
```sql
WITH product as (
    SELECT
        fullVisitorId,
        product.v2ProductName,
        product.productRevenue,
        product.productQuantity 
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
        UNNEST(hits),
        UNNEST(product) as product
    Where 
        _table_suffix between '20170701' and '20170731'
        AND product.productRevenue IS NOT NULL
)

SELECT
    product.v2ProductName as other_purchased_products,
    SUM(product.productQuantity) as quantity
FROM product
WHERE 
    product.fullVisitorId IN (
        SELECT fullVisitorId
        FROM product
        WHERE product.v2ProductName = "YouTube Men's Vintage Henley"

    )
    AND product.v2ProductName NOT LIKE "YouTube Men's Vintage Henley"
GROUP BY other_purchased_products
ORDER BY quantity desc
```
### 📊 Query Result (Top Purchased Products)
| Other Purchased Products                         | Quantity |
|--------------------------------------------------|----------|
| Google Sunglasses                                | 20       |
| Google Women's Vintage Hero Tee Black           | 7        |
| SPF-15 Slim & Slender Lip Balm                  | 6        |
| Google Women's Short Sleeve Hero Tee Red        | 4        |
| YouTube Men's Fleece Hoodie Black               | 3        |
| ...                                             | ...      |
| Google Men's Airflow 1/4 Zip Pullover Black     | 1        |
| Android Men's Short Sleeve Hero Tee Heather    | 1        |
| YouTube Men's Long & Lean Tee Charcoal         | 1        |
| Google Women's Long Sleeve Tee Lavender        | 1        |
| 8 pc Android Sticker Sheet                     | 1        |

# 📌 Query 08: Calculate cohort map from product view to addtocart to purchase in Jan, Feb and March 2017. For example, 100% product view then 40% add_to_cart and 10% purchase.
```sql
WITH product_data AS (
    SELECT
        FORMAT_DATE('%Y%m', PARSE_DATE('%Y%m%d', date)) AS month,
        COUNT(CASE WHEN eCommerceAction.action_type = '2' THEN product.v2ProductName END) AS num_product_view,
        COUNT(CASE WHEN eCommerceAction.action_type = '3' THEN product.v2ProductName END) AS num_add_to_cart,
        COUNT(CASE WHEN eCommerceAction.action_type = '6' AND product.productRevenue IS NOT NULL THEN product.v2ProductName END) AS num_purchase
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
         UNNEST(hits) AS hits,
         UNNEST(hits.product) AS product
    WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20170331'
          AND eCommerceAction.action_type IN ('2', '3', '6')
    GROUP BY month
    ORDER BY month
)

SELECT
    *,
    ROUND(num_add_to_cart / num_product_view * 100, 2) AS add_to_cart_rate,
    ROUND(num_purchase / num_product_view * 100, 2) AS purchase_rate
FROM product_data;
```
### 📊 Query Result
| month  | num_product_view | num_add_to_cart | num_purchase | add_to_cart_rate | purchase_rate |
|--------|-----------------|----------------|--------------|------------------|---------------|
| 201701 | 25787           | 7342           | 2143         | 28.47            | 8.31          |
| 201702 | 21489           | 7360           | 2060         | 34.25            | 9.59          |
| 201703 | 23549           | 8782           | 2977         | 37.29            | 12.64         |

## 🎯 Key Takeaways  
✅ March recorded the highest number of transactions, likely due to a successful marketing campaign or increased shopping demand. This strategy could be replicated in other months.  
✅ Traffic from YouTube has a high Bounce Rate (66.73%), indicating that users from this source do not engage much after landing on the site. Optimizing landing pages and ad content could help retain these visitors.  
✅ Direct traffic & Google are the main revenue sources, contributing the majority of transactions. Efforts should focus on SEO, Google Ads, and other strategies to sustain and grow these channels.  
✅ Non-purchasers view more pages than purchasers, which may indicate issues in the checkout process or difficulty in finding the right products. Improving the user experience, especially on product and checkout pages, is crucial.  
✅ The average customer makes 4.16 transactions per month, highlighting the presence of repeat buyers. A loyalty program or exclusive offers can help increase customer retention and lifetime value.  
✅ Add-to-cart rate is high, but the purchase completion rate remains low (~12%), although there is a positive trend over the months. This suggests that customers are becoming more willing to complete purchases, possibly due to improved checkout UX or effective marketing.  
🔹 Further optimization needed: Streamlining the checkout process, offering incentives, and implementing remarketing strategies could help reduce cart abandonment.
