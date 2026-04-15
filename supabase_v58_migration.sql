-- ══════════════════════════════════════════════════════════════════
-- Supabase Migration: v58 (REPAIR) - Real Data Readiness
-- Logic: Granular 'IF NOT EXISTS' for every column to ensure idempotency
-- ══════════════════════════════════════════════════════════════════

-- 1. Table: invoice_lines
ALTER TABLE IF EXISTS public.invoice_lines ADD COLUMN IF NOT EXISTS item_id TEXT;
ALTER TABLE IF EXISTS public.invoice_lines ADD COLUMN IF NOT EXISTS total NUMERIC DEFAULT 0;

-- 2. Table: purchase_invoice_lines
ALTER TABLE IF EXISTS public.purchase_invoice_lines ADD COLUMN IF NOT EXISTS total NUMERIC DEFAULT 0;

-- 3. Table: leave_requests (Metadata Safety Pass - Individual checks)
DO $$ BEGIN
    IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'leave_requests') THEN
        ALTER TABLE public.leave_requests ADD COLUMN IF NOT EXISTS sync_status INTEGER DEFAULT 0;
        ALTER TABLE public.leave_requests ADD COLUMN IF NOT EXISTS device_id TEXT;
        ALTER TABLE public.leave_requests ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT now();
    END IF;
END $$;

-- 4. Table: employee_loans (Metadata Safety Pass)
DO $$ BEGIN
    IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'employee_loans') THEN
        ALTER TABLE public.employee_loans ADD COLUMN IF NOT EXISTS sync_status INTEGER DEFAULT 0;
        ALTER TABLE public.employee_loans ADD COLUMN IF NOT EXISTS device_id TEXT;
        ALTER TABLE public.employee_loans ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT now();
    END IF;
END $$;

-- 5. Add Comments for clarity
COMMENT ON COLUMN public.invoice_lines.total IS 'Calculated total (Price * Qty) stored for sync performance';
COMMENT ON COLUMN public.purchase_invoice_lines.total IS 'Calculated total (Price * Qty) stored for sync performance';
