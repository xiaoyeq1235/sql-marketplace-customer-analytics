-- Marketplace Order & Customer Analytics
-- Product Analysis

USE olist_ecommerce;


-- 1. Top 10 Product Categories by Revenue

SELECT
    ct.product_category_name_english AS category,

    COUNT(
        DISTINCT o.order_id
    ) AS orders,

    ROUND(
        SUM(oi.price),
        2
    ) AS revenue

FROM orders AS o

JOIN order_items AS oi
    ON o.order_id = oi.order_id

JOIN products AS p
    ON oi.product_id = p.product_id

LEFT JOIN category_translation AS ct
    ON p.product_category_name =
       ct.product_category_name

WHERE o.order_status = 'delivered'

GROUP BY
    ct.product_category_name_english

ORDER BY revenue DESC

LIMIT 10;


-- 2. Product Category Revenue and AOV

SELECT
    ct.product_category_name_english AS category,

    COUNT(
        DISTINCT o.order_id
    ) AS orders,

    ROUND(
        SUM(oi.price),
        2
    ) AS revenue,

    ROUND(
        SUM(oi.price)
        / COUNT(DISTINCT o.order_id),
        2
    ) AS category_aov

FROM orders AS o

JOIN order_items AS oi
    ON o.order_id = oi.order_id

JOIN products AS p
    ON oi.product_id = p.product_id

LEFT JOIN category_translation AS ct
    ON p.product_category_name =
       ct.product_category_name

WHERE o.order_status = 'delivered'

GROUP BY
    ct.product_category_name_english

ORDER BY revenue DESC;


-- 3. Monthly Top 3 Product Categories

WITH monthly_category_sales AS (

    SELECT
        DATE_FORMAT(
            o.order_purchase_timestamp,
            '%Y-%m'
        ) AS month,

        ct.product_category_name_english
            AS category,

        SUM(oi.price) AS revenue

    FROM orders AS o

    JOIN order_items AS oi
        ON o.order_id = oi.order_id

    JOIN products AS p
        ON oi.product_id = p.product_id

    LEFT JOIN category_translation AS ct
        ON p.product_category_name =
           ct.product_category_name

    WHERE o.order_status = 'delivered'

    GROUP BY
        month,
        category
),

ranked_categories AS (

    SELECT
        month,
        category,
        revenue,

        DENSE_RANK() OVER (
            PARTITION BY month
            ORDER BY revenue DESC
        ) AS category_rank

    FROM monthly_category_sales
)

SELECT
    month,
    category,

    ROUND(
        revenue,
        2
    ) AS revenue,

    category_rank

FROM ranked_categories

WHERE category_rank <= 3

ORDER BY
    month,
    category_rank;