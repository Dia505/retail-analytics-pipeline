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

SELECT * FROM raw_retail_inventory

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
    FROM raw_retail_inventory

