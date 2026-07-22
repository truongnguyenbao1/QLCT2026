-- From migration_fix_rls_thongbao.sql
-- Kích hoạt RLS cho bảng thongbao
ALTER TABLE public.thongbao ENABLE ROW LEVEL SECURITY;

-- From migration_fix_rls_thongbao.sql
-- Xóa các policy cũ nếu có
DROP POLICY IF EXISTS "Cho phép người dùng xem thông báo liên quan" ON public.thongbao;

-- From migration_fix_rls_thongbao.sql
DROP POLICY IF EXISTS "Cho phép tạo thông báo" ON public.thongbao;

-- From migration_fix_rls_thongbao.sql
DROP POLICY IF EXISTS "Cho phép cập nhật thông báo" ON public.thongbao;

-- From migration_fix_rls_thongbao.sql
DROP POLICY IF EXISTS "Cho phép xóa thông báo" ON public.thongbao;

-- From migration_fix_rls_thongbao.sql
DROP POLICY IF EXISTS "Enable read access for all authenticated users" ON public.thongbao;

-- From migration_fix_rls_thongbao.sql
DROP POLICY IF EXISTS "Enable insert access for all authenticated users" ON public.thongbao;

-- From migration_fix_rls_thongbao.sql
DROP POLICY IF EXISTS "Enable update access for all authenticated users" ON public.thongbao;

-- From migration_fix_rls_thongbao.sql
DROP POLICY IF EXISTS "Enable delete access for all authenticated users" ON public.thongbao;

-- From migration_fix_rls_thongbao.sql
-- 1. Policy cho phép XEM (SELECT) thông báo
CREATE POLICY "Cho phép người dùng xem thông báo liên quan"
ON public.thongbao
FOR SELECT
USING (
    -- Là người gửi
    auth.uid() = sender_id
    
    -- Hoặc là người nhận trực tiếp
    OR auth.uid() = receiver_id
    
    -- Hoặc liên quan đến phòng
    OR (
        room_id IS NOT NULL AND (
            -- Là khách thuê của phòng đó
            EXISTS (
                SELECT 1 FROM public.users 
                WHERE users.iduser = auth.uid() AND users.room_id = thongbao.room_id
            )
            -- Hoặc có trong bảng khachthue
            OR EXISTS (
                SELECT 1 FROM public.khachthue
                WHERE khachthue.user_id = auth.uid() AND khachthue.room_id = thongbao.room_id
            )
            -- Hoặc là chủ trọ của phòng đó
            OR EXISTS (
                SELECT 1 FROM public.phong 
                JOIN public.nhatro ON phong.property_id = nhatro.id
                WHERE phong.id = thongbao.room_id AND nhatro.iduser = auth.uid()
            )
        )
    )
    
    -- Hoặc là thông báo chung (hệ thống hoặc chủ trọ gửi cho tất cả phòng)
    OR (
        room_id IS NULL AND receiver_id IS NULL AND (
            -- Người gửi là chủ trọ của khách thuê đang xem
            EXISTS (
                SELECT 1 FROM public.users u
                JOIN public.phong p ON u.room_id = p.id
                JOIN public.nhatro n ON p.property_id = n.id
                WHERE u.iduser = auth.uid() AND n.iduser = thongbao.sender_id
            )
            OR EXISTS (
                SELECT 1 FROM public.khachthue k
                JOIN public.phong p ON k.room_id = p.id
                JOIN public.nhatro n ON p.property_id = n.id
                WHERE k.user_id = auth.uid() AND n.iduser = thongbao.sender_id
            )
        )
    )
);

-- From migration_fix_rls_thongbao.sql
-- 2. Policy cho phép TẠO (INSERT) thông báo
CREATE POLICY "Cho phép tạo thông báo"
ON public.thongbao
FOR INSERT
WITH CHECK (
    auth.uid() = sender_id
);

-- From migration_fix_rls_thongbao.sql
-- 3. Policy cho phép CẬP NHẬT (UPDATE) thông báo (ví dụ: đổi status sang đã đọc/đã giải quyết)
CREATE POLICY "Cho phép cập nhật thông báo"
ON public.thongbao
FOR UPDATE
USING (
    auth.uid() = sender_id OR auth.uid() = receiver_id OR 
    (
        room_id IS NOT NULL AND EXISTS (
            SELECT 1 FROM public.phong 
            JOIN public.nhatro ON phong.property_id = nhatro.id
            WHERE phong.id = thongbao.room_id AND nhatro.iduser = auth.uid()
        )
    )
);

-- From migration_fix_rls_thongbao.sql
-- 4. Policy cho phép XÓA (DELETE) thông báo
CREATE POLICY "Cho phép xóa thông báo"
ON public.thongbao
FOR DELETE
USING (
    auth.uid() = sender_id
);

-- From migration_momo_qr.sql
-- 3. Tạo chính sách RLS cho Storage Bucket
-- Cho phép mọi người (cả khách thuê chưa đăng nhập hoặc đã đăng nhập) có thể XEM ảnh
CREATE POLICY "anyone_can_read_payment_qrs"
ON storage.objects FOR SELECT
USING (bucket_id = 'payment_qrs');

-- From migration_momo_qr.sql
-- Cho phép người dùng đã đăng nhập có thể UPLOAD (Tạo mới)
CREATE POLICY "authenticated_can_insert_payment_qrs"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'payment_qrs');

-- From migration_momo_qr.sql
-- Cho phép người dùng cập nhật/xóa ảnh của chính họ
CREATE POLICY "owner_can_update_delete_payment_qrs"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'payment_qrs');

-- From migration_momo_qr.sql
CREATE POLICY "owner_can_delete_payment_qrs"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'payment_qrs');

-- From migration_notifications_update.sql
-- Policies cho bucket attachments
CREATE POLICY "Cho phép mọi người xem ảnh đính kèm" 
  ON storage.objects FOR SELECT 
  USING ( bucket_id = 'attachments' );

-- From migration_notifications_update.sql
CREATE POLICY "Cho phép user đăng nhập upload ảnh đính kèm" 
  ON storage.objects FOR INSERT 
  WITH CHECK ( bucket_id = 'attachments' AND auth.role() = 'authenticated' );

-- From migration_notifications_update.sql
CREATE POLICY "Cho phép user xóa ảnh của mình" 
  ON storage.objects FOR DELETE 
  USING ( bucket_id = 'attachments' AND auth.uid() = owner );

-- From migration_payment_settings.sql
-- ── Row Level Security ────────────────────────────────────────────────────
-- (Bắt buộc nếu bạn đã bật RLS trong Supabase)
ALTER TABLE public.caidat_thanhtoan ENABLE ROW LEVEL SECURITY;

-- From migration_payment_settings.sql
-- Chủ trọ được toàn quyền thao tác trên dữ liệu của chính mình
CREATE POLICY "owner_can_manage_own_settings" ON public.caidat_thanhtoan
    FOR ALL
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- From migration_payment_settings.sql
-- Cho phép tất cả người dùng (khách thuê) đọc thông tin thanh toán
CREATE POLICY "anyone_can_read_settings" ON public.caidat_thanhtoan
    FOR SELECT
    USING (true);

-- From migration_split_invoice.sql
-- Bật RLS
ALTER TABLE public.hoadon ENABLE ROW LEVEL SECURITY;

-- From migration_split_invoice.sql
ALTER TABLE public.chitiethoadon ENABLE ROW LEVEL SECURITY;

-- From migration_split_invoice.sql
-- Tạo Policy cơ bản (Bạn có thể điều chỉnh lại sau nếu có RLS riêng)
CREATE POLICY "Cho phép tất cả thao tác" ON public.hoadon FOR ALL USING (true) WITH CHECK (true);

-- From migration_split_invoice.sql
CREATE POLICY "Cho phép tất cả thao tác" ON public.chitiethoadon FOR ALL USING (true) WITH CHECK (true);

-- From migration_split_payment.sql
-- 3. Cập nhật RLS cho chitiethoadon (Cho phép người dùng xác thực truy cập)
ALTER TABLE public.chitiethoadon ENABLE ROW LEVEL SECURITY;

-- From migration_split_payment.sql
DROP POLICY IF EXISTS "Enable read access for all authenticated users" ON public.chitiethoadon;

-- From migration_split_payment.sql
CREATE POLICY "Enable read access for all authenticated users"
ON public.chitiethoadon FOR SELECT
TO authenticated USING (true);

-- From migration_split_payment.sql
DROP POLICY IF EXISTS "Enable insert access for all authenticated users" ON public.chitiethoadon;

-- From migration_split_payment.sql
CREATE POLICY "Enable insert access for all authenticated users"
ON public.chitiethoadon FOR INSERT
TO authenticated WITH CHECK (true);

-- From migration_split_payment.sql
DROP POLICY IF EXISTS "Enable update access for all authenticated users" ON public.chitiethoadon;

-- From migration_split_payment.sql
CREATE POLICY "Enable update access for all authenticated users"
ON public.chitiethoadon FOR UPDATE
TO authenticated USING (true);

-- From migration_split_payment.sql
DROP POLICY IF EXISTS "Enable delete access for all authenticated users" ON public.chitiethoadon;

-- From migration_split_payment.sql
CREATE POLICY "Enable delete access for all authenticated users"
ON public.chitiethoadon FOR DELETE
TO authenticated USING (true);