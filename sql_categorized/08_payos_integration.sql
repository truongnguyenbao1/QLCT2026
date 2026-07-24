-- Thêm cột order_code cho bảng subscriptions (Dùng cho chủ trọ mua gói)
ALTER TABLE subscriptions 
ADD COLUMN IF NOT EXISTS order_code BIGINT UNIQUE;

-- Thêm cột order_code cho bảng hoadon (Dùng cho khách thuê trả tiền nhà)
ALTER TABLE hoadon 
ADD COLUMN IF NOT EXISTS order_code BIGINT UNIQUE;

-- Tạo index để query nhanh order_code khi webhook gọi về
CREATE INDEX IF NOT EXISTS idx_subscriptions_order_code ON subscriptions(order_code);
CREATE INDEX IF NOT EXISTS idx_hoadon_order_code ON hoadon(order_code);
