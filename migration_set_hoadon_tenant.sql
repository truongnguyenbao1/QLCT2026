-- Trigger tự động điền tenant_id cho hóa đơn nếu chưa có
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

DROP TRIGGER IF EXISTS trigger_set_tenant_id_for_hoadon ON public.hoadon;
CREATE TRIGGER trigger_set_tenant_id_for_hoadon
BEFORE INSERT ON public.hoadon
FOR EACH ROW
EXECUTE FUNCTION set_tenant_id_for_hoadon();
