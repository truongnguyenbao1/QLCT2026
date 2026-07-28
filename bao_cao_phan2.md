# BÁO CÁO PHẦN 2: PHÁT TRIỂN & HOÀN THIỆN SẢN PHẨM
**Dự án:** TroKeeper - Hệ thống Quản lý Nhà trọ Đa nền tảng
**Công nghệ sử dụng:** Flutter, Dart, Supabase (PostgreSQL), BLoC, Vercel, Google Play Console.
**Đối tượng người dùng:** Chủ nhà trọ (Admin)

---

## LỜI CẢM ƠN
Nhóm phát triển xin gửi lời cảm ơn chân thành đến các giảng viên hướng dẫn đã tận tình chỉ bảo, định hướng và cung cấp những kiến thức quý báu trong suốt quá trình thực hiện đồ án. Sự hỗ trợ của nhà trường và các bạn học đã tạo động lực to lớn giúp chúng em hoàn thiện sản phẩm này một cách trọn vẹn nhất.

## LỜI CAM ĐOAN
Chúng em xin cam đoan đây là công trình nghiên cứu và phát triển phần mềm độc lập của nhóm. Các số liệu, mã nguồn và kết quả báo cáo là hoàn toàn trung thực. Các tài liệu tham khảo, thư viện mã nguồn mở đều được trích dẫn rõ ràng theo đúng quy định.

## TÓM TẮT BÁO CÁO
Báo cáo Phần 2 trình bày chi tiết quá trình phát triển, hiện thực hóa mã nguồn, kiểm thử và triển khai ứng dụng TroKeeper. Từ nền tảng kiến trúc Clean Architecture đã thiết kế ở Phần 1, nhóm đã hoàn thiện các module cốt lõi (Quản lý phòng, Khách thuê, Hóa đơn thu chi), tối ưu hóa trải nghiệm đa nền tảng (Web & Mobile Android), và triển khai thành công hệ thống lên môi trường thực tế (Supabase, Vercel, Google Play).

---

## CHƯƠNG I: QUY TRÌNH THỰC TẾ & KIẾN TRÚC TRIỂN KHAI

### 1.1. Mô hình vòng đời phát triển phần mềm
Trong quá trình phát triển phần mềm, dự án áp dụng **Mô hình Thác nước (Waterfall)** kết hợp linh hoạt với các giai đoạn lặp (Iterative) cho phần UI.
- **Khái niệm & Giai đoạn:** Bao gồm Khảo sát yêu cầu -> Phân tích thiết kế (Phần 1) -> Lập trình -> Kiểm thử -> Triển khai (Phần 2). Các bước được thực hiện tuần tự, đầu ra của bước trước là đầu vào của bước sau.
- **Ưu điểm:** Quá trình phát triển minh bạch, tài liệu hóa rõ ràng, dễ quản lý tiến độ và phân chia công việc.
- **Nhược điểm:** Khó thay đổi yêu cầu lớn khi đã bước vào giai đoạn code và test.
- **Lý do chọn lựa:** Phù hợp với đồ án có thời gian giới hạn, yêu cầu nghiệp vụ quản lý nhà trọ đã được xác định rất rõ ràng từ đầu thông qua khảo sát thực tế, ít có sự thay đổi đột ngột về scope dự án.

### 1.2. Kiến trúc & Công nghệ sử dụng

| Công nghệ / Thư viện | Vai trò trong dự án |
|----------------------|---------------------|
| **Flutter (Dart)** | Xây dựng giao diện đa nền tảng (Android, Web). Tuân thủ Clean Architecture. |
| **Supabase** | Backend-as-a-Service, cung cấp PostgreSQL Database, Authentication và Storage. |
| **BLoC / flutter_bloc**| Quản lý trạng thái (State Management) chính của ứng dụng, tách biệt Logic và UI. |
| **GoRouter** | Xử lý điều hướng (Routing) khai báo đa nền tảng, hỗ trợ deep-linking tốt cho Web. |
| **Vercel** | Hosting trực tiếp bản Web của ứng dụng và các trang tĩnh (Landing, Privacy). |
| **Google Play Console**| Đóng gói (.aab) và phát hành phiên bản Mobile App lên cửa hàng ứng dụng Android. |

---

## CHƯƠNG II: HOÀN THIỆN CÁC TÍNH NĂNG CHÍNH (IMPLEMENTATION)

Dựa trên thiết kế ERD và Use Case ở Phần 1, nhóm đã lập trình hoàn chỉnh các tính năng nghiệp vụ:

### 2.1. Quản lý thu chi & Hóa đơn
- **Tạo hóa đơn tự động:** Hệ thống tự động tính toán tổng tiền dựa trên giá phòng, số ký điện/nước tiêu thụ trong tháng và các dịch vụ đi kèm (rác, wifi).
- **Theo dõi thanh toán:** Cập nhật trạng thái hóa đơn (Chưa thanh toán, Đã thanh toán một phần, Đã hoàn thành).
- **Lịch sử thu chi:** Ghi nhận dòng tiền, tổng hợp doanh thu theo từng tháng/năm.

### 2.2. Quản lý Khách thuê (Hoàn chỉnh)
- **Lưu trữ hồ sơ:** Quản lý hình ảnh CCCD/CMND (lưu trên Supabase Storage).
- **Trạng thái lưu trú:** Cập nhật trạng thái Đang thuê, Đã trả phòng, Sắp hết hạn hợp đồng.
- **Tìm kiếm & Lọc:** Công cụ tìm kiếm khách thuê theo tên, số điện thoại hoặc trạng thái phòng.

### 2.3. Thông báo & Nhắc nhở
- **Cảnh báo hạn thanh toán:** Báo cáo trực quan (Dashboard) các phòng đang nợ tiền, nhắc nhở đóng tiền.
- **Trạng thái hợp đồng:** Cảnh báo hợp đồng sắp hết hạn để chủ nhà có kế hoạch tái ký.

---

## CHƯƠNG III: PHÁT TRIỂN ĐA NỀN TẢNG & GIAO DIỆN (CODE DEMO)

Ứng dụng được thiết kế responsive, đảm bảo trải nghiệm liền mạch trên cả 2 nền tảng:

### 3.1. Mobile (Android/iOS)
Giao diện Mobile được tối ưu hóa cho màn hình cảm ứng, tuân thủ nguyên tắc **Material Design 3**:
- **Màn hình Đăng nhập:** Form đăng nhập sạch sẽ, có xác thực Email/Password qua Supabase Auth.
- **Trang chủ (Dashboard):** Hiển thị tổng quan số phòng trống, tổng doanh thu trong tháng, danh sách hóa đơn cần thu.
- **Chi tiết phòng / Chi tiết khách hàng:** Sử dụng BottomSheet và thẻ (Cards) để trình bày thông tin dễ nhìn, hỗ trợ thao tác vuốt, chạm để sửa/xóa.

### 3.2. Web Dashboard
Bản Web được đóng gói bằng `flutter build web` và triển khai tối ưu trên màn hình lớn:
- Tận dụng Sidebar (thanh điều hướng bên trái) thay vì BottomNavigationBar như trên Mobile.
- Các bảng biểu (DataTables) hiển thị danh sách hóa đơn, khách thuê rộng rãi, dễ dàng xem báo cáo doanh thu trực quan.

---

## CHƯƠNG IV: KIỂM THỬ PHẦN MỀM (TESTING)

Quá trình kiểm thử được thực hiện cẩn thận để đảm bảo hệ thống hoạt động ổn định, bảo mật dữ liệu cho người dùng.

### Bảng Kiểm thử (Test Cases)

| ID | Nội dung Unit Test / Chức năng | Dữ liệu đầu vào (Test Case) | Kết quả mong đợi | Trạng thái |
|----|--------------------------------|-----------------------------|------------------|------------|
| TC01 | Xác thực đăng nhập | Email: đúng, Pass: đúng | Chuyển hướng vào Dashboard | ✅ Success |
| TC02 | Xác thực đăng nhập sai | Email: sai định dạng | Báo lỗi "Email không hợp lệ" | ✅ Success |
| TC03 | Thêm phòng trống thông tin | Bỏ trống "Tên phòng" | Yêu cầu điền trường bắt buộc | ✅ Success |
| TC04 | Tính toán tổng tiền hóa đơn | Tiền phòng: 2tr, Điện: 50k | Tổng hóa đơn = 2.050.000đ | ✅ Success |
| TC05 | Xóa khách thuê đang có HĐ | Chọn xóa khách "Nguyễn Văn A" | Cảnh báo: "Cần thanh lý HĐ trước" | ✅ Success |
| TC06 | Responsive Web UI | Kéo thu nhỏ cửa sổ trình duyệt | Layout tự động chuyển sang Mobile | ✅ Success |
| TC07 | RLS Security (Supabase) | User A gọi API lấy dữ liệu User B | Bị chặn (Error 403 / Trả về rỗng) | ✅ Success |

---

## CHƯƠNG V: TRIỂN KHAI & TỔNG KẾT (DEPLOYMENT)

### 5.1. Triển khai Hệ thống (Deployment)
- **Backend & Database:** Đã triển khai toàn bộ 13 bảng dữ liệu, Row Level Security (RLS) và Storage Buckets lên hạ tầng đám mây của **Supabase**.
- **Web App & Landing Page:** Đóng gói source code và deploy tự động thông qua **Vercel** CI/CD. Đã cấu hình domain tùy chỉnh (`trokeeper.tnb.io.vn`), chuẩn hóa SEO (sitemap.xml, robots.txt) và trang Chính sách quyền riêng tư.
- **Mobile App:** Đã build ra định dạng `.aab` (Android App Bundle), hoàn tất các thủ tục khai báo thông tin, chính sách và đẩy lên môi trường thử nghiệm của **Google Play Console**.

### 5.2. Tổng kết đồ án
- **Kết quả đạt được:** Hoàn thành 100% mục tiêu ban đầu. Ứng dụng chạy mượt mà, logic nghiệp vụ quản lý nhà trọ (phòng, khách, điện nước, hóa đơn) hoạt động chính xác. Kiến trúc Clean Architecture giúp code dễ bảo trì.
- **Hạn chế:** Bản Web load lần đầu còn hơi chậm (do đặc thù Flutter Web). Chưa tích hợp cổng thanh toán trực tuyến (VNPay/Momo) để khách thuê tự trả tiền.
- **Hướng phát triển tương lai:** 
  1. Tích hợp thanh toán online. 
  2. Tạo ứng dụng riêng biệt dành cho Khách thuê (Tenant App) để họ tự xem hóa đơn và báo cáo sự cố. 
  3. Xuất báo cáo doanh thu ra file Excel/PDF.

---
✅ **KẾT QUẢ BÀN GIAO PHẦN 2:** 
- Ứng dụng hoàn chỉnh chạy được trên Mobile (Android) & Web.
- Đã được kiểm thử và đảm bảo tính bảo mật.
- Đã lên các nền tảng thực tế (Vercel, Google Play).
- Bộ tài liệu báo cáo hoàn chỉnh Phần 1 & Phần 2.
