-- Cập nhật bảng thongbao hiện có
ALTER TABLE public.thongbao
  ADD COLUMN IF NOT EXISTS type VARCHAR(50) NOT NULL DEFAULT 'ANNOUNCEMENT' CHECK (type IN ('ANNOUNCEMENT', 'ISSUE', 'SYSTEM')),
  ADD COLUMN IF NOT EXISTS image_url TEXT;

-- Tạo Storage Bucket cho attachments nếu chưa có (Chỉ có thể chạy trên trình duyệt nếu ko có quyền db admin, 
-- tuy nhiên có thể dùng lệnh sql sau đây)
-- Lưu ý: Lệnh INSERT vào storage.buckets có thể bị lỗi do phân quyền, khuyến nghị tạo trên Giao diện Supabase.
INSERT INTO storage.buckets (id, name, public) 
VALUES ('attachments', 'attachments', true)
ON CONFLICT (id) DO NOTHING;

-- Policies cho bucket attachments
CREATE POLICY "Cho phép mọi người xem ảnh đính kèm" 
  ON storage.objects FOR SELECT 
  USING ( bucket_id = 'attachments' );

CREATE POLICY "Cho phép user đăng nhập upload ảnh đính kèm" 
  ON storage.objects FOR INSERT 
  WITH CHECK ( bucket_id = 'attachments' AND auth.role() = 'authenticated' );

CREATE POLICY "Cho phép user xóa ảnh của mình" 
  ON storage.objects FOR DELETE 
  USING ( bucket_id = 'attachments' AND auth.uid() = owner );
