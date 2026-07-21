-- Hàm RPC để khách thuê xác nhận thanh toán (bỏ qua RLS của bảng hoadon)
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
        'total_amount', (v_invoice.rent_amount + 
                         (v_invoice.electric_curr_reading - v_invoice.electric_prev_reading) * v_invoice.electric_unit_price + 
                         (v_invoice.water_curr_reading - v_invoice.water_prev_reading) * v_invoice.water_unit_price + 
                         v_invoice.service_amount + 
                         COALESCE(v_invoice.other_amount, 0)),
        'room_number', (SELECT room_number FROM public.phong WHERE id = v_invoice.room_id)
    ) INTO v_result;

    RETURN v_result;
END;
$$ LANGUAGE plpgsql;
