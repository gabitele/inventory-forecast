# inventory-forecast

**Inventory Forecast Project - UNDER CONSTRUCTION**

**Tools: Python, BigQuery, Data Studio**

## Problem
**Inventory.** Every company that produces products and sells them to the public directly or indirectly has. However, it came to my attention that even the most well-known companies do not have a way to track it and, based on facts, predict what items will and will not last. 

What happens if you order too many items? What happens if you have an unbelievable amount of items that will expire tomorrow? I guess impossible to know if you do not keep track of these things.

## Structure
To generate this inventory forecast, I generated the data (i.e., 3 tables) needed using Python notebook. The data was then uploaded to BigQuery, where the actual forecast and calculations were made. The newly generated variables include weighted daily sales average, estimated number of days until stockout, estimated stockout date, and estimated loss. The relevant columns were then exported as a table and used by Data Studio (previously known as Looker Studio), where the dashboard and data visualizations took place.

## Data

| Table  | Description |
| ------------- | ------------- |
| `products`  | 150 unique SKUs across 8 brands, including 46 products and 4 categories (nailcare, bodycare, skincare, haircare) |
| `orders`  | 10k orders ranging between 2025-06-01 and 2026-06-01. |
| `inventory`  | A static snapshot (as of 2026-06-01) of the current stock for each sku and their expiration date.  |

## Assumptions
- Inventory, including current stock and expiration dates, are static and do not change. In real world, this data would need to be updated frequently.
- The number of SKUs, products, orders, etc. and their weights/importance are predefined and do not change.
- Order IDs are unique and contain a single SKU (i.e., one row per order).
- SKUs are unique but they can share the same product names and categories.
- The prices for the products remain the same, excluding the fact that companies might have bundles or other deals/discounts.

## Methodology

### 1. Data Generation (Python)
Instead of finding a generic data set, I wanted to brush off my Python skills and generate the exact columns that I needed. Each table was built around 150 unique SKUs, including other information that might be important or interesting to see in a report. I introduced randomness and weights to skew some distributions to add some complexity, just like real world scenarios would. For instance, some products were labeled as popular (i.e., high demand), whilst others not so much, thus higher demand products are ordered more often. The cost of producing a product is always lower than what the customer is charged. Also, customers are more likely to order smaller quantities. As for the dates, certain date ranges were weighted to appear more frequently, to simulate realistic seasonal or demand patterns.
### 2. Inventory Forecast and Calculations (BigQuery)
- **Weighted Daily Demand Rate**: Instead of taking a weekly, monthly or quarterly daily average of sales, we want some variety. What if there was a huge sale for a certain product last week (not in our case, we do not do discounts)? Or what if there was a blizzard in the middle of the summer, where people actually did not need or use sunscreen (not recommended)? To avoid these edge cases, we want to, again, assign weights to different periods. In our case, we put the emphasis on items sold the past week (i.e., 2026-05-25 - 2026-06-01), then some emphasis on the past 14 days, and least but still some emphasis on the past 30 days, meaning: `0.5 * 7 days + 0.3 * 14 days + 0.2 * 30 days`.
- **Days Until Stockout and Estimated Stockout Date**: To estimate how many days it will take for a product to run out, we take the current stock for that product and divide it by the calculated daily demand rate. To get the exact date that the product may run out on, we add that estimated number of days to our current static date (i.e., 2026-06-01).
- **Estimated Loss**: Sometimes a company might overestimate the popularity of a certain product, which could depend on a season, current trends, and other factors. In such cases, there might be some products that are sitting in the warehouse but have reached their expiration date. To calculate the loss of such products, we calculate the number of items that are estimated to still remain after the expiration and multiply by the cost.

### 3. Dashboard (Data Studio)
- 

## Key Findings


## Dashboard
The dashboard as a PDF file can be found in the `Dashboard` folder. Alternatively, here is a link to the actual interactive dashboard: https://datastudio.google.com/s/i1eJ1g0pgRk

## How to Run
To recreate the project \*:
1. Run the `Python/generate_data.ipynb` file to generate the three CSV files.
2. Upload the files (or the ones from `Data/Tables (Python Output)`) to BigQuery and run `SQL/forecast_query.sql` query.
3. Connect the output to Data Studio to create a report.

\* *The output will differ during every run, as the generated information for each CSV file will not be the same.*