-- =========================================================================
-- MIGRATION: Thêm chức năng tải ảnh mã QR MoMo
-- Chạy script này trong Supabase SQL Editor
-- =========================================================================

-- 1. Thêm cột momo_qr_url vào bảng caidat_thanhtoan
ALTER TABLE public.caidat_thanhtoan 
ADD COLUMN IF NOT EXISTS momo_qr_url TEXT;

-- 2. Tạo Storage Bucket mới tên là 'payment_qrs' (Public)
-- Supabase tự động lưu trữ bucket vào schema `storage.buckets`
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES ('payment_qrs', 'payment_qrs', true, 5242880, ARRAY['image/png', 'image/jpeg', 'image/jpg'])
ON CONFLICT (id) DO NOTHING;

-- 3. Tạo chính sách RLS cho Storage Bucket
-- Cho phép mọi người (cả khách thuê chưa đăng nhập hoặc đã đăng nhập) có thể XEM ảnh
CREATE POLICY "anyone_can_read_payment_qrs"
ON storage.objects FOR SELECT
USING (bucket_id = 'payment_qrs');

-- Cho phép người dùng đã đăng nhập có thể UPLOAD (Tạo mới)
CREATE POLICY "authenticated_can_insert_payment_qrs"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'payment_qrs');

-- Cho phép người dùng cập nhật/xóa ảnh của chính họ
CREATE POLICY "owner_can_update_delete_payment_qrs"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'payment_qrs');

CREATE POLICY "owner_can_delete_payment_qrs"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'payment_qrs');
