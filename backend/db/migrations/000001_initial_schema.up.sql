-- GuriMAX · Esquema inicial
-- MySQL 9.7 · importes en unidades menores de DOP (centavos)
-- Los timestamps técnicos se almacenan en UTC; las fechas de negocio se guardan explícitamente.

CREATE TABLE roles (
    id CHAR(36) NOT NULL,
    name VARCHAR(50) NOT NULL,
    description VARCHAR(255) NULL,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    UNIQUE KEY uq_roles_name (name)
) ENGINE = InnoDB;

CREATE TABLE permissions (
    id CHAR(36) NOT NULL,
    code VARCHAR(100) NOT NULL,
    description VARCHAR(255) NULL,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    UNIQUE KEY uq_permissions_code (code)
) ENGINE = InnoDB;

CREATE TABLE role_permissions (
    role_id CHAR(36) NOT NULL,
    permission_id CHAR(36) NOT NULL,
    PRIMARY KEY (role_id, permission_id),
    CONSTRAINT fk_role_permissions_role FOREIGN KEY (role_id) REFERENCES roles (id),
    CONSTRAINT fk_role_permissions_permission FOREIGN KEY (permission_id) REFERENCES permissions (id)
) ENGINE = InnoDB;

CREATE TABLE users (
    id CHAR(36) NOT NULL,
    role_id CHAR(36) NOT NULL,
    username VARCHAR(80) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(150) NOT NULL,
    email VARCHAR(255) NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    last_login_at DATETIME(6) NULL,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    UNIQUE KEY uq_users_username (username),
    UNIQUE KEY uq_users_email (email),
    KEY idx_users_role_active (role_id, is_active),
    CONSTRAINT fk_users_role FOREIGN KEY (role_id) REFERENCES roles (id)
) ENGINE = InnoDB;

CREATE TABLE sessions (
    id CHAR(36) NOT NULL,
    user_id CHAR(36) NOT NULL,
    token_hash CHAR(64) NOT NULL,
    expires_at DATETIME(6) NOT NULL,
    revoked_at DATETIME(6) NULL,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    UNIQUE KEY uq_sessions_token_hash (token_hash),
    KEY idx_sessions_user_expiry (user_id, expires_at),
    CONSTRAINT fk_sessions_user FOREIGN KEY (user_id) REFERENCES users (id)
) ENGINE = InnoDB;

CREATE TABLE categories (
    id CHAR(36) NOT NULL,
    name VARCHAR(120) NOT NULL,
    description VARCHAR(255) NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    UNIQUE KEY uq_categories_name (name)
) ENGINE = InnoDB;

CREATE TABLE units (
    id CHAR(36) NOT NULL,
    code VARCHAR(30) NOT NULL,
    name VARCHAR(80) NOT NULL,
    allows_fractional BOOLEAN NOT NULL DEFAULT FALSE,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    UNIQUE KEY uq_units_code (code)
) ENGINE = InnoDB;

CREATE TABLE suppliers (
    id CHAR(36) NOT NULL,
    trade_name VARCHAR(150) NOT NULL,
    legal_name VARCHAR(180) NULL,
    rnc VARCHAR(20) NULL,
    contact_name VARCHAR(150) NULL,
    phone VARCHAR(40) NULL,
    email VARCHAR(255) NULL,
    address VARCHAR(255) NULL,
    payment_terms_days SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    notes TEXT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    UNIQUE KEY uq_suppliers_rnc (rnc),
    KEY idx_suppliers_active_name (is_active, trade_name),
    CONSTRAINT chk_suppliers_payment_terms CHECK (payment_terms_days <= 3650)
) ENGINE = InnoDB;

CREATE TABLE customers (
    id CHAR(36) NOT NULL,
    full_name VARCHAR(150) NOT NULL,
    national_id VARCHAR(30) NULL,
    phone VARCHAR(40) NULL,
    email VARCHAR(255) NULL,
    address VARCHAR(255) NULL,
    credit_limit_cents BIGINT UNSIGNED NOT NULL DEFAULT 0,
    credit_term_days SMALLINT UNSIGNED NOT NULL DEFAULT 30,
    is_credit_blocked BOOLEAN NOT NULL DEFAULT FALSE,
    block_reason VARCHAR(255) NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    UNIQUE KEY uq_customers_national_id (national_id),
    KEY idx_customers_active_name (is_active, full_name),
    CONSTRAINT chk_customers_credit_term CHECK (credit_term_days <= 3650)
) ENGINE = InnoDB;

CREATE TABLE products (
    id CHAR(36) NOT NULL,
    category_id CHAR(36) NOT NULL,
    unit_id CHAR(36) NOT NULL,
    primary_supplier_id CHAR(36) NULL,
    sku VARCHAR(80) NOT NULL,
    name VARCHAR(180) NOT NULL,
    description VARCHAR(255) NULL,
    sale_price_cents BIGINT UNSIGNED NOT NULL DEFAULT 0,
    cost_price_cents BIGINT UNSIGNED NOT NULL DEFAULT 0,
    minimum_stock DECIMAL(14,3) NOT NULL DEFAULT 0,
    tax_rate_basis_points SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    tax_category VARCHAR(30) NOT NULL DEFAULT 'EXEMPT',
    allow_negative_stock BOOLEAN NOT NULL DEFAULT FALSE,
    is_perishable BOOLEAN NOT NULL DEFAULT FALSE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    UNIQUE KEY uq_products_sku (sku),
    KEY idx_products_search (is_active, name),
    KEY idx_products_category (category_id, is_active),
    KEY idx_products_supplier (primary_supplier_id),
    CONSTRAINT fk_products_category FOREIGN KEY (category_id) REFERENCES categories (id),
    CONSTRAINT fk_products_unit FOREIGN KEY (unit_id) REFERENCES units (id),
    CONSTRAINT fk_products_primary_supplier FOREIGN KEY (primary_supplier_id) REFERENCES suppliers (id) ON DELETE SET NULL,
    CONSTRAINT chk_products_minimum_stock CHECK (minimum_stock >= 0),
    CONSTRAINT chk_products_tax_rate CHECK (tax_rate_basis_points <= 10000)
) ENGINE = InnoDB;

CREATE TABLE product_barcodes (
    id CHAR(36) NOT NULL,
    product_id CHAR(36) NOT NULL,
    barcode VARCHAR(80) NOT NULL,
    is_primary BOOLEAN NOT NULL DEFAULT FALSE,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    UNIQUE KEY uq_product_barcodes_barcode (barcode),
    UNIQUE KEY uq_product_barcodes_product_barcode (product_id, barcode),
    CONSTRAINT fk_product_barcodes_product FOREIGN KEY (product_id) REFERENCES products (id)
) ENGINE = InnoDB;

CREATE TABLE product_suppliers (
    product_id CHAR(36) NOT NULL,
    supplier_id CHAR(36) NOT NULL,
    supplier_code VARCHAR(80) NULL,
    last_cost_cents BIGINT UNSIGNED NOT NULL DEFAULT 0,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    PRIMARY KEY (product_id, supplier_id),
    CONSTRAINT fk_product_suppliers_product FOREIGN KEY (product_id) REFERENCES products (id),
    CONSTRAINT fk_product_suppliers_supplier FOREIGN KEY (supplier_id) REFERENCES suppliers (id)
) ENGINE = InnoDB;

CREATE TABLE product_price_history (
    id CHAR(36) NOT NULL,
    product_id CHAR(36) NOT NULL,
    price_type VARCHAR(20) NOT NULL,
    amount_cents BIGINT UNSIGNED NOT NULL,
    effective_from DATETIME(6) NOT NULL,
    effective_to DATETIME(6) NULL,
    changed_by_user_id CHAR(36) NULL,
    reason VARCHAR(255) NULL,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    KEY idx_product_price_history_product_date (product_id, effective_from),
    CONSTRAINT fk_product_price_history_product FOREIGN KEY (product_id) REFERENCES products (id),
    CONSTRAINT fk_product_price_history_user FOREIGN KEY (changed_by_user_id) REFERENCES users (id) ON DELETE SET NULL,
    CONSTRAINT chk_product_price_history_type CHECK (price_type IN ('SALE', 'COST'))
) ENGINE = InnoDB;

CREATE TABLE product_lots (
    id CHAR(36) NOT NULL,
    product_id CHAR(36) NOT NULL,
    lot_number VARCHAR(80) NOT NULL,
    expires_on DATE NULL,
    received_quantity DECIMAL(14,3) NOT NULL DEFAULT 0,
    current_quantity DECIMAL(14,3) NOT NULL DEFAULT 0,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    UNIQUE KEY uq_product_lots_product_number (product_id, lot_number),
    KEY idx_product_lots_expiry (expires_on),
    CONSTRAINT fk_product_lots_product FOREIGN KEY (product_id) REFERENCES products (id),
    CONSTRAINT chk_product_lots_received CHECK (received_quantity >= 0),
    CONSTRAINT chk_product_lots_current CHECK (current_quantity >= 0)
) ENGINE = InnoDB;

CREATE TABLE cash_registers (
    id CHAR(36) NOT NULL,
    code VARCHAR(30) NOT NULL,
    name VARCHAR(80) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    UNIQUE KEY uq_cash_registers_code (code)
) ENGINE = InnoDB;

CREATE TABLE cash_sessions (
    id CHAR(36) NOT NULL,
    cash_register_id CHAR(36) NOT NULL,
    business_date DATE NOT NULL,
    opened_by_user_id CHAR(36) NOT NULL,
    opened_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    initial_float_cents BIGINT UNSIGNED NOT NULL DEFAULT 0,
    status VARCHAR(20) NOT NULL DEFAULT 'OPEN',
    closed_by_user_id CHAR(36) NULL,
    closed_at DATETIME(6) NULL,
    expected_cash_cents BIGINT NULL,
    counted_cash_cents BIGINT UNSIGNED NULL,
    difference_cents BIGINT NULL,
    reviewed_by_user_id CHAR(36) NULL,
    reviewed_at DATETIME(6) NULL,
    review_notes VARCHAR(255) NULL,
    active_slot TINYINT GENERATED ALWAYS AS (CASE WHEN status IN ('OPEN', 'REOPENED') THEN 1 ELSE NULL END) STORED,
    PRIMARY KEY (id),
    UNIQUE KEY uq_cash_sessions_register_business_date_active (cash_register_id, business_date, active_slot),
    KEY idx_cash_sessions_business_date (business_date, status),
    CONSTRAINT fk_cash_sessions_register FOREIGN KEY (cash_register_id) REFERENCES cash_registers (id),
    CONSTRAINT fk_cash_sessions_opened_by FOREIGN KEY (opened_by_user_id) REFERENCES users (id),
    CONSTRAINT fk_cash_sessions_closed_by FOREIGN KEY (closed_by_user_id) REFERENCES users (id) ON DELETE SET NULL,
    CONSTRAINT fk_cash_sessions_reviewed_by FOREIGN KEY (reviewed_by_user_id) REFERENCES users (id) ON DELETE SET NULL,
    CONSTRAINT chk_cash_sessions_status CHECK (status IN ('OPEN', 'PENDING_REVIEW', 'APPROVED', 'REOPENED'))
) ENGINE = InnoDB;

CREATE TABLE sales (
    id CHAR(36) NOT NULL,
    cash_session_id CHAR(36) NULL,
    customer_id CHAR(36) NULL,
    sale_number VARCHAR(40) NOT NULL,
    sale_type VARCHAR(20) NOT NULL DEFAULT 'STANDARD',
    status VARCHAR(20) NOT NULL DEFAULT 'DRAFT',
    currency_code CHAR(3) NOT NULL DEFAULT 'DOP',
    subtotal_cents BIGINT UNSIGNED NOT NULL DEFAULT 0,
    discount_cents BIGINT UNSIGNED NOT NULL DEFAULT 0,
    tax_cents BIGINT UNSIGNED NOT NULL DEFAULT 0,
    delivery_fee_cents BIGINT UNSIGNED NOT NULL DEFAULT 0,
    total_cents BIGINT UNSIGNED NOT NULL DEFAULT 0,
    paid_cents BIGINT UNSIGNED NOT NULL DEFAULT 0,
    change_cents BIGINT UNSIGNED NOT NULL DEFAULT 0,
    idempotency_key VARCHAR(100) NOT NULL,
    created_by_user_id CHAR(36) NOT NULL,
    completed_at DATETIME(6) NULL,
    cancelled_at DATETIME(6) NULL,
    cancellation_reason VARCHAR(255) NULL,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    UNIQUE KEY uq_sales_sale_number (sale_number),
    UNIQUE KEY uq_sales_idempotency_key (idempotency_key),
    KEY idx_sales_date_status (created_at, status),
    KEY idx_sales_customer (customer_id, status),
    KEY idx_sales_cash_session (cash_session_id, status),
    CONSTRAINT fk_sales_cash_session FOREIGN KEY (cash_session_id) REFERENCES cash_sessions (id),
    CONSTRAINT fk_sales_customer FOREIGN KEY (customer_id) REFERENCES customers (id) ON DELETE SET NULL,
    CONSTRAINT fk_sales_created_by FOREIGN KEY (created_by_user_id) REFERENCES users (id),
    CONSTRAINT chk_sales_currency CHECK (currency_code = 'DOP'),
    CONSTRAINT chk_sales_type CHECK (sale_type IN ('STANDARD', 'CREDIT', 'LAYAWAY', 'DELIVERY')),
    CONSTRAINT chk_sales_status CHECK (status IN ('DRAFT', 'PENDING', 'COMPLETED', 'CANCELLED'))
) ENGINE = InnoDB;

CREATE TABLE sale_lines (
    id CHAR(36) NOT NULL,
    sale_id CHAR(36) NOT NULL,
    product_id CHAR(36) NOT NULL,
    lot_id CHAR(36) NULL,
    product_name_snapshot VARCHAR(180) NOT NULL,
    sku_snapshot VARCHAR(80) NOT NULL,
    quantity DECIMAL(14,3) NOT NULL,
    unit_price_cents BIGINT UNSIGNED NOT NULL,
    discount_cents BIGINT UNSIGNED NOT NULL DEFAULT 0,
    tax_cents BIGINT UNSIGNED NOT NULL DEFAULT 0,
    line_total_cents BIGINT UNSIGNED NOT NULL,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    KEY idx_sale_lines_sale (sale_id),
    KEY idx_sale_lines_product (product_id),
    CONSTRAINT fk_sale_lines_sale FOREIGN KEY (sale_id) REFERENCES sales (id),
    CONSTRAINT fk_sale_lines_product FOREIGN KEY (product_id) REFERENCES products (id),
    CONSTRAINT fk_sale_lines_lot FOREIGN KEY (lot_id) REFERENCES product_lots (id) ON DELETE SET NULL,
    CONSTRAINT chk_sale_lines_quantity CHECK (quantity > 0)
) ENGINE = InnoDB;

CREATE TABLE sale_payments (
    id CHAR(36) NOT NULL,
    sale_id CHAR(36) NOT NULL,
    payment_method VARCHAR(30) NOT NULL,
    amount_cents BIGINT UNSIGNED NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'CONFIRMED',
    external_reference VARCHAR(120) NULL,
    verified_by_user_id CHAR(36) NULL,
    verified_at DATETIME(6) NULL,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    KEY idx_sale_payments_sale (sale_id),
    KEY idx_sale_payments_status (status, payment_method),
    CONSTRAINT fk_sale_payments_sale FOREIGN KEY (sale_id) REFERENCES sales (id),
    CONSTRAINT fk_sale_payments_verified_by FOREIGN KEY (verified_by_user_id) REFERENCES users (id) ON DELETE SET NULL,
    CONSTRAINT chk_sale_payments_method CHECK (payment_method IN ('CASH', 'CARD', 'BANK_TRANSFER', 'CREDIT', 'STORE_CREDIT')),
    CONSTRAINT chk_sale_payments_status CHECK (status IN ('PENDING', 'CONFIRMED', 'REFUNDED', 'VOIDED'))
) ENGINE = InnoDB;

CREATE TABLE inventory_balances (
    product_id CHAR(36) NOT NULL,
    quantity DECIMAL(14,3) NOT NULL DEFAULT 0,
    reserved_quantity DECIMAL(14,3) NOT NULL DEFAULT 0,
    updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    PRIMARY KEY (product_id),
    CONSTRAINT fk_inventory_balances_product FOREIGN KEY (product_id) REFERENCES products (id),
    CONSTRAINT chk_inventory_balances_reserved CHECK (reserved_quantity >= 0)
) ENGINE = InnoDB;

CREATE TABLE stock_movements (
    id CHAR(36) NOT NULL,
    product_id CHAR(36) NOT NULL,
    lot_id CHAR(36) NULL,
    movement_type VARCHAR(30) NOT NULL,
    quantity_delta DECIMAL(14,3) NOT NULL,
    quantity_before DECIMAL(14,3) NOT NULL,
    quantity_after DECIMAL(14,3) NOT NULL,
    unit_cost_cents BIGINT UNSIGNED NOT NULL DEFAULT 0,
    reference_type VARCHAR(40) NULL,
    reference_id CHAR(36) NULL,
    reason VARCHAR(255) NULL,
    idempotency_key VARCHAR(100) NULL,
    created_by_user_id CHAR(36) NULL,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    UNIQUE KEY uq_stock_movements_idempotency (idempotency_key),
    KEY idx_stock_movements_product_date (product_id, created_at),
    KEY idx_stock_movements_reference (reference_type, reference_id),
    CONSTRAINT fk_stock_movements_product FOREIGN KEY (product_id) REFERENCES products (id),
    CONSTRAINT fk_stock_movements_lot FOREIGN KEY (lot_id) REFERENCES product_lots (id) ON DELETE SET NULL,
    CONSTRAINT fk_stock_movements_created_by FOREIGN KEY (created_by_user_id) REFERENCES users (id) ON DELETE SET NULL,
    CONSTRAINT chk_stock_movements_type CHECK (movement_type IN ('OPENING', 'PURCHASE', 'SALE', 'RETURN', 'ADJUSTMENT', 'SHRINKAGE', 'RESERVATION', 'RELEASE'))
) ENGINE = InnoDB;

CREATE TABLE inventory_counts (
    id CHAR(36) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'DRAFT',
    counted_by_user_id CHAR(36) NOT NULL,
    approved_by_user_id CHAR(36) NULL,
    started_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    approved_at DATETIME(6) NULL,
    notes TEXT NULL,
    PRIMARY KEY (id),
    KEY idx_inventory_counts_status_date (status, started_at),
    CONSTRAINT fk_inventory_counts_counted_by FOREIGN KEY (counted_by_user_id) REFERENCES users (id),
    CONSTRAINT fk_inventory_counts_approved_by FOREIGN KEY (approved_by_user_id) REFERENCES users (id) ON DELETE SET NULL,
    CONSTRAINT chk_inventory_counts_status CHECK (status IN ('DRAFT', 'PENDING_APPROVAL', 'APPROVED', 'CANCELLED'))
) ENGINE = InnoDB;

CREATE TABLE inventory_count_lines (
    id CHAR(36) NOT NULL,
    inventory_count_id CHAR(36) NOT NULL,
    product_id CHAR(36) NOT NULL,
    system_quantity DECIMAL(14,3) NOT NULL,
    counted_quantity DECIMAL(14,3) NOT NULL,
    difference_quantity DECIMAL(14,3) NOT NULL,
    reason VARCHAR(255) NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uq_inventory_count_lines_product (inventory_count_id, product_id),
    CONSTRAINT fk_inventory_count_lines_count FOREIGN KEY (inventory_count_id) REFERENCES inventory_counts (id),
    CONSTRAINT fk_inventory_count_lines_product FOREIGN KEY (product_id) REFERENCES products (id),
    CONSTRAINT chk_inventory_count_lines_quantity CHECK (system_quantity >= 0 AND counted_quantity >= 0)
) ENGINE = InnoDB;

CREATE TABLE cash_movements (
    id CHAR(36) NOT NULL,
    cash_session_id CHAR(36) NOT NULL,
    movement_type VARCHAR(30) NOT NULL,
    payment_method VARCHAR(30) NULL,
    amount_cents BIGINT NOT NULL,
    reference_type VARCHAR(40) NULL,
    reference_id CHAR(36) NULL,
    reason VARCHAR(255) NULL,
    idempotency_key VARCHAR(100) NULL,
    created_by_user_id CHAR(36) NOT NULL,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    UNIQUE KEY uq_cash_movements_idempotency (idempotency_key),
    KEY idx_cash_movements_session_date (cash_session_id, created_at),
    CONSTRAINT fk_cash_movements_session FOREIGN KEY (cash_session_id) REFERENCES cash_sessions (id),
    CONSTRAINT fk_cash_movements_created_by FOREIGN KEY (created_by_user_id) REFERENCES users (id),
    CONSTRAINT chk_cash_movements_type CHECK (movement_type IN ('OPENING_FLOAT', 'SALE', 'REFUND', 'WITHDRAWAL', 'DEPOSIT', 'ADJUSTMENT')),
    CONSTRAINT chk_cash_movements_method CHECK (payment_method IS NULL OR payment_method IN ('CASH', 'CARD', 'BANK_TRANSFER'))
) ENGINE = InnoDB;

CREATE TABLE purchases (
    id CHAR(36) NOT NULL,
    supplier_id CHAR(36) NOT NULL,
    purchase_number VARCHAR(40) NOT NULL,
    supplier_invoice_number VARCHAR(80) NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'DRAFT',
    currency_code CHAR(3) NOT NULL DEFAULT 'DOP',
    subtotal_cents BIGINT UNSIGNED NOT NULL DEFAULT 0,
    discount_cents BIGINT UNSIGNED NOT NULL DEFAULT 0,
    tax_cents BIGINT UNSIGNED NOT NULL DEFAULT 0,
    total_cents BIGINT UNSIGNED NOT NULL DEFAULT 0,
    purchase_date DATE NOT NULL,
    due_date DATE NULL,
    idempotency_key VARCHAR(100) NOT NULL,
    created_by_user_id CHAR(36) NOT NULL,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    UNIQUE KEY uq_purchases_number (purchase_number),
    UNIQUE KEY uq_purchases_idempotency (idempotency_key),
    KEY idx_purchases_supplier_date (supplier_id, purchase_date),
    CONSTRAINT fk_purchases_supplier FOREIGN KEY (supplier_id) REFERENCES suppliers (id),
    CONSTRAINT fk_purchases_created_by FOREIGN KEY (created_by_user_id) REFERENCES users (id),
    CONSTRAINT chk_purchases_currency CHECK (currency_code = 'DOP'),
    CONSTRAINT chk_purchases_status CHECK (status IN ('DRAFT', 'ORDERED', 'PARTIALLY_RECEIVED', 'RECEIVED', 'CANCELLED'))
) ENGINE = InnoDB;

CREATE TABLE purchase_lines (
    id CHAR(36) NOT NULL,
    purchase_id CHAR(36) NOT NULL,
    product_id CHAR(36) NOT NULL,
    product_name_snapshot VARCHAR(180) NOT NULL,
    quantity_ordered DECIMAL(14,3) NOT NULL,
    quantity_received DECIMAL(14,3) NOT NULL DEFAULT 0,
    unit_cost_cents BIGINT UNSIGNED NOT NULL,
    discount_cents BIGINT UNSIGNED NOT NULL DEFAULT 0,
    tax_cents BIGINT UNSIGNED NOT NULL DEFAULT 0,
    line_total_cents BIGINT UNSIGNED NOT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uq_purchase_lines_product (purchase_id, product_id),
    CONSTRAINT fk_purchase_lines_purchase FOREIGN KEY (purchase_id) REFERENCES purchases (id),
    CONSTRAINT fk_purchase_lines_product FOREIGN KEY (product_id) REFERENCES products (id),
    CONSTRAINT chk_purchase_lines_quantities CHECK (quantity_ordered > 0 AND quantity_received >= 0 AND quantity_received <= quantity_ordered)
) ENGINE = InnoDB;

CREATE TABLE purchase_receipts (
    id CHAR(36) NOT NULL,
    purchase_id CHAR(36) NULL,
    supplier_id CHAR(36) NOT NULL,
    receipt_number VARCHAR(40) NOT NULL,
    received_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    received_by_user_id CHAR(36) NOT NULL,
    notes TEXT NULL,
    idempotency_key VARCHAR(100) NOT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uq_purchase_receipts_number (receipt_number),
    UNIQUE KEY uq_purchase_receipts_idempotency (idempotency_key),
    KEY idx_purchase_receipts_supplier_date (supplier_id, received_at),
    CONSTRAINT fk_purchase_receipts_purchase FOREIGN KEY (purchase_id) REFERENCES purchases (id),
    CONSTRAINT fk_purchase_receipts_supplier FOREIGN KEY (supplier_id) REFERENCES suppliers (id),
    CONSTRAINT fk_purchase_receipts_received_by FOREIGN KEY (received_by_user_id) REFERENCES users (id)
) ENGINE = InnoDB;

CREATE TABLE purchase_receipt_lines (
    id CHAR(36) NOT NULL,
    receipt_id CHAR(36) NOT NULL,
    product_id CHAR(36) NOT NULL,
    lot_id CHAR(36) NULL,
    quantity_received DECIMAL(14,3) NOT NULL,
    unit_cost_cents BIGINT UNSIGNED NOT NULL,
    expires_on DATE NULL,
    PRIMARY KEY (id),
    CONSTRAINT fk_purchase_receipt_lines_receipt FOREIGN KEY (receipt_id) REFERENCES purchase_receipts (id),
    CONSTRAINT fk_purchase_receipt_lines_product FOREIGN KEY (product_id) REFERENCES products (id),
    CONSTRAINT fk_purchase_receipt_lines_lot FOREIGN KEY (lot_id) REFERENCES product_lots (id) ON DELETE SET NULL,
    CONSTRAINT chk_purchase_receipt_lines_quantity CHECK (quantity_received > 0)
) ENGINE = InnoDB;

CREATE TABLE purchase_incidents (
    id CHAR(36) NOT NULL,
    purchase_id CHAR(36) NULL,
    receipt_id CHAR(36) NULL,
    product_id CHAR(36) NULL,
    incident_type VARCHAR(30) NOT NULL,
    quantity DECIMAL(14,3) NULL,
    description VARCHAR(255) NOT NULL,
    resolved_at DATETIME(6) NULL,
    resolved_by_user_id CHAR(36) NULL,
    created_by_user_id CHAR(36) NOT NULL,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    KEY idx_purchase_incidents_status (resolved_at, created_at),
    CONSTRAINT fk_purchase_incidents_purchase FOREIGN KEY (purchase_id) REFERENCES purchases (id),
    CONSTRAINT fk_purchase_incidents_receipt FOREIGN KEY (receipt_id) REFERENCES purchase_receipts (id),
    CONSTRAINT fk_purchase_incidents_product FOREIGN KEY (product_id) REFERENCES products (id),
    CONSTRAINT fk_purchase_incidents_resolved_by FOREIGN KEY (resolved_by_user_id) REFERENCES users (id) ON DELETE SET NULL,
    CONSTRAINT fk_purchase_incidents_created_by FOREIGN KEY (created_by_user_id) REFERENCES users (id),
    CONSTRAINT chk_purchase_incidents_type CHECK (incident_type IN ('SHORTAGE', 'DAMAGE', 'WRONG_PRODUCT', 'RECEIVING_ERROR', 'OTHER'))
) ENGINE = InnoDB;

CREATE TABLE payables (
    id CHAR(36) NOT NULL,
    supplier_id CHAR(36) NOT NULL,
    purchase_id CHAR(36) NULL,
    document_number VARCHAR(80) NULL,
    currency_code CHAR(3) NOT NULL DEFAULT 'DOP',
    original_amount_cents BIGINT UNSIGNED NOT NULL,
    paid_amount_cents BIGINT UNSIGNED NOT NULL DEFAULT 0,
    balance_cents BIGINT UNSIGNED NOT NULL,
    due_date DATE NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    KEY idx_payables_supplier_status_due (supplier_id, status, due_date),
    CONSTRAINT fk_payables_supplier FOREIGN KEY (supplier_id) REFERENCES suppliers (id),
    CONSTRAINT fk_payables_purchase FOREIGN KEY (purchase_id) REFERENCES purchases (id),
    CONSTRAINT chk_payables_currency CHECK (currency_code = 'DOP'),
    CONSTRAINT chk_payables_status CHECK (status IN ('PENDING', 'PARTIALLY_PAID', 'PAID', 'OVERDUE', 'VOIDED')),
    CONSTRAINT chk_payables_balance CHECK (paid_amount_cents <= original_amount_cents AND balance_cents <= original_amount_cents)
) ENGINE = InnoDB;

CREATE TABLE payable_payments (
    id CHAR(36) NOT NULL,
    payable_id CHAR(36) NOT NULL,
    amount_cents BIGINT UNSIGNED NOT NULL,
    payment_method VARCHAR(30) NOT NULL,
    external_reference VARCHAR(120) NULL,
    paid_by_user_id CHAR(36) NOT NULL,
    idempotency_key VARCHAR(100) NOT NULL,
    paid_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    UNIQUE KEY uq_payable_payments_idempotency (idempotency_key),
    CONSTRAINT fk_payable_payments_payable FOREIGN KEY (payable_id) REFERENCES payables (id),
    CONSTRAINT fk_payable_payments_paid_by FOREIGN KEY (paid_by_user_id) REFERENCES users (id),
    CONSTRAINT chk_payable_payments_method CHECK (payment_method IN ('CASH', 'CARD', 'BANK_TRANSFER'))
) ENGINE = InnoDB;

CREATE TABLE credit_accounts (
    id CHAR(36) NOT NULL,
    customer_id CHAR(36) NOT NULL,
    balance_cents BIGINT NOT NULL DEFAULT 0,
    last_activity_at DATETIME(6) NULL,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    UNIQUE KEY uq_credit_accounts_customer (customer_id),
    CONSTRAINT fk_credit_accounts_customer FOREIGN KEY (customer_id) REFERENCES customers (id),
    CONSTRAINT chk_credit_accounts_balance CHECK (balance_cents >= 0)
) ENGINE = InnoDB;

CREATE TABLE credit_entries (
    id CHAR(36) NOT NULL,
    credit_account_id CHAR(36) NOT NULL,
    entry_type VARCHAR(20) NOT NULL,
    amount_cents BIGINT UNSIGNED NOT NULL,
    balance_before_cents BIGINT NOT NULL,
    balance_after_cents BIGINT NOT NULL,
    sale_id CHAR(36) NULL,
    payment_method VARCHAR(30) NULL,
    due_date DATE NULL,
    reference VARCHAR(120) NULL,
    idempotency_key VARCHAR(100) NOT NULL,
    created_by_user_id CHAR(36) NOT NULL,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    UNIQUE KEY uq_credit_entries_idempotency (idempotency_key),
    KEY idx_credit_entries_account_date (credit_account_id, created_at),
    CONSTRAINT fk_credit_entries_account FOREIGN KEY (credit_account_id) REFERENCES credit_accounts (id),
    CONSTRAINT fk_credit_entries_sale FOREIGN KEY (sale_id) REFERENCES sales (id),
    CONSTRAINT fk_credit_entries_created_by FOREIGN KEY (created_by_user_id) REFERENCES users (id),
    CONSTRAINT chk_credit_entries_type CHECK (entry_type IN ('CHARGE', 'PAYMENT', 'ADJUSTMENT', 'REFUND')),
    CONSTRAINT chk_credit_entries_payment_method CHECK (payment_method IS NULL OR payment_method IN ('CASH', 'CARD', 'BANK_TRANSFER')),
    CONSTRAINT chk_credit_entries_balance CHECK (balance_before_cents >= 0 AND balance_after_cents >= 0)
) ENGINE = InnoDB;

CREATE TABLE sales_returns (
    id CHAR(36) NOT NULL,
    sale_id CHAR(36) NOT NULL,
    return_number VARCHAR(40) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING_APPROVAL',
    reason VARCHAR(255) NOT NULL,
    is_approved BOOLEAN NOT NULL DEFAULT FALSE,
    requested_by_user_id CHAR(36) NOT NULL,
    approved_by_user_id CHAR(36) NULL,
    approved_at DATETIME(6) NULL,
    idempotency_key VARCHAR(100) NOT NULL,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    UNIQUE KEY uq_sales_returns_number (return_number),
    UNIQUE KEY uq_sales_returns_idempotency (idempotency_key),
    CONSTRAINT fk_sales_returns_sale FOREIGN KEY (sale_id) REFERENCES sales (id),
    CONSTRAINT fk_sales_returns_requested_by FOREIGN KEY (requested_by_user_id) REFERENCES users (id),
    CONSTRAINT fk_sales_returns_approved_by FOREIGN KEY (approved_by_user_id) REFERENCES users (id) ON DELETE SET NULL,
    CONSTRAINT chk_sales_returns_status CHECK (status IN ('PENDING_APPROVAL', 'APPROVED', 'REJECTED', 'COMPLETED'))
) ENGINE = InnoDB;

CREATE TABLE sales_return_lines (
    id CHAR(36) NOT NULL,
    return_id CHAR(36) NOT NULL,
    sale_line_id CHAR(36) NOT NULL,
    quantity DECIMAL(14,3) NOT NULL,
    condition_type VARCHAR(20) NOT NULL,
    refund_amount_cents BIGINT UNSIGNED NOT NULL DEFAULT 0,
    PRIMARY KEY (id),
    UNIQUE KEY uq_sales_return_lines_line (return_id, sale_line_id),
    CONSTRAINT fk_sales_return_lines_return FOREIGN KEY (return_id) REFERENCES sales_returns (id),
    CONSTRAINT fk_sales_return_lines_sale_line FOREIGN KEY (sale_line_id) REFERENCES sale_lines (id),
    CONSTRAINT chk_sales_return_lines_quantity CHECK (quantity > 0),
    CONSTRAINT chk_sales_return_lines_condition CHECK (condition_type IN ('SELLABLE', 'DAMAGED', 'EXPIRED', 'OPENED', 'OTHER'))
) ENGINE = InnoDB;

CREATE TABLE refunds (
    id CHAR(36) NOT NULL,
    return_id CHAR(36) NOT NULL,
    amount_cents BIGINT UNSIGNED NOT NULL,
    refund_method VARCHAR(30) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    external_reference VARCHAR(120) NULL,
    processed_by_user_id CHAR(36) NULL,
    processed_at DATETIME(6) NULL,
    idempotency_key VARCHAR(100) NOT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uq_refunds_return (return_id),
    UNIQUE KEY uq_refunds_idempotency (idempotency_key),
    CONSTRAINT fk_refunds_return FOREIGN KEY (return_id) REFERENCES sales_returns (id),
    CONSTRAINT fk_refunds_processed_by FOREIGN KEY (processed_by_user_id) REFERENCES users (id) ON DELETE SET NULL,
    CONSTRAINT chk_refunds_method CHECK (refund_method IN ('ORIGINAL', 'CASH', 'STORE_CREDIT')),
    CONSTRAINT chk_refunds_status CHECK (status IN ('PENDING', 'COMPLETED', 'REJECTED'))
) ENGINE = InnoDB;

CREATE TABLE tax_policies (
    id CHAR(36) NOT NULL,
    code VARCHAR(30) NOT NULL,
    name VARCHAR(100) NOT NULL,
    rate_basis_points SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    is_exempt BOOLEAN NOT NULL DEFAULT FALSE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    effective_from DATE NOT NULL,
    effective_to DATE NULL,
    created_by_user_id CHAR(36) NULL,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    UNIQUE KEY uq_tax_policies_code (code),
    CONSTRAINT fk_tax_policies_created_by FOREIGN KEY (created_by_user_id) REFERENCES users (id) ON DELETE SET NULL,
    CONSTRAINT chk_tax_policies_rate CHECK (rate_basis_points <= 10000)
) ENGINE = InnoDB;

CREATE TABLE billing_sequences (
    id CHAR(36) NOT NULL,
    document_type VARCHAR(20) NOT NULL,
    prefix VARCHAR(20) NOT NULL,
    next_number BIGINT UNSIGNED NOT NULL DEFAULT 1,
    valid_from DATE NULL,
    valid_to DATE NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    PRIMARY KEY (id),
    UNIQUE KEY uq_billing_sequences_type_prefix (document_type, prefix),
    CONSTRAINT chk_billing_sequences_type CHECK (document_type IN ('B01', 'B02', 'B04', 'E01', 'E02', 'CREDIT_NOTE'))
) ENGINE = InnoDB;

CREATE TABLE billing_documents (
    id CHAR(36) NOT NULL,
    sale_id CHAR(36) NULL,
    return_id CHAR(36) NULL,
    document_type VARCHAR(20) NOT NULL,
    document_number VARCHAR(60) NULL,
    customer_name_snapshot VARCHAR(150) NULL,
    customer_tax_id_snapshot VARCHAR(30) NULL,
    currency_code CHAR(3) NOT NULL DEFAULT 'DOP',
    subtotal_cents BIGINT UNSIGNED NOT NULL DEFAULT 0,
    tax_cents BIGINT UNSIGNED NOT NULL DEFAULT 0,
    total_cents BIGINT UNSIGNED NOT NULL DEFAULT 0,
    status VARCHAR(20) NOT NULL DEFAULT 'DRAFT',
    issued_at DATETIME(6) NULL,
    created_by_user_id CHAR(36) NOT NULL,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    UNIQUE KEY uq_billing_documents_number (document_number),
    KEY idx_billing_documents_date_type (issued_at, document_type),
    CONSTRAINT fk_billing_documents_sale FOREIGN KEY (sale_id) REFERENCES sales (id),
    CONSTRAINT fk_billing_documents_return FOREIGN KEY (return_id) REFERENCES sales_returns (id),
    CONSTRAINT fk_billing_documents_created_by FOREIGN KEY (created_by_user_id) REFERENCES users (id),
    CONSTRAINT chk_billing_documents_currency CHECK (currency_code = 'DOP'),
    CONSTRAINT chk_billing_documents_type CHECK (document_type IN ('B01', 'B02', 'B04', 'E01', 'E02', 'CREDIT_NOTE')),
    CONSTRAINT chk_billing_documents_status CHECK (status IN ('DRAFT', 'ISSUED', 'VOIDED'))
) ENGINE = InnoDB;

CREATE TABLE billing_document_lines (
    id CHAR(36) NOT NULL,
    document_id CHAR(36) NOT NULL,
    product_id CHAR(36) NULL,
    description VARCHAR(255) NOT NULL,
    quantity DECIMAL(14,3) NOT NULL DEFAULT 1,
    unit_price_cents BIGINT UNSIGNED NOT NULL,
    tax_rate_basis_points SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    tax_cents BIGINT UNSIGNED NOT NULL DEFAULT 0,
    line_total_cents BIGINT UNSIGNED NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT fk_billing_document_lines_document FOREIGN KEY (document_id) REFERENCES billing_documents (id),
    CONSTRAINT fk_billing_document_lines_product FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE SET NULL,
    CONSTRAINT chk_billing_document_lines_quantity CHECK (quantity > 0),
    CONSTRAINT chk_billing_document_lines_tax CHECK (tax_rate_basis_points <= 10000)
) ENGINE = InnoDB;

CREATE TABLE idempotency_keys (
    id CHAR(36) NOT NULL,
    scope VARCHAR(80) NOT NULL,
    idempotency_key VARCHAR(100) NOT NULL,
    request_hash CHAR(64) NOT NULL,
    response_status SMALLINT UNSIGNED NULL,
    response_body JSON NULL,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    expires_at DATETIME(6) NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uq_idempotency_scope_key (scope, idempotency_key)
) ENGINE = InnoDB;

CREATE TABLE audit_log (
    id CHAR(36) NOT NULL,
    actor_user_id CHAR(36) NULL,
    actor_role VARCHAR(50) NULL,
    action VARCHAR(100) NOT NULL,
    entity_type VARCHAR(80) NOT NULL,
    entity_id CHAR(36) NULL,
    reason VARCHAR(255) NULL,
    authorization_id CHAR(36) NULL,
    before_values JSON NULL,
    after_values JSON NULL,
    correlation_id VARCHAR(100) NULL,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    KEY idx_audit_log_entity (entity_type, entity_id, created_at),
    KEY idx_audit_log_actor_date (actor_user_id, created_at),
    CONSTRAINT fk_audit_log_actor FOREIGN KEY (actor_user_id) REFERENCES users(id),
    CONSTRAINT chk_audit_log_actor_or_system CHECK (actor_user_id IS NOT NULL OR actor_role = 'SYSTEM')
) ENGINE = InnoDB;

CREATE TABLE migration_batches (
    id CHAR(36) NOT NULL,
    source_name VARCHAR(120) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    total_records INT UNSIGNED NOT NULL DEFAULT 0,
    accepted_records INT UNSIGNED NOT NULL DEFAULT 0,
    rejected_records INT UNSIGNED NOT NULL DEFAULT 0,
    started_at DATETIME(6) NULL,
    completed_at DATETIME(6) NULL,
    approved_by_user_id CHAR(36) NULL,
    notes TEXT NULL,
    PRIMARY KEY (id),
    CONSTRAINT fk_migration_batches_approved_by FOREIGN KEY (approved_by_user_id) REFERENCES users (id) ON DELETE SET NULL,
    CONSTRAINT chk_migration_batches_status CHECK (status IN ('PENDING', 'VALIDATED', 'APPROVED', 'APPLIED', 'FAILED'))
) ENGINE = InnoDB;

CREATE TABLE backup_jobs (
    id CHAR(36) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'STARTED',
    storage_path VARCHAR(255) NULL,
    checksum CHAR(64) NULL,
    size_bytes BIGINT UNSIGNED NULL,
    started_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    completed_at DATETIME(6) NULL,
    initiated_by_user_id CHAR(36) NULL,
    error_message VARCHAR(500) NULL,
    PRIMARY KEY (id),
    KEY idx_backup_jobs_started (started_at),
    CONSTRAINT fk_backup_jobs_initiated_by FOREIGN KEY (initiated_by_user_id) REFERENCES users (id) ON DELETE SET NULL,
    CONSTRAINT chk_backup_jobs_status CHECK (status IN ('STARTED', 'COMPLETED', 'FAILED', 'RESTORED'))
) ENGINE = InnoDB;

CREATE TABLE system_settings (
    setting_key VARCHAR(100) NOT NULL,
    setting_value JSON NOT NULL,
    description VARCHAR(255) NULL,
    updated_by_user_id CHAR(36) NULL,
    updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    PRIMARY KEY (setting_key),
    CONSTRAINT fk_system_settings_updated_by FOREIGN KEY (updated_by_user_id) REFERENCES users (id) ON DELETE SET NULL
) ENGINE = InnoDB;

INSERT INTO roles (id, name, description) VALUES
    ('00000000-0000-0000-0000-000000000001', 'ADMIN', 'Propietaria administradora'),
    ('00000000-0000-0000-0000-000000000002', 'OPERATOR', 'Empleada operativa de caja');

INSERT INTO permissions (id, code, description) VALUES
    ('10000000-0000-0000-0000-000000000001', 'sales.create', 'Crear y completar ventas'),
    ('10000000-0000-0000-0000-000000000002', 'cash.operate', 'Abrir, operar y solicitar cierre de caja'),
    ('10000000-0000-0000-0000-000000000003', 'catalog.read', 'Consultar catálogo'),
    ('10000000-0000-0000-0000-000000000004', 'inventory.read', 'Consultar inventario y alertas'),
    ('10000000-0000-0000-0000-000000000005', 'catalog.manage', 'Administrar catálogo y precios'),
    ('10000000-0000-0000-0000-000000000006', 'inventory.manage', 'Administrar existencias, conteos, ajustes y mermas'),
    ('10000000-0000-0000-0000-000000000007', 'purchasing.manage', 'Administrar compras y proveedores'),
    ('10000000-0000-0000-0000-000000000008', 'credit.manage', 'Administrar clientes, crédito y abonos'),
    ('10000000-0000-0000-0000-000000000009', 'returns.approve', 'Aprobar devoluciones, anulaciones y reembolsos'),
    ('10000000-0000-0000-0000-000000000010', 'reports.read', 'Consultar reportes sensibles'),
    ('10000000-0000-0000-0000-000000000011', 'audit.read', 'Consultar auditoría'),
    ('10000000-0000-0000-0000-000000000012', 'operations.manage', 'Gestionar migraciones y respaldos');

INSERT INTO role_permissions (role_id, permission_id)
SELECT '00000000-0000-0000-0000-000000000001', id FROM permissions;

INSERT INTO role_permissions (role_id, permission_id) VALUES
    ('00000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000001'),
    ('00000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000002'),
    ('00000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000003'),
    ('00000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000004');

INSERT INTO units (id, code, name, allows_fractional) VALUES
    ('20000000-0000-0000-0000-000000000001', 'UNIT', 'Unidad', FALSE),
    ('20000000-0000-0000-0000-000000000002', 'KG', 'Kilogramo', TRUE),
    ('20000000-0000-0000-0000-000000000003', 'L', 'Litro', TRUE),
    ('20000000-0000-0000-0000-000000000004', 'PACK', 'Paquete', FALSE);

INSERT INTO cash_registers (id, code, name) VALUES
    ('30000000-0000-0000-0000-000000000001', 'MAIN', 'Caja principal');

INSERT INTO tax_policies (id, code, name, rate_basis_points, is_exempt, effective_from) VALUES
    ('40000000-0000-0000-0000-000000000001', 'EXEMPT', 'Exento', 0, TRUE, '2026-01-01');

INSERT INTO billing_sequences (id, document_type, prefix, next_number, is_active) VALUES
    ('50000000-0000-0000-0000-000000000001', 'B02', 'B0200000001', 1, TRUE),
    ('50000000-0000-0000-0000-000000000002', 'B01', 'B0100000001', 1, TRUE),
    ('50000000-0000-0000-0000-000000000003', 'CREDIT_NOTE', 'NC00000001', 1, TRUE);

INSERT INTO system_settings (setting_key, setting_value, description) VALUES
    ('currency', JSON_OBJECT('code', 'DOP', 'minor_unit', 2), 'Moneda operativa'),
    ('credit.default_term_days', JSON_OBJECT('days', 30), 'Plazo predeterminado del crédito'),
    ('returns.non_perishable_days', JSON_OBJECT('days', 7), 'Ventana operativa para devoluciones no perecederas'),
    ('inventory.expiry_alert_days', JSON_OBJECT('days', 30), 'Anticipación para alertas de vencimiento'),
    ('sales.allow_negative_stock_default', JSON_OBJECT('enabled', FALSE), 'Valor predeterminado de existencias negativas');
