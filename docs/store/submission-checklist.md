# Checklist nộp kiểm duyệt — Tiny POS

Tài sản đã chuẩn bị sẵn (trong repo) ✅ · Việc cần tài khoản store ⏳

## Tài sản đồ họa (đã có)
- ✅ App icon 1024×1024 — `assets/icon/icon.png` (đã sinh icon mọi nền qua flutter_launcher_icons)
- ✅ Adaptive icon (foreground + nền #241008)
- ✅ Splash screen (flutter_native_splash, nền #241008)
- ✅ Feature graphic 1024×500 — `assets/store/feature_graphic.png`
- ✅ 6 screenshots điện thoại (1170×2532) — `assets/store/screenshots/01..06`

## Nội dung (đã có)
- ✅ Tên, mô tả ngắn/đầy đủ, từ khóa — `docs/store/listing.md`
- ✅ Chính sách bảo mật — URL công khai: **https://hidequan.github.io/tiny-pos-privacy/**
  (⚠️ host từ repo riêng `hidequan/tiny-pos-privacy` — phải đẩy bản HTML mới ở
  `docs/store/privacy-site/index.html` lên đó thì trang công khai mới cập nhật)
- ✅ Data Safety (Play) + App Privacy (iOS): **Data Collected** (tài khoản + dữ liệu vận hành,
  truyền qua HTTPS) — `docs/store/data-safety.md`
- ✅ `ITSAppUsesNonExemptEncryption=false` đã thêm vào iOS Info.plist
- ✅ Nhà phát triển **LP Tech** · hỗ trợ **hidequan@gmail.com** (lỗi 1.5 Developer Information)

## Google Play (⏳ cần tài khoản Play Developer $25)
1. Tạo app trong Play Console → điền: tên, mô tả, danh mục Business, email, **privacy URL**.
2. Upload **AAB** (lấy từ CI artifact `tiny-pos-aab`, hoặc workflow `android-playstore`).
3. Graphics: icon 512 (Play tự lấy từ AAB hoặc upload `icon.png`), feature graphic, screenshots.
4. **Data safety** form → **Data Collected** (Yes), theo `data-safety.md`.
5. Content rating questionnaire → kết quả 3+ (Everyone).
6. Tạo **Internal testing** → thêm email tester → phát hành để duyệt.
7. (Tự động) Cấu hình secret `GCLOUD_SERVICE_ACCOUNT_CREDENTIALS` cho workflow Codemagic
   `android-playstore` để CI đẩy AAB lên track internal.

## App Store / TestFlight (⏳ cần Apple Developer $99/năm)
1. App Store Connect → tạo app, bundle id `com.tinypos.tinyPosMobile`.
2. App Privacy → **Data Collected** (theo `data-safety.md`) — KHÔNG để "Data Not Collected".
3. Build IPA + upload qua Codemagic workflow `ios-testflight` (cần App Store Connect API key).
4. Điền metadata (mô tả, từ khóa, screenshots), **Support URL**, gửi review.
5. **App Review Information** (BẮT BUỘC — app gated sau login): khai tài khoản demo THẬT:
   - Admin (xem hết tính năng): `superadmin` / `admin123`
   - Thu ngân: `cashier01` / `cashier123` · Pha chế (KDS): `barista01` / `barista123`
   - Ghi chú: app cần kết nối backend `pos.lptech.info.vn` (đang chạy 24/7) để đăng nhập.
   - ⚠️ KHÔNG dùng `manager01/manager123` — tài khoản này không tồn tại, gây reject 2.1.

## Phiên bản
- Tăng `version` trong `pubspec.yaml` trước mỗi lần nộp (vd `0.1.3+4`).
- `flutter build appbundle --release` (Codemagic) tạo AAB đã ký bằng upload keystore
  (`android/key.properties` — xem README mục *Ký release Android*).

## Lệnh tái tạo tài sản (nếu sửa icon/screenshot)
```
dart run flutter_launcher_icons        # sinh lại icon mọi nền
dart run flutter_native_splash:create  # sinh lại splash
flutter build web --release            # build web để chụp
node tool/serve_web.cjs                # serve :8099
node tool/screenshots.cjs              # chụp lại 6 screenshots
```
