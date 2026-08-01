-- 12_fix_thongbao_status_constraint.sql
-- Sửa lỗi: Cho phép bảng thongbao lưu trạng thái 'RESOLVED' khi giải quyết sự cố

ALTER TABLE public.thongbao DROP CONSTRAINT IF EXISTS thongbao_status_check;

ALTER TABLE public.thongbao ADD CONSTRAINT thongbao_status_check 
CHECK (status::text = ANY (ARRAY['UNREAD'::character varying, 'READ'::character varying, 'RESOLVED'::character varying]::text[]));
