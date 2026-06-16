# Data Safety (Google Play) & App Privacy (App Store)

App **Tiny POS** kết nối tới một backend dùng chung với web POS (`pos.lptech.info.vn`).
Để đăng nhập và vận hành, app **truyền và lưu dữ liệu trên máy chủ** qua HTTPS. Dùng các
câu trả lời sau (phản ánh đúng hành vi thật của app).

## Google Play — Data safety form
- **Does your app collect or share any of the required user data types?** → **Yes**
- **Data types collected (thu thập):**
  - **Personal info** — Tên (tên nhân viên `fullName`), User IDs (username, account id).
  - **App activity** — Thao tác trong app: tạo/sửa đơn hàng, bill, thanh toán, mở/đóng ca.
  - **Other info** — Dữ liệu kinh doanh: hoá đơn, khuyến mãi, ca làm, báo cáo doanh thu.
- **Is this data collected, shared, or both?** → **Collected** (gửi & lưu trên máy chủ của
  chúng tôi). **Không chia sẻ với bên thứ ba** (No data shared).
- **Is all of the user data encrypted in transit?** → **Yes** (toàn bộ gọi API qua HTTPS).
- **Do you provide a way for users to request that their data be deleted?** → **Yes** — người
  dùng/chủ cửa hàng liên hệ **technology.lamphongtech@gmail.com** để yêu cầu xoá dữ liệu tài khoản trên máy
  chủ; gỡ cài đặt sẽ xoá dữ liệu tạm lưu trên thiết bị.
- **Mục đích sử dụng dữ liệu (purpose):** App functionality (đăng nhập, đồng bộ vận hành).
  **KHÔNG** dùng cho quảng cáo, **KHÔNG** tracking, **KHÔNG** bán dữ liệu.

## App Store — App Privacy ("Nutrition label")
Chọn **"Data Collected"** (không phải "Data Not Collected"). Khai như sau:
- **Data Used to Track You:** None.
- **Data Linked to You** (dùng cho *App Functionality*):
  - **Contact Info** → Name (tên nhân viên).
  - **Identifiers** → User ID (username / account id).
  - **User Content** → đơn hàng, bill, ghi chú, dữ liệu vận hành.
  - **Other Data** → bản ghi doanh thu / báo cáo.
- **Data Not Linked to You:** None.
- **Export Compliance (ITSAppUsesNonExemptEncryption):** App chỉ dùng HTTPS chuẩn → chọn
  "No" cho mã hoá phi miễn trừ. (Đã thêm `ITSAppUsesNonExemptEncryption=false` vào
  Info.plist để bỏ qua hỏi mỗi lần upload — xem checklist.)

## Quyền (permissions) khai trong manifest
- Android: chỉ `INTERNET` (gọi API backend + tải phông chữ). Không vị trí/camera/danh bạ/micro.
- iOS: không khai quyền nhạy cảm nào (chỉ dùng kết nối mạng HTTPS).

> Lưu ý: app dùng tài khoản đăng nhập và đồng bộ đám mây với web POS. Mọi khai báo Data
> Safety / App Privacy ở đây phải khớp với chính sách bảo mật công khai
> (https://hidequan.github.io/tiny-pos-privacy/). Nếu sau này thêm tracking/quảng cáo/thanh
> toán online thật, phải cập nhật lại các mục trên.
