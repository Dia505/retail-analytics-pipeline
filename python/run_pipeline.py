import subprocess
import logging
import os

BASE_DIR = os.path.dirname(os.path.dirname(__file__))

log_path = os.path.join(BASE_DIR, "logs", "pipeline.log")

os.makedirs(os.path.dirname(log_path), exist_ok=True)

logging.basicConfig(
    filename=log_path,
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s"
)

try:
    logging.info("Starting data load pipeline......")
    
    subprocess.run(
        ["python", "load_raw_data.py"],
        check=True
    )
    
    logging.info("Data loading complete")
    
    logging.info("Starting automated eda pipeline......")
    
    subprocess.run(
        ["python", "automated_eda.py"],
        check=True
    )
    
    logging.info("Automated EDA complete")
    
except subprocess.CalledProcessError as e:
        logging.error("Pipeline failed")
        print(e)