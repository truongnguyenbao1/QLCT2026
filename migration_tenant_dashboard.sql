-- Hàm lấy thông tin phòng và nhà trọ cho dashboard của khách thuê
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
