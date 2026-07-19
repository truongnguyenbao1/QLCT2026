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

COMMENT ON TABLE public.caidat_thanhtoan IS 'Cài đặt thông tin thanh toán của chủ trọ (tài khoản ngân hàng, VietQR, MoMo)';

-- ── Trigger cập nhật updated_at ───────────────────────────────────────────
CREATE TRIGGER update_caidat_thanhtoan_updated_at
    BEFORE UPDATE ON public.caidat_thanhtoan
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- ── Index ─────────────────────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_caidat_thanhtoan_user ON public.caidat_thanhtoan(user_id);

-- ── Row Level Security ────────────────────────────────────────────────────
-- (Tuỳ chọn - nếu bạn dùng RLS trong Supabase)
-- ALTER TABLE public.caidat_thanhtoan ENABLE ROW LEVEL SECURITY;

-- -- Chủ trọ chỉ xem được cài đặt của chính mình
-- CREATE POLICY "owner_can_manage_own_settings" ON public.caidat_thanhtoan
--     FOR ALL
--     USING (user_id = auth.uid())
--     WITH CHECK (user_id = auth.uid());
