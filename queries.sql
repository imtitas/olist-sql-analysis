-- Olist E-Commerce SQL Analysis (PostgreSQL)
-- Run one query at a time.

-- =====================================================
-- DATA QUALITY CHECKS
-- =====================================================

-- Business question: How many orders are in each status?
SELECT order_status, COUNT(*) AS orders
FROM orders
GROUP BY 1
ORDER BY 2 DESC;

-- Business question: How many orders have no delivery date?
SELECT COUNT(*) AS missing_delivery_date
FROM orders
WHERE order_delivered_customer_date IS NULL;

-- Business question: Which statuses do the missing delivery dates belong to?
SELECT order_status, COUNT(*) AS missing_delivery_date
FROM orders
WHERE order_delivered_customer_date IS NULL
GROUP BY 1
ORDER BY 2 DESC;

-- =====================================================
-- ANALYSIS
-- Q1, Q5, Q8 use delivered orders only.
-- Q2, Q3, Q4, Q6, Q7, Q9 use all orders (Q4 and Q10 need a delivery date).
-- =====================================================

-- Q1. Business question: What is total revenue and average order value?
SELECT COUNT(DISTINCT o.order_id) AS orders,
       ROUND(SUM(oi.price),2) AS revenue,
       ROUND(SUM(oi.price)/COUNT(DISTINCT o.order_id),2) AS avg_order_value
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered';

-- Q2. Business question: Which 10 product categories earn the most revenue?
SELECT t.product_category_name_english AS category,
       ROUND(SUM(oi.price),2) AS revenue
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
JOIN category_translation t ON p.product_category_name = t.product_category_name
GROUP BY 1
ORDER BY 2 DESC
LIMIT 10;

-- Q3. Business question: Which customer states generate the most revenue?
SELECT c.customer_state, ROUND(SUM(oi.price),2) AS revenue
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY 1
ORDER BY 2 DESC;

-- Q4. Business question: Which sellers have the most late deliveries (min 20 late orders)?
SELECT oi.seller_id, COUNT(DISTINCT o.order_id) AS late_orders
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_delivered_customer_date > o.order_estimated_delivery_date
GROUP BY 1
HAVING COUNT(DISTINCT o.order_id) >= 20
ORDER BY 2 DESC
LIMIT 10;

-- Q5. Business question: How does monthly revenue trend over time?
SELECT DATE_TRUNC('month', o.order_purchase_timestamp)::date AS month,
       ROUND(SUM(oi.price),2) AS revenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY 1
ORDER BY 1;

-- Q6. Business question: What share of customers are repeat vs one-time buyers?
WITH cust_orders AS (
  SELECT c.customer_unique_id, COUNT(DISTINCT o.order_id) AS n
  FROM orders o
  JOIN customers c ON o.customer_id = c.customer_id
  GROUP BY 1)
SELECT CASE WHEN n = 1 THEN 'One-time' ELSE 'Repeat' END AS type,
       COUNT(*) AS customers,
       ROUND(100.0*COUNT(*)/SUM(COUNT(*)) OVER (),2) AS pct
FROM cust_orders
GROUP BY 1;

-- Q7. Business question: Who are the top 3 sellers by revenue in each state?
WITH s AS (
  SELECT se.seller_state, se.seller_id, SUM(oi.price) AS revenue
  FROM order_items oi
  JOIN sellers se ON oi.seller_id = se.seller_id
  GROUP BY 1,2)
SELECT * FROM (
  SELECT *, RANK() OVER (PARTITION BY seller_state ORDER BY revenue DESC) AS rnk
  FROM s) x
WHERE rnk <= 3;

-- Q8. Business question: How fast is revenue growing month over month?
WITH m AS (
  SELECT DATE_TRUNC('month', o.order_purchase_timestamp)::date AS month,
         SUM(oi.price) AS revenue
  FROM orders o
  JOIN order_items oi ON o.order_id = oi.order_id
  WHERE o.order_status = 'delivered'
  GROUP BY 1)
SELECT month, ROUND(revenue,2) AS revenue,
       ROUND(100.0*(revenue - LAG(revenue) OVER (ORDER BY month))
             / LAG(revenue) OVER (ORDER BY month),1) AS mom_growth_pct
FROM m
ORDER BY month;

-- Q9. Business question: What is the cumulative revenue over time?
WITH m AS (
  SELECT DATE_TRUNC('month', o.order_purchase_timestamp)::date AS month,
         SUM(oi.price) AS revenue
  FROM orders o
  JOIN order_items oi ON o.order_id = oi.order_id
  GROUP BY 1)
SELECT month, ROUND(revenue,2) AS revenue,
       ROUND(SUM(revenue) OVER (ORDER BY month),2) AS running_total
FROM m
ORDER BY month;

-- Q10. Business question: Do late deliveries lower customer review scores?
SELECT CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
            THEN 'Late' ELSE 'On time' END AS delivery,
       COUNT(*) AS orders,
       ROUND(AVG(r.review_score),2) AS avg_review
FROM orders o
JOIN reviews r ON o.order_id = r.order_id
WHERE o.order_delivered_customer_date IS NOT NULL
GROUP BY 1;
