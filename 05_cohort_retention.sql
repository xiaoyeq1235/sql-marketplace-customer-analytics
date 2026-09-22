-- Marketplace Order & Customer Analytics
-- Cohort Retention Analysis

USE olist_ecommerce;


-- 1. First Purchase Date for Each Customer

SELECT
    c.customer_unique_id,

    MIN(
        o.order_purchase_timestamp
    ) AS first_purchase

FROM orders AS o

JOIN customers AS c
    ON o.customer_id = c.customer_id

WHERE o.order_status = 'delivered'

GROUP BY
    c.customer_unique_id

LIMIT 20;


-- 2. Customer Cohort Month and Order Month

WITH first_purchase AS (

    SELECT
        c.customer_unique_id,

        MIN(
            o.order_purchase_timestamp
        ) AS first_purchase

    FROM orders AS o

    JOIN customers AS c
        ON o.customer_id = c.customer_id

    WHERE o.order_status = 'delivered'

    GROUP BY
        c.customer_unique_id
)

SELECT
    c.customer_unique_id,

    DATE_FORMAT(
        fp.first_purchase,
        '%Y-%m'
    ) AS cohort_month,

    DATE_FORMAT(
        o.order_purchase_timestamp,
        '%Y-%m'
    ) AS order_month

FROM orders AS o

JOIN customers AS c
    ON o.customer_id = c.customer_id

JOIN first_purchase AS fp
    ON c.customer_unique_id =
       fp.customer_unique_id

WHERE o.order_status = 'delivered'

LIMIT 30;


-- 3. Calculate Cohort Month Number

WITH first_purchase AS (

    SELECT
        c.customer_unique_id,

        MIN(
            o.order_purchase_timestamp
        ) AS first_purchase

    FROM orders AS o

    JOIN customers AS c
        ON o.customer_id = c.customer_id

    WHERE o.order_status = 'delivered'

    GROUP BY
        c.customer_unique_id
)

SELECT
    c.customer_unique_id,

    DATE_FORMAT(
        fp.first_purchase,
        '%Y-%m'
    ) AS cohort_month,

    DATE_FORMAT(
        o.order_purchase_timestamp,
        '%Y-%m'
    ) AS order_month,

    PERIOD_DIFF(
        DATE_FORMAT(
            o.order_purchase_timestamp,
            '%Y%m'
        ),

        DATE_FORMAT(
            fp.first_purchase,
            '%Y%m'
        )
    ) AS month_number

FROM orders AS o

JOIN customers AS c
    ON o.customer_id = c.customer_id

JOIN first_purchase AS fp
    ON c.customer_unique_id =
       fp.customer_unique_id

WHERE o.order_status = 'delivered'

LIMIT 30;


-- 4. Active Customers by Cohort and Month Number

WITH first_purchase AS (

    SELECT
        c.customer_unique_id,

        MIN(
            o.order_purchase_timestamp
        ) AS first_purchase

    FROM orders AS o

    JOIN customers AS c
        ON o.customer_id = c.customer_id

    WHERE o.order_status = 'delivered'

    GROUP BY
        c.customer_unique_id
),

cohort_data AS (

    SELECT
        c.customer_unique_id,

        DATE_FORMAT(
            fp.first_purchase,
            '%Y-%m'
        ) AS cohort_month,

        PERIOD_DIFF(
            DATE_FORMAT(
                o.order_purchase_timestamp,
                '%Y%m'
            ),

            DATE_FORMAT(
                fp.first_purchase,
                '%Y%m'
            )
        ) AS month_number

    FROM orders AS o

    JOIN customers AS c
        ON o.customer_id = c.customer_id

    JOIN first_purchase AS fp
        ON c.customer_unique_id =
           fp.customer_unique_id

    WHERE o.order_status = 'delivered'
)

SELECT
    cohort_month,

    month_number,

    COUNT(
        DISTINCT customer_unique_id
    ) AS active_customers

FROM cohort_data

GROUP BY
    cohort_month,
    month_number

ORDER BY
    cohort_month,
    month_number;


-- 5. Cohort Retention Rate

WITH first_purchase AS (

    SELECT
        c.customer_unique_id,

        MIN(
            o.order_purchase_timestamp
        ) AS first_purchase

    FROM orders AS o

    JOIN customers AS c
        ON o.customer_id = c.customer_id

    WHERE o.order_status = 'delivered'

    GROUP BY
        c.customer_unique_id
),

cohort_data AS (

    SELECT
        c.customer_unique_id,

        DATE_FORMAT(
            fp.first_purchase,
            '%Y-%m'
        ) AS cohort_month,

        PERIOD_DIFF(
            DATE_FORMAT(
                o.order_purchase_timestamp,
                '%Y%m'
            ),

            DATE_FORMAT(
                fp.first_purchase,
                '%Y%m'
            )
        ) AS month_number

    FROM orders AS o

    JOIN customers AS c
        ON o.customer_id = c.customer_id

    JOIN first_purchase AS fp
        ON c.customer_unique_id =
           fp.customer_unique_id

    WHERE o.order_status = 'delivered'
),

cohort_counts AS (

    SELECT
        cohort_month,

        month_number,

        COUNT(
            DISTINCT customer_unique_id
        ) AS active_customers

    FROM cohort_data

    GROUP BY
        cohort_month,
        month_number
),

cohort_sizes AS (

    SELECT
        cohort_month,

        active_customers AS cohort_size

    FROM cohort_counts

    WHERE month_number = 0
)

SELECT
    cc.cohort_month,

    cc.month_number,

    cc.active_customers,

    cs.cohort_size,

    ROUND(
        cc.active_customers
        / cs.cohort_size
        * 100,
        2
    ) AS retention_rate

FROM cohort_counts AS cc

JOIN cohort_sizes AS cs
    ON cc.cohort_month =
       cs.cohort_month

ORDER BY
    cc.cohort_month,
    cc.month_number;