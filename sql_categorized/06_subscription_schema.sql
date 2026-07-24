-- =========================================================================
-- MIGRATION: Multi-Tenant SaaS — Subscription & Registration Control
-- Chạy script này trong Supabase SQL Editor
-- =========================================================================

-- ─────────────────────────────────────────────────────────────────────────
-- BƯỚC 1: Thêm cột registration_status vào bảng nhatro
-- Mỗi chủ trọ đăng ký phải được bạn (super admin) duyệt thủ công
-- ─────────────────────────────────────────────────────────────────────────
ALTER TABLE public.nhatro
  ADD COLUMN IF NOT EXISTS registration_status VARCHAR(20)
    NOT NULL DEFAULT 'PENDING'
    CHECK (registration_status IN ('PENDING', 'APPROVED', 'REJECTED', 'SUSPENDED'));

COMMENT ON COLUMN public.nhatro.registration_status IS
  'Trạng thái duyệt tài khoản chủ trọ: PENDING=chờ duyệt, APPROVED=đã duyệt, REJECTED=từ chối, SUSPENDED=tạm khóa';

-- ─────────────────────────────────────────────────────────────────────────
-- BƯỚC 2: Tạo bảng subscriptions (gói đăng ký của chủ trọ)
-- ─────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.subscriptions (
  id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id             UUID NOT NULL REFERENCES public.users(iduser) ON DELETE CASCADE,
  property_id          UUID REFERENCES public.nhatro(id) ON DELETE SET NULL,

  -- Gói cước
  plan                 VARCHAR(20) NOT NULL DEFAULT 'TRIAL'
    CHECK (plan IN ('TRIAL', 'BASIC', 'STANDARD', 'PRO')),

  -- Trạng thái
  status               VARCHAR(20) NOT NULL DEFAULT 'PENDING'
    CHECK (status IN ('PENDING', 'ACTIVE', 'EXPIRED', 'SUSPENDED')),

  -- Thời gian dùng thử (7 ngày)
  trial_ends_at        TIMESTAMPTZ,

  -- Chu kỳ thanh toán hiện tại
  current_period_start TIMESTAMPTZ,
  current_period_end   TIMESTAMPTZ,

  -- Giá và giới hạn (snapshot tại thời điểm đăng ký)
  price_per_month      NUMERIC DEFAULT 0,
  max_rooms            INTEGER DEFAULT 10,

  -- Ghi chú từ admin (lý do từ chối, ghi chú khi duyệt, v.v.)
  admin_note           TEXT,

  -- Audit
  created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  -- Mỗi chủ trọ chỉ có 1 subscription hiện tại
  CONSTRAINT unique_subscription_per_owner UNIQUE (owner_id)
);

COMMENT ON TABLE public.subscriptions IS
  'Gói đăng ký dịch vụ của chủ trọ. TRIAL=dùng thử 7 ngày, BASIC=49k/th, STANDARD=99k/th, PRO=199k/th';

-- ─────────────────────────────────────────────────────────────────────────
-- BƯỚC 3: Index
-- ─────────────────────────────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_subscriptions_owner   ON public.subscriptions(owner_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_status  ON public.subscriptions(status);
CREATE INDEX IF NOT EXISTS idx_nhatro_reg_status     ON public.nhatro(registration_status);

-- ─────────────────────────────────────────────────────────────────────────
-- BƯỚC 4: RLS cho bảng subscriptions
-- ─────────────────────────────────────────────────────────────────────────
ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;

-- Chủ trọ xem subscription của chính mình
CREATE POLICY "owner_can_view_own_subscription"
  ON public.subscriptions FOR SELECT
  USING (owner_id = auth.uid());

-- Chỉ service_role (backend/admin) mới được INSERT/UPDATE/DELETE
-- (bạn thực hiện qua Supabase dashboard hoặc service key)
CREATE POLICY "service_role_manages_subscriptions"
  ON public.subscriptions FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- ─────────────────────────────────────────────────────────────────────────
-- BƯỚC 5: Trigger tự động cập nhật updated_at
-- ─────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_subscriptions_updated_at ON public.subscriptions;
CREATE TRIGGER trg_subscriptions_updated_at
  BEFORE UPDATE ON public.subscriptions
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ─────────────────────────────────────────────────────────────────────────
-- BƯỚC 6: RPC để lấy trạng thái subscription (vượt qua RLS từ app)
-- ─────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.get_owner_subscription_status(p_user_id UUID)
RETURNS TABLE(
  plan                 TEXT,
  sub_status           TEXT,
  reg_status           TEXT,
  trial_ends_at        TIMESTAMPTZ,
  current_period_end   TIMESTAMPTZ,
  max_rooms            INTEGER,
  price_per_month      NUMERIC,
  property_name        TEXT
)
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY
  SELECT
    s.plan::TEXT,
    s.status::TEXT            AS sub_status,
    n.registration_status::TEXT AS reg_status,
    s.trial_ends_at,
    s.current_period_end,
    s.max_rooms,
    s.price_per_month,
    n.name::TEXT              AS property_name
  FROM public.subscriptions s
  LEFT JOIN public.nhatro n ON s.property_id = n.id
  WHERE s.owner_id = p_user_id;
END;
$$;
