# Changelog — Tiny POS

Phát hành test qua **Firebase App Distribution** (group `testers`). Mỗi bản phụ:
tăng `version` trong `pubspec.yaml` → push `main` → GitHub Actions tự build APK/AAB,
chạy `flutter test`, và phát hành cho tester.

## v0.2.1 — Thực đơn thật (thu ngân)
- Màn Bán hàng nạp **thực đơn thật** từ `GET /pos/menu` (cùng dữ liệu với web): nhóm,
  sản phẩm, **ảnh thật**, giá, tồn kho (Hết hàng), tìm kiếm. Có loading / lỗi + thử lại.
- Model menu (categories/sizes/toppings/products + variants), `PosMenuController` (cache).
  Sản phẩm có tu biến (size/topping) mở sheet chọn; còn lại thêm thẳng.
- Giỏ hàng/thanh toán tạm vẫn cục bộ (chưa ghi server) — lớp bill API ở bản kế. Đã verify
  end-to-end: đăng nhập cashier01 → menu production hiển thị đúng (ảnh + giá thật).

## v0.2.0 — Tích hợp backend dùng chung (nền tảng)
- **Đăng nhập thật** username/password vào API dùng chung với web
  (https://pos.lptech.info.vn/api) — "app và web là 1". Định tuyến theo `staffRole`
  (CASHIER→bán hàng, BARISTA→KDS, MANAGER/ADMIN→quản trị).
- Lớp API: Dio client (bóc envelope {success,data}, tự gắn Bearer, tự refresh token
  khi 401), lưu phiên qua restart, base URL cấu hình `--dart-define=API_BASE`.
- Đã verify login LIVE end-to-end (cashier01). Lưu ý: web cross-origin bị CORS — app
  native không ảnh hưởng. Các màn vẫn dùng dữ liệu mock; lớp thay dữ liệu thật ở bản kế.

## v0.1.3 — Thương hiệu + hồ sơ store
- **App icon** cốc cà phê (gradient terracotta) thay icon Flutter mặc định; adaptive icon
  Android + icon iOS/web; **splash screen** nền espresso.
- Chuẩn bị hồ sơ kiểm duyệt: feature graphic, 6 screenshots, mô tả/từ khóa, Data Safety,
  **chính sách bảo mật** (URL công khai), checklist nộp Play/App Store.
- `ITSAppUsesNonExemptEncryption=false` (bỏ hỏi export compliance khi upload TestFlight).

## v0.1.2 — Lưu cục bộ + Form thêm
- Lưu dữ liệu cục bộ (`shared_preferences`): chế độ tối, ca làm, giỏ hàng và đơn đã
  thanh toán **sống sót khi tắt/mở lại app**.
- Form thêm thật (ghi vào danh sách): **Nhân viên**, **Khuyến mãi**, **Chi nhánh** —
  thay cho các nút chỉ hiện toast trước đây.
- Test: form thêm NV + round-trip lưu/đọc state. 8/8 test pass.

## v0.1.1 — Tìm kiếm + Chế độ tối
- **Tìm kiếm sản phẩm** realtime ở màn Bán hàng (lọc theo tên) và **tìm đơn** ở màn
  Đơn hàng (theo mã/bàn), kèm trạng thái rỗng.
- **Chế độ tối** bật/tắt cho toàn app (Cài đặt + hồ sơ Thu ngân).
- Test: tìm kiếm lọc đúng lưới sản phẩm.

## v0.1.0 — Bản đầu + sửa lỗi
- Port đầy đủ từ mockup `tinypos.html`: 3 vai trò (Thu ngân/KDS/Quản trị), khung
  điện thoại cố định 480px, đủ màn hình + sheet.
- Vòng lặp sửa lỗi (walkthrough test): khắc phục 11 lỗi crash/overflow
  (Container color+decoration, gradient stops lệch, các RenderFlex tràn).
- Hạ tầng: GitHub Actions build APK/AAB + phát hành Firebase; ký release Android.
