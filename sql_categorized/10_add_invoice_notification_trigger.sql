-- =========================================================================
-- MIGRATION: Tạo Trigger gọi Webhook tới Edge Function send_notification
-- Bằng cách sử dụng PL/pgSQL và extension pg_net (được hỗ trợ mặc định)
-- =========================================================================

-- 1. Đảm bảo extension pg_net đã được cài đặt
CREATE EXTENSION IF NOT EXISTS pg_net;

-- 2. Tạo hàm (Function) xử lý việc gọi HTTP POST
CREATE OR REPLACE FUNCTION public.fn_hoadon_insert_notification()
RETURNS TRIGGER AS $$
BEGIN
  -- Dùng net.http_post để gửi request
  PERFORM net.http_post(
    url := 'https://eaihqwzhfwtwzqmsrkgk.supabase.co/functions/v1/send_notification',
    
    -- THAY THẾ CHUỖI MÃ BÊN DƯỚI BẰNG ANON KEY CỦA BẠN (GIỮ NGUYÊN CHỮ Bearer)
    headers := '{"Content-Type": "application/json", "Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVhaWhxd3poZnd0d3pxbXNya2drIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODM0ODU5MDcsImV4cCI6MjA5OTA2MTkwN30.JO7Q6yiNMbwYj3dmD5VneJ7f87NuFIIGbwEg2xPp_kg"}'::jsonb,
    
    -- Đóng gói dữ liệu bản ghi mới (NEW) thành JSON payload chuẩn của Supabase Webhook
    body := jsonb_build_object(
      'type', 'INSERT',
      'table', 'hoadon',
      'schema', 'public',
      'record', row_to_json(NEW)
    )
  );
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Gắn hàm này vào Trigger của bảng hoadon
DROP TRIGGER IF EXISTS tr_hoadon_insert_notification ON public.hoadon;

CREATE TRIGGER tr_hoadon_insert_notification
AFTER INSERT ON public.hoadon
FOR EACH ROW
EXECUTE FUNCTION public.fn_hoadon_insert_notification();

COMMENT ON TRIGGER tr_hoadon_insert_notification ON public.hoadon IS 'Gọi Webhook Push Notification qua pg_net khi có hóa đơn mới';
