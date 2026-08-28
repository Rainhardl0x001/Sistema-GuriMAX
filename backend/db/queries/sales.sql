-- name: GetSaleByID :one
SELECT
    s.id,
    s.sale_number,
    s.sale_type,
    s.status,
    s.currency_code,
    s.subtotal_cents,
    s.discount_cents,
    s.tax_cents,
    s.delivery_fee_cents,
    s.total_cents,
    s.paid_cents,
    s.change_cents,
    s.customer_id,
    c.full_name AS customer_name,
    s.cash_session_id,
    cs.business_date,
    s.created_by_user_id,
    s.idempotency_key,
    s.cancellation_reason,
    s.created_at,
    s.updated_at,
    s.completed_at
FROM sales AS s
LEFT JOIN customers AS c ON c.id = s.customer_id
LEFT JOIN cash_sessions AS cs ON cs.id = s.cash_session_id
WHERE s.id = sqlc.arg(sale_id)
LIMIT 1;

-- name: GetSaleByIdempotencyKey :one
SELECT
    s.id,
    s.sale_number,
    s.status,
    s.total_cents,
    s.paid_cents,
    s.change_cents,
    s.created_at,
    s.completed_at
FROM sales AS s
WHERE s.idempotency_key = sqlc.arg(idempotency_key)
LIMIT 1;

-- name: ListSaleLines :many
SELECT
    sl.id,
    sl.sale_id,
    sl.product_id,
    sl.product_name_snapshot,
    sl.sku_snapshot,
    sl.quantity,
    sl.unit_price_cents,
    sl.discount_cents,
    sl.tax_cents,
    sl.line_total_cents,
    sl.lot_id
FROM sale_lines AS sl
WHERE sl.sale_id = sqlc.arg(sale_id)
ORDER BY sl.created_at, sl.id;

-- name: ListSalePayments :many
SELECT
    sp.id,
    sp.sale_id,
    sp.payment_method,
    sp.amount_cents,
    sp.status,
    sp.external_reference,
    sp.verified_by_user_id,
    sp.verified_at,
    sp.created_at
FROM sale_payments AS sp
WHERE sp.sale_id = sqlc.arg(sale_id)
ORDER BY sp.created_at, sp.id;

-- name: ListSalesByDate :many
SELECT
    s.id,
    s.sale_number,
    s.sale_type,
    s.status,
    s.subtotal_cents,
    s.discount_cents,
    s.tax_cents,
    s.delivery_fee_cents,
    s.total_cents,
    s.paid_cents,
    s.change_cents,
    s.customer_id,
    c.full_name AS customer_name,
    s.cash_session_id,
    cs.business_date,
    s.created_by_user_id,
    s.created_at,
    COUNT(sl.id) AS line_count
FROM sales AS s
LEFT JOIN customers AS c ON c.id = s.customer_id
LEFT JOIN cash_sessions AS cs ON cs.id = s.cash_session_id
LEFT JOIN sale_lines AS sl ON sl.sale_id = s.id
WHERE s.created_at >= sqlc.arg(from_datetime)
  AND s.created_at < sqlc.arg(to_datetime)
  AND (sqlc.narg('status') IS NULL OR s.status = sqlc.narg('status'))
  AND (sqlc.narg('cash_session_id') IS NULL OR s.cash_session_id = sqlc.narg('cash_session_id'))
  AND (sqlc.narg('created_by_user_id') IS NULL OR s.created_by_user_id = sqlc.narg('created_by_user_id'))
GROUP BY s.id
ORDER BY s.created_at DESC
LIMIT ? OFFSET ?;
