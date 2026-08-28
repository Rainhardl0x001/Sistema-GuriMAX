-- name: GetOpenCashSession :one
SELECT
    cs.id,
    cs.cash_register_id,
    cs.business_date,
    cs.opened_by_user_id,
    cs.opened_at,
    cs.initial_float_cents,
    cs.status
FROM cash_sessions AS cs
WHERE cs.cash_register_id = sqlc.arg(cash_register_id)
  AND cs.status IN ('OPEN', 'REOPENED')
LIMIT 1;

-- name: GetCashSessionSummary :one
SELECT
    cs.id,
    cs.business_date,
    cs.status,
    cs.initial_float_cents,
    COALESCE(SUM(CASE WHEN cm.movement_type = 'SALE' AND cm.payment_method = 'CASH' THEN cm.amount_cents ELSE 0 END), 0) AS cash_sales_cents,
    COALESCE(SUM(CASE WHEN cm.movement_type = 'REFUND' AND cm.payment_method = 'CASH' THEN cm.amount_cents ELSE 0 END), 0) AS cash_refunds_cents,
    COALESCE(SUM(CASE WHEN cm.movement_type = 'WITHDRAWAL' THEN cm.amount_cents ELSE 0 END), 0) AS withdrawals_cents,
    COALESCE(SUM(CASE WHEN cm.movement_type IN ('DEPOSIT', 'ADJUSTMENT') THEN cm.amount_cents ELSE 0 END), 0) AS adjustments_cents
FROM cash_sessions AS cs
LEFT JOIN cash_movements AS cm ON cm.cash_session_id = cs.id
WHERE cs.id = sqlc.arg(cash_session_id)
GROUP BY cs.id;

-- name: ListPendingPayables :many
SELECT
    p.id,
    p.supplier_id,
    s.trade_name AS supplier_name,
    p.purchase_id,
    p.document_number,
    p.original_amount_cents,
    p.paid_amount_cents,
    p.balance_cents,
    p.due_date,
    p.status
FROM payables AS p
JOIN suppliers AS s ON s.id = p.supplier_id
WHERE p.status IN ('PENDING', 'PARTIALLY_PAID', 'OVERDUE')
ORDER BY p.due_date IS NULL, p.due_date, s.trade_name;

-- name: GetCustomerCreditSummary :one
SELECT
    c.id AS customer_id,
    c.full_name,
    c.credit_limit_cents,
    c.credit_term_days,
    c.is_credit_blocked,
    COALESCE(ca.balance_cents, 0) AS balance_cents,
    GREATEST(c.credit_limit_cents - COALESCE(ca.balance_cents, 0), 0) AS available_credit_cents
FROM customers AS c
LEFT JOIN credit_accounts AS ca ON ca.customer_id = c.id
WHERE c.id = sqlc.arg(customer_id)
LIMIT 1;

-- name: ListOverdueCreditEntries :many
SELECT
    ce.id,
    ce.credit_account_id,
    ca.customer_id,
    c.full_name,
    ce.amount_cents,
    ce.balance_after_cents,
    ce.due_date,
    ce.created_at
FROM credit_entries AS ce
JOIN credit_accounts AS ca ON ca.id = ce.credit_account_id
JOIN customers AS c ON c.id = ca.customer_id
WHERE ce.entry_type = 'CHARGE'
  AND ce.due_date IS NOT NULL
  AND ce.due_date < sqlc.arg(as_of_date)
  AND ce.balance_after_cents > 0
ORDER BY ce.due_date, c.full_name;

-- name: ListAuditEntries :many
SELECT
    al.id,
    al.actor_user_id,
    al.actor_role,
    al.action,
    al.entity_type,
    al.entity_id,
    al.reason,
    al.authorization_id,
    al.before_values,
    al.after_values,
    al.correlation_id,
    al.created_at
FROM audit_log AS al
WHERE (sqlc.arg(entity_type) = '' OR al.entity_type = sqlc.arg(entity_type))
  AND al.created_at >= sqlc.arg(from_datetime)
  AND al.created_at < sqlc.arg(to_datetime)
ORDER BY al.created_at DESC
LIMIT ? OFFSET ?;
