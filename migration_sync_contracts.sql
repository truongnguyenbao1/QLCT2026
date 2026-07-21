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
    '2099-12-31'::timestamptz AS end_date, -- Mặc định vô thời hạn
    0 AS deposit_amount,
    'ACTIVE' AS status
FROM public.khachthue k
WHERE k.is_active = TRUE
  AND k.room_id IS NOT NULL
  AND NOT EXISTS (
      SELECT 1 FROM public.thuephong t 
      WHERE t.tenant_id = k.id AND t.room_id = k.room_id AND t.status = 'ACTIVE'
  );
