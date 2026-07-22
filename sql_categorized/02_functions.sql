-- From migration_notifications.sql
CREATE OR REPLACE FUNCTION notify_landlord_on_tenant_confirm()
    RETURNS TRIGGER AS $$
    DECLARE
        v_room_name VARCHAR(100);
        v_tenant_name VARCHAR(100);
        v_sender_id UUID;
    BEGIN
        -- Chỉ kích hoạt khi trạng thái chuyển thành CONFIRMED_BY_TENANT
        IF NEW.status = 'CONFIRMED_BY_TENANT' AND (OLD.status IS NULL OR OLD.status != 'CONFIRMED_BY_TENANT') THEN
            
            -- Lấy số phòng (bảng phong dùng cột room_number, không phải name)
            SELECT room_number INTO v_room_name FROM public.phong WHERE id = NEW.room_id;
            
            -- Lấy tên khách thuê & user_id làm sender_id
        IF NEW.tenant_id IS NOT NULL THEN
            SELECT full_name, user_id INTO v_tenant_name, v_sender_id FROM public.khachthue WHERE id = NEW.tenant_id;
        ELSE
            -- Nếu hóa đơn chưa được gán tenant_id, lấy iduser với role là khách thuê từ bảng users
            SELECT tenuser, iduser INTO v_tenant_name, v_sender_id 
            FROM public.users 
            WHERE room_id = NEW.room_id AND quyenhan = 'khách thuê' 
            LIMIT 1;
        END IF;

            IF v_tenant_name IS NULL THEN
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
                image_url,
                sent_at
            ) VALUES (
                NEW.room_id,
                v_sender_id,
                NEW.created_by, -- Chủ trọ là người tạo hóa đơn
                'Xác nhận thanh toán',
                v_tenant_name || ' phòng ' || COALESCE(v_room_name, '') || ' vừa xác nhận đã chuyển tiền hóa đơn tháng ' || NEW.month || '/' || NEW.year || '. Vui lòng kiểm tra tài khoản. [invoice_id:' || NEW.id || ']',
                'UNREAD',
                NEW.payment_image_url,
                NOW()
            );
            
        END IF;
        RETURN NEW;
    END;
    $$ LANGUAGE plpgsql;

-- From migration_set_hoadon_tenant.sql
CREATE OR REPLACE FUNCTION set_tenant_id_for_hoadon()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.tenant_id IS NULL THEN
        SELECT id INTO NEW.tenant_id
        FROM public.khachthue
        WHERE room_id = NEW.room_id AND is_active = TRUE
        ORDER BY created_at DESC
        LIMIT 1;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- From migration_tenant_confirm.sql
CREATE OR REPLACE FUNCTION public.tenant_confirm_payment(p_invoice_id UUID)
RETURNS JSONB
SECURITY DEFINER
AS $$
DECLARE
    v_invoice RECORD;
    v_result JSONB;
BEGIN
    -- Cập nhật trạng thái hóa đơn
    UPDATE public.hoadon
    SET status = 'CONFIRMED_BY_TENANT',
        updated_at = NOW()
    WHERE id = p_invoice_id
    RETURNING * INTO v_invoice;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Không tìm thấy hóa đơn hoặc không thể cập nhật';
    END IF;

    -- Lấy thêm thông tin phòng và khách thuê để trả về cho Flutter
    SELECT jsonb_build_object(
        'id', v_invoice.id,
        'status', v_invoice.status,
        'room_id', v_invoice.room_id,
        'month', v_invoice.month,
        'year', v_invoice.year,
        'total_amount', v_invoice.total_amount,
        'room_number', (SELECT room_number FROM public.phong WHERE id = v_invoice.room_id)
    ) INTO v_result;

    RETURN v_result;
END;
$$ LANGUAGE plpgsql;

-- From migration_tenant_dashboard.sql
CREATE OR REPLACE FUNCTION public.get_tenant_dashboard_info(p_user_id UUID)
RETURNS JSONB
SECURITY DEFINER
AS $$
DECLARE
    v_room_id UUID;
    v_property_id UUID;
    v_room_number VARCHAR;
    v_floor INT;
    v_property_name VARCHAR;
BEGIN
    -- Ưu tiên lấy từ bảng khachthue (vì bảng khách thuê chứa room_id cập nhật nhất và liên kết trực tiếp với user_id)
    SELECT room_id, property_id INTO v_room_id, v_property_id
    FROM public.khachthue 
    WHERE user_id = p_user_id AND is_active = TRUE
    ORDER BY created_at DESC 
    LIMIT 1;

    -- Nếu không có trong khachthue, lấy từ bảng users (dự phòng)
    IF v_room_id IS NULL THEN
        SELECT room_id, property_id INTO v_room_id, v_property_id
        FROM public.users 
        WHERE iduser = p_user_id;
    END IF;

    -- Nếu có room_id thì lấy thông tin phòng và nhà trọ
    IF v_room_id IS NOT NULL THEN
        SELECT room_number, floor 
        INTO v_room_number, v_floor 
        FROM public.phong 
        WHERE id = v_room_id;
        
        IF v_property_id IS NOT NULL THEN
            SELECT name INTO v_property_name 
            FROM public.nhatro 
            WHERE id = v_property_id;
        END IF;
    END IF;

    RETURN jsonb_build_object(
        'room_id', v_room_id,
        'room_number', v_room_number,
        'floor', v_floor,
        'property_id', v_property_id,
        'property_name', v_property_name
    );
END;
$$ LANGUAGE plpgsql;