-- =========================================================================
-- MIGRATION 09: Fix RLS Infinite Recursion
-- Sửa lỗi 42P17: infinite recursion detected in policy for relation "nhatro"
-- =========================================================================

-- 1. Tạo các hàm Security Definer để bypass RLS khi tra cứu quyền hạn
-- Những hàm này chạy với quyền admin (postgres) nên sẽ không kích hoạt RLS
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


-- 2. Cập nhật RLS bảng nhatro
DROP POLICY IF EXISTS "tenant_can_view_own_nhatro" ON public.nhatro;
CREATE POLICY "tenant_can_view_own_nhatro"
  ON public.nhatro FOR SELECT
  USING (
    id IN (
      SELECT public.get_tenant_property_ids()
    )
  );

-- 3. Cập nhật RLS bảng phong
DROP POLICY IF EXISTS "owner_can_manage_own_phong" ON public.phong;
CREATE POLICY "owner_can_manage_own_phong"
  ON public.phong FOR ALL
  USING (
    property_id IN (
      SELECT public.get_owner_property_ids()
    )
  )
  WITH CHECK (
    property_id IN (
      SELECT public.get_owner_property_ids()
    )
  );

DROP POLICY IF EXISTS "tenant_can_view_own_phong" ON public.phong;
CREATE POLICY "tenant_can_view_own_phong"
  ON public.phong FOR SELECT
  USING (
    id IN (
      SELECT public.get_tenant_room_ids()
    )
  );

-- 4. Cập nhật RLS bảng khachthue
DROP POLICY IF EXISTS "owner_can_manage_own_khachthue" ON public.khachthue;
CREATE POLICY "owner_can_manage_own_khachthue"
  ON public.khachthue FOR ALL
  USING (
    property_id IN (
      SELECT public.get_owner_property_ids()
    )
  )
  WITH CHECK (
    property_id IN (
      SELECT public.get_owner_property_ids()
    )
  );

-- 5. Cập nhật RLS bảng users
DROP POLICY IF EXISTS "owner_can_view_tenant_profiles" ON public.users;
CREATE POLICY "owner_can_view_tenant_profiles"
  ON public.users FOR SELECT
  USING (
    property_id IN (
      SELECT public.get_owner_property_ids()
    )
  );
