-- Marketplace Order & Customer Analytics
-- Seller, Delivery and Review Analysis

USE olist_ecommerce;


-- 1. Top 10 Sellers by Revenue

SELECT
    oi.seller_id,

    COUNT(
        DISTINCT o.order_id
    ) AS orders,

    COUNT(
        DISTINCT c.customer_unique_id
    ) AS customers,

    ROUND(
        SUM(oi.price),
        2
    ) AS revenue,

    ROUND(
        SUM(oi.price)
        / COUNT(DISTINCT o.order_id),
        2
    ) AS revenue_per_order

FROM orders AS o

JOIN order_items AS oi
    ON o.order_id = oi.order_id

JOIN customers AS c
    ON o.customer_id = c.customer_id

WHERE o.order_status = 'delivered'

GROUP BY oi.seller_id

ORDER BY revenue DESC

LIMIT 10;


-- 2. Seller Revenue Share

WITH seller_sales AS (

    SELECT
        oi.seller_id,

        SUM(
            oi.price
        ) AS revenue

    FROM orders AS o

    JOIN order_items AS oi
        ON o.order_id = oi.order_id

    WHERE o.order_status = 'delivered'

    GROUP BY oi.seller_id
)

SELECT
    seller_id,

    ROUND(
        revenue,
        2
    ) AS revenue,

    ROUND(
        revenue
        / SUM(revenue) OVER ()
        * 100,
        2
    ) AS revenue_share

FROM seller_sales

ORDER BY revenue DESC

LIMIT 10;


-- 3. Average Delivery Time

SELECT
    ROUND(
        AVG(
            DATEDIFF(
                order_delivered_customer_date,
                order_purchase_timestamp
            )
        ),
        2
    ) AS avg_delivery_days

FROM orders

WHERE order_status = 'delivered'

  AND order_delivered_customer_date
      IS NOT NULL;


-- 4. Late Delivery Rate

SELECT
    COUNT(*) AS delivered_orders,

    SUM(
        CASE

            WHEN order_delivered_customer_date >
                 order_estimated_delivery_date

            THEN 1

            ELSE 0

        END
    ) AS late_orders,

    ROUND(
        SUM(
            CASE

                WHEN order_delivered_customer_date >
                     order_estimated_delivery_date

                THEN 1

                ELSE 0

            END
        )
        / COUNT(*)
        * 100,
        2
    ) AS late_delivery_rate

FROM orders

WHERE order_status = 'delivered'

  AND order_delivered_customer_date
      IS NOT NULL

  AND order_estimated_delivery_date
      IS NOT NULL;


-- 5. Average Delivery Time by Customer State

SELECT
    c.customer_state,

    COUNT(
        DISTINCT o.order_id
    ) AS orders,

    ROUND(
        AVG(
            DATEDIFF(
                o.order_delivered_customer_date,
                o.order_purchase_timestamp
            )
        ),
        2
    ) AS avg_delivery_days

FROM orders AS o

JOIN customers AS c
    ON o.customer_id = c.customer_id

WHERE o.order_status = 'delivered'

  AND o.order_delivered_customer_date
      IS NOT NULL

GROUP BY
    c.customer_state

HAVING
    COUNT(
        DISTINCT o.order_id
    ) >= 100

ORDER BY avg_delivery_days DESC;


-- 6. Review Score Distribution

SELECT
    review_score,

    COUNT(*) AS reviews,

    ROUND(
        COUNT(*)
        / SUM(COUNT(*)) OVER ()
        * 100,
        2
    ) AS review_share

FROM reviews

GROUP BY review_score

ORDER BY review_score;


-- 7. Average Review Score

SELECT
    ROUND(
        AVG(review_score),
        2
    ) AS avg_review_score

FROM reviews;


-- 8. Review Score by Delivery Status

SELECT

    CASE

        WHEN o.order_delivered_customer_date >
             o.order_estimated_delivery_date

        THEN 'Late'

        ELSE 'On Time or Early'

    END AS delivery_status,

    COUNT(*) AS reviews,

    ROUND(
        AVG(r.review_score),
        2
    ) AS avg_review_score

FROM orders AS o

JOIN reviews AS r
    ON o.order_id = r.order_id

WHERE o.order_status = 'delivered'

  AND o.order_delivered_customer_date
      IS NOT NULL

  AND o.order_estimated_delivery_date
      IS NOT NULL

GROUP BY delivery_status;


-- 9. Review Score by Delivery Delay Group

SELECT

    CASE

        WHEN DATEDIFF(
            o.order_delivered_customer_date,
            o.order_estimated_delivery_date
        ) <= 0

        THEN 'On Time or Early'


        WHEN DATEDIFF(
            o.order_delivered_customer_date,
            o.order_estimated_delivery_date
        ) BETWEEN 1 AND 3

        THEN '1-3 Days Late'


        WHEN DATEDIFF(
            o.order_delivered_customer_date,
            o.order_estimated_delivery_date
        ) BETWEEN 4 AND 7

        THEN '4-7 Days Late'


        ELSE '8+ Days Late'

    END AS delay_group,

    COUNT(*) AS reviews,

    ROUND(
        AVG(r.review_score),
        2
    ) AS avg_review_score

FROM orders AS o

JOIN reviews AS r
    ON o.order_id = r.order_id

WHERE o.order_status = 'delivered'

  AND o.order_delivered_customer_date
      IS NOT NULL

  AND o.order_estimated_delivery_date
      IS NOT NULL

GROUP BY delay_group

ORDER BY

    CASE delay_group

        WHEN 'On Time or Early' THEN 1

        WHEN '1-3 Days Late' THEN 2

        WHEN '4-7 Days Late' THEN 3

        WHEN '8+ Days Late' THEN 4

    END;
