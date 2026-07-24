-- =========================================================================
-- MIGRATION: Multi-Tenant RLS — Cô lập dữ liệu giữa các chủ trọ
-- Sau khi chạy: Admin A KHÔNG thể xem dữ liệu của Admin B
-- =========================================================================

-- ─────────────────────────────────────────────────────────────────────────
-- HELPER FUNCTIONS: Security Definer để bypass RLS, chống infinite recursion
-- ─────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.get_owner_property_ids()
RETURNS SETOF UUID
SECURITY DEFINER
SET search_path = public
LANGUAGE sql STABLE AS $$
  SELECT id FROM public.nhatro WHERE iduser = auth.uid();
$$;

CREATE OR REPLACE FUNCTION public.get_tenant_property_ids()
RETURNS SETOF UUID
SECURITY DEFINER
SET search_path = public
LANGUAGE sql STABLE AS $$
  SELECT property_id FROM public.users WHERE iduser = auth.uid() AND property_id IS NOT NULL;
$$;

CREATE OR REPLACE FUNCTION public.get_tenant_room_ids()
RETURNS SETOF UUID
SECURITY DEFINER
SET search_path = public
LANGUAGE sql STABLE AS $$
  SELECT room_id FROM public.users WHERE iduser = auth.uid() AND room_id IS NOT NULL;
$$;

-- ─────────────────────────────────────────────────────────────────────────
-- BẢNG: nhatro
-- ─────────────────────────────────────────────────────────────────────────
ALTER TABLE public.nhatro ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "owner_can_manage_own_nhatro" ON public.nhatro;
DROP POLICY IF EXISTS "tenant_can_view_own_nhatro" ON public.nhatro;

-- Chủ trọ quản lý nhà trọ của mình
CREATE POLICY "owner_can_manage_own_nhatro"
  ON public.nhatro FOR ALL
  USING (iduser = auth.uid())
  WITH CHECK (iduser = auth.uid());

-- Khách thuê xem được nhà trọ họ đang ở
CREATE POLICY "tenant_can_view_own_nhatro"
  ON public.nhatro FOR SELECT
  USING (
    id IN (
      SELECT property_id FROM public.users WHERE iduser = auth.uid()
    )
  );

-- ─────────────────────────────────────────────────────────────────────────
-- BẢNG: phong
-- ─────────────────────────────────────────────────────────────────────────
ALTER TABLE public.phong ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "owner_can_manage_own_phong" ON public.phong;
DROP POLICY IF EXISTS "tenant_can_view_own_phong" ON public.phong;

-- Chủ trọ CRUD phòng thuộc nhà trọ của mình
CREATE POLICY "owner_can_manage_own_phong"
  ON public.phong FOR ALL
  USING (
    property_id IN (
      SELECT id FROM public.nhatro WHERE iduser = auth.uid()
    )
  )
  WITH CHECK (
    property_id IN (
      SELECT id FROM public.nhatro WHERE iduser = auth.uid()
    )
  );

-- Khách thuê chỉ xem phòng họ đang thuê
CREATE POLICY "tenant_can_view_own_phong"
  ON public.phong FOR SELECT
  USING (
    id IN (
      SELECT room_id FROM public.users WHERE iduser = auth.uid() AND room_id IS NOT NULL
    )
  );

-- ─────────────────────────────────────────────────────────────────────────
-- BẢNG: khachthue
-- ─────────────────────────────────────────────────────────────────────────
ALTER TABLE public.khachthue ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "owner_can_manage_own_khachthue" ON public.khachthue;
DROP POLICY IF EXISTS "tenant_can_view_own_record" ON public.khachthue;

-- Chủ trọ CRUD khách thuê thuộc nhà trọ của mình
CREATE POLICY "owner_can_manage_own_khachthue"
  ON public.khachthue FOR ALL
  USING (
    property_id IN (
      SELECT id FROM public.nhatro WHERE iduser = auth.uid()
    )
  )
  WITH CHECK (
    property_id IN (
      SELECT id FROM public.nhatro WHERE iduser = auth.uid()
    )
  );

-- Khách thuê xem hồ sơ của chính mình
CREATE POLICY "tenant_can_view_own_record"
  ON public.khachthue FOR SELECT
  USING (user_id = auth.uid());

-- ─────────────────────────────────────────────────────────────────────────
-- BẢNG: thuephong (hợp đồng thuê)
-- ─────────────────────────────────────────────────────────────────────────
ALTER TABLE public.thuephong ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "owner_can_manage_own_thuephong" ON public.thuephong;
DROP POLICY IF EXISTS "tenant_can_view_own_contract" ON public.thuephong;

CREATE POLICY "owner_can_manage_own_thuephong"
  ON public.thuephong FOR ALL
  USING (
    room_id IN (
      SELECT p.id FROM public.phong p
      JOIN public.nhatro n ON p.property_id = n.id
      WHERE n.iduser = auth.uid()
    )
  )
  WITH CHECK (
    room_id IN (
      SELECT p.id FROM public.phong p
      JOIN public.nhatro n ON p.property_id = n.id
      WHERE n.iduser = auth.uid()
    )
  );

CREATE POLICY "tenant_can_view_own_contract"
  ON public.thuephong FOR SELECT
  USING (
    tenant_id IN (
      SELECT id FROM public.khachthue WHERE user_id = auth.uid()
    )
  );

-- ─────────────────────────────────────────────────────────────────────────
-- BẢNG: hoadon — XÓA policy cũ USING(true)
-- ─────────────────────────────────────────────────────────────────────────
ALTER TABLE public.hoadon ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Cho phép tất cả thao tác" ON public.hoadon;
DROP POLICY IF EXISTS "owner_can_manage_own_hoadon" ON public.hoadon;
DROP POLICY IF EXISTS "tenant_can_view_own_hoadon" ON public.hoadon;
DROP POLICY IF EXISTS "tenant_can_update_own_hoadon" ON public.hoadon;

-- Chủ trọ CRUD hóa đơn thuộc nhà trọ của mình
CREATE POLICY "owner_can_manage_own_hoadon"
  ON public.hoadon FOR ALL
  USING (
    room_id IN (
      SELECT p.id FROM public.phong p
      JOIN public.nhatro n ON p.property_id = n.id
      WHERE n.iduser = auth.uid()
    )
  )
  WITH CHECK (
    room_id IN (
      SELECT p.id FROM public.phong p
      JOIN public.nhatro n ON p.property_id = n.id
      WHERE n.iduser = auth.uid()
    )
  );

-- Khách thuê xem hóa đơn phòng mình
CREATE POLICY "tenant_can_view_own_hoadon"
  ON public.hoadon FOR SELECT
  USING (
    room_id IN (
      SELECT room_id FROM public.users WHERE iduser = auth.uid() AND room_id IS NOT NULL
    )
  );

-- Khách thuê cập nhật trạng thái thanh toán (xác nhận đã trả)
CREATE POLICY "tenant_can_update_own_hoadon"
  ON public.hoadon FOR UPDATE
  USING (
    room_id IN (
      SELECT room_id FROM public.users WHERE iduser = auth.uid() AND room_id IS NOT NULL
    )
  );

-- ─────────────────────────────────────────────────────────────────────────
-- BẢNG: chitiethoadon — XÓA policy cũ USING(true)
-- ─────────────────────────────────────────────────────────────────────────
ALTER TABLE public.chitiethoadon ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Cho phép tất cả thao tác" ON public.chitiethoadon;
DROP POLICY IF EXISTS "Enable read access for all authenticated users" ON public.chitiethoadon;
DROP POLICY IF EXISTS "Enable insert access for all authenticated users" ON public.chitiethoadon;
DROP POLICY IF EXISTS "Enable update access for all authenticated users" ON public.chitiethoadon;
DROP POLICY IF EXISTS "Enable delete access for all authenticated users" ON public.chitiethoadon;
DROP POLICY IF EXISTS "owner_can_manage_own_chitiethoadon" ON public.chitiethoadon;
DROP POLICY IF EXISTS "tenant_can_view_own_chitiethoadon" ON public.chitiethoadon;

CREATE POLICY "owner_can_manage_own_chitiethoadon"
  ON public.chitiethoadon FOR ALL
  USING (
    invoice_id IN (
      SELECT h.id FROM public.hoadon h
      JOIN public.phong p ON h.room_id = p.id
      JOIN public.nhatro n ON p.property_id = n.id
      WHERE n.iduser = auth.uid()
    )
  )
  WITH CHECK (
    invoice_id IN (
      SELECT h.id FROM public.hoadon h
      JOIN public.phong p ON h.room_id = p.id
      JOIN public.nhatro n ON p.property_id = n.id
      WHERE n.iduser = auth.uid()
    )
  );

CREATE POLICY "tenant_can_view_own_chitiethoadon"
  ON public.chitiethoadon FOR SELECT
  USING (
    invoice_id IN (
      SELECT h.id FROM public.hoadon h
      JOIN public.users u ON h.room_id = u.room_id
      WHERE u.iduser = auth.uid()
    )
  );

-- ─────────────────────────────────────────────────────────────────────────
-- BẢNG: chiso (chỉ số điện nước)
-- ─────────────────────────────────────────────────────────────────────────
ALTER TABLE public.chiso ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "owner_can_manage_own_chiso" ON public.chiso;
DROP POLICY IF EXISTS "tenant_can_view_own_chiso" ON public.chiso;

CREATE POLICY "owner_can_manage_own_chiso"
  ON public.chiso FOR ALL
  USING (
    room_id IN (
      SELECT p.id FROM public.phong p
      JOIN public.nhatro n ON p.property_id = n.id
      WHERE n.iduser = auth.uid()
    )
  )
  WITH CHECK (
    room_id IN (
      SELECT p.id FROM public.phong p
      JOIN public.nhatro n ON p.property_id = n.id
      WHERE n.iduser = auth.uid()
    )
  );

CREATE POLICY "tenant_can_view_own_chiso"
  ON public.chiso FOR SELECT
  USING (
    room_id IN (
      SELECT room_id FROM public.users WHERE iduser = auth.uid() AND room_id IS NOT NULL
    )
  );

-- ─────────────────────────────────────────────────────────────────────────
-- BẢNG: thuchi (thu chi tài chính)
-- ─────────────────────────────────────────────────────────────────────────
ALTER TABLE public.thuchi ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "owner_can_manage_own_thuchi" ON public.thuchi;

-- Chỉ chủ trọ thấy giao dịch của mình
CREATE POLICY "owner_can_manage_own_thuchi"
  ON public.thuchi FOR ALL
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- ─────────────────────────────────────────────────────────────────────────
-- BẢNG: nhatky_hethong (system log)
-- ─────────────────────────────────────────────────────────────────────────
ALTER TABLE public.nhatky_hethong ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "owner_can_view_own_logs" ON public.nhatky_hethong;

CREATE POLICY "owner_can_view_own_logs"
  ON public.nhatky_hethong FOR ALL
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- ─────────────────────────────────────────────────────────────────────────
-- BẢNG: users — Chỉ cập nhật profile của chính mình
-- ─────────────────────────────────────────────────────────────────────────
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "user_can_view_own_profile" ON public.users;
DROP POLICY IF EXISTS "user_can_update_own_profile" ON public.users;
DROP POLICY IF EXISTS "owner_can_view_tenant_profiles" ON public.users;
DROP POLICY IF EXISTS "service_role_can_insert_users" ON public.users;

-- Mọi user xem profile của chính mình
CREATE POLICY "user_can_view_own_profile"
  ON public.users FOR SELECT
  USING (iduser = auth.uid());

-- Chủ trọ xem profile khách thuê trong nhà trọ của mình
CREATE POLICY "owner_can_view_tenant_profiles"
  ON public.users FOR SELECT
  USING (
    property_id IN (
      SELECT id FROM public.nhatro WHERE iduser = auth.uid()
    )
  );

-- User cập nhật profile của chính mình
CREATE POLICY "user_can_update_own_profile"
  ON public.users FOR UPDATE
  USING (iduser = auth.uid())
  WITH CHECK (iduser = auth.uid());

-- Trigger handle_new_user cần INSERT → dùng service_role
CREATE POLICY "service_role_can_insert_users"
  ON public.users FOR INSERT
  TO service_role
  WITH CHECK (true);

-- ─────────────────────────────────────────────────────────────────────────
-- KIỂM TRA: Test xem policy đã đúng chưa
-- (Uncomment để chạy thủ công, KHÔNG để trong migration production)
-- ─────────────────────────────────────────────────────────────────────────
-- SELECT tablename, policyname, cmd, qual
-- FROM pg_policies
-- WHERE schemaname = 'public'
-- ORDER BY tablename, policyname;
