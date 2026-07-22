-- Thêm cột lưu URL ảnh giao dịch khi khách thuê xác nhận thanh toán
ALTER TABLE public.hoadon ADD COLUMN IF NOT EXISTS payment_image_url TEXT;
