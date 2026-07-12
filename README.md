# 🏢 Ứng dụng Quản lý Nhà trọ 2026

Dự án ứng dụng quản lý nhà trọ quy mô vừa và nhỏ, hỗ trợ 2 phân hệ: **Chủ trọ (Admin)** và **Khách thuê (Tenant)**. Hệ thống tập trung vào tính minh bạch trong thanh toán, hỗ trợ kê khai thuế, và bảo mật dữ liệu theo quy định (Nghị định 13/2023/NĐ-CP).

---

## 📊 BÁO CÁO TIẾN ĐỘ DỰ ÁN

*Cập nhật lần cuối: 12/07/2026*

### 🟢 ĐÃ HOÀN THÀNH (Done)

**1. Khởi tạo & Cấu hình lõi (Core & Setup)**
- [x] Khởi tạo dự án Flutter với `pubspec.yaml` (các packages: BLoC, get_it, go_router, supabase_flutter, encrypt...).
- [x] Cấu hình `main.dart` (Supabase, Hive, Notifications).
- [x] Hệ thống hằng số (Constants, Colors).
- [x] Hệ thống xử lý lỗi (Failures) theo Clean Architecture.
- [x] **Bảo mật:** `EncryptionService` mã hóa AES-256 cho dữ liệu nhạy cảm (CCCD, SĐT) và Hashing SHA-256.
- [x] Tiện ích định dạng (Formatters) cho tiền tệ (VND), ngày tháng, che dấu dữ liệu.
- [x] Dependency Injection Container bằng `get_it`.
- [x] Thiết lập giao diện ứng dụng (`AppTheme` - Material 3 Light/Dark).
- [x] Cấu hình điều hướng (`AppRouter` bằng go_router với bảo vệ route chưa đăng nhập).

**2. Thiết lập Cơ sở dữ liệu (Database Setup)**
- [x] Thiết kế và khởi tạo hoàn chỉnh CSDL Supabase với các bảng tiếng Việt đồng bộ: `nhatro`, `phong`, `khachthue`, `thuephong`, `hoadon`, `chitiethoadon`, `chiso`, `nhatky_hethong`, `thongbao`, `tailieudinhkem`, `thuchi`.
- [x] Thiết lập Trigger tự động cập nhật `updated_at` và tạo các Index tối ưu hóa tốc độ truy vấn liên kết.

**3. Tính năng Xác thực & Phân quyền (Auth Feature)**
- [x] Tầng Domain & Data (Entities, Models, Repository, RemoteDataSource với Supabase).
- [x] Các Use cases: Đăng nhập, Đăng xuất, Kiểm tra phiên, Chấp nhận chính sách.
- [x] State Management: `AuthBloc`.
- [x] Giao diện (UI):
  - [x] Trang Đăng nhập (`LoginPage`).
  - [x] Trang Chính sách bảo mật bắt buộc (`PrivacyPolicyPage` tuân thủ quy định pháp luật).

**4. Tính năng Quản lý Phòng (Room Management Feature)**
- [x] Tầng Domain & Data (Room Entity, RoomModel, Repository, RemoteDataSource).
- [x] Use cases: Thêm, Sửa, Xóa, Lấy danh sách phòng.
- [x] State Management: `RoomBloc`.
- [x] Giao diện (UI):
  - [x] Màn hình Danh sách phòng (`RoomsListPage`) với lưới, thanh thống kê và bộ lọc trạng thái. Chỉ cho phép Chủ trọ/Admin thêm phòng.
  - [x] Màn hình Chi tiết phòng (`RoomDetailPage`).
  - [x] Màn hình Thêm/Sửa phòng (`AddEditRoomPage`) tích hợp bảo mật kiểm tra vai trò chủ trọ/admin và tự động lấy `property_id` từ phiên đăng nhập.

**5. Tính năng Quản lý Khách thuê (Tenant Management Feature)**
- [x] Tầng Domain & Data (Tenant Entity, TenantModel, Repository, RemoteDataSource).
- [x] Bảo mật nâng cao: CCCD được mã hóa đầu cuối tại ứng dụng qua AES-256 và tự động giải mã khi tải danh sách.
- [x] Sử dụng thuật toán tra cứu dữ liệu CCCD cũ đã giải mã để tự động điền (autofill) thông tin khách cũ quay lại thuê phòng.
- [x] **Xác thực mật khẩu đăng nhập**: Chủ trọ/admin bắt buộc phải xác thực lại bằng mật khẩu đăng nhập của mình để lưu thông tin khách thuê (bảo mật nghiêm ngặt thông tin CCCD).
- [x] Giao diện (UI):
  - [x] Màn hình Danh sách khách thuê (`TenantListPage`) giới hạn quyền truy cập chỉ cho chủ trọ/admin.
  - [x] Màn hình Thêm/Sửa thông tin khách thuê (`AddEditTenantPage`) hoàn chỉnh, hỗ trợ chọn phòng trống, chọn hạn hợp đồng và xác thực mật khẩu.

**6. Tính năng Quản lý Hóa đơn (Invoice Feature)**
- [x] Tầng Domain & Data (Invoice Entity, InvoiceModel, Repository, RemoteDataSource, Usecases).
- [x] Logic phức tạp: Tự động tính tiền điện, nước, trạng thái hóa đơn, xác nhận song phương, ghi Audit log.
- [x] State Management: `InvoiceBloc`.
- [x] Giao diện (UI):
  - [x] Trang Chi tiết Hóa đơn (`InvoiceDetailPage`) với breakdown tính toán đầy đủ và nút xác nhận thanh toán.
  - [x] Màn hình Danh sách hóa đơn (`InvoiceListPage`).
  - [x] Màn hình Tạo/Chốt hóa đơn hàng tháng (`CreateInvoicePage`).
  - [x] Màn hình Thanh toán qua mã VietQR (`PaymentPage`).

**7. Khởi tạo Bảng điều khiển (Dashboard)**
- [x] Tạo Domain & Data layer cho Dashboard.
- [x] Thiết lập State Management (BLoC) và Use cases.
- [x] Khởi tạo khung giao diện (DashboardPage).
- [x] Sửa toàn bộ lỗi biên dịch và kết nối thành công Supabase.

**8. Triển khai Web (Web Deployment)**
- [x] Thay đổi thông tin SEO cơ bản (Title, Description) trong `web/index.html`.
- [x] Tạo cấu hình `vercel.json` phục vụ cho việc Single Page Application routing (rewrites).
- [x] Build thành công phiên bản web (`build/web`).

---

### 🟡 ĐANG DANG DỞ (In Progress)

- [ ] Ẩn danh hóa dữ liệu CCCD (Anonymize) khi hết hạn hợp đồng.
- [ ] Tích hợp biểu đồ thực tế cho Dashboard (`fl_chart`).

---

### 🔴 CHƯA BẮT ĐẦU (To Do)

**1. Tính năng Báo cáo Thuế & Xuất PDF (Tax Report & PDF Export) - *Tính năng cốt lõi***
- [ ] Tổng hợp doanh thu theo quý (tiền phòng, điện, nước).
- [ ] Xuất hóa đơn định dạng PDF đúng chuẩn.
- [ ] Giao diện Dashboard Thuế & Màn hình xem trước PDF.

**2. Phân hệ Khách thuê (Tenant Portal & Room Finder)**
- [ ] Xem hóa đơn cá nhân, lịch sử thanh toán.
- [ ] Tích hợp Google Maps tìm phòng trong bán kính 10km.

---

## 🛠️ Tech Stack Tổng Quan
- **Framework:** Flutter (Dart)
- **Kiến trúc:** Clean Architecture + Feature-first
- **State Management:** BLoC (`flutter_bloc`)
- **Backend Services:** Supabase (Auth, Database, Storage)
- **Routing:** `go_router`
- **Dependency Injection:** `get_it`
