-- =========================================================================
-- MIGRATION 11: Fix RLS cho bảng hoadon và chitiethoadon đối với khách thuê
-- Vấn đề: Khách thuê không thấy hóa đơn vì policy cũ chỉ check bảng users, 
--         trong khi thông tin room_id có thể nằm ở bảng khachthue.
-- =========================================================================

-- 1. Cập nhật lại hàm get_tenant_room_ids() để lấy room_id từ cả bảng users và khachthue
CREATE OR REPLACE FUNCTION public.get_tenant_room_ids()
RETURNS SETOF UUID
SECURITY DEFINER
SET search_path = public
LANGUAGE sql STABLE AS $$
  SELECT room_id FROM public.users WHERE iduser = auth.uid() AND room_id IS NOT NULL
  UNION
  SELECT room_id FROM public.khachthue WHERE user_id = auth.uid() AND room_id IS NOT NULL;
$$;

-- 2. Cập nhật RLS bảng hoadon
DROP POLICY IF EXISTS "tenant_can_view_own_hoadon" ON public.hoadon;
CREATE POLICY "tenant_can_view_own_hoadon"
  ON public.hoadon FOR SELECT
  USING (
    room_id IN (
      SELECT public.get_tenant_room_ids()
    )
  );

DROP POLICY IF EXISTS "tenant_can_update_own_hoadon" ON public.hoadon;
CREATE POLICY "tenant_can_update_own_hoadon"
  ON public.hoadon FOR UPDATE
  USING (
    room_id IN (
      SELECT public.get_tenant_room_ids()
    )
  );

-- 3. Cập nhật RLS bảng chitiethoadon
DROP POLICY IF EXISTS "tenant_can_view_own_chitiethoadon" ON public.chitiethoadon;
CREATE POLICY "tenant_can_view_own_chitiethoadon"
  ON public.chitiethoadon FOR SELECT
  USING (
    invoice_id IN (
      SELECT h.id FROM public.hoadon h
      WHERE h.room_id IN (SELECT public.get_tenant_room_ids())
    )
  );

-- 4. Cập nhật RLS bảng chiso (nếu cần)
DROP POLICY IF EXISTS "tenant_can_view_own_chiso" ON public.chiso;
CREATE POLICY "tenant_can_view_own_chiso"
  ON public.chiso FOR SELECT
  USING (
    room_id IN (
      SELECT public.get_tenant_room_ids()
    )
  );
