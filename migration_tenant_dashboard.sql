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
    -- Ưu tiên lấy từ bảng thuephong (hợp đồng đang active)
    SELECT room_id INTO v_room_id 
    FROM public.thuephong 
    WHERE tenant_id = p_user_id AND status = 'ACTIVE' 
    LIMIT 1;

    -- Nếu không có trong thuephong, lấy từ bảng users
    IF v_room_id IS NULL THEN
        SELECT room_id INTO v_room_id
        FROM public.users 
        WHERE iduser = p_user_id;
    END IF;

    -- Nếu có room_id thì lấy thông tin phòng và nhà trọ
    IF v_room_id IS NOT NULL THEN
        SELECT room_number, floor, property_id 
        INTO v_room_number, v_floor, v_property_id 
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
