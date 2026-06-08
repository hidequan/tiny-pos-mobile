# Data Safety (Google Play) & App Privacy (App Store)

App **Tiny POS** không thu thập/không gửi dữ liệu người dùng. Dùng các câu trả lời sau.

## Google Play — Data safety form
- **Does your app collect or share any of the required user data types?** → **No**
  (Toàn bộ dữ liệu lưu cục bộ trên thiết bị, không gửi lên server.)
- **Is all of the user data encrypted in transit?** → Không áp dụng (không truyền dữ liệu
  người dùng). Nếu form bắt buộc: chọn "Yes" (HTTPS dùng cho tải phông chữ).
- **Do you provide a way for users to request that their data be deleted?** → Yes — gỡ
  cài đặt sẽ xóa toàn bộ dữ liệu cục bộ.
- **Data types collected:** None.
- **Data types shared:** None.

## App Store — App Privacy ("Nutrition label")
- **Data Used to Track You:** None.
- **Data Linked to You:** None.
- **Data Not Linked to You:** None.
- Chọn **"Data Not Collected"** cho tất cả nhóm.
- **Export Compliance (ITSAppUsesNonExemptEncryption):** App chỉ dùng HTTPS chuẩn → chọn
  "No" cho mã hóa phi miễn trừ. (Đã thêm `ITSAppUsesNonExemptEncryption=false` vào
  Info.plist để bỏ qua hỏi mỗi lần upload — xem checklist.)

## Quyền (permissions) khai trong manifest
- Android: chỉ `INTERNET` (mặc định, để tải phông chữ). Không vị trí/camera/danh bạ/micro.
- iOS: không khai quyền nhạy cảm nào.

> Lưu ý: nếu sau này thêm backend (đồng bộ đám mây, đăng nhập, thanh toán online), phải
> cập nhật lại Data Safety/App Privacy + chính sách bảo mật cho đúng.
