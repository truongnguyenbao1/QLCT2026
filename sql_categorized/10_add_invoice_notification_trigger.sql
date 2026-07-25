-- Hàm trigger gửi thông báo cho khách thuê khi chủ trọ tạo hóa đơn mới
CREATE OR REPLACE FUNCTION notify_tenant_on_invoice_created()
RETURNS TRIGGER AS $$
DECLARE
    v_room_name VARCHAR(100);
    v_receiver_id UUID;
BEGIN
    -- Chỉ thông báo nếu trạng thái là UNPAID (mới tạo)
    IF NEW.status = 'UNPAID' THEN
        -- Lấy số phòng
        SELECT room_number INTO v_room_name FROM public.phong WHERE id = NEW.room_id;
        
        -- Lấy user_id của khách thuê để gửi thông báo
        IF NEW.tenant_id IS NOT NULL THEN
            SELECT user_id INTO v_receiver_id FROM public.khachthue WHERE id = NEW.tenant_id;
        ELSE
            SELECT iduser INTO v_receiver_id 
            FROM public.users 
            WHERE room_id = NEW.room_id AND quyenhan = 'khách thuê' 
            LIMIT 1;
        END IF;

        IF v_receiver_id IS NOT NULL THEN
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
                NEW.created_by, -- Người tạo hóa đơn (chủ trọ)
                v_receiver_id, -- Người nhận (khách thuê)
                'Hóa đơn mới',
                'Bạn có hóa đơn mới tháng ' || NEW.month || '/' || NEW.year || ' cho phòng ' || COALESCE(v_room_name, '') || '. Vui lòng kiểm tra và thanh toán.',
                'UNREAD',
                NOW()
            );
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Tạo trigger trên bảng hoadon
DROP TRIGGER IF EXISTS trigger_notify_tenant_on_invoice_created ON public.hoadon;

CREATE TRIGGER trigger_notify_tenant_on_invoice_created
    AFTER INSERT ON public.hoadon
    FOR EACH ROW
    EXECUTE FUNCTION notify_tenant_on_invoice_created();
