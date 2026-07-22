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

-- 2. Xóa các cột thanh toán khỏi bảng hoadon
ALTER TABLE public.hoadon
DROP COLUMN IF EXISTS paid_at,
DROP COLUMN IF EXISTS payment_method,
DROP COLUMN IF EXISTS transaction_id;

-- 3. Cập nhật RLS cho chitiethoadon (Cho phép người dùng xác thực truy cập)
ALTER TABLE public.chitiethoadon ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Enable read access for all authenticated users" ON public.chitiethoadon;
CREATE POLICY "Enable read access for all authenticated users"
ON public.chitiethoadon FOR SELECT
TO authenticated USING (true);

DROP POLICY IF EXISTS "Enable insert access for all authenticated users" ON public.chitiethoadon;
CREATE POLICY "Enable insert access for all authenticated users"
ON public.chitiethoadon FOR INSERT
TO authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "Enable update access for all authenticated users" ON public.chitiethoadon;
CREATE POLICY "Enable update access for all authenticated users"
ON public.chitiethoadon FOR UPDATE
TO authenticated USING (true);

DROP POLICY IF EXISTS "Enable delete access for all authenticated users" ON public.chitiethoadon;
CREATE POLICY "Enable delete access for all authenticated users"
ON public.chitiethoadon FOR DELETE
TO authenticated USING (true);
