-- =========================================================================
-- MIGRATION: Thêm cột FCM Token và tạo Webhook cho Thông báo
-- Chạy script này trong Supabase SQL Editor
-- =========================================================================

-- 1. Thêm cột fcm_token vào bảng users
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS fcm_token TEXT;

COMMENT ON COLUMN public.users.fcm_token IS 'Firebase Cloud Messaging Token của thiết bị người dùng';

-- 2. Hướng dẫn tạo Database Webhook (Trigger)
-- Để gọi Edge Function `send_notification`, bạn cần tạo một Webhook trên Supabase Dashboard:
-- 
-- Cách làm:
-- Bước 1: Vào trang quản trị Supabase -> Database -> Webhooks.
-- Bước 2: Bấm nút "Create Webhook".
-- Bước 3: Cấu hình như sau:
--   - Name: Bắn thông báo khi có hóa đơn mới
--   - Table: `hoadon`
--   - Events: `Insert`
--   - Type: `Supabase Edge Function`
--   - Method: `POST`
--   - Edge Function: Chọn `send-notification`
-- Bước 4: Lưu lại.
