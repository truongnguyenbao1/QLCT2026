-- From migration_momo_qr.sql
-- 2. Tạo Storage Bucket mới tên là 'payment_qrs' (Public)
-- Supabase tự động lưu trữ bucket vào schema `storage.buckets`
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES ('payment_qrs', 'payment_qrs', true, 5242880, ARRAY['image/png', 'image/jpeg', 'image/jpg'])
ON CONFLICT (id) DO NOTHING;

-- From migration_notifications_update.sql
-- Tạo Storage Bucket cho attachments nếu chưa có (Chỉ có thể chạy trên trình duyệt nếu ko có quyền db admin, 
-- tuy nhiên có thể dùng lệnh sql sau đây)
-- Lưu ý: Lệnh INSERT vào storage.buckets có thể bị lỗi do phân quyền, khuyến nghị tạo trên Giao diện Supabase.
INSERT INTO storage.buckets (id, name, public) 
VALUES ('attachments', 'attachments', true)
ON CONFLICT (id) DO NOTHING;

-- From migration_split_payment.sql
-- migration_split_payment.sql
-- Kế hoạch tinh giản bảng hoadon và chia tải sang chitiethoadon

-- 1. Chuyển đổi dữ liệu cũ (nếu có) từ hoadon sang chitiethoadon trước khi xóa cột
INSERT INTO public.chitiethoadon (invoice_id, amount, payment_method, transaction_id, paid_at, created_at)
SELECT 
    id AS invoice_id,
    COALESCE(rent_amount + service_amount + other_amount, 0) AS amount,
    COALESCE(payment_method, 'CASH') AS payment_method,
    transaction_id,
    COALESCE(paid_at, NOW()) AS paid_at,
    NOW() AS created_at
FROM public.hoadon
WHERE status = 'PAID' OR paid_at IS NOT NULL
ON CONFLICT DO NOTHING;

-- From migration_sync_contracts.sql
-- =========================================================================
-- MIGRATION: Đồng bộ Khách thuê (khachthue) vào bảng Xác nhận thuê (thuephong)
-- =========================================================================

-- Thêm dữ liệu vào thuephong cho những khách thuê đang ACTIVE nhưng chưa có bản ghi thuephong
INSERT INTO public.thuephong (
    tenant_id, 
    room_id, 
    start_date, 
    end_date, 
    deposit_amount, 
    status
)
SELECT 
    k.id AS tenant_id,
    k.room_id AS room_id,
    k.created_at AS start_date,
    NULL AS end_date, -- Để trống khi đang thuê
    0 AS deposit_amount,
    'ACTIVE' AS status
FROM public.khachthue k
WHERE k.is_active = TRUE
  AND k.room_id IS NOT NULL
  AND NOT EXISTS (
      SELECT 1 FROM public.thuephong t 
      WHERE t.tenant_id = k.id AND t.room_id = k.room_id AND t.status = 'ACTIVE'
  );