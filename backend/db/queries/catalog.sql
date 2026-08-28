-- name: GetProductByBarcode :one
SELECT
    p.id,
    p.category_id,
    c.name AS category_name,
    p.unit_id,
    u.code AS unit_code,
    p.primary_supplier_id,
    p.sku,
    p.name,
    p.description,
    p.sale_price_cents,
    p.cost_price_cents,
    p.minimum_stock,
    p.tax_rate_basis_points,
    p.tax_category,
    p.allow_negative_stock,
    p.is_perishable,
    p.is_active,
    pb.barcode,
    COALESCE(ib.quantity, 0) AS stock_quantity,
    COALESCE(ib.reserved_quantity, 0) AS reserved_quantity,
    COALESCE(ib.quantity, 0) - COALESCE(ib.reserved_quantity, 0) AS available_quantity
FROM product_barcodes AS pb
JOIN products AS p ON p.id = pb.product_id
JOIN categories AS c ON c.id = p.category_id
JOIN units AS u ON u.id = p.unit_id
LEFT JOIN inventory_balances AS ib ON ib.product_id = p.id
WHERE pb.barcode = sqlc.arg(barcode)
  AND p.is_active = TRUE
LIMIT 1;

-- name: SearchProducts :many
SELECT DISTINCT
    p.id,
    p.category_id,
    c.name AS category_name,
    p.sku,
    p.name,
    p.sale_price_cents,
    p.cost_price_cents,
    p.minimum_stock,
    p.tax_rate_basis_points,
    p.tax_category,
    p.allow_negative_stock,
    p.is_perishable,
    u.code AS unit_code,
    COALESCE(ib.quantity, 0) AS stock_quantity,
    COALESCE(ib.reserved_quantity, 0) AS reserved_quantity,
    COALESCE(ib.quantity, 0) - COALESCE(ib.reserved_quantity, 0) AS available_quantity
FROM products AS p
JOIN categories AS c ON c.id = p.category_id
JOIN units AS u ON u.id = p.unit_id
LEFT JOIN inventory_balances AS ib ON ib.product_id = p.id
LEFT JOIN product_barcodes AS pb ON pb.product_id = p.id
WHERE p.is_active = TRUE
  AND (sqlc.narg('category_id') IS NULL OR p.category_id = sqlc.narg('category_id'))
  AND (
      p.name LIKE CONCAT('%', sqlc.arg(query), '%')
      OR p.sku LIKE CONCAT('%', sqlc.arg(query), '%')
      OR pb.barcode LIKE CONCAT('%', sqlc.arg(query), '%')
  )
ORDER BY p.name
LIMIT ? OFFSET ?;

-- name: ListLowStockProducts :many
SELECT
    p.id,
    p.sku,
    p.name,
    p.minimum_stock,
    COALESCE(ib.quantity, 0) AS stock_quantity,
    COALESCE(ib.reserved_quantity, 0) AS reserved_quantity,
    COALESCE(ib.quantity, 0) - COALESCE(ib.reserved_quantity, 0) AS available_quantity,
    p.allow_negative_stock
FROM products AS p
LEFT JOIN inventory_balances AS ib ON ib.product_id = p.id
WHERE p.is_active = TRUE
  AND COALESCE(ib.quantity, 0) - COALESCE(ib.reserved_quantity, 0) <= p.minimum_stock
ORDER BY p.name;

-- name: GetExpiringLots :many
SELECT
    pl.id,
    pl.product_id,
    p.sku,
    p.name,
    pl.lot_number,
    pl.expires_on,
    pl.current_quantity
FROM product_lots AS pl
JOIN products AS p ON p.id = pl.product_id
WHERE p.is_active = TRUE
  AND p.is_perishable = TRUE
  AND pl.expires_on IS NOT NULL
  AND pl.expires_on BETWEEN sqlc.arg(from_date) AND sqlc.arg(to_date)
  AND pl.current_quantity > 0
ORDER BY pl.expires_on, p.name;
