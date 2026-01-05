SELECT * FROM cleaned_retail_inventory;

-- Summary Stats --
-- units_sold & units_ordered --
-- Most products have moderate sales, but a few top-selling products significantly boost overall sales volume --
SELECT MIN(units_sold) AS min_units_sold, 
    MAX(units_sold) AS max_units_sold, 
    AVG(units_sold) AS avg_units_sold, 
    PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY units_sold) AS median_units_sold,

    MIN(units_ordered) AS min_units_ordered,
    MAX(units_ordered) AS max_units_ordered,
    AVG(units_ordered) AS avg_units_ordered,
    PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY units_ordered) AS median_units_ordered

FROM cleaned_retail_inventory;

-- price & discount --
-- Prices and discounts are fairly consistent across products, with no extreme performers significantly skewing the distribution --
SELECT
    MIN(price)  AS min_price,
    MAX(price)  AS max_price,
    AVG(price)  AS avg_price,
    PERCENTILE_CONT(0.5) 
        WITHIN GROUP (ORDER BY price) AS median_price,

    MIN(discount) AS min_discount,
    MAX(discount) AS max_discount,
    AVG(discount) AS avg_discount,
    PERCENTILE_CONT(0.5) 
        WITHIN GROUP (ORDER BY discount) AS median_discount

FROM cleaned_retail_inventory;

-- inventory --
SELECT
    MIN(inventory)  AS min_inventory,
    MAX(inventory)  AS max_inventory,
    AVG(inventory)  AS avg_inventory,
    PERCENTILE_CONT(0.5) 
        WITHIN GROUP (ORDER BY inventory) AS median_inventory
FROM cleaned_retail_inventory;

-- demand_forecast --
SELECT
    MIN(demand_forecast)  AS min_demand_forecast,
    MAX(demand_forecast)  AS max_demand_forecast,
    AVG(demand_forecast)  AS avg_demand_forecast,
    PERCENTILE_CONT(0.5) 
        WITHIN GROUP (ORDER BY demand_forecast) AS median_demand_forecast
FROM cleaned_retail_inventory;

-- competitor_pricing --
SELECT
    MIN(competitor_pricing) AS min_competitor_pricing,
    MAX(competitor_pricing) AS max_competitor_pricing,
    AVG(competitor_pricing) AS avg_competitor_pricing,
    PERCENTILE_CONT(0.5)
        WITHIN GROUP(ORDER BY competitor_pricing) AS median_competitor_pricing
FROM cleaned_retail_inventory;

-- sales_date --
SELECT
    MIN(sales_date) AS start_date,
    MAX(sales_date) AS end_date
FROM cleaned_retail_inventory;

-- Data Distribution --
-- units_sold & units_ordered --
SELECT PERCENTILE_CONT(ARRAY[0.25, 0.5, 0.75])
    WITHIN GROUP(ORDER BY units_sold) AS quartiles_units_sold,

    PERCENTILE_CONT(ARRAY[0.25, 0.5, 0.75])
    WITHIN GROUP(ORDER BY units_ordered) AS quartiles_units_ordered

FROM cleaned_retail_inventory

-- price & discount --
SELECT PERCENTILE_CONT(ARRAY[0.25, 0.5, 0.75])
    WITHIN GROUP(ORDER BY price) AS quartiles_price,

    PERCENTILE_CONT(ARRAY[0.25, 0.5, 0.75])
    WITHIN GROUP(ORDER BY discount) AS quartiles_discount

FROM cleaned_retail_inventory

-- inventory --
SELECT PERCENTILE_CONT(ARRAY[0.25, 0.5, 0.75])
    WITHIN GROUP(ORDER BY inventory) AS quartiles_inventory
FROM cleaned_retail_inventory

-- demand_forecast --
SELECT PERCENTILE_CONT(ARRAY[0.25, 0.5, 0.75])
    WITHIN GROUP(ORDER BY demand_forecast) AS quartiles_demand_forecast
FROM cleaned_retail_inventory

-- competitor_pricing --
SELECT PERCENTILE_CONT(ARRAY[0.25, 0.5, 0.75])
    WITHIN GROUP(ORDER BY competitor_pricing) AS quartiles_competitor_pricing
FROM cleaned_retail_inventory

-- Categorical Summary --
-- category --
SELECT category, COUNT(*) AS records
FROM cleaned_retail_inventory
GROUP BY category
ORDER BY records DESC;

-- region --
SELECT region, COUNT(*) AS records
FROM cleaned_retail_inventory
GROUP BY region
ORDER BY records DESC;

-- weather_condition --
SELECT weather_condition, COUNT(*) AS records
FROM cleaned_retail_inventory
GROUP BY weather_condition
ORDER BY records DESC;

-- holiday_promotion --
SELECT holiday_promotion, COUNT(*) AS records
FROM cleaned_retail_inventory
GROUP BY holiday_promotion
ORDER BY records DESC;

-- seasonality --
SELECT seasonality, COUNT(*) AS records
FROM cleaned_retail_inventory
GROUP BY seasonality
ORDER BY records DESC;

---------------------------------------------- EDA ---------------------------------------------
-------------------------------- Sales and Product Performance ----------------------------
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

-- Products declining month over month -- 
WITH monthly_sales AS(
    SELECT TO_CHAR(DATE_TRUNC('month', sales_date), 'YYYY-MM') as sales_month, product_id, category, SUM(units_sold) AS total_units_sold
    FROM cleaned_retail_inventory 
    GROUP BY 1,2,3
),
declining_monthly_ranked AS(
    SELECT *,
    RANK() OVER(
        PARTITION BY sales_month
        ORDER BY total_units_sold DESC
    ) AS rank_per_month
    FROM monthly_sales
)
SELECT sales_month, product_id, category, total_units_sold FROM declining_monthly_ranked
WHERE total_units_sold < 2500
ORDER BY sales_month, rank_per_month DESC

-- Products declining month over month (revenue-based) -- 
WITH monthly_prices AS(
    SELECT TO_CHAR(DATE_TRUNC('month', sales_date), 'YYYY-MM') as sales_month, product_id, category, SUM((units_sold*price) - ((discount/100)*(units_sold*price))) AS monthly_price, SUM(units_sold) AS monthly_units_sold
    FROM cleaned_retail_inventory
    GROUP BY 1,2,3
),
declining_monthly_ranked AS(
    SELECT *,
    RANK() OVER(
        PARTITION BY sales_month
        ORDER BY monthly_price DESC
    ) AS monthly_rank
    FROM monthly_prices
)
SELECT sales_month, product_id, category, monthly_price, monthly_units_sold
FROM declining_monthly_ranked
WHERE monthly_price < 150000
ORDER BY sales_month, monthly_rank DESC

-- Top 10 products per category -- 
WITH product_category AS(
    SELECT product_id, category, SUM(units_sold) AS total_units_sold
    FROM cleaned_retail_inventory
    GROUP BY 1,2
),
ranked_products AS(
    SELECT *,
    RANK() OVER(
        PARTITION BY category
        ORDER BY total_units_sold DESC
    ) AS product_rank
    FROM product_category
)
SELECT product_id, category, total_units_sold, product_rank
FROM ranked_products
WHERE product_rank >= 1 AND product_rank <= 10

-- Top product per category per month -- 
WITH product_category AS(
    SELECT TO_CHAR(DATE_TRUNC('month', sales_date), 'YYYY-MM') as sales_month, product_id, category, SUM(units_sold) AS total_units_sold
    FROM cleaned_retail_inventory
    GROUP BY 1,2,3
),
ranked_products AS(
    SELECT *,
    RANK() OVER(
        PARTITION BY sales_month, category
        ORDER BY total_units_sold DESC
    ) AS product_rank
    FROM product_category
)
SELECT sales_month, product_id, category, total_units_sold
FROM ranked_products
WHERE product_rank = 1
ORDER BY sales_month, total_units_sold DESC

------------------------------------ Inventory Health ---------------------------------------
-- Items that are overstocked but have low sales --
WITH monthly_inventory_sales_status AS(
    SELECT TO_CHAR(DATE_TRUNC('month', sales_date), 'YYYY-MM') AS sales_month, product_id, category,
    SUM(units_ordered) AS monthly_units_ordered,
    SUM(units_sold) AS monthly_units_sold,
    SUM(demand_forecast) AS monthly_demand_forecast
    FROM cleaned_retail_inventory
    GROUP BY 1,2,3
)
SELECT sales_month, product_id, category, monthly_units_sold, monthly_units_ordered,
(monthly_units_ordered - monthly_units_sold)/monthly_units_sold AS overstock_ratio,
monthly_demand_forecast,
CASE WHEN ((monthly_units_ordered - monthly_units_sold)/monthly_units_sold)>0.75 THEN 'Overstocked' ELSE 'Healthy' END AS stock_status
FROM monthly_inventory_sales_status
WHERE ((monthly_units_ordered - monthly_units_sold)/monthly_units_sold)>0.75
ORDER BY sales_month, overstock_ratio DESC

-- Inventory turnover rate (monthly)
WITH start_date_cte AS(
    SELECT TO_CHAR(DATE_TRUNC('month', sales_date), 'YYYY-MM') AS inventory_month,
    MIN(sales_date) AS start_date,
    category
    FROM cleaned_retail_inventory
    GROUP BY 1,3
),
beginning_inventory_cte AS(
    SELECT s.inventory_month, s.category, SUM(c.inventory) AS beginning_inventory
    FROM start_date_cte AS s JOIN cleaned_retail_inventory AS c
    ON TO_CHAR(DATE_TRUNC('month', c.sales_date), 'YYYY-MM') = s.inventory_month
      AND c.category = s.category
      AND c.sales_date = s.start_date
    GROUP BY s.inventory_month, s.category
),
end_date_cte AS(
    SELECT TO_CHAR(DATE_TRUNC('month', sales_date), 'YYYY-MM') AS inventory_month,
    MAX(sales_date) AS end_date,
    category
    FROM cleaned_retail_inventory
    GROUP BY 1,3
),
ending_inventory_cte AS(
    SELECT e.inventory_month, e.category, SUM(c.inventory) AS ending_inventory
    FROM end_date_cte AS e JOIN cleaned_retail_inventory AS c
    ON TO_CHAR(DATE_TRUNC('month', c.sales_date), 'YYYY-MM') = e.inventory_month
      AND c.category = e.category
      AND c.sales_date = e.end_date
    GROUP BY e.inventory_month, e.category
),
monthly_units_sold_cte AS(
    SELECT TO_CHAR(DATE_TRUNC('month', sales_date), 'YYYY-MM') AS inventory_month, category, SUM(units_sold) AS total_monthly_units_sold
    FROM cleaned_retail_inventory
    GROUP BY 1,2
),
inventory_cte AS(
    SELECT b.inventory_month, b.category, b.beginning_inventory, e.ending_inventory, m.total_monthly_units_sold
    FROM beginning_inventory_cte AS b JOIN ending_inventory_cte AS e
    ON b.inventory_month = e.inventory_month AND b.category = e.category
    JOIN monthly_units_sold_cte AS m
    ON b.inventory_month = m.inventory_month AND b.category = m.category
)
SELECT *, ROUND((beginning_inventory+ending_inventory)/2.0, 2) AS average_inventory,
ROUND((total_monthly_units_sold)/((beginning_inventory+ending_inventory)/2.0), 2) AS inventory_turnover_rate
FROM inventory_cte
ORDER BY inventory_month

