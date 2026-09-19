"""
NorthPeak Retail — Synthetic Data Generation
==============================================
Generates a 3-year synthetic retail transaction dataset with THREE deliberately
engineered profitability problems, matching the BRD's core scenario:
overall margin declines from ~18% to ~11% over the most recent 6 quarters,
while total sales grow ~22% over the full 3-year window.

Engineered scenarios (documented in docs/ground_truth.md — NOT shared publicly):
  1. Discount creep — Nairobi region, Furniture category: average discount
     rises steadily over the last 6 quarters while cost stays flat.
  2. Structurally unprofitable sub-category — "Tables" (under Furniture) is
     generated with cost close to price, making it margin-thin/negative
     even at modest discounts, for the entire 3-year period.
  3. Segment margin dilution — Corporate segment's share of volume grows
     fastest, but Corporate orders carry a systematically higher average
     discount (simulating negotiated bulk deals), diluting overall margin
     as its share increases.

Run:  python generate_data.py
Reads DB credentials from a .env file (see .env.example).
"""

import os
import random
from datetime import date, timedelta

import numpy as np
import pandas as pd
from dotenv import load_dotenv
from sqlalchemy import create_engine, text, Table, MetaData
from sqlalchemy.engine import URL

# ============================================================================
# 0. CONFIG & REPRODUCIBILITY
# ============================================================================

SEED = 42
random.seed(SEED)
np.random.seed(SEED)

load_dotenv()  # reads .env file in the same directory

DB_CONFIG = {
    "host": os.getenv("DB_HOST", "localhost"),
    "port": os.getenv("DB_PORT", "5432"),
    "dbname": os.getenv("DB_NAME", "northpeak_retail"),
    "user": os.getenv("DB_USER", "northpeak_analyst"),
    "password": os.getenv("DB_PASSWORD"),
}

START_DATE = date(2023, 1, 1)
END_DATE = date(2025, 12, 31)
DATE_DIM_END = END_DATE + timedelta(days=10)  # buffer so ship_date always has a match
DECLINE_START = date(2024, 7, 1)  # start of the "last 6 quarters" window

TARGET_ORDERS = 37000          # ~1.9 line items/order -> ~70,000 fact rows
LOAD_TO_DB = True               # set False to only generate + preview, no DB write

# ============================================================================
# 1. DIM_DATE
# ============================================================================

def generate_dim_date(start: date, end: date) -> pd.DataFrame:
    dates = pd.date_range(start, end, freq="D")
    df = pd.DataFrame({"full_date": dates})
    df["date_key"] = df["full_date"].dt.strftime("%Y%m%d").astype(int)
    df["day"] = df["full_date"].dt.day
    df["month"] = df["full_date"].dt.month
    df["month_name"] = df["full_date"].dt.strftime("%B")
    df["quarter"] = df["full_date"].dt.quarter
    df["year"] = df["full_date"].dt.year
    df["day_of_week"] = df["full_date"].dt.strftime("%A")
    df["is_weekend"] = df["full_date"].dt.dayofweek >= 5
    df["fiscal_quarter"] = "FY" + (df["year"] % 100).astype(str).str.zfill(2) + "-Q" + df["quarter"].astype(str)
    return df[["date_key", "full_date", "day", "month", "month_name",
               "quarter", "year", "day_of_week", "is_weekend", "fiscal_quarter"]]


# ============================================================================
# 2. DIM_REGION — Kenya geography (former 8 provinces as 'region')
# ============================================================================

def generate_dim_region() -> pd.DataFrame:
    # (region, county, city, relative_weight) — weight drives order volume share
    rows = [
        ("Nairobi", "Nairobi", "Nairobi CBD", 18),
        ("Nairobi", "Nairobi", "Westlands", 10),
        ("Nairobi", "Nairobi", "Kilimani", 8),
        ("Nairobi", "Nairobi", "Eastleigh", 6),
        ("Central", "Kiambu", "Thika", 5),
        ("Central", "Kiambu", "Kiambu Town", 4),
        ("Central", "Nyeri", "Nyeri Town", 3),
        ("Central", "Murang'a", "Murang'a Town", 2),
        ("Coast", "Mombasa", "Mombasa", 9),
        ("Coast", "Kilifi", "Malindi", 3),
        ("Coast", "Kwale", "Ukunda", 2),
        ("Eastern", "Machakos", "Machakos Town", 4),
        ("Eastern", "Kitui", "Kitui Town", 2),
        ("Eastern", "Embu", "Embu Town", 2),
        ("North Eastern", "Garissa", "Garissa Town", 2),
        ("North Eastern", "Wajir", "Wajir Town", 1),
        ("Nyanza", "Kisumu", "Kisumu", 6),
        ("Nyanza", "Homa Bay", "Homa Bay Town", 2),
        ("Nyanza", "Kisii", "Kisii Town", 3),
        ("Rift Valley", "Uasin Gishu", "Eldoret", 5),
        ("Rift Valley", "Nakuru", "Nakuru", 5),
        ("Rift Valley", "Kajiado", "Kajiado Town", 2),
        ("Western", "Kakamega", "Kakamega Town", 3),
        ("Western", "Bungoma", "Bungoma Town", 2),
    ]
    df = pd.DataFrame(rows, columns=["region", "county", "city", "weight"])
    df["region_key"] = range(1, len(df) + 1)
    df["country"] = "Kenya"
    return df[["region_key", "region", "county", "city", "country", "weight"]]


# ============================================================================
# 3. DIM_PRODUCT
#    "Tables" sub-category deliberately thin-margin (Engineered Scenario 2)
# ============================================================================

def generate_dim_product() -> pd.DataFrame:
    # (product_name, category, sub_category, base_unit_cost, base_unit_price)
    # Healthy categories priced at ~75% cost-to-price ratio (25% gross margin
    # before discount) so that, combined with baseline ~8-9% discount, the
    # BASELINE net margin lands close to the BRD's 18% historical figure.
    # "Tables" sub-category priced at ~93-96% cost-to-price ratio so it is
    # structurally thin/negative margin even before any discount is applied.
    rows = [
        # Technology
        ("Smartphone X12", "Technology", "Phones", 29400, 42000),
        ("Smartphone Lite S2", "Technology", "Phones", 15050, 21500),
        ("Laptop Pro 15", "Technology", "Computers", 64400, 92000),
        ("Laptop Air 13", "Technology", "Computers", 49700, 71000),
        ("Wireless Mouse", "Technology", "Accessories", 980, 1400),
        ("Bluetooth Speaker", "Technology", "Accessories", 2520, 3600),
        ("Tablet Air 10", "Technology", "Computers", 22400, 32000),
        ("USB-C Hub", "Technology", "Accessories", 1680, 2400),

        # Furniture — Chairs/Desks/Bookcases: healthy; Tables: thin/negative margin
        ("Executive Office Chair", "Furniture", "Chairs", 10850, 15500),
        ("Ergonomic Task Chair", "Furniture", "Chairs", 7140, 10200),
        ("Standing Desk", "Furniture", "Desks", 16450, 23500),
        ("Compact Office Desk", "Furniture", "Desks", 9660, 13800),
        ("Bookcase Classic", "Furniture", "Bookcases", 8050, 11500),
        ("Conference Table", "Furniture", "Tables", 22800, 24500),    # thin margin
        ("Study Table", "Furniture", "Tables", 10450, 11200),         # thin margin
        ("Office Pantry Table", "Furniture", "Tables", 13100, 13800), # thin margin

        # Office Supplies
        ("A4 Paper Ream (Box of 10)", "Office Supplies", "Paper", 1120, 1600),
        ("Binder Clips Box", "Office Supplies", "Binders", 245, 350),
        ("Storage Box (Set of 3)", "Office Supplies", "Storage", 1050, 1500),
        ("Ball Pens Pack (12pcs)", "Office Supplies", "Writing", 336, 480),
        ("Sticky Notes Pack", "Office Supplies", "Writing", 210, 300),
    ]
    df = pd.DataFrame(rows, columns=["product_name", "category", "sub_category",
                                      "base_unit_cost", "base_unit_price"])
    df["product_key"] = range(1, len(df) + 1)
    df["product_id"] = "PRD-" + df["product_key"].astype(str).str.zfill(4)
    return df[["product_key", "product_id", "product_name", "category",
               "sub_category", "base_unit_cost", "base_unit_price"]]


# ============================================================================
# 4. DIM_CUSTOMER
# ============================================================================

FIRST_NAMES = ["Wanjiru", "Otieno", "Achieng", "Kamau", "Njoroge", "Wafula",
               "Cherono", "Mutua", "Njeri", "Odhiambo", "Kiptoo", "Wambui",
               "Mwangi", "Adhiambo", "Kilonzo", "Nyambura", "Barasa", "Chebet",
               "Omondi", "Muthoni", "Kiprotich", "Akinyi", "Gitau", "Wekesa"]
LAST_NAMES = ["Kariuki", "Ochieng", "Mwendwa", "Njuguna", "Cheruiyot", "Wanyama",
              "Kimani", "Auma", "Maina", "Rotich", "Wachira", "Nekesa",
              "Kibet", "Atieno", "Mburu", "Chepkoech", "Onyango", "Wairimu"]
COMPANY_SUFFIXES = ["Enterprises", "Holdings", "Group", "Traders", "Solutions",
                     "& Sons", "Logistics", "Ventures"]

def generate_dim_customer(n: int) -> pd.DataFrame:
    segments = np.random.choice(
        ["Consumer", "Corporate", "Home Office"],
        size=n, p=[0.55, 0.30, 0.15]
    )
    names = []
    for seg in segments:
        first = random.choice(FIRST_NAMES)
        last = random.choice(LAST_NAMES)
        if seg == "Corporate":
            names.append(f"{last} {random.choice(COMPANY_SUFFIXES)}")
        else:
            names.append(f"{first} {last}")

    join_dates = [
        START_DATE - timedelta(days=random.randint(0, 900))
        for _ in range(n)
    ]

    df = pd.DataFrame({
        "customer_key": range(1, n + 1),
        "customer_name": names,
        "segment": segments,
        "join_date": join_dates,
    })
    df["customer_id"] = "CUST-" + df["customer_key"].astype(str).str.zfill(5)
    return df[["customer_key", "customer_id", "customer_name", "segment", "join_date"]]


# ============================================================================
# 5. FACT_SALES — the engineered core of the project
# ============================================================================

SHIP_MODES = {
    "Standard Class": (4, 7),
    "Second Class": (2, 4),
    "First Class": (1, 2),
    "Same Day": (0, 0),
}
SHIP_MODE_WEIGHTS = [0.55, 0.25, 0.15, 0.05]


def months_into_decline(order_date: date) -> float:
    """Returns 0.0 before decline window; 0.0 -> 1.0 progress through the
    18-month decline window (2024-07-01 to 2025-12-31)."""
    if order_date < DECLINE_START:
        return 0.0
    total_days = (END_DATE - DECLINE_START).days
    elapsed_days = (order_date - DECLINE_START).days
    return min(max(elapsed_days / total_days, 0.0), 1.0)


def sample_discount(category, sub_category, region, segment, order_date) -> float:
    """
    Baseline discount ~8-12%, with three engineered upward pressures:
      - Scenario 1: Nairobi + Furniture -> discount creeps from ~8% to ~28%
        across the decline window.
      - Scenario 3: Corporate segment carries a higher baseline discount,
        which itself widens further during the decline window.
    """
    progress = months_into_decline(order_date)

    base = np.random.beta(3, 22) * 0.55  # baseline distribution, mean ~9%

    # Mild company-wide secular drift (broader competitive/market pressure) —
    # small on its own, but shows up in the discount-band analysis as a
    # general upward shift, not just isolated to one region/segment.
    base += 0.015 * progress

    # Scenario 1: Nairobi + Furniture discount creep
    if region == "Nairobi" and category == "Furniture":
        creep_bonus = 0.16 * progress  # rises up to +16pp by end of window
        base += creep_bonus

    # Scenario 3: Corporate segment negotiated-discount dilution
    if segment == "Corporate":
        corporate_bonus = 0.10 + (0.07 * progress)  # 10pp baseline, +7pp more by end
        base += corporate_bonus

    return float(np.clip(base, 0.0, 0.80))


def sample_order_volume_curve(n_days: int) -> np.ndarray:
    """Monotonic growth trend (with seasonal + weekday noise) used to weight
    which day an order falls on, producing ~22% overall sales growth across
    the 3-year window."""
    t = np.linspace(0, 1, n_days)
    growth_trend = 0.81 + 0.40 * t  # relative order-count growth end vs start
    all_days = pd.date_range(START_DATE, END_DATE, freq="D")
    month_of_year = all_days.month.to_numpy()
    seasonal = 1.0 + 0.15 * np.sin((month_of_year - 3) / 12 * 2 * np.pi)  # mild seasonality
    weekday = all_days.dayofweek.to_numpy()
    weekday_factor = np.where(weekday >= 5, 0.65, 1.05)  # fewer B2B orders on weekends
    curve = growth_trend * seasonal * weekday_factor
    return curve / curve.sum()


def generate_fact_sales(dim_date, dim_region, dim_product, dim_customer, n_orders) -> pd.DataFrame:
    # Orders may only be PLACED within the original START_DATE..END_DATE window.
    # dim_date itself extends a few days past END_DATE purely so that a
    # ship_date computed from a late order still has a valid FK target.
    orderable_dates = dim_date[dim_date["full_date"] <= pd.Timestamp(END_DATE)]
    n_days = len(orderable_dates)
    day_probs = sample_order_volume_curve(n_days)
    order_days = np.random.choice(orderable_dates["full_date"].values, size=n_orders, p=day_probs)

    region_probs = dim_region["weight"] / dim_region["weight"].sum()

    # Corporate segment's SHARE of orders grows over the decline window
    # (Engineered Scenario 3 — volume growth concentrated in the diluting segment)
    customer_lookup = dim_customer.set_index("customer_key")
    consumer_ids = dim_customer.loc[dim_customer.segment == "Consumer", "customer_key"].values
    corporate_ids = dim_customer.loc[dim_customer.segment == "Corporate", "customer_key"].values
    homeoffice_ids = dim_customer.loc[dim_customer.segment == "Home Office", "customer_key"].values

    rows = []
    sales_key = 1

    for i in range(n_orders):
        order_date = pd.Timestamp(order_days[i]).date()
        order_id = f"ORD-{order_date.strftime('%Y%m%d')}-{i+1:06d}"

        progress = months_into_decline(order_date)
        # Corporate share rises from 30% baseline to ~41% by end of decline window
        corporate_share = 0.30 + 0.11 * progress
        remaining = 1 - corporate_share
        seg_choice = np.random.choice(
            ["Corporate", "Consumer", "Home Office"],
            p=[corporate_share, remaining * (0.55/0.70), remaining * (0.15/0.70)]
        )
        if seg_choice == "Corporate":
            customer_key = np.random.choice(corporate_ids)
        elif seg_choice == "Consumer":
            customer_key = np.random.choice(consumer_ids)
        else:
            customer_key = np.random.choice(homeoffice_ids)
        segment = seg_choice

        region_row = dim_region.sample(1, weights=region_probs).iloc[0]
        region_name = region_row["region"]
        region_key = region_row["region_key"]

        ship_mode = np.random.choice(list(SHIP_MODES.keys()), p=SHIP_MODE_WEIGHTS)
        delay_min, delay_max = SHIP_MODES[ship_mode]
        ship_date = order_date + timedelta(days=random.randint(delay_min, delay_max))

        n_line_items = np.random.choice([1, 2, 3, 4], p=[0.45, 0.30, 0.16, 0.09])
        products = dim_product.sample(n_line_items, replace=False)

        for _, prod in products.iterrows():
            quantity = np.random.choice([1, 2, 3, 4, 5], p=[0.45, 0.25, 0.15, 0.10, 0.05])

            price_noise = np.random.uniform(0.97, 1.03)
            cost_noise = np.random.uniform(0.98, 1.02)
            unit_price = round(prod["base_unit_price"] * price_noise, 2)
            unit_cost = round(prod["base_unit_cost"] * cost_noise, 2)

            discount_pct = round(sample_discount(
                prod["category"], prod["sub_category"], region_name, segment, order_date
            ), 4)

            sales_amount = round(quantity * unit_price * (1 - discount_pct), 2)
            cost_amount = round(quantity * unit_cost, 2)
            profit_amount = round(sales_amount - cost_amount, 2)

            rows.append({
                "sales_key": sales_key,
                "order_id": order_id,
                "order_date_key": int(order_date.strftime("%Y%m%d")),
                "ship_date_key": int(ship_date.strftime("%Y%m%d")),
                "customer_key": int(customer_key),
                "product_key": int(prod["product_key"]),
                "region_key": int(region_key),
                "ship_mode": ship_mode,
                "quantity": int(quantity),
                "unit_price": unit_price,
                "unit_cost": unit_cost,
                "discount_pct": discount_pct,
                "sales_amount": sales_amount,
                "cost_amount": cost_amount,
                "profit_amount": profit_amount,
            })
            sales_key += 1

    return pd.DataFrame(rows)


# ============================================================================
# 6. CALIBRATION SUMMARY — verify the engineered scenario before loading
# ============================================================================

def print_calibration_summary(fact_df: pd.DataFrame, dim_date: pd.DataFrame):
    merged = fact_df.merge(dim_date[["date_key", "year", "quarter"]],
                            left_on="order_date_key", right_on="date_key")

    print("\n" + "=" * 70)
    print("CALIBRATION SUMMARY")
    print("=" * 70)

    yearly = merged.groupby("year").agg(
        total_sales=("sales_amount", "sum"),
        total_profit=("profit_amount", "sum"),
    )
    yearly["margin_pct"] = (yearly["total_profit"] / yearly["total_sales"] * 100).round(2)
    print("\n-- Sales & Margin by Year --")
    print(yearly)

    sales_growth = (yearly.loc[2025, "total_sales"] / yearly.loc[2023, "total_sales"] - 1) * 100
    print(f"\nTotal Sales Growth (2023 -> 2025): {sales_growth:.1f}%  (target: ~22%)")

    quarterly = merged.groupby(["year", "quarter"]).agg(
        total_sales=("sales_amount", "sum"),
        total_profit=("profit_amount", "sum"),
    )
    quarterly["margin_pct"] = (quarterly["total_profit"] / quarterly["total_sales"] * 100).round(2)
    print("\n-- Margin % by Quarter (watch for 18% -> 11% decline in last 6 rows) --")
    print(quarterly[["margin_pct"]])

    print("\n-- Margin % by Product Sub-Category (Tables should be lowest) --")
    prod_margin = fact_df.merge(dim_product_global, on="product_key").groupby("sub_category").agg(
        total_sales=("sales_amount", "sum"), total_profit=("profit_amount", "sum")
    )
    prod_margin["margin_pct"] = (prod_margin["total_profit"] / prod_margin["total_sales"] * 100).round(2)
    print(prod_margin.sort_values("margin_pct"))

    print("=" * 70 + "\n")


# ============================================================================
# 7. LOAD TO POSTGRES
# ============================================================================

def load_to_postgres(dim_date, dim_region, dim_product, dim_customer, fact_sales):
    if not DB_CONFIG["password"]:
        raise ValueError(
            "DB_PASSWORD not found. Create a .env file (see .env.example) "
            "with your database credentials before running with LOAD_TO_DB=True."
        )

    conn_url = URL.create(
        "postgresql+psycopg2",
        username=DB_CONFIG["user"],
        password=DB_CONFIG["password"],
        host=DB_CONFIG["host"],
        port=int(DB_CONFIG["port"]),
        database=DB_CONFIG["dbname"],
    )
    engine = create_engine(conn_url)

    with engine.begin() as conn:
        print("Truncating existing data (idempotent re-run)...")
        conn.execute(text(
            "TRUNCATE TABLE northpeak.fact_sales, northpeak.dim_customer, "
            "northpeak.dim_product, northpeak.dim_region, northpeak.dim_date "
            "RESTART IDENTITY CASCADE;"
        ))

    print("Loading dim_date...")
    dim_date.to_sql("dim_date", engine, schema="northpeak", if_exists="append", index=False)

    print("Loading dim_region...")
    dim_region.drop(columns=["weight"]).to_sql(
        "dim_region", engine, schema="northpeak", if_exists="append", index=False
    )

    print("Loading dim_product...")
    dim_product.to_sql("dim_product", engine, schema="northpeak", if_exists="append", index=False)

    print("Loading dim_customer...")
    dim_customer.to_sql("dim_customer", engine, schema="northpeak", if_exists="append", index=False)

    print(f"Loading fact_sales ({len(fact_sales):,} rows)...")
    # Convert to a list of plain-Python-typed dicts before inserting.
    # pandas.to_sql silently re-boxes converted values back into numpy
    # scalars on column reassignment, so we bypass to_sql for this table
    # and use SQLAlchemy Core executemany with genuinely native types —
    # the only reliable way to guarantee psycopg2 never sees a numpy scalar.
    int_cols = ["sales_key", "order_date_key", "ship_date_key", "customer_key",
                "product_key", "region_key", "quantity"]
    float_cols = ["unit_price", "unit_cost", "discount_pct", "sales_amount",
                  "cost_amount", "profit_amount"]
    str_cols = ["order_id", "ship_mode"]

    records = fact_sales.to_dict("records")
    for r in records:
        for c in int_cols:
            r[c] = int(r[c])
        for c in float_cols:
            r[c] = float(r[c])
        for c in str_cols:
            r[c] = str(r[c])

    metadata = MetaData()
    fact_sales_table = Table("fact_sales", metadata, autoload_with=engine, schema="northpeak")

    try:
        with engine.begin() as conn:
            batch_size = 5000
            for i in range(0, len(records), batch_size):
                batch = records[i:i + batch_size]
                conn.execute(fact_sales_table.insert(), batch)
                print(f"  ...inserted {min(i + batch_size, len(records)):,} / {len(records):,} rows")
    except Exception as e:
        root_cause = getattr(e, "orig", e)
        print("\n" + "=" * 70)
        print("FACT_SALES LOAD FAILED — concise error below:")
        print(f"{type(root_cause).__name__}: {root_cause}")
        print("=" * 70 + "\n")
        raise SystemExit(1)

    with engine.begin() as conn:
        print("Resyncing sequences after explicit key inserts...")
        for tbl, key_col in [("dim_region", "region_key"), ("dim_product", "product_key"),
                              ("dim_customer", "customer_key"), ("fact_sales", "sales_key")]:
            conn.execute(text(
                f"SELECT setval(pg_get_serial_sequence('northpeak.{tbl}', '{key_col}'), "
                f"(SELECT MAX({key_col}) FROM northpeak.{tbl}));"
            ))

    print("Load complete.")


# ============================================================================
# 8. MAIN
# ============================================================================

if __name__ == "__main__":
    print("Generating dim_date...")
    dim_date = generate_dim_date(START_DATE, DATE_DIM_END)

    print("Generating dim_region...")
    dim_region = generate_dim_region()

    print("Generating dim_product...")
    dim_product_global = generate_dim_product()  # module-level for calibration summary
    dim_product = dim_product_global

    print("Generating dim_customer...")
    dim_customer = generate_dim_customer(n=1200)

    print(f"Generating fact_sales (~{TARGET_ORDERS:,} orders)...")
    fact_sales = generate_fact_sales(dim_date, dim_region, dim_product, dim_customer, TARGET_ORDERS)
    print(f"Generated {len(fact_sales):,} fact_sales rows.")

    print_calibration_summary(fact_sales, dim_date)

    if LOAD_TO_DB:
        load_to_postgres(dim_date, dim_region, dim_product, dim_customer, fact_sales)
    else:
        print("LOAD_TO_DB is False — skipping database load (preview only).")
