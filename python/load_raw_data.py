import logging
import os

import pandas as pd
from dotenv import load_dotenv
from sqlalchemy import MetaData, Table, create_engine, text
from sqlalchemy.dialects.postgresql import insert

load_dotenv()

logging.basicConfig(
    filename="../logs/pipeline.log",
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s"
)

db_name = os.getenv('DB_NAME')
db_user = os.getenv('DB_USERNAME')
db_password = os.getenv('DB_PASSWORD')
db_host = os.getenv('DB_HOST')
db_port = os.getenv('DB_PORT')

engine = create_engine(f"postgresql+psycopg2://{db_user}:{db_password}@{db_host}:{db_port}/{db_name}")
logging.info("Database connection established")

df = pd.read_csv("../data/retail_store_inventory_data.csv")

df["Date"] = pd.to_datetime(df["Date"], dayfirst=True)
df["Holiday/Promotion"] = df["Holiday/Promotion"].astype(bool)

df = df.dropna(subset=["Date", "Product ID", "Category", "Store ID"])

low_threshold = 0.25
high_threshold = 0.75

null_check_list = ["Units Ordered", "Units Sold", "Demand Forecast", "Price", "Discount", "Holiday/Promotion", "Competitor Pricing", "Inventory Level", "Region", "Weather Condition", "Seasonality"]
for col in null_check_list:
    null_percent = df[col].isnull().mean()
    
    if null_percent > low_threshold and null_percent < high_threshold:
        if df[col].dtype in ['float64', 'int64'] and col not in ["Discount", "Holiday/Promotion"]:
            df[col] = df[col].fillna(df[col].median())
        else:
            mode_val = df[col].mode()
            if not mode_val.empty:
                df[col] = df[col].fillna(mode_val[0])
            else:
                df[col] = df[col].fillna("Unknown")
    
    elif null_percent <= low_threshold:
        df = df.dropna(subset=[col])
        
    elif null_percent >= high_threshold:
        df = df.drop(columns=[col])
        
df = df[(df["Price"] > 0) & 
        (df["Competitor Pricing"] > 0) &
        (df["Inventory Level"] >= 0) &
        (df["Units Sold"] >= 0) &
        (df["Units Ordered"] >= 0) &
        (df["Discount"] < 100) &
        (df["Discount"] >= 0)
    ]

df["Is Negative Forecast"] = (df["Demand Forecast"] < 0)

df["Loaded At"] = pd.Timestamp.now()

metadata = MetaData()
table = Table('raw_retail_inventory_automation', metadata, autoload_with=engine)

chunk_size = 1000  # adjust as needed
for i in range(0, len(df), chunk_size):
    chunk = df.iloc[i:i+chunk_size]
    records = chunk.to_dict(orient='records')
    stmt = insert(table).values(records)
    stmt = stmt.on_conflict_do_update(
        index_elements=["Date", "Store ID", "Product ID"],
        set_={c.name: stmt.excluded[c.name] for c in table.c if c.name not in ["Date", "Store ID", "Product ID"]}
    )
    with engine.begin() as conn:
        conn.execute(stmt)

logging.info("CSV loaded to database successfully")

quality_checks = {
    "null_checks": """ 
        SELECT 
        COUNT(*) FILTER (WHERE "Date" IS NULL) as null_sales_date,
        COUNT(*) FILTER (WHERE "Units Ordered" IS NULL) as null_units_ordered,
        COUNT(*) FILTER (WHERE "Demand Forecast" IS NULL)  as null_demand_forecast,
        COUNT(*) FILTER (WHERE "Price" IS NULL) as null_price,
        COUNT(*) FILTER (WHERE "Discount" IS NULL) as null_discount,
        COUNT(*) FILTER (WHERE "Holiday/Promotion" IS NULL) as null_holiday_promotion,
        COUNT(*) FILTER (WHERE "Competitor Pricing" IS NULL) as null_competitor_pricing,
        COUNT(*) FILTER (WHERE "Inventory Level" IS NULL) as null_inventory,
        COUNT(*) FILTER (WHERE "Units Sold" IS NULL) as null_units_sold,
        COUNT(*) FILTER (WHERE "Store ID" IS NULL) as null_store_id,
        COUNT(*) FILTER (WHERE "Product ID" IS NULL) as null_product_id,
        COUNT(*) FILTER (WHERE "Region" IS NULL) as null_region,
        COUNT(*) FILTER (WHERE "Category" IS NULL) as null_category,
        COUNT(*) FILTER (WHERE "Weather Condition" IS NULL) as null_weather_condition,
        COUNT(*) FILTER (WHERE "Seasonality" IS NULL) as null_seasonality
        FROM raw_retail_inventory_automation;
    """,
    
    "negative_price_check": """
        SELECT COUNT(*) FROM raw_retail_inventory_automation WHERE "Price" <= 0 OR "Competitor Pricing" <= 0;
    """,
    
    "negative_inventory_check": """
        SELECT COUNT(*) FROM raw_retail_inventory_automation WHERE "Inventory Level" < 0;
    """,
    
    "negative_units_check": """
        SELECT COUNT(*) FROM raw_retail_inventory_automation WHERE "Units Sold" < 0 or "Units Ordered" < 0;
    """,
    
    "negative_discount_check": """
        SELECT COUNT(*) FROM raw_retail_inventory_automation WHERE "Discount" > 100 OR "Discount" < 0;
    """
}
with engine.connect() as conn:
    print("\n--- DATA QUALITY CHECKS ---")
    
    for check_name, query in quality_checks.items():
        result = conn.execute(text(query)).fetchall()
        
        print(f"\n{check_name.upper()}")
        for row in result:
            print(row)

duplicate_check = """
    SELECT * FROM (
        SELECT *, COUNT(*) OVER(
            PARTITION BY "Date", "Units Ordered", "Demand Forecast", "Price", "Discount", "Holiday/Promotion", "Competitor Pricing", "Inventory Level", "Units Sold", "Store ID", "Product ID", "Region", "Category", "Weather Condition", "Seasonality"
        ) AS dup_count
        FROM raw_retail_inventory_automation
    ) t
    WHERE dup_count > 1;
"""
with engine.connect() as conn:
    print("\n--- DUPLICATE CHECKS ---")
    
    result = conn.execute(text(duplicate_check)).fetchall()
        
    if len(result) == 0:
        print("No duplicate rows found")
    else:
        print(f"{len(result)} duplicate rows found")


create_view_query = """
    CREATE OR REPLACE VIEW cleaned_retail_inventory_automation AS 
    SELECT *
    FROM raw_retail_inventory_automation
    WHERE
        "Price" > 0 AND
        "Competitor Pricing" > 0 AND
        "Inventory Level" >= 0 AND 
        "Units Ordered" >= 0 AND
        "Units Sold" >= 0 AND
        "Discount" BETWEEN 0 AND 100;
"""

with engine.begin() as conn:
    conn.execute(text(create_view_query))
    logging.info("View created")