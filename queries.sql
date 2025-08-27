-- 1. Total Active Users (last 7 Days)
SELECT COUNT(DISTINCT user_id) AS users_last_week
FROM `bigquery-public-data.thelook_ecommerce.orders`
WHERE DATE(created_at) >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY);


-- 2. Daily Active Users (last 14 days)
SELECT 
  DATE(created_at) AS order_date,
  COUNT(DISTINCT user_id) AS daily_active_users
FROM `bigquery-public-data.thelook_ecommerce.orders`
WHERE DATE(created_at) >= DATE_SUB(CURRENT_DATE(), INTERVAL 14 DAY)
GROUP BY order_date
ORDER BY order_date;


-- 3. Total Sales per Category
SELECT 
  p.category, 
  SUM(o.sale_price) AS total_sales
FROM `bigquery-public-data.thelook_ecommerce.order_items` o
JOIN `bigquery-public-data.thelook_ecommerce.products` p
  ON o.product_id = p.id
GROUP BY p.category
ORDER BY total_sales DESC;


-- 4. Revenue by Gender (last 30 days)
SELECT    
  u.gender,   
  ROUND(SUM(oi.sale_price), 2) AS total_revenue
FROM `bigquery-public-data.thelook_ecommerce.order_items` oi
JOIN `bigquery-public-data.thelook_ecommerce.orders` o
  ON oi.order_id = o.order_id
JOIN `bigquery-public-data.thelook_ecommerce.users` u
  ON o.user_id = u.id
WHERE DATE(oi.created_at) >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
GROUP BY u.gender
ORDER BY total_revenue DESC;


-- 5. Classify Users as Active, Churned, or New
SELECT    
  o.user_id AS customer_id,
  CASE
    WHEN MAX(DATE(o.created_at)) >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY) THEN 'Active'
    WHEN MAX(DATE(o.created_at)) BETWEEN DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY) 
                                     AND DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY) THEN 'Churned'
    ELSE 'New'
  END AS user_status
FROM `bigquery-public-data.thelook_ecommerce.orders` o
GROUP BY customer_id;


-- 6. Top 3 spenders per month
WITH monthly_spending AS (
  SELECT 
    o.user_id AS customer_id,
    EXTRACT(MONTH FROM o.created_at) AS order_month,
    SUM(oi.sale_price) AS total_spent
  FROM bigquery-public-data.thelook_ecommerce.orders o
  JOIN bigquery-public-data.thelook_ecommerce.order_items oi
    ON o.order_id = oi.order_id
  GROUP BY customer_id, order_month
),
ranked_spenders AS (
  SELECT
    customer_id,
    order_month,
    total_spent,
    RANK() OVER(PARTITION BY order_month ORDER BY total_spent DESC) AS rank
  FROM monthly_spending
)
SELECT *
FROM ranked_spenders
WHERE rank <= 3
ORDER BY order_month, rank;


-- 7. 7-day rolling average sales + compare with previous day
SELECT
  order_date,
  daily_sales,
  AVG(daily_sales) OVER (
      ORDER BY order_date 
      ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
  ) AS rolling_avg_7d,
  LAG(daily_sales) OVER (ORDER BY order_date) AS prev_day_sales
FROM (
  SELECT 
    DATE(o.created_at) AS order_date,
    SUM(oi.sale_price) AS daily_sales
  FROM `bigquery-public-data.thelook_ecommerce.orders` o
  JOIN `bigquery-public-data.thelook_ecommerce.order_items` oi
    ON o.order_id = oi.order_id
  GROUP BY order_date
) AS daily

ORDER BY order_date;
