-- Kích hoạt RLS cho bảng thongbao
ALTER TABLE public.thongbao ENABLE ROW LEVEL SECURITY;

-- Xóa các policy cũ nếu có
DROP POLICY IF EXISTS "Cho phép người dùng xem thông báo liên quan" ON public.thongbao;
DROP POLICY IF EXISTS "Cho phép tạo thông báo" ON public.thongbao;
DROP POLICY IF EXISTS "Cho phép cập nhật thông báo" ON public.thongbao;
DROP POLICY IF EXISTS "Cho phép xóa thông báo" ON public.thongbao;
DROP POLICY IF EXISTS "Enable read access for all authenticated users" ON public.thongbao;
DROP POLICY IF EXISTS "Enable insert access for all authenticated users" ON public.thongbao;
DROP POLICY IF EXISTS "Enable update access for all authenticated users" ON public.thongbao;
DROP POLICY IF EXISTS "Enable delete access for all authenticated users" ON public.thongbao;

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
        )
    )
);

-- 2. Policy cho phép TẠO (INSERT) thông báo
CREATE POLICY "Cho phép tạo thông báo"
ON public.thongbao
FOR INSERT
WITH CHECK (
    auth.uid() = sender_id
);

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

-- 4. Policy cho phép XÓA (DELETE) thông báo
CREATE POLICY "Cho phép xóa thông báo"
ON public.thongbao
FOR DELETE
USING (
    auth.uid() = sender_id
);
