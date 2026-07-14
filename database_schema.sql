-- =========================================================================
-- CSDL QUẢN LÝ NHÀ TRỌ 2026 (Tương thích Supabase & PostgreSQL)
-- Đã chuyển đổi toàn bộ tên bảng sang tiếng Việt theo sơ đồ ERD
-- =========================================================================

-- Kích hoạt extension UUID
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ─────────────────────────────────────────────────────────────────────────
-- 1. BẢNG: nhatro (Tương ứng "properties" - Dãy trọ / Nhà trọ)
-- ─────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.nhatro (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    address VARCHAR(500),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE public.nhatro IS 'Quản lý thông tin các dãy trọ/nhà trọ';

-- ─────────────────────────────────────────────────────────────────────────
-- 2. BẢNG: phong (Tương ứng "rooms" - Phòng trọ)
-- ─────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.phong (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id UUID NOT NULL REFERENCES public.nhatro(id) ON DELETE CASCADE,
    room_number VARCHAR(50) NOT NULL,
    floor INTEGER NOT NULL DEFAULT 1,
    area NUMERIC NOT NULL DEFAULT 0,
    rent_price NUMERIC NOT NULL DEFAULT 0,
    electric_price NUMERIC NOT NULL DEFAULT 3500,
    water_price NUMERIC NOT NULL DEFAULT 15000,
    service_price NUMERIC NOT NULL DEFAULT 0,
    status VARCHAR(50) NOT NULL DEFAULT 'EMPTY' CHECK (status IN ('EMPTY', 'OCCUPIED', 'MAINTENANCE')),
    amenities TEXT[] DEFAULT '{}',
    description TEXT,
    image_urls TEXT[] DEFAULT '{}',
    max_occupants INTEGER,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Tránh trùng số phòng trong cùng một dãy trọ
    CONSTRAINT unique_room_number_per_property UNIQUE (property_id, room_number)
);

COMMENT ON TABLE public.phong IS 'Quản lý thông tin chi tiết các phòng trọ';

-- ─────────────────────────────────────────────────────────────────────────
-- 3. BẢNG: khachthue (Tương ứng "tenants" - Khách thuê)
-- ─────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.khachthue (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id UUID REFERENCES public.nhatro(id) ON DELETE SET NULL,
    room_id UUID REFERENCES public.phong(id) ON DELETE SET NULL,
    user_id UUID REFERENCES public.users(iduser) ON DELETE SET NULL,
    full_name VARCHAR(255) NOT NULL,
    phone_number VARCHAR(50) NOT NULL,
    cccd_number TEXT, -- Mã hóa đầu cuối trong Flutter App
    date_of_birth TIMESTAMPTZ,
    email VARCHAR(255),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE public.khachthue IS 'Quản lý thông tin khách thuê phòng';

-- ─────────────────────────────────────────────────────────────────────────
-- 4. BẢNG: thuephong (Tương ứng "contracts" - Hợp đồng thuê)
-- ─────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.thuephong (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES public.khachthue(id) ON DELETE CASCADE,
    room_id UUID NOT NULL REFERENCES public.phong(id) ON DELETE CASCADE,
    start_date TIMESTAMPTZ NOT NULL,
    end_date TIMESTAMPTZ NOT NULL,
    deposit_amount NUMERIC NOT NULL DEFAULT 0,
    status VARCHAR(50) NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'TERMINATED', 'EXPIRED')),
    contract_url TEXT, -- Lưu trữ trên Supabase Storage
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE public.thuephong IS 'Quản lý hợp đồng và tiền đặt cọc thuê phòng';

-- ─────────────────────────────────────────────────────────────────────────
-- 5. BẢNG: hoadon (Tương ứng "invoices" - Hóa đơn tiền phòng)
-- ─────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.hoadon (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    room_id UUID NOT NULL REFERENCES public.phong(id) ON DELETE CASCADE,
    tenant_id UUID REFERENCES public.khachthue(id) ON DELETE SET NULL,
    month INTEGER NOT NULL CHECK (month BETWEEN 1 AND 12),
    year INTEGER NOT NULL CHECK (year >= 2020),
    
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

COMMENT ON TABLE public.hoadon IS 'Hóa đơn tiền phòng hàng tháng';

-- ─────────────────────────────────────────────────────────────────────────
-- 6. BẢNG: chitiethoadon (Tương ứng "payments" - Chi tiết giao dịch thanh toán)
-- ─────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.chitiethoadon (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    invoice_id UUID NOT NULL REFERENCES public.hoadon(id) ON DELETE CASCADE,
    amount NUMERIC NOT NULL,
    payment_method VARCHAR(50) NOT NULL DEFAULT 'BANK_TRANSFER',
    transaction_id VARCHAR(100),
    paid_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE public.chitiethoadon IS 'Lịch sử chi tiết giao dịch thanh toán hóa đơn';

-- ─────────────────────────────────────────────────────────────────────────
-- 7. BẢNG: chiso (Tương ứng "meter_readings" - Ghi số điện nước)
-- ─────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.chiso (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    room_id UUID NOT NULL REFERENCES public.phong(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL CHECK (type IN ('ELECTRIC', 'WATER')),
    prev_reading NUMERIC NOT NULL DEFAULT 0,
    curr_reading NUMERIC NOT NULL DEFAULT 0,
    reading_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    unit_price NUMERIC NOT NULL DEFAULT 0,
    month INTEGER NOT NULL CHECK (month BETWEEN 1 AND 12),
    year INTEGER NOT NULL CHECK (year >= 2020),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    CONSTRAINT unique_meter_reading_per_month_year UNIQUE (room_id, type, month, year)
);

COMMENT ON TABLE public.chiso IS 'Nhật ký ghi số điện và nước theo từng tháng';

-- ─────────────────────────────────────────────────────────────────────────
-- 8. BẢNG: nhatky_hethong (Tương ứng "audit_logs" - Nhật ký hệ thống)
-- ─────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.nhatky_hethong (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.users(iduser) ON DELETE SET NULL,
    action VARCHAR(100) NOT NULL,
    table_name VARCHAR(100) NOT NULL,
    record_id VARCHAR(100) NOT NULL,
    new_value JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE public.nhatky_hethong IS 'Ghi nhận các tác vụ thay đổi dữ liệu quan trọng của hệ thống';

-- ─────────────────────────────────────────────────────────────────────────
-- 9. BẢNG: thongbao (Tương ứng "notifications" - Hệ thống thông báo)
-- ─────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.thongbao (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    room_id UUID REFERENCES public.phong(id) ON DELETE SET NULL,
    sender_id UUID REFERENCES public.users(iduser) ON DELETE SET NULL,
    receiver_id UUID REFERENCES public.users(iduser) ON DELETE SET NULL,
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'UNREAD' CHECK (status IN ('UNREAD', 'READ')),
    sent_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE public.thongbao IS 'Hệ thống thông báo giữa chủ trọ và khách thuê';

-- ─────────────────────────────────────────────────────────────────────────
-- 10. BẢNG: tailieudinhkem (Tương ứng "attachments" - Tài liệu đính kèm)
-- ─────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.tailieudinhkem (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    notification_id UUID NOT NULL REFERENCES public.thongbao(id) ON DELETE CASCADE,
    file_name VARCHAR(255) NOT NULL,
    file_url TEXT NOT NULL,
    file_size INTEGER,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE public.tailieudinhkem IS 'Các tệp tin, tài liệu đính kèm theo thông báo';

-- ─────────────────────────────────────────────────────────────────────────
-- 11. BẢNG: thuchi (Tương ứng "revenue_records" - Sổ thu chi)
-- ─────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.thuchi (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.users(iduser) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL CHECK (type IN ('INCOME', 'EXPENSE')),
    category VARCHAR(100),
    amount NUMERIC NOT NULL DEFAULT 0,
    description TEXT,
    transaction_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE public.thuchi IS 'Sổ nhật ký thu chi nội bộ của chủ nhà trọ';


-- =========================================================================
-- TRIGGERS & FUNCTIONS CẬP NHẬT TỰ ĐỘNG "updated_at"
-- =========================================================================

CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_nhatro_updated_at BEFORE UPDATE ON public.nhatro
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_phong_updated_at BEFORE UPDATE ON public.phong
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_khachthue_updated_at BEFORE UPDATE ON public.khachthue
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_thuephong_updated_at BEFORE UPDATE ON public.thuephong
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_hoadon_updated_at BEFORE UPDATE ON public.hoadon
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


-- =========================================================================
-- CHỈ MỤC (INDEX) TỐI ƯU HÓA TRUY VẤN
-- =========================================================================
CREATE INDEX IF NOT EXISTS idx_phong_nhatro ON public.phong(property_id);
CREATE INDEX IF NOT EXISTS idx_khachthue_nhatro_phong ON public.khachthue(property_id, room_id);
CREATE INDEX IF NOT EXISTS idx_thuephong_khach_phong ON public.thuephong(tenant_id, room_id);
CREATE INDEX IF NOT EXISTS idx_hoadon_phong_ky ON public.hoadon(room_id, year, month);
CREATE INDEX IF NOT EXISTS idx_chiso_phong ON public.chiso(room_id, year, month);
CREATE INDEX IF NOT EXISTS idx_thongbao_nguoinhan ON public.thongbao(receiver_id, status);
CREATE INDEX IF NOT EXISTS idx_thuchi_user ON public.thuchi(user_id, type);
