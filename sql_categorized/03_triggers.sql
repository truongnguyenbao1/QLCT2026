-- From migration_notifications.sql
-- Hàm trigger xử lý việc tạo thông báo
    

    -- Tạo trigger trên bảng hoadon
    DROP TRIGGER IF EXISTS trigger_notify_landlord_on_tenant_confirm ON public.hoadon;

-- From migration_notifications.sql
CREATE TRIGGER trigger_notify_landlord_on_tenant_confirm
    AFTER UPDATE ON public.hoadon
    FOR EACH ROW
    EXECUTE FUNCTION notify_landlord_on_tenant_confirm();

-- From migration_payment_settings.sql
-- ── Trigger cập nhật updated_at ───────────────────────────────────────────
CREATE TRIGGER update_caidat_thanhtoan_updated_at
    BEFORE UPDATE ON public.caidat_thanhtoan
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- From migration_set_hoadon_tenant.sql
-- Trigger tự động điền tenant_id cho hóa đơn nếu chưa có


DROP TRIGGER IF EXISTS trigger_set_tenant_id_for_hoadon ON public.hoadon;

-- From migration_set_hoadon_tenant.sql
CREATE TRIGGER trigger_set_tenant_id_for_hoadon
BEFORE INSERT ON public.hoadon
FOR EACH ROW
EXECUTE FUNCTION set_tenant_id_for_hoadon();

-- From migration_split_invoice.sql
CREATE TRIGGER update_hoadon_updated_at BEFORE UPDATE ON public.hoadon
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();