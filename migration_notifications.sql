-- Cập nhật CHECK constraint cho cột status của bảng hoadon nếu cần
ALTER TABLE public.hoadon DROP CONSTRAINT IF EXISTS hoadon_status_check;
ALTER TABLE public.hoadon ADD CONSTRAINT hoadon_status_check CHECK (status IN ('PENDING', 'CONFIRMED_BY_TENANT', 'CONFIRMED_BY_OWNER', 'PAID', 'OVERDUE'));

-- Hàm trigger xử lý việc tạo thông báo
CREATE OR REPLACE FUNCTION notify_landlord_on_tenant_confirm()
RETURNS TRIGGER AS $$
DECLARE
    v_room_name VARCHAR(100);
    v_tenant_id UUID;
    v_tenant_name VARCHAR(100);
BEGIN
    -- Chỉ kích hoạt khi trạng thái chuyển thành CONFIRMED_BY_TENANT
    IF NEW.status = 'CONFIRMED_BY_TENANT' AND OLD.status != 'CONFIRMED_BY_TENANT' THEN
        
        -- Lấy tên phòng
        SELECT name INTO v_room_name FROM public.phong WHERE id = NEW.room_id;
        
        -- Lấy thông tin khách thuê (nếu có)
        SELECT tenant_id INTO v_tenant_id FROM public.thuephong WHERE room_id = NEW.room_id AND status = 'ACTIVE' LIMIT 1;
        
        IF v_tenant_id IS NOT NULL THEN
            SELECT full_name INTO v_tenant_name FROM public.users WHERE iduser = v_tenant_id;
        ELSE
            v_tenant_name := 'Khách thuê';
        END IF;

        -- Chèn thông báo vào bảng thongbao
        INSERT INTO public.thongbao (
            room_id, 
            sender_id, 
            receiver_id, 
            title, 
            content, 
            status, 
            sent_at
        ) VALUES (
            NEW.room_id,
            v_tenant_id,
            NEW.created_by, -- Chủ trọ là người tạo hóa đơn
            'Xác nhận thanh toán',
            v_tenant_name || ' phòng ' || v_room_name || ' vừa xác nhận đã chuyển tiền hóa đơn tháng ' || NEW.month || '/' || NEW.year || '. Mã hóa đơn: ' || NEW.id || '. Vui lòng kiểm tra tài khoản.',
            'UNREAD',
            NOW()
        );
        
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Tạo trigger trên bảng hoadon
DROP TRIGGER IF EXISTS trigger_notify_landlord_on_tenant_confirm ON public.hoadon;
CREATE TRIGGER trigger_notify_landlord_on_tenant_confirm
AFTER UPDATE ON public.hoadon
FOR EACH ROW
EXECUTE FUNCTION notify_landlord_on_tenant_confirm();
