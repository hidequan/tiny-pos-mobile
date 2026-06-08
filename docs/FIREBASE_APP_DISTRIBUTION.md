# Phát hành bản test qua Firebase App Distribution

Mục tiêu: tester nhận **email + link cài** APK, miễn phí, repo vẫn private.

Bạn làm 4 bước trong trình duyệt (đăng nhập Google), rồi đưa tôi 3 thông tin —
tôi lo phần tự động (đẩy APK + cấu hình CI để các bản sau tự phát hành).

## Bạn làm (một lần, ~5 phút)

1. **Tạo project**: https://console.firebase.google.com → *Add project* → đặt tên
   "Tiny POS" → có thể tắt Google Analytics → Create.

2. **Đăng ký app Android**: trong project → biểu tượng Android (Add app) →
   - *Android package name*: `com.tinypos.tiny_pos_mobile`
   - *App nickname*: Tiny POS (tuỳ ý)
   - Register app → **bỏ qua** bước tải `google-services.json` và các bước SDK
     (App Distribution không cần). Bấm Next/Continue cho hết.

3. **Lấy App ID**: ⚙️ *Project settings* → tab *General* → mục *Your apps* →
   copy **App ID** dạng `1:1234567890:android:abc123def456`.

4. **Lấy khoá service account**: ⚙️ *Project settings* → tab *Service accounts* →
   *Generate new private key* → tải file **JSON** về (giữ bí mật, đừng commit).

5. **(Tester)** Menu trái *Run* → *App Distribution* → *Get started* → tab *Testers
   & Groups* → tạo group tên **`testers`** → thêm email tester. (Hoặc chỉ cần đưa tôi
   danh sách email, tôi truyền vào lúc đẩy.)

## Đưa tôi 3 thứ

- **App ID** (ở bước 3).
- **Nội dung file JSON** service account (bước 4) — dán vào chat hoặc lưu vào
  `D:\tiny-pos-mobile\firebase-sa.json` (đã gitignore) rồi báo tôi.
- **Danh sách email tester** (nếu chưa tạo group ở bước 5).

## Tôi làm (tự động)

- Đẩy APK hiện tại lên ngay → bạn + tester nhận link:
  `firebase appdistribution:distribute app-release.apk --app <APP_ID> --groups testers`
- Đặt secret cho CI để **mỗi lần build sau tự phát hành**:
  `gh secret set FIREBASE_APP_ID` và `gh secret set FIREBASE_SERVICE_ACCOUNT`
  (workflow `.github/workflows/android.yml` đã có sẵn bước này).

> File JSON service account và `firebase-sa.json` đã nằm trong `.gitignore` — không lọt vào repo.
