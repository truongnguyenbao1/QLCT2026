-- =========================================================================
-- MIGRATION: Split hoadon into hoadon and chitiethoadon
-- WARNING: This will drop existing data in hoadon and chitiethoadon.
-- =========================================================================

-- 1. Xóa bảng hiện tại
DROP TABLE IF EXISTS public.chitiethoadon CASCADE;
DROP TABLE IF EXISTS public.hoadon CASCADE;

-- 2. Tạo lại bảng hoadon (Thông tin chung)
CREATE TABLE public.hoadon (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    room_id UUID NOT NULL REFERENCES public.phong(id) ON DELETE CASCADE,
    tenant_id UUID REFERENCES public.khachthue(id) ON DELETE SET NULL,
    month INTEGER NOT NULL CHECK (month BETWEEN 1 AND 12),
    year INTEGER NOT NULL CHECK (year >= 2020),
    
    total_amount NUMERIC NOT NULL DEFAULT 0,
    
    -- Thanh toán
    status VARCHAR(50) NOT NULL DEFAULT 'PENDING' CHECK (
        status IN ('PENDING', 'CONFIRMED_BY_TENANT', 'CONFIRMED_BY_OWNER', 'PAID', 'OVERDUE')
    ),
    due_date TIMESTAMPTZ NOT NULL,
    paid_at TIMESTAMPTZ,
    payment_method VARCHAR(50),
    transaction_id VARCHAR(100),
    
    -- Audit & khóa hóa đơn
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES public.users(iduser) ON DELETE SET NULL,
    is_locked BOOLEAN NOT NULL DEFAULT FALSE,
    
    CONSTRAINT unique_invoice_per_month_year UNIQUE (room_id, month, year)
);

COMMENT ON TABLE public.hoadon IS 'Thông tin tổng quan hóa đơn tiền phòng hàng tháng';

CREATE TRIGGER update_hoadon_updated_at BEFORE UPDATE ON public.hoadon
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
    
CREATE INDEX IF NOT EXISTS idx_hoadon_phong_ky ON public.hoadon(room_id, year, month);

-- 3. Tạo lại bảng chitiethoadon (Chi tiết hóa đơn)
CREATE TABLE public.chitiethoadon (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    invoice_id UUID NOT NULL UNIQUE REFERENCES public.hoadon(id) ON DELETE CASCADE,
    
    -- Chỉ số điện
    electric_prev_reading NUMERIC NOT NULL DEFAULT 0,
    electric_curr_reading NUMERIC NOT NULL DEFAULT 0,
    electric_unit_price NUMERIC NOT NULL DEFAULT 3500,
    
    -- Chỉ số nước
    water_prev_reading NUMERIC NOT NULL DEFAULT 0,
    water_curr_reading NUMERIC NOT NULL DEFAULT 0,
    water_unit_price NUMERIC NOT NULL DEFAULT 15000,
    
    -- Tiền phòng & dịch vụ cố định
    rent_amount NUMERIC NOT NULL DEFAULT 0,
    service_amount NUMERIC NOT NULL DEFAULT 0,
    
    -- Các khoản khác
    other_amount NUMERIC DEFAULT 0,
    other_description TEXT,
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE public.chitiethoadon IS 'Chi tiết các khoản phí của hóa đơn';

-- Bật RLS
ALTER TABLE public.hoadon ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chitiethoadon ENABLE ROW LEVEL SECURITY;

-- Tạo Policy cơ bản (Bạn có thể điều chỉnh lại sau nếu có RLS riêng)
CREATE POLICY "Cho phép tất cả thao tác" ON public.hoadon FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Cho phép tất cả thao tác" ON public.chitiethoadon FOR ALL USING (true) WITH CHECK (true);
