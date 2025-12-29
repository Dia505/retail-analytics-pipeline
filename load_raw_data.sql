-- CREATE TABLE raw_retail_inventory (
--     sales_date DATE,
--     store_id TEXT,
--     product_id TEXT,
--     category TEXT,
--     region TEXT,
--     inventory INTEGER,
--     units_sold INTEGER,
--     units_ordered INTEGER,
--     demand_forecast NUMERIC(10,2),
--     price NUMERIC(10,2),
--     discount INTEGER,
--     weather_condition TEXT,
--     holiday_promotion INTEGER,
--     competitor_pricing NUMERIC(10,2),
--     seasonality TEXT
-- );

SELECT * FROM raw_retail_inventory;

-- To check the columns and their data type --
SELECT column_name, data_type, is_nullable FROM information_schema.columns WHERE table_name = 'raw_retail_inventory';

-- To check number of null values in each column --
-- There are no null values -- 
SELECT 
    COUNT(*) FILTER (WHERE sales_date IS NULL) as null_sales_date,
    COUNT(*) FILTER (WHERE units_ordered IS NULL) as null_units_ordered,
    COUNT(*) FILTER (WHERE demand_forecast IS NULL)  as null_demand_forecast,
    COUNT(*) FILTER (WHERE price IS NULL) as null_price,
    COUNT(*) FILTER (WHERE discount IS NULL) as null_discount,
    COUNT(*) FILTER (WHERE holiday_promotion IS NULL) as null_holiday_promotion,
    COUNT(*) FILTER (WHERE competitor_pricing IS NULL) as null_competitor_pricing,
    COUNT(*) FILTER (WHERE inventory IS NULL) as null_inventory,
    COUNT(*) FILTER (WHERE units_sold IS NULL) as null_units_sold,
    COUNT(*) FILTER (WHERE store_id IS NULL) as null_store_id,
    COUNT(*) FILTER (WHERE product_id IS NULL) as null_product_id,
    COUNT(*) FILTER (WHERE region IS NULL) as null_region,
    COUNT(*) FILTER (WHERE category IS NULL) as null_category,
    COUNT(*) FILTER (WHERE weather_condition IS NULL) as null_weather_condition,
    COUNT(*) FILTER (WHERE seasonality IS NULL) as null_seasonality
    FROM raw_retail_inventory;

-- TO check for duplicate rows --
-- No duplicate rows --
SELECT COUNT(*) - COUNT(*) FROM (
    SELECT DISTINCT sales_date, units_ordered, demand_forecast, price, discount, holiday_promotion, competitor_pricing, inventory, units_sold, store_id, product_id, region, category, weather_condition, seasonality FROM raw_retail_inventory
) t;

SELECT * FROM (
    SELECT *, COUNT(*) OVER(
        PARTITION BY sales_date, units_ordered, demand_forecast, price, discount, holiday_promotion, competitor_pricing, inventory, units_sold, store_id, product_id, region, category, weather_condition, seasonality
    ) AS dup_count
    FROM raw_retail_inventory
) t
WHERE dup_count > 1;

-- Check for invalid values --
-- Negative prices --
SELECT COUNT(*) FROM raw_retail_inventory WHERE price <= 0 OR competitor_pricing <= 0;
-- Negative inventory --
SELECT COUNT(*) FROM raw_retail_inventory WHERE inventory < 0;
-- Negative amounts of units sold or ordered -- 
SELECT COUNT(*) FROM raw_retail_inventory WHERE units_sold < 0 or units_ordered < 0
-- Negative discounts or discounts above 100% --
SELECT COUNT(*) FROM raw_retail_inventory WHERE discount > 100 OR discount < 0

-- There seem to be products with negative demands --
SELECT * FROM raw_retail_inventory WHERE demand_forecast < 0

CREATE OR REPLACE VIEW cleaned_retail_inventory AS 
SELECT *, CASE
    WHEN demand_forecast < 0 THEN 1 ELSE 0
    END AS is_negative_forecast
FROM raw_retail_inventory
WHERE
    price > 0 AND
    competitor_pricing > 0 AND
    inventory > 0 AND 
    units_ordered > 0 AND
    units_sold > 0 AND
    discount BETWEEN 0 AND 100;

SELECT * FROM cleaned_retail_inventory;
