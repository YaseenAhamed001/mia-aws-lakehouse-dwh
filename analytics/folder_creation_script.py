import os

# Dimensions and Facts definitions
dimensions = [
    "001_dim_date",
    "002_dim_customer",
    "003_dim_account",
    "004_dim_product",
    "005_dim_customer_segment",
    "006_dim_baseline_period"
]

facts = [
    "001_fact_account_daily_balance",
    "002_fact_customer_baseline",
    "003_fact_account_transaction"
]

# Function to create folders and files
def create_structure(items, type_):
    type_dir = type_
    os.makedirs(type_dir, exist_ok=True)
    
    for item in items:
        item_dir = os.path.join(type_dir, item)
        os.makedirs(item_dir, exist_ok=True)
        
        # Create ddl and dml SQL files
        ddl_file = os.path.join(item_dir, f"ddl_{item}.sql")
        dml_file = os.path.join(item_dir, f"dml_{item}.sql")
        
        open(ddl_file, 'w').close()
        open(dml_file, 'w').close()

# Create dimensions and facts in the current directory
create_structure(dimensions, "dimensions")
create_structure(facts, "facts")

print("Folder structure for dimensions and facts created successfully in the current directory.")

# This script is used to create the dim and facts formated directory