-- ══════════════════════════════════════════════════════════════════
-- HISABATI ERP - SYNC REPAIR SCRIPT (REMOTE) - v2 (SAFE)
-- Run this in your Supabase SQL Editor to fix synchronization errors.
-- ══════════════════════════════════════════════════════════════════

-- 1. Create a function to automatically maintain 'updated_at' timestamps
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 2. Repair Core Tables (Adding missing columns safely)
DO $$
DECLARE
    t text;
    tables_to_repair text[] := ARRAY[
        'companies', 'clients', 'items', 'invoices', 'invoice_lines',
        'purchase_invoices', 'purchase_invoice_lines', 'journal_entries',
        'journal_entry_lines', 'accounts', 'employees', 'salary_payments',
        'salary_slips', 'attendance_logs', 'leave_requests', 'employee_loans',
        'suppliers', 'payments', 'cost_centers', 'projects', 'budgets',
        'assets', 'asset_depreciation_logs', 'warehouses', 'inventory_batches',
        'inventory_transfers', 'bom', 'bom_lines', 'manufacturing_orders',
        'cheques', 'financial_custodies', 'asset_custody_logs', 'money_transfers',
        'real_estate_units', 'real_estate_contracts', 'investments',
        'investment_transactions', 'sales_targets', 'commissions',
        'job_applications', 'system_users', 'security_audit',
        'performance_reviews', 'employee_contracts'
    ];
BEGIN
    FOREACH t IN ARRAY tables_to_repair
    LOOP
        -- Safety: Check if table exists before proceeding
        IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = t) THEN
            
            -- Add updated_at if missing
            IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = t AND column_name = 'updated_at') THEN
                EXECUTE format('ALTER TABLE %I ADD COLUMN updated_at TIMESTAMPTZ DEFAULT NOW()', t);
            END IF;

            -- Add device_id if missing
            IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = t AND column_name = 'device_id') THEN
                EXECUTE format('ALTER TABLE %I ADD COLUMN device_id TEXT', t);
            END IF;

            -- Create/Replace Trigger
            EXECUTE format('DROP TRIGGER IF EXISTS tr_set_updated_at ON %I', t);
            EXECUTE format('CREATE TRIGGER tr_set_updated_at BEFORE UPDATE ON %I FOR EACH ROW EXECUTE FUNCTION set_updated_at()', t);
            
            RAISE NOTICE 'Repaired table: %', t;
        ELSE
            -- Just skip if table doesn't exist yet
            RAISE NOTICE 'Table % does not exist in remote Supabase yet, skipping repair.', t;
        END IF;
    END LOOP;
END;
$$;

-- 3. Verify specific problematic tables
SELECT table_name, column_name, data_type 
FROM information_schema.columns 
WHERE table_name IN ('companies', 'clients', 'invoices') 
AND column_name = 'updated_at';
