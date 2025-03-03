--Tổng hợp--
--Q1
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

--Q2

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

--Q3

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

--Q4

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

--Q5
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


--Q6
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

--Q7
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

--đây là 2 cách ghi khác

--subquery:
select
    product.v2productname as other_purchased_product,
    sum(product.productQuantity) as quantity
from `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`,
    unnest(hits) as hits,
    unnest(hits.product) as product
where fullvisitorid in (select distinct fullvisitorid
                        from `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`,
                        unnest(hits) as hits,
                        unnest(hits.product) as product
                        where product.v2productname = "YouTube Men's Vintage Henley"
                        and product.productRevenue is not null)
and product.v2productname != "YouTube Men's Vintage Henley"
and product.productRevenue is not null
group by other_purchased_product
order by quantity desc;

--CTE:

with buyer_list as(
    SELECT
        distinct fullVisitorId
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`
    , UNNEST(hits) AS hits
    , UNNEST(hits.product) as product
    WHERE product.v2ProductName = "YouTube Men's Vintage Henley"
    AND totals.transactions>=1
    AND product.productRevenue is not null
)

SELECT
  product.v2ProductName AS other_purchased_products,
  SUM(product.productQuantity) AS quantity
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`
, UNNEST(hits) AS hits
, UNNEST(hits.product) as product
JOIN buyer_list using(fullVisitorId)
WHERE product.v2ProductName != "YouTube Men's Vintage Henley"
 and product.productRevenue is not null
GROUP BY other_purchased_products
ORDER BY quantity DESC;


--Q8
WITH p_view AS (
    SELECT
        FORMAT_DATE('%Y%m', PARSE_DATE('%Y%m%d', date)) AS month,
        COUNT(eCommerceAction.action_type) AS num_product_view
    FROM 
        `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
        UNNEST(hits) AS hit,
        UNNEST(hit.product) AS product
    WHERE 
        _TABLE_SUFFIX BETWEEN '20170101' AND '20170331'
        AND eCommerceAction.action_type = '2'
    GROUP BY 
        month
),
p_add AS (
    SELECT
        FORMAT_DATE('%Y%m', PARSE_DATE('%Y%m%d', date)) AS month,
        COUNT(eCommerceAction.action_type) AS num_addtocart
    FROM 
        `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
        UNNEST(hits) AS hit,
        UNNEST(hit.product) AS product
    WHERE 
        _TABLE_SUFFIX BETWEEN '20170101' AND '20170331'
        AND eCommerceAction.action_type = '3'
    GROUP BY 
        month
),
p_purchase AS (
    SELECT
        FORMAT_DATE('%Y%m', PARSE_DATE('%Y%m%d', date)) AS month,
        COUNT(eCommerceAction.action_type) AS num_purchase
    FROM 
        `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
        UNNEST(hits) AS hit,
        UNNEST(hit.product) AS product
    WHERE 
        _TABLE_SUFFIX BETWEEN '20170101' AND '20170331'
        AND eCommerceAction.action_type = '6'
        AND product.productRevenue IS NOT NULL 
    GROUP BY 
        month
)
SELECT
    p_add.month,
    p_view.num_product_view,
    p_add.num_addtocart,
    p_purchase.num_purchase,
    ROUND(100 * p_add.num_addtocart / p_view.num_product_view, 2) AS add_to_cart_rate,
    ROUND(100 * p_purchase.num_purchase / p_view.num_product_view, 2) AS purchase_rate
FROM   
    p_add
FULL JOIN
    p_view
USING(month)
FULL JOIN
    p_purchase
USING(month)
ORDER BY 
    p_add.month;

--bài yêu cầu tính số sản phầm, mình nên count productName hay productSKU thì sẽ hợp lý hơn là count action_type
--k nên xài inner join, nếu table1 có 10 record,table2 có 5 record,table3 có 1 record, thì sau khi inner join, output chỉ ra 1 record

--Cách 1:dùng CTE
with
product_view as(
  SELECT
    format_date("%Y%m", parse_date("%Y%m%d", date)) as month,
    count(product.productSKU) as num_product_view
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  , UNNEST(hits) AS hits
  , UNNEST(hits.product) as product
  WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20170331'
  AND hits.eCommerceAction.action_type = '2'
  GROUP BY 1
),

add_to_cart as(
  SELECT
    format_date("%Y%m", parse_date("%Y%m%d", date)) as month,
    count(product.productSKU) as num_addtocart
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  , UNNEST(hits) AS hits
  , UNNEST(hits.product) as product
  WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20170331'
  AND hits.eCommerceAction.action_type = '3'
  GROUP BY 1
),

purchase as(
  SELECT
    format_date("%Y%m", parse_date("%Y%m%d", date)) as month,
    count(product.productSKU) as num_purchase
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  , UNNEST(hits) AS hits
  , UNNEST(hits.product) as product
  WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20170331'
  AND hits.eCommerceAction.action_type = '6'
  and product.productRevenue is not null   --phải thêm điều kiện này để đảm bảo có revenue
  group by 1
)

select
    pv.*,
    num_addtocart,
    num_purchase,
    round(num_addtocart*100/num_product_view,2) as add_to_cart_rate,
    round(num_purchase*100/num_product_view,2) as purchase_rate
from product_view pv
left join add_to_cart a on pv.month = a.month
left join purchase p on pv.month = p.month
order by pv.month;

--bài này k nên inner join, vì nếu như bảng purchase k có data thì sẽ k mapping đc vs bảng productview, từ đó kết quả sẽ k có luôn, mình nên dùng left join
--lấy số product_view làm gốc, nên mình sẽ left join ra 2 bảng còn lại

--Cách 2: bài này mình có thể dùng count(case when) hoặc sum(case when)

with product_data as(
select
    format_date('%Y%m', parse_date('%Y%m%d',date)) as month,
    count(CASE WHEN eCommerceAction.action_type = '2' THEN product.v2ProductName END) as num_product_view,
    count(CASE WHEN eCommerceAction.action_type = '3' THEN product.v2ProductName END) as num_add_to_cart,
    count(CASE WHEN eCommerceAction.action_type = '6' and product.productRevenue is not null THEN product.v2ProductName END) as num_purchase
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
,UNNEST(hits) as hits
,UNNEST (hits.product) as product
where _table_suffix between '20170101' and '20170331'
and eCommerceAction.action_type in ('2','3','6')
group by month
order by month
)

select
    *,
    round(num_add_to_cart/num_product_view * 100, 2) as add_to_cart_rate,
    round(num_purchase/num_product_view * 100, 2) as purchase_rate
from product_data;


                                                     