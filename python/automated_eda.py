import logging
import os
import pandas as pd
from dotenv import load_dotenv
from sqlalchemy import create_engine

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

queries = {
    "monthly_sales_trend": """
        SELECT 
            TO_CHAR(DATE_TRUNC('month', "Date"), 'YYYY-MM') AS sales_month,
            SUM("Units Sold") AS total_monthly_sale
        FROM cleaned_retail_inventory_automation
        GROUP BY 1
        ORDER BY 1;
    """
}

# SQL-driven automated EDA
with pd.ExcelWriter("../retail-analytics-csv-files/retail_eda.xlsx") as writer:
    for name, query in queries.items():
        df = pd.read_sql(query, engine)
        df.to_excel(writer, sheet_name=name, index=False)

    logging.info("Query converted to excel sheet")