-- Marketplace Order & Customer Analytics
-- Customer Analysis

USE olist_ecommerce;


-- 1. Number of Orders per Customer

WITH customer_orders AS (

    SELECT
        c.customer_unique_id,

        COUNT(
            DISTINCT o.order_id
        ) AS order_count

    FROM orders AS o

    JOIN customers AS c
        ON o.customer_id = c.customer_id

    WHERE o.order_status = 'delivered'

    GROUP BY
        c.customer_unique_id
)

SELECT
    customer_unique_id,
    order_count

FROM customer_orders

ORDER BY order_count DESC

LIMIT 20;


-- 2. Repeat Customer Rate

WITH customer_orders AS (

    SELECT
        c.customer_unique_id,

        COUNT(
            DISTINCT o.order_id
        ) AS order_count

    FROM orders AS o

    JOIN customers AS c
        ON o.customer_id = c.customer_id

    WHERE o.order_status = 'delivered'

    GROUP BY
        c.customer_unique_id
)

SELECT

    COUNT(*) AS total_customers,

    SUM(
        CASE
            WHEN order_count > 1 THEN 1
            ELSE 0
        END
    ) AS repeat_customers,

    ROUND(
        SUM(
            CASE
                WHEN order_count > 1 THEN 1
                ELSE 0
            END
        )
        / COUNT(*)
        * 100,
        2
    ) AS repeat_customer_rate

FROM customer_orders;


-- 3. Customer Purchase Frequency Distribution

WITH customer_orders AS (

    SELECT
        c.customer_unique_id,

        COUNT(
            DISTINCT o.order_id
        ) AS order_count

    FROM orders AS o

    JOIN customers AS c
        ON o.customer_id = c.customer_id

    WHERE o.order_status = 'delivered'

    GROUP BY
        c.customer_unique_id
)

SELECT
    order_count,

    COUNT(*) AS customers

FROM customer_orders

GROUP BY order_count

ORDER BY order_count;


-- 4. Customer Purchase Frequency Share

WITH customer_orders AS (

    SELECT
        c.customer_unique_id,

        COUNT(
            DISTINCT o.order_id
        ) AS order_count

    FROM orders AS o

    JOIN customers AS c
        ON o.customer_id = c.customer_id

    WHERE o.order_status = 'delivered'

    GROUP BY
        c.customer_unique_id
),

frequency_distribution AS (

    SELECT
        order_count,

        COUNT(*) AS customers

    FROM customer_orders

    GROUP BY order_count
)

SELECT
    order_count,

    customers,

    ROUND(
        customers
        / SUM(customers) OVER ()
        * 100,
        2
    ) AS customer_share

FROM frequency_distribution

ORDER BY order_count;
