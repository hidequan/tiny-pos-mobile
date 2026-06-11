# Test trên điện thoại qua LAN (backend cục bộ — an toàn, không đụng web khách)

App chạy ở máy này, điện thoại cùng wifi mở trình duyệt là test được — **mọi thao tác
ghi (tạo bill, thanh toán) vào backend CỤC BỘ**, không ảnh hưởng web production của khách.

## Mở trên điện thoại
1. Điện thoại **cùng mạng wifi** với máy tính (IP máy: `192.168.1.43`).
2. Mở trình duyệt → **http://192.168.1.43:8099**
3. Đăng nhập tài khoản **dữ liệu cục bộ**:
   - Thu ngân: `cashier01` / `cashier123`
   - Pha chế (KDS): `barista01` / `barista123`
   - Quản trị: `superadmin` / `admin123`

## 3 dịch vụ phải chạy trên máy (đang chạy sẵn)
| Dịch vụ | Cổng | Lệnh khởi động lại |
|---|---|---|
| PostgreSQL (portable) | 5432 | `cd D:\tiny-pos; npm run db:local:start` |
| API (NestJS, **bản built**) | 4000 | `cd D:\tiny-pos\apps\api; node dist\main.js` |
| Web (app) | 8099 | `cd D:\tiny-pos-mobile; node tool\serve_web.cjs` |

> ⚠️ Dùng `node dist\main.js` cho API (KHÔNG dùng `npm run start:dev` — bản watch bị treo
> trên máy này). Nếu sửa code backend: `npm -w @tiny/api run build` rồi chạy lại dist.
> CORS đã mở cho `http://192.168.1.43:8099` trong `D:\tiny-pos\.env` (CORS_ORIGINS).

## Build lại web (khi app có thay đổi) — vẫn trỏ LAN backend
```powershell
cd D:\tiny-pos-mobile
flutter build web --release --dart-define=API_BASE=http://192.168.1.43:4000/api
# rồi để node tool\serve_web.cjs phục vụ (đọc lại build/web tự động)
```

## 🔌 Khi app HOÀN THIỆN → tích hợp dữ liệu với web (1 tham số duy nhất)
Toàn bộ app đã viết theo **API contract của backend dùng chung** (đăng nhập, menu, bill,
thanh toán... đều gọi đúng endpoint web đang dùng). Để chuyển sang **dùng chung dữ liệu
với web khách**, chỉ cần build lại trỏ production — **không sửa code, không đổi model**:
```powershell
flutter build apk   --release --dart-define=API_BASE=https://pos.lptech.info.vn/api
flutter build web   --release --dart-define=API_BASE=https://pos.lptech.info.vn/api
```
Mặc định (không truyền `--dart-define`) app đã trỏ thẳng `https://pos.lptech.info.vn/api`.
Lúc đó app và web **chung một dữ liệu** đúng như yêu cầu "app và web là 1".
