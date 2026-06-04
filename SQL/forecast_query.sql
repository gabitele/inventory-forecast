WITH
  orders AS (
    SELECT
      pro.sku,
      pro.product_name,
      pro.category,
      pro.brand,
      pro.demand,
      pro.price,
      pro.cost,
      CAST(inv.expiration_date AS DATE) AS expiration_date,
      inv.current_stock,
      CAST(ord.order_date AS DATE) AS order_date,
      CAST(ord.quantity AS INT64) AS quantity,
    FROM `inventory-forecast-498014.inventory_forecast.products` pro
    LEFT JOIN `inventory-forecast-498014.inventory_forecast.orders` ord
      ON pro.sku = ord.sku
    LEFT JOIN `inventory-forecast-498014.inventory_forecast.inventory` inv
      ON pro.sku = inv.sku
  ),
  oneweek_daily_avg AS (
    SELECT DISTINCT
      sku,
      product_name,
      category,
      brand,
      demand,
      price,
      cost,
      expiration_date,
      current_stock,
      ROUND(SUM(quantity) / 7, 2) AS oneweek_daily_avg
    FROM orders
    WHERE
      order_date BETWEEN DATE_SUB('2026-06-01', INTERVAL 6 DAY) AND '2026-06-01'
    GROUP BY ALL
  ),
  twoweek_daily_avg AS (
    SELECT DISTINCT
      sku,
      product_name,
      category,
      brand,
      demand,
      price,
      cost,
      expiration_date,
      current_stock,
      ROUND(SUM(quantity) / 14, 2) AS twoweek_daily_avg
    FROM orders
    WHERE
      order_date
      BETWEEN DATE_SUB('2026-06-01', INTERVAL 13 DAY)
      AND '2026-06-01'
    GROUP BY ALL
  ),
  thirtyday_daily_avg AS (
    SELECT DISTINCT
      sku,
      product_name,
      category,
      brand,
      demand,
      price,
      cost,
      expiration_date,
      current_stock,
      ROUND(SUM(quantity) / 30, 2) AS thirtyday_daily_avg
    FROM orders
    WHERE
      order_date
      BETWEEN DATE_SUB('2026-06-01', INTERVAL 29 DAY)
      AND '2026-06-01'
    GROUP BY ALL
  ),
  joined_averages AS (
    SELECT DISTINCT
      ord.sku,
      ord.product_name,
      ord.category,
      ord.brand,
      ord.demand,
      ord.price,
      ord.cost,
      ord.expiration_date,
      ord.current_stock,
      COALESCE(one.oneweek_daily_avg, 0) AS oneweek_daily_avg,
      COALESCE(two.twoweek_daily_avg, 0) AS twoweek_daily_avg,
      COALESCE(three.thirtyday_daily_avg, 0) AS thirtyday_daily_avg
    FROM orders ord
    LEFT JOIN oneweek_daily_avg one
      ON one.sku = ord.sku
    LEFT JOIN twoweek_daily_avg two
      ON one.sku = two.sku
    LEFT JOIN thirtyday_daily_avg three
      ON one.sku = three.sku
  ),
  weighted_avg AS (
    SELECT
      sku,
      product_name,
      category,
      brand,
      demand,
      price,
      cost,
      expiration_date,
      CAST(current_stock AS FLOAT64) AS current_stock,
      ROUND(
        (
          0.5 * oneweek_daily_avg
          + 0.3 * twoweek_daily_avg
          + 0.2 * thirtyday_daily_avg),
        2) AS weighted_daily_avg
    FROM joined_averages
  ),
  stockout_days AS (
    SELECT
      *,
      ROUND(SAFE_DIVIDE(current_stock, weighted_daily_avg), 0)
        AS days_until_est_stockout,
    FROM weighted_avg
  ),
  stockout_date AS (
    SELECT
      *,
      DATE_ADD(
        DATE '2026-06-01', INTERVAL CAST(days_until_est_stockout AS INT64) DAY)
        AS estimated_stockout_date
    FROM stockout_days
  )
SELECT
  *,
  CASE
    WHEN estimated_stockout_date > expiration_date
      THEN
        ROUND(
          (
            current_stock - (
              DATE_DIFF(expiration_date, DATE '2026-06-01', DAY)
              * weighted_daily_avg))
            * cost,
          2)
    ELSE 0
    END AS est_loss
FROM stockout_date
