# Tiny POS — Mobile (Flutter)

Ứng dụng POS chuỗi cà phê, dựng bằng **Flutter** từ bản thiết kế đã duyệt `tinypos.html`
(tông màu coffee ấm: espresso / terracotta / caramel / cream). Một codebase chạy cho
**Web · Android · iOS**.

Web hiển thị theo **khung điện thoại cố định** (rộng tối đa 480px, căn giữa) — **không
responsive** — để khớp 1:1 với giao diện mobile trong file HTML gốc.

## Tính năng (3 vai trò, khớp mockup)

- **Thu ngân**: bán hàng (grid món + tùy chọn size/đường/đá/topping/ghi chú), giỏ hàng,
  khuyến mãi, thanh toán (tiền mặt/QR/thẻ/MoMo, tính tiền thối), in bill, đơn hàng,
  sơ đồ bàn (mở/đang phục vụ/chờ thanh toán), ca làm + đối soát tiền mặt.
- **KDS / Bar** (theme tối): hàng chờ real-time (đếm giờ, cảnh báo trễ), tick từng món,
  hoàn thành đơn, đã xong, thống kê pha chế.
- **Quản trị**: tổng quan (KPI + biểu đồ 7 ngày), thực đơn (CRUD + bật/tắt bán), kho +
  định lượng (BOM), báo cáo (biểu đồ + donut cơ cấu thanh toán), nhân viên & RBAC,
  khuyến mãi, chi nhánh, ca làm, cài đặt hệ thống.

## Cấu trúc

```
lib/
  main.dart                  # MaterialApp + Provider<AppState>
  theme/                     # palette (light + KDS dark), typography (Fraunces+Hanken), icon map
  data/                      # models + seed (port nguyên seed của tinypos.html) + format tiền
  state/app_state.dart       # toàn bộ state + business logic (ChangeNotifier)
  widgets/                   # phone_frame (khung 480px), bottom nav, shell (sheet/toast), common UI
  screens/
    login_screen.dart
    cashier/                 # sell, orders, tables, shift + sheets (options/cart/payment)
    kds/                     # queue, done, stats
    admin/                   # home, menu, inv, reports, more + subs (staff/promos/branches/shift) + sheets
```

State management: `provider` + `ChangeNotifier`. Fonts: `google_fonts` (Fraunces + Hanken Grotesk).

---

## Yêu cầu môi trường

| Thành phần | Dùng cho | Trạng thái máy này |
|---|---|---|
| Flutter SDK (stable) | tất cả | đã cài tại `D:\dev\flutter` |
| Chrome / trình duyệt | chạy & build web | có |
| JDK 17 | build Android | đã cài tại `D:\dev\jdk17` (Temurin) |
| Android SDK (platform-tools, android-35, build-tools 35) | build APK/AAB, emulator | cài tại `D:\dev\android-sdk` |
| Xcode (macOS) | build iOS | chỉ có trên máy Mac / cloud Codemagic |

Trỏ Flutter tới toolchain cục bộ (một lần):

```powershell
$env:PATH = "D:\dev\flutter\bin;$env:PATH"
flutter config --android-sdk D:\dev\android-sdk --jdk-dir D:\dev\jdk17
flutter doctor
```

---

## Lệnh thường dùng

```powershell
$env:PATH = "D:\dev\flutter\bin;$env:PATH"
flutter pub get
flutter analyze                 # tĩnh: 0 lỗi
flutter test                    # smoke test: login hiện 3 vai trò

# WEB (khung mobile căn giữa)
flutter run -d chrome           # dev, hot reload
flutter build web --release     # ra build/web/  →  node tool/serve_web.cjs  (http://localhost:8099)

# ANDROID
flutter build apk --release         # ra build/app/outputs/flutter-apk/app-release.apk
flutter build appbundle --release   # ra build/app/outputs/bundle/release/app-release.aab
flutter emulators --launch <id>     # mở giả lập rồi:  flutter run

# iOS (chỉ macOS)
flutter build ipa --release
```

---

## Lộ trình 8 bước & trạng thái

1. **Flutter Web — khung mobile khớp HTML** — ✅ Xong. `flutter build web` pass, `flutter analyze` 0 lỗi.
2. **APK + giả lập** — ⚠️ Toolchain (JDK17 + Android SDK) đã cài & cấu hình xong, NHƯNG build
   Gradle cục bộ **bị chặn bởi máy này** (xem mục *Sự cố loopback* bên dưới). Build APK chạy
   được trên **Codemagic cloud** (workflow `android-artifacts`) hoặc trên một máy Windows không
   bị lỗi loopback. Giả lập: cần system image + tăng tốc phần cứng (WHPX) — cũng cần loopback OK.
3. **App Bundle (AAB) + link test** — ⚠️ Cùng tình trạng: lệnh `flutter build appbundle` đã sẵn
   sàng, ra AAB qua Codemagic; link test phát hành qua Google Play internal track khi có tài khoản.
4. **iOS TestFlight qua Codemagic** — ⚙️ Đã cấu hình `codemagic.yaml` (workflow `ios-testflight`).
   Cần: App Store Connect API key + bundle id đăng ký.
5. **Thêm tester (TestFlight + Google Play)** — ⏸ Cần tài khoản store. Hướng dẫn bên dưới.
6. **Vòng lặp sửa lỗi** — ⏸ Sau khi có bản build chạy trên thiết bị/giả lập.
7. **Cập nhật version phụ** — ⏸ Tăng `version:` trong `pubspec.yaml` (vd `0.1.1+2`).
8. **Hồ sơ kiểm duyệt store** — ⏸ Cần icon, screenshot, mô tả, chính sách bảo mật.

> Bạn **chưa có** credentials store (GitHub/Apple/Google). Các bước 4–8 đã được dựng sẵn cấu
> hình + tài liệu; sẽ thực thi khi bạn cung cấp tài khoản/API key.

---

## CI/CD — Codemagic (`codemagic.yaml`)

4 workflow:

| Workflow | Ra gì | Cần credential |
|---|---|---|
| `android-artifacts` | APK + AAB (tải về test) | không |
| `android-playstore` | AAB ký + đẩy Play internal track | keystore + service-account JSON |
| `ios-testflight` | IPA + đẩy TestFlight | App Store Connect API key |
| `web-build` | bundle web (.zip) | không |

Cấu hình credential trong Codemagic UI (KHÔNG commit vào repo): xem chú thích đầu file
`codemagic.yaml`. Codemagic build trên cloud nên không cần Xcode/Android SDK cục bộ.

### Thêm tester (bước 5)
- **TestFlight (iOS)**: App Store Connect → ứng dụng → TestFlight → Internal/External Testing →
  thêm email tester (hoặc tạo group, khai trong `codemagic.yaml` mục `beta_groups`).
- **Google Play (Android)**: Play Console → Testing → Internal testing → tạo danh sách tester
  (email) → chia sẻ "opt-in URL".

### Hồ sơ kiểm duyệt (bước 8)
- Icon app (1024×1024), feature graphic, screenshot điện thoại, mô tả, từ khóa.
- Chính sách bảo mật (URL bắt buộc), phân loại nội dung, thông tin liên hệ.
- Android: điền Data Safety. iOS: điền App Privacy + Export Compliance.

---

## Sự cố loopback (build Gradle cục bộ trên máy này)

`flutter build apk/appbundle` thất bại ngay với:

```
java.io.IOException: Unable to establish loopback connection
  Caused by: java.net.SocketException: Invalid argument: connect
    at sun.nio.ch.PipeImpl$Initializer$LoopbackConnector.run
```

Đã chẩn đoán: ngay cả `Selector.open()` của Java NIO cũng lỗi trên máy này — JVM không tạo
được "self-pipe" loopback mà Gradle bắt buộc dùng. Đây **không phải lỗi code**; socket loopback
thường (java.net, node) vẫn chạy, chỉ NIO selector bị chặn. Đã loại trừ: dải cổng Hyper-V
(bình thường), WSL (đã tắt), IPv4/IPv6 preference (không đổi), Gradle daemon on/off, sandbox of/off.

Nguyên nhân thường gặp & cách xử lý (cần quyền admin):
- Phần mềm bảo mật/AntiVirus/EDR hoặc VPN cài LSP chặn loopback của `java.exe` → thêm ngoại lệ
  cho `D:\dev\jdk17\bin\java.exe`, hoặc tạm tắt để thử.
- Winsock catalog hỏng → `netsh winsock reset` rồi khởi động lại máy.
- Kiểm tra firewall cho loopback của java.

➡️ Trong khi chưa sửa được ở máy này, build APK/AAB/IPA qua **Codemagic** (mục CI/CD) là đường
chạy được — runner cloud không gặp lỗi này. Web build cục bộ vẫn bình thường.

## Ký release Android

1. Tạo keystore:
   ```powershell
   D:\dev\jdk17\bin\keytool -genkey -v -keystore upload-keystore.jks -storetype JKS `
     -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
2. Copy `android/key.properties.example` → `android/key.properties`, điền đường dẫn + mật khẩu.
3. `flutter build appbundle --release` sẽ tự ký bằng keystore đó.

`android/key.properties` và `*.jks` đã được gitignore — không lọt vào repo.
