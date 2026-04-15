-- ==============================================================================
-- 🚀 نظام حساباتي ERP — ملف تهيئة سحابة Supabase (النسخة 54 المحدثة)
-- انسخ هذا الكود بالكامل وضعه في SQL Editor داخل Supabase ثم اضغط "Run"
-- ==============================================================================

-- 0. التهيئة الأساسية
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. الشركات (Companies)
CREATE TABLE IF NOT EXISTS public.companies (
    id TEXT PRIMARY KEY,
    name TEXT,
    industry_type TEXT,
    cr_number TEXT,
    vat_number TEXT,
    address TEXT,
    currency TEXT,
    country TEXT,
    tax_rate REAL,
    logo_path TEXT,
    letterhead_path TEXT,
    closing_date TEXT,
    device_id TEXT,
    updated_at TEXT,
    is_deleted INTEGER DEFAULT 0
);

-- 2. العملاء (Clients)
CREATE TABLE IF NOT EXISTS public.clients (
    id TEXT PRIMARY KEY,
    name TEXT,
    cr_number TEXT,
    tax_id TEXT,
    address TEXT,
    user_id TEXT,
    device_id TEXT,
    updated_at TEXT,
    is_deleted INTEGER DEFAULT 0
);

-- 3. المنتجات والخدمات (Items)
CREATE TABLE IF NOT EXISTS public.items (
    id TEXT PRIMARY KEY,
    name TEXT,
    industry_type TEXT,
    base_price REAL,
    cost_price REAL DEFAULT 0,
    tax_type TEXT,
    quantity REAL DEFAULT 0,
    sku TEXT,
    barcode TEXT,
    min_stock_level REAL DEFAULT 0,
    lead_time INTEGER DEFAULT 3,
    user_id TEXT,
    device_id TEXT,
    updated_at TEXT,
    is_deleted INTEGER DEFAULT 0
);

-- 4. الفواتير (Invoices)
CREATE TABLE IF NOT EXISTS public.invoices (
    id TEXT PRIMARY KEY,
    issue_date TEXT,
    client_id TEXT,
    subtotal REAL,
    tax_amount REAL,
    total REAL,
    status TEXT,
    payment_type TEXT DEFAULT 'cash',
    due_date TEXT,
    user_id TEXT,
    project_id TEXT,
    shift_id TEXT,
    is_return INTEGER DEFAULT 0,
    attachment_path TEXT,
    sales_agent_id TEXT,
    device_id TEXT,
    updated_at TEXT,
    is_deleted INTEGER DEFAULT 0
);

CREATE TABLE IF NOT EXISTS public.invoice_lines (
    id TEXT PRIMARY KEY,
    invoice_id TEXT,
    name TEXT,
    quantity REAL,
    price_at_sale REAL,
    device_id TEXT,
    updated_at TEXT,
    is_deleted INTEGER DEFAULT 0
);

-- 5. المشتريات والموردين (Purchases & Suppliers)
CREATE TABLE IF NOT EXISTS public.suppliers (
    id TEXT PRIMARY KEY,
    name TEXT,
    contact_info TEXT,
    tax_id TEXT,
    balance REAL DEFAULT 0,
    device_id TEXT,
    updated_at TEXT,
    is_deleted INTEGER DEFAULT 0
);

CREATE TABLE IF NOT EXISTS public.purchase_invoices (
    id TEXT PRIMARY KEY,
    issue_date TEXT,
    supplier_id TEXT,
    subtotal REAL,
    tax_amount REAL,
    total REAL,
    payment_type TEXT DEFAULT 'credit',
    project_id TEXT,
    due_date TEXT,
    cost_center_id TEXT,
    is_return INTEGER DEFAULT 0,
    attachment_path TEXT,
    device_id TEXT,
    updated_at TEXT,
    is_deleted INTEGER DEFAULT 0
);

CREATE TABLE IF NOT EXISTS public.purchase_invoice_lines (
    id TEXT PRIMARY KEY,
    invoice_id TEXT,
    item_id TEXT,
    name TEXT,
    quantity REAL,
    price_at_purchase REAL,
    device_id TEXT,
    updated_at TEXT,
    is_deleted INTEGER DEFAULT 0
);

-- 6. القيود اليومية والحسابات (Journal & Accounts)
CREATE TABLE IF NOT EXISTS public.accounts (
    id TEXT PRIMARY KEY,
    code TEXT,
    name TEXT,
    type TEXT,
    balance REAL DEFAULT 0,
    parent_id TEXT,
    device_id TEXT,
    updated_at TEXT,
    is_deleted INTEGER DEFAULT 0
);

CREATE TABLE IF NOT EXISTS public.journal_entries (
    id TEXT PRIMARY KEY,
    date TEXT,
    description TEXT,
    reference_id TEXT,
    attachment_path TEXT,
    device_id TEXT,
    updated_at TEXT,
    is_deleted INTEGER DEFAULT 0
);

CREATE TABLE IF NOT EXISTS public.journal_entry_lines (
    id TEXT PRIMARY KEY,
    entry_id TEXT,
    account_id TEXT,
    debit REAL DEFAULT 0,
    credit REAL DEFAULT 0,
    project_id TEXT,
    cost_center_id TEXT,
    device_id TEXT,
    updated_at TEXT,
    is_deleted INTEGER DEFAULT 0
);

-- 7. الموارد البشرية (HR)
CREATE TABLE IF NOT EXISTS public.employees (
    id TEXT PRIMARY KEY,
    name TEXT,
    job_title TEXT,
    basic_salary REAL,
    hiring_date TEXT,
    manager_id TEXT,
    department TEXT,
    device_id TEXT,
    updated_at TEXT,
    is_deleted INTEGER DEFAULT 0
);

CREATE TABLE IF NOT EXISTS public.salary_payments (
    id TEXT PRIMARY KEY,
    employee_id TEXT,
    pay_period TEXT,
    amount REAL,
    payment_date TEXT,
    project_id TEXT,
    device_id TEXT,
    updated_at TEXT,
    is_deleted INTEGER DEFAULT 0
);

CREATE TABLE IF NOT EXISTS public.salary_slips (
    id TEXT PRIMARY KEY,
    employee_id TEXT,
    month TEXT,
    basic_salary REAL,
    net_salary REAL,
    payment_status TEXT DEFAULT 'draft',
    cost_center_id TEXT,
    device_id TEXT,
    updated_at TEXT,
    is_deleted INTEGER DEFAULT 0
);

-- 8. المخزون (Inventory)
CREATE TABLE IF NOT EXISTS public.warehouses (
    id TEXT PRIMARY KEY,
    name TEXT,
    location TEXT,
    cost_center_id TEXT,
    device_id TEXT,
    updated_at TEXT,
    is_deleted INTEGER DEFAULT 0
);

CREATE TABLE IF NOT EXISTS public.inventory_batches (
    id TEXT PRIMARY KEY,
    item_id TEXT,
    warehouse_id TEXT,
    quantity REAL DEFAULT 0,
    expiry_date TEXT,
    batch_number TEXT,
    device_id TEXT,
    updated_at TEXT,
    is_deleted INTEGER DEFAULT 0
);

-- 9. الأصول (Assets)
CREATE TABLE IF NOT EXISTS public.assets (
    id TEXT PRIMARY KEY,
    name TEXT,
    barcode TEXT,
    cost_price REAL DEFAULT 0,
    status TEXT,
    device_id TEXT,
    updated_at TEXT,
    is_deleted INTEGER DEFAULT 0
);

-- 10. النظام والأمان (System & Security)
CREATE TABLE IF NOT EXISTS public.system_users (
    id TEXT PRIMARY KEY,
    name TEXT,
    email TEXT,
    role TEXT DEFAULT 'employee',
    device_id TEXT,
    updated_at TEXT,
    is_deleted INTEGER DEFAULT 0
);

CREATE TABLE IF NOT EXISTS public.security_audit (
    id TEXT PRIMARY KEY,
    action_type TEXT,
    description TEXT,
    is_critical INTEGER DEFAULT 0,
    device_id TEXT,
    updated_at TEXT,
    is_deleted INTEGER DEFAULT 0
);

-- 11. جداول أخرى للمزامنة
CREATE TABLE IF NOT EXISTS public.cost_centers (id TEXT PRIMARY KEY, name TEXT, code TEXT, budget REAL, device_id TEXT, updated_at TEXT, is_deleted INTEGER DEFAULT 0);
CREATE TABLE IF NOT EXISTS public.projects (id TEXT PRIMARY KEY, name TEXT, budget REAL, status TEXT, device_id TEXT, updated_at TEXT, is_deleted INTEGER DEFAULT 0);
CREATE TABLE IF NOT EXISTS public.budgets (id TEXT PRIMARY KEY, account_id TEXT, period TEXT, budget_amount REAL, device_id TEXT, updated_at TEXT, is_deleted INTEGER DEFAULT 0);
CREATE TABLE IF NOT EXISTS public.cheques (id TEXT PRIMARY KEY, number TEXT, bank TEXT, amount REAL, due_date TEXT, device_id TEXT, updated_at TEXT, is_deleted INTEGER DEFAULT 0);
CREATE TABLE IF NOT EXISTS public.financial_custodies (id TEXT PRIMARY KEY, employee_id TEXT, amount REAL, status TEXT, device_id TEXT, updated_at TEXT, is_deleted INTEGER DEFAULT 0);
CREATE TABLE IF NOT EXISTS public.real_estate_units (id TEXT PRIMARY KEY, name TEXT, rent_amount REAL, status TEXT, device_id TEXT, updated_at TEXT, is_deleted INTEGER DEFAULT 0);
CREATE TABLE IF NOT EXISTS public.real_estate_contracts (id TEXT PRIMARY KEY, tenant_name TEXT, annual_rent REAL, status TEXT, device_id TEXT, updated_at TEXT, is_deleted INTEGER DEFAULT 0);
CREATE TABLE IF NOT EXISTS public.investments (id TEXT PRIMARY KEY, name TEXT, current_value REAL, risk_level TEXT, status TEXT, device_id TEXT, updated_at TEXT, is_deleted INTEGER DEFAULT 0);

-- ==============================================================================
-- إعطاء الصلاحيات للجميع للمزامنة السلسة
-- ==============================================================================
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO anon;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO authenticated;

-- تعطيل RLS لضمان استقرار المزامنة في هذه المرحلة
DO $$ DECLARE r RECORD; BEGIN FOR r IN (SELECT tablename FROM pg_tables WHERE schemaname = 'public') LOOP EXECUTE 'ALTER TABLE public.' || quote_ident(r.tablename) || ' DISABLE ROW LEVEL SECURITY;'; END LOOP; END $$;
