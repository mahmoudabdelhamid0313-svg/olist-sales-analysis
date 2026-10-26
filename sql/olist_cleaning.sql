
--- 1- IMPORT: done manually via DBeaver (Import Data > CSV)

--- 2- RENAME TABLES WITH SHORT NAMES 

ALTER TABLE olist_customers_dataset RENAME TO customers ;
ALTER TABLE olist_order_items_dataset RENAME TO order_items ;
ALTER TABLE olist_order_payments_dataset RENAME TO payments ;
ALTER TABLE olist_orders_dataset RENAME TO orders ;
ALTER TABLE olist_products_dataset RENAME TO products ;
ALTER TABLE product_category_name_translation RENAME TO category_translation ;

--- 3- CHECK RAWS NUMBER IN EACH TABLE
--- Result: customers 99441 | orders 99441 | payments 103886
--         products 32951 | order_items 112650 | category_translation 71

SELECT 'customers' AS tbl, COUNT(*) AS n FROM customers 
UNION ALL SELECT 'order_items', COUNT(*) from order_items 
UNION ALL SELECT 'payments', COUNT(*) from payments 
UNION ALL SELECT 'orders', COUNT(*) FROM orders 
UNION ALL SELECT 'products', COUNT(*) FROM products 
UNION ALL SELECT 'category_translation', COUNT(*) FROM category_translation ;

--- 4- CHECK IF THERE ANY CATEGORY NAME HAS NO TRANSLATION
--- Result: 2 rows: pc_gamer, portateis_cozinha_e_preparadores_de_alimentos 

SELECT DISTINCT p.product_category_name FROM products p 
LEFT JOIN category_translation t ON p.product_category_name = t.product_category_name
WHERE t.product_category_name IS NULL 
AND p.product_category_name IS NOT NULL ;

--- 5- CHECK THE NULL VALUES IN PRODUCT NAME 
--- Decision: keep the 610 rows, label them "Unknown" in the analysis

SELECT COUNT(*) FROM products 
WHERE product_category_name = '';

--- 6- INSERT THE MISSING TWO VALUES IN CATEGORY TRANSLATION TABLE 

INSERT INTO category_translation(product_category_name, product_category_name_english)
VALUES 
('portateis_cozinha_e_preparadores_de_alimentos', 'portable_kitchen_and_food_preparers'),
  ('pc_gamer', 'pc_gamer');

--- 7- CHECK RAWS NUMBER IN CATEGORY TRANSLATION TABLE 
--- Result: 73 raws 

SELECT COUNT(*) FROM category_translation ;


--- 8- CALCULATE THE REVENUE PER MONTH (DELIVERED ORDERS ONLY)

SELECT STRFTIME('%Y-%m',o.order_purchase_timestamp) AS  month,
       COUNT(DISTINCT o.order_id) AS orders_number,
       ROUND(SUM(oi.price) , 2) AS revenue,
       ROUND(SUM(oi.freight_value) , 2) AS freight
FROM orders o 
JOIN order_items oi ON o.order_id = oi.order_id 
WHERE o.order_status = 'delivered'
GROUP BY month
ORDER BY month ;

--- 9- TOP 10 CATEGORIES BY REVENUE (DELIVERED ORDERS ONLY)

SELECT COALESCE(t.product_category_name_english, 'Unknown') AS category,
       COUNT(DISTINCT o.order_id) AS orders_number,
       ROUND(SUM(oi.price), 2 ) AS revenue
FROM orders o 
JOIN order_items oi ON oi.order_id = o.order_id 
JOIN products p ON p.product_id =oi.product_id 
LEFT JOIN category_translation t ON t.product_category_name = p.product_category_name 
WHERE o.order_status = 'delivered'
GROUP BY category 
ORDER BY revenue DESC 
LIMIT 10 ;


--- 10a- REVENUE PER STATE (DELIVERED ORDERS ONLY)

-- Result: 27 states. Top 3: SP 5,067,633.16 | RJ 1,759,651.13 | MG 1,552,481.83
-- Insight: SP alone brings ~38% of delivered revenue

SELECT c.customer_state AS state,
       COUNT(DISTINCT o.order_id) AS orders_number,
       ROUND(SUM(oi.price), 2 ) AS revenue
FROM orders o 
JOIN order_items oi ON oi.order_id = o.order_id 
JOIN customers c ON c.customer_id = o.customer_id 
WHERE o.order_status = 'delivered'
GROUP BY state 
ORDER BY revenue DESC ;

--- 10b- TOTAL REVENUE (DELIVERED ORDERS ONLY) 
-- Result: 13,221,498.11

SELECT 
ROUND(SUM(oi.price),2) AS total_revenue 
FROM order_items oi 
JOIN orders o  ON oi.order_id = o.order_id 
WHERE o.order_status = 'delivered' ;



--- 11- AVERAGE ORDER VALUE BY CATEGORY (DELIVERED ORDERS ONLY)

SELECT COALESCE(t.product_category_name_english, 'Unknown') AS category,
       COUNT(DISTINCT o.order_id) AS orders_number,
       ROUND(SUM(oi.price) / COUNT(DISTINCT o.order_id), 2) AS aov
FROM orders o 
JOIN order_items oi ON oi.order_id = o.order_id 
JOIN products p ON p.product_id = oi.product_id 
LEFT JOIN category_translation t ON t.product_category_name = p.product_category_name 
WHERE o.order_status = 'delivered'
GROUP BY category 
ORDER BY aov DESC ;


--- 12- DELIVERY DELAY: ON TIME VS LATE (DELIVERED ORDERS ONLY)
-- Result: late 7,826 (8.1%, avg +9.6 days) | on_time 88,652 (avg -13 days)
-- Insight: 1 in 12 orders arrives late, but late orders are ~10 days late on average

SELECT CASE 
	WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
	THEN 'late'
	ELSE 'on_time'
END AS delivery_status, 
COUNT(*) AS orders_number,
ROUND(AVG(JULIANDAY(o.order_delivered_customer_date) 
- JULIANDAY(o.order_estimated_delivery_date)) , 1) AS avg_days_vs_estimate
FROM orders o
WHERE o.order_status = 'delivered'
AND o.order_delivered_customer_date IS NOT NULL
GROUP BY delivery_status ;


--- 13- IMPORT olist_order_reviews_dataset 

--- 14- RENAME olist_order_reviews_dataset TO reviews

ALTER TABLE olist_order_reviews_dataset RENAME TO reviews ;  

-- 13- CHECK REVIEWS ROWS (after import)
-- Expected: 99224 

SELECT COUNT(*) FROM reviews ;

--- 14- REVIEW SCORE BY DELIVERY STATUS (DELIVERED ORDERS ONLY)


SELECT CASE 
	WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
	THEN 'late'
	ELSE 'on_time'
END AS delivery_status,
COUNT(*) AS reviews_number,
ROUND(AVG(r.review_score), 1 ) AS avg_review_score
FROM orders o 
JOIN reviews r ON r.order_id = o.order_id 
WHERE o.order_status = 'delivered'
AND o.order_delivered_customer_date IS NOT null 
GROUP BY delivery_status ;











