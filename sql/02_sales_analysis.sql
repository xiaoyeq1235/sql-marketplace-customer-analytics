-- Marketplace Order & Customer Analytics
-- Sales Analysis

USE olist_ecommerce;


-- 1. Total Orders

SELECT
    COUNT(*) AS total_orders
FROM orders;


-- 2. Order Status Distribution

SELECT
    order_status,
    COUNT(*) AS order_count
FROM orders
GROUP BY order_status
ORDER BY order_count DESC;


-- 3. Dataset Time Range

SELECT
    MIN(order_purchase_timestamp) AS first_order,
    MAX(order_purchase_timestamp) AS last_order
FROM orders;


-- 4. Monthly Orders, GMV and AOV

SELECT
    DATE_FORMAT(
        o.order_purchase_timestamp,
        '%Y-%m'
    ) AS month,

    COUNT(DISTINCT o.order_id) AS orders,

    ROUND(
        SUM(oi.price),
        2
    ) AS gmv,

    ROUND(
        SUM(oi.price)
        / COUNT(DISTINCT o.order_id),
        2
    ) AS aov

FROM orders AS o

JOIN order_items AS oi
    ON o.order_id = oi.order_id

WHERE o.order_status = 'delivered'

GROUP BY month

ORDER BY month;


-- 5. Monthly Active Customers

SELECT
    DATE_FORMAT(
        o.order_purchase_timestamp,
        '%Y-%m'
    ) AS month,

    COUNT(
        DISTINCT c.customer_unique_id
    ) AS active_customers

FROM orders AS o

JOIN customers AS c
    ON o.customer_id = c.customer_id

WHERE o.order_status = 'delivered'

GROUP BY month

ORDER BY month;


-- 6. Monthly GMV Growth Rate

WITH monthly_sales AS (

    SELECT
        DATE_FORMAT(
            o.order_purchase_timestamp,
            '%Y-%m'
        ) AS month,

        SUM(oi.price) AS gmv

    FROM orders AS o

    JOIN order_items AS oi
        ON o.order_id = oi.order_id

    WHERE o.order_status = 'delivered'

    GROUP BY month
),

sales_with_previous AS (

    SELECT
        month,
        gmv,

        LAG(gmv) OVER (
            ORDER BY month
        ) AS previous_month_gmv

    FROM monthly_sales
)

SELECT
    month,

    ROUND(
        gmv,
        2
    ) AS gmv,

    ROUND(
        previous_month_gmv,
        2
    ) AS previous_month_gmv,

    ROUND(
        (
            gmv - previous_month_gmv
        )
        / previous_month_gmv
        * 100,
        2
    ) AS mom_growth_rate

FROM sales_with_previous

ORDER BY month;
