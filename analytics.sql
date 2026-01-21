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
ORDER BY sales_month;

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
ORDER BY sales_month;

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
ORDER BY sales_year;

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
ORDER BY sales_month, rank_per_month DESC;

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
WHERE product_rank >= 1 AND product_rank <= 10;

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
ORDER BY sales_month, total_units_sold DESC;

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
ORDER BY sales_month, overstock_ratio DESC;

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
ORDER BY inventory_month;

------------------------- Seasonal Trends ------------------------------
-- How do sales vary through the months? --
SELECT TO_CHAR(DATE_TRUNC('month', sales_date), 'YYYY-MM') as sales_month, seasonality, SUM(units_sold) as total_monthly_sale
FROM cleaned_retail_inventory
GROUP BY 1, seasonality
ORDER BY 1,
    CASE seasonality
        WHEN 'Spring' THEN 2
        WHEN 'Summer' THEN 3
        WHEN 'Autumn' THEN 4
        WHEN 'winter' THEN 5
    END;

-- How do sales vary by season through the years? --
SELECT TO_CHAR(DATE_TRUNC('year', sales_date), 'YYYY') as sales_year, seasonality, SUM(units_sold) as total_yearly_sale
FROM cleaned_retail_inventory
GROUP BY 1, seasonality
ORDER BY 1,
    CASE seasonality
        WHEN 'Spring' THEN 2
        WHEN 'Summer' THEN 3
        WHEN 'Autumn' THEN 4
        WHEN 'winter' THEN 5
    END;

-- How do sales vary by season? --
SELECT seasonality, SUM(units_sold) as total_monthly_sale
FROM cleaned_retail_inventory
GROUP BY seasonality
ORDER BY
    CASE seasonality
        WHEN 'Spring' THEN 2
        WHEN 'Summer' THEN 3
        WHEN 'Autumn' THEN 4
        WHEN 'winter' THEN 5
    END;

-- Which categories perform better in summer and winter? --
WITH summer_category_performance AS(
    SELECT TO_CHAR(DATE_TRUNC('year', sales_date), 'YYYY') as sales_year, category, SUM(units_sold) as summer_sale
    FROM cleaned_retail_inventory
    WHERE seasonality = 'Summer'
    GROUP BY 1, 2
),
winter_category_performance AS(
    SELECT TO_CHAR(DATE_TRUNC('year', sales_date), 'YYYY') as sales_year, category, SUM(units_sold) as winter_sale
    FROM cleaned_retail_inventory
    WHERE seasonality = 'Winter'
    GROUP BY 1, 2
)
SELECT s.sales_year, s.category, s.summer_sale, w.winter_sale
FROM summer_category_performance AS s JOIN winter_category_performance AS w
ON s.sales_year = w.sales_year AND s.category = w.category
ORDER BY s.sales_year;

-- Which products were the highest in demand month-wise --
WITH monthly_demand_forecast_cte AS(
    SELECT TO_CHAR(DATE_TRUNC('month', sales_date), 'YYYY-MM') AS demand_month, category, SUM(demand_forecast) AS monthly_demand_forecast
    FROM cleaned_retail_inventory
    GROUP BY 1,2
),
demand_forecast_rank_cte AS(
    SELECT *,
    RANK() OVER(
        PARTITION BY demand_month
        ORDER BY monthly_demand_forecast DESC
    ) AS demand_rank
    FROM monthly_demand_forecast_cte
)
SELECT demand_month, category, monthly_demand_forecast
FROM demand_forecast_rank_cte
WHERE demand_rank=1;

-- Peak demand months for each category --
WITH category_monthly_demand_forecast_cte AS(
    SELECT TO_CHAR(DATE_TRUNC('month', sales_date), 'MM') AS demand_month, category, SUM(demand_forecast) AS monthly_demand_forecast
    FROM cleaned_retail_inventory
    GROUP BY 1,2
),
demand_forecast_rank_cte AS(
    SELECT *,
    RANK() OVER(
        PARTITION BY category
        ORDER BY monthly_demand_forecast DESC
    ) AS demand_rank
    FROM category_monthly_demand_forecast_cte
)
SELECT category, demand_month AS peak_demand_calendar_month, monthly_demand_forecast AS peak_demand_forecast
FROM demand_forecast_rank_cte
WHERE demand_rank = 1;

-- Overstocked products in off season -- 
WITH monthly_inventory_status_cte AS(
    SELECT TO_CHAR(DATE_TRUNC('month', sales_date), 'YYYY-MM') AS demand_month, product_id, category,
    SUM(units_ordered) AS monthly_units_ordered,
    SUM(units_sold) AS monthly_units_sold,
    SUM(demand_forecast) AS monthly_demand_forecast
    FROM cleaned_retail_inventory
    GROUP BY 1,2,3
),
demand_forecast_rank_cte AS(
    SELECT *,
    RANK() OVER(
        PARTITION BY demand_month
        ORDER BY monthly_demand_forecast DESC
    ) AS demand_rank
    FROM monthly_inventory_status_cte
)
SELECT demand_month, product_id, category, monthly_units_sold, monthly_units_ordered,
(monthly_units_ordered - monthly_units_sold)/monthly_units_sold AS overstock_ratio,
monthly_demand_forecast, demand_rank,
CASE WHEN ((monthly_units_ordered - monthly_units_sold)/monthly_units_sold)>0.75 THEN 'Overstocked' ELSE 'Healthy' END AS stock_status
FROM demand_forecast_rank_cte
WHERE ((monthly_units_ordered - monthly_units_sold)/monthly_units_sold)>0.75
ORDER BY demand_month, overstock_ratio DESC;

-- Missed sales in high season --
SELECT 
    TO_CHAR(DATE_TRUNC('month', sales_date), 'YYYY-MM') AS sales_month,
    product_id,
    category,
    GREATEST(
        0,
        ROUND(SUM(demand_forecast) - SUM(units_sold), 0)
    ) AS missed_sales
FROM cleaned_retail_inventory
GROUP BY 1,2,3;

-- Are discounted items actually selling better? --
WITH monthly_discounted_cte AS(
    SELECT TO_CHAR(DATE_TRUNC('month', sales_date), 'YYYY-MM') as sales_month, product_id, category, ROUND(AVG(units_sold),2) as avg_units_sold, SUM((units_sold*price) - ((discount/100)*(units_sold*price))) AS total_revenue
    FROM cleaned_retail_inventory
    WHERE discount > 0
    GROUP BY 1,2,3
),
monthly_non_discounted_cte AS(
    SELECT TO_CHAR(DATE_TRUNC('month', sales_date), 'YYYY-MM') as sales_month, product_id, category, ROUND(AVG(units_sold),2) as avg_units_sold, SUM(units_sold*price) AS total_revenue
    FROM cleaned_retail_inventory
    WHERE discount = 0
    GROUP BY 1,2,3
)
SELECT d.sales_month, d.product_id, d.category, (d.avg_units_sold - n.avg_units_sold) AS diff_avg_units_sold, (d.total_revenue - n.total_revenue) AS diff_total_revenue,
CASE 
    WHEN (d.avg_units_sold - n.avg_units_sold) > 0 AND (d.total_revenue - n.total_revenue) > 0 THEN 'Effective Discount'
    WHEN (d.avg_units_sold - n.avg_units_sold) > 0 AND (d.total_revenue - n.total_revenue) < 0 THEN 'Volume at a Cost'
    WHEN (d.avg_units_sold - n.avg_units_sold) < 0 AND (d.total_revenue - n.total_revenue) > 0 THEN 'Ineffective Discount'
    WHEN (d.avg_units_sold - n.avg_units_sold) < 0 AND (d.total_revenue - n.total_revenue) < 0 THEN 'Counterproductive Discount'
END AS discount_performance
FROM monthly_discounted_cte AS d INNER JOIN monthly_non_discounted_cte AS n
ON d.sales_month = n.sales_month AND d.product_id = n.product_id AND d.category = n.category
ORDER BY d.sales_month, product_id;

-- Discount that gives highest revenue for each product (month-wise) --
WITH discount_revenue_cte AS(
    SELECT TO_CHAR(DATE_TRUNC('month', sales_date), 'YYYY-MM') as sales_month, product_id, category, discount, SUM((units_sold*price) - ((discount/100)*(units_sold*price))) AS revenue
    FROM cleaned_retail_inventory
    WHERE discount > 0
    GROUP BY 1,2,3,4
),
revenue_rank_cte AS(
    SELECT *,
    RANK() OVER(
        PARTITION BY sales_month, product_id, category
        ORDER BY revenue DESC
    ) AS revenue_rank
    FROM discount_revenue_cte
)
SELECT sales_month, product_id, category, discount, revenue
FROM revenue_rank_cte
WHERE revenue_rank = 1;

-- Price positioning against competitors --
SELECT TO_CHAR(DATE_TRUNC('month', sales_date), 'YYYY-MM') AS sales_month, product_id, category, 
ROUND(AVG(price), 2) AS avg_price, ROUND(AVG(competitor_pricing), 2) AS avg_competitor_price, 
ROUND(AVG(price - competitor_pricing), 2) AS avg_price_gap
FROM cleaned_retail_inventory
GROUP BY 1,2,3;

-- Correlation between demand forecast and competitor pricing --
SELECT TO_CHAR(DATE_TRUNC('month', sales_date), 'YYYY-MM') AS sales_month, product_id, category,
CORR(units_sold, competitor_pricing) AS correlation
FROM cleaned_retail_inventory
GROUP BY 1,2,3
HAVING CORR(units_sold, competitor_pricing) > 0.5 OR CORR(units_sold, competitor_pricing) < -0.5
ORDER BY 1,2;

-- Trend of units sold on the basis of competitor pricing fluctuation --
WITH competitor_pricing_distribution_cte AS(
    SELECT TO_CHAR(DATE_TRUNC('month', sales_date), 'YYYY-MM') AS sales_month, product_id, category,
    MIN(competitor_pricing) AS min_competitor_pricing,
    ROUND(PERCENTILE_CONT(0.25)
        WITHIN GROUP(ORDER BY competitor_pricing)) AS q1_competitor_pricing,
    ROUND(PERCENTILE_CONT(0.5)
        WITHIN GROUP(ORDER BY competitor_pricing)) AS q2_competitor_pricing,
    ROUND(PERCENTILE_CONT(0.75)
        WITHIN GROUP(ORDER BY competitor_pricing)) AS q3_competitor_pricing,
    MAX(competitor_pricing) AS max_competitor_pricing
    FROM cleaned_retail_inventory
    GROUP BY 1,2,3
)
SELECT d.sales_month, c.product_id, c.category, c.units_sold,
CASE
    WHEN c.competitor_pricing BETWEEN d.min_competitor_pricing AND d.q1_competitor_pricing THEN 'Low'
    WHEN c.competitor_pricing BETWEEN d.q1_competitor_pricing AND d.q2_competitor_pricing THEN 'Lower-Mid'
    WHEN c.competitor_pricing BETWEEN d.q2_competitor_pricing AND d.q3_competitor_pricing THEN 'Upper-Mid'
    WHEN c.competitor_pricing BETWEEN d.q3_competitor_pricing AND d.max_competitor_pricing THEN 'High'
END AS competitor_price_status
FROM competitor_pricing_distribution_cte AS d INNER JOIN cleaned_retail_inventory AS c
ON d.sales_month = TO_CHAR(DATE_TRUNC('month', c.sales_date), 'YYYY-MM') AND d.product_id = c.product_id AND d.category = c.category
ORDER BY d.sales_month, c.product_id, c.category;

-- Revenue impact due to competitor pricing --
WITH price_difference_cte AS(
    SELECT 
        TO_CHAR(DATE_TRUNC('month', sales_date), 'YYYY-MM') AS sales_month,
        product_id, 
        category, 
        ROUND(AVG(price - competitor_pricing), 2) AS avg_price_difference
    FROM cleaned_retail_inventory
    GROUP BY 1,2,3
),
price_difference_distribution_cte AS (
    SELECT
        MIN(avg_price_difference) AS min_avg_price_difference,
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY avg_price_difference) AS q1_avg_price_difference,
        PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY avg_price_difference) AS median_avg_price_difference,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY avg_price_difference) AS q3_avg_price_difference,
        MAX(avg_price_difference) AS max_avg_price_difference
    FROM price_difference_cte
)
SELECT
    c.sales_date, c.product_id, c.category, c.price, c.competitor_pricing,
    CASE
        WHEN (c.price-c.competitor_pricing) BETWEEN d.min_avg_price_difference AND d.q1_avg_price_difference THEN 'Below competitor'
        WHEN (c.price-c.competitor_pricing) BETWEEN d.q1_avg_price_difference AND d.median_avg_price_difference THEN 'Slightly below competitor'
        WHEN (c.price-c.competitor_pricing) BETWEEN d.median_avg_price_difference AND d.q3_avg_price_difference THEN 'Slightly above competitor'
        WHEN (c.price-c.competitor_pricing) BETWEEN d.q3_avg_price_difference AND d.max_avg_price_difference THEN 'Above competitor'
    END AS price_difference_status
FROM cleaned_retail_inventory c
CROSS JOIN price_difference_distribution_cte d
ORDER BY c.product_id, c.category, c.sales_date;

-- Discount applied revenue impact due to competitor pricing --
WITH discounted_price_difference_cte AS(
    SELECT 
        TO_CHAR(DATE_TRUNC('month', sales_date), 'YYYY-MM') AS sales_month,
        product_id, 
        category, 
        ROUND(AVG((price * (1 - discount/100)) - competitor_pricing), 2) AS avg_discounted_price_difference
    FROM cleaned_retail_inventory
    WHERE discount > 0
    GROUP BY 1,2,3
),
discounted_price_difference_distribution_cte AS (
    SELECT
        MIN(avg_discounted_price_difference) AS min_avg_discounted_price_difference,
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY avg_discounted_price_difference) AS q1_avg_discounted_price_difference,
        PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY avg_discounted_price_difference) AS median_avg_discounted_price_difference,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY avg_discounted_price_difference) AS q3_avg_discounted_price_difference,
        MAX(avg_discounted_price_difference) AS max_avg_discounted_price_difference
    FROM discounted_price_difference_cte
)
SELECT
    c.sales_date, c.product_id, c.category, c.price, c.discount, c.competitor_pricing,
    CASE
        WHEN ((c.price * (1 - c.discount/100)) - c.competitor_pricing) BETWEEN d.min_avg_discounted_price_difference AND d.q1_avg_discounted_price_difference THEN 'Below competitor'
        WHEN ((c.price * (1 - c.discount/100)) - c.competitor_pricing) BETWEEN d.q1_avg_discounted_price_difference AND d.median_avg_discounted_price_difference THEN 'Slightly below competitor'
        WHEN ((c.price * (1 - c.discount/100)) - c.competitor_pricing) BETWEEN d.median_avg_discounted_price_difference AND d.q3_avg_discounted_price_difference THEN 'Slightly above competitor'
        WHEN ((c.price * (1 - c.discount/100)) - c.competitor_pricing) BETWEEN d.q3_avg_discounted_price_difference AND d.max_avg_discounted_price_difference THEN 'Above competitor'
    END AS price_difference_status
FROM cleaned_retail_inventory c
CROSS JOIN discounted_price_difference_distribution_cte d
ORDER BY c.product_id, c.category, c.sales_date;