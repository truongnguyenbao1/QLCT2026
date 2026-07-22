-- From migration_add_payment_image.sql
-- Thêm cột lưu URL ảnh giao dịch khi khách thuê xác nhận thanh toán
ALTER TABLE public.hoadon ADD COLUMN IF NOT EXISTS payment_image_url TEXT;

-- From migration_momo_qr.sql
-- =========================================================================
-- MIGRATION: Thêm chức năng tải ảnh mã QR MoMo
-- Chạy script này trong Supabase SQL Editor
-- =========================================================================

-- 1. Thêm cột momo_qr_url vào bảng caidat_thanhtoan
ALTER TABLE public.caidat_thanhtoan 
ADD COLUMN IF NOT EXISTS momo_qr_url TEXT;

-- From migration_notifications.sql
-- Cập nhật CHECK constraint cho cột status của bảng hoadon nếu cần
    ALTER TABLE public.hoadon DROP CONSTRAINT IF EXISTS hoadon_status_check;

-- From migration_notifications.sql
ALTER TABLE public.hoadon ADD CONSTRAINT hoadon_status_check CHECK (status IN ('PENDING', 'CONFIRMED_BY_TENANT', 'CONFIRMED_BY_OWNER', 'PAID', 'OVERDUE'));

-- From migration_notifications_update.sql
-- Cập nhật bảng thongbao hiện có
ALTER TABLE public.thongbao
  ADD COLUMN IF NOT EXISTS type VARCHAR(50) NOT NULL DEFAULT 'ANNOUNCEMENT' CHECK (type IN ('ANNOUNCEMENT', 'ISSUE', 'SYSTEM')),
  ADD COLUMN IF NOT EXISTS image_url TEXT;

-- From migration_payment_settings.sql
-- =========================================================================
-- MIGRATION: Thêm bảng cài đặt thanh toán (caidat_thanhtoan)
-- Chạy script này trong Supabase SQL Editor
-- =========================================================================

-- ─────────────────────────────────────────────────────────────────────────
-- BẢNG: caidat_thanhtoan (Payment Settings)
-- Lưu thông tin tài khoản ngân hàng & ví điện tử của chủ trọ
-- ─────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.caidat_thanhtoan (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id      UUID NOT NULL REFERENCES public.users(iduser) ON DELETE CASCADE,

    -- Thông tin tài khoản ngân hàng
    bank_code    VARCHAR(20),          -- Mã ngân hàng (VD: VCB, TCB, MB)
    bank_name    VARCHAR(255),         -- Tên ngân hàng đầy đủ
    account_number VARCHAR(50),        -- Số tài khoản
    account_name  VARCHAR(255),        -- Tên chủ tài khoản (IN HOA)

    -- Nội dung chuyển khoản mẫu
    transfer_note_template TEXT DEFAULT 'Phong {room} thang {month}/{year}',

    -- Ví điện tử
    momo_phone   VARCHAR(20),          -- SĐT Momo
    vnpay_qr     TEXT,                 -- Mã VNPay QR (nếu có)

    -- Metadata
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Mỗi user chỉ có 1 bộ cài đặt
    CONSTRAINT unique_payment_settings_per_user UNIQUE (user_id)
);

-- From migration_payment_settings.sql
COMMENT ON TABLE public.caidat_thanhtoan IS 'Cài đặt thông tin thanh toán của chủ trọ (tài khoản ngân hàng, VietQR, MoMo)';

-- From migration_payment_settings.sql
-- ── Index ─────────────────────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_caidat_thanhtoan_user ON public.caidat_thanhtoan(user_id);

-- From migration_split_invoice.sql
-- =========================================================================
-- MIGRATION: Split hoadon into hoadon and chitiethoadon
-- WARNING: This will drop existing data in hoadon and chitiethoadon.
-- =========================================================================

-- 1. Xóa bảng hiện tại
DROP TABLE IF EXISTS public.chitiethoadon CASCADE;

-- From migration_split_invoice.sql
DROP TABLE IF EXISTS public.hoadon CASCADE;

-- From migration_split_invoice.sql
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

-- From migration_split_invoice.sql
COMMENT ON TABLE public.hoadon IS 'Thông tin tổng quan hóa đơn tiền phòng hàng tháng';

-- From migration_split_invoice.sql
CREATE INDEX IF NOT EXISTS idx_hoadon_phong_ky ON public.hoadon(room_id, year, month);

-- From migration_split_invoice.sql
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

-- From migration_split_invoice.sql
COMMENT ON TABLE public.chitiethoadon IS 'Chi tiết các khoản phí của hóa đơn';

-- From migration_split_payment.sql
-- 2. Xóa các cột thanh toán khỏi bảng hoadon
ALTER TABLE public.hoadon
DROP COLUMN IF EXISTS paid_at,
DROP COLUMN IF EXISTS payment_method,
DROP COLUMN IF EXISTS transaction_id;