SELECT * FROM cleaned_retail_inventory;

-- Which products and categories sell the most --
-- Highest selling product per day --
WITH daily_product_sales AS(
    SELECT sales_date, product_id, category, SUM(units_sold) as total_daily_sales
    FROM cleaned_retail_inventory
    GROUP BY sales_date, product_id, category
),
daily_ranked AS(
    SELECT *,
    RANK() OVER(
        PARTITION BY sales_date
        ORDER BY total_daily_sales DESC
    ) AS rank_per_day
    FROM daily_product_sales
)
SELECT sales_date, product_id, category, total_daily_sales FROM daily_ranked
WHERE rank_per_day = 1
ORDER BY sales_date;

-- Highest selling product per month -- 
WITH monthly_product_sales AS(
    SELECT TO_CHAR(DATE_TRUNC('month', sales_date), 'YYYY-MM') AS sales_month, product_id, category, SUM(units_sold) AS total_monthly_sales
    FROM cleaned_retail_inventory
    GROUP BY 1,2,3
),
monthly_ranked AS(
    SELECT *,
    RANK() OVER(
        PARTITION BY sales_month
        ORDER BY total_monthly_sales DESC
    ) AS rank_per_month
    FROM monthly_product_sales
)
SELECT sales_month, product_id, category, total_monthly_sales FROM monthly_ranked
WHERE rank_per_month = 1
ORDER BY sales_month

-- Highest selling category per month --
WITH monthly_category_sales AS(
    SELECT TO_CHAR(DATE_TRUNC('month', sales_date), 'YYYY-MM') AS sales_month, category, SUM(units_sold) AS total_monthly_category_sales
    FROM cleaned_retail_inventory
    GROUP BY 1,2
),
monthly_ranked_category AS(
    SELECT *,
    RANK() OVER(
        PARTITION BY sales_month
        ORDER BY total_monthly_category_sales DESC
    ) AS category_rank_per_month
    FROM monthly_category_sales
)
SELECT sales_month, category, total_monthly_category_sales FROM monthly_ranked_category
WHERE category_rank_per_month = 1
ORDER BY sales_month

-- Highest selling product per year -- 
WITH yearly_product_sales AS(
    SELECT TO_CHAR(DATE_TRUNC('year', sales_date), 'YYYY') AS sales_year, product_id, category, SUM(units_sold) AS total_yearly_sales
    FROM cleaned_retail_inventory
    GROUP BY 1,2,3
),
yearly_ranked AS(
    SELECT *,
    RANK() OVER(
        PARTITION BY sales_year
        ORDER BY total_yearly_sales DESC
    ) AS rank_per_year
    FROM yearly_product_sales
)
SELECT sales_year, product_id, category, total_yearly_sales FROM yearly_ranked
WHERE rank_per_year = 1
ORDER BY sales_year
