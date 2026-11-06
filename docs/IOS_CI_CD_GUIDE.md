# HƯỚNG DẪN BUILD FILE IPA CHO IPHONE BẰNG GITHUB ACTIONS (CI/CD)

Tài liệu này hướng dẫn bạn cách sử dụng GitHub Actions tự động build file `.ipa` từ mã nguồn Flutter và cài đặt lên máy iPhone thực tế (ngay cả khi bạn đang dùng máy tính Windows và không có máy Mac!).

---

## 1. CÁC TÙY CHỌN BUILD IPA TRONG WORKFLOW

Quy trình CI/CD được cấu hình hỗ trợ **2 chế độ build**:

| Chế độ | Yêu cầu | Cách cài lên iPhone | Phù hợp với |
| :--- | :--- | :--- | :--- |
| **Unsigned IPA** *(Mặc định)* | **Miễn phí 100%**, không cần tài khoản Apple Developer ($99/năm) | Dùng **Sideloadly**, **AltStore** hoặc **TrollStore** | Developer cá nhân, test máy thật nhanh chóng |
| **Signed IPA** | Cần tài khoản **Apple Developer** ($99/năm) có Certificate (`.p12`) và Provisioning Profile | Cài trực tiếp qua TestFlight, Ad Hoc hoặc MDM | Triển khai phân phối nội bộ hoặc đưa lên App Store |

---

## 2. CẤU HÌNH GITHUB SECRETS (BẮT BUỘC & TÙY CHỌN)

Vào repository của bạn trên GitHub:
`Settings` -> `Secrets and variables` -> `Actions` -> nhấn nút **New repository secret**.

### A. Cấu hình Supabase (Bắt buộc để app kết nối CSDL)
* `SUPABASE_URL`: URL dự án Supabase của bạn (ví dụ: `https://xxxx.supabase.co`).
* `SUPABASE_ANON_KEY`: Khóa anon public từ Supabase Dashboard.

### B. Cấu hình Apple Developer (Chỉ cần nếu chọn Signed IPA)
* `APPLE_CERTIFICATE_BASE64`: File chứng chỉ `.p12` đã mã hóa dạng Base64.
* `APPLE_CERTIFICATE_PASSWORD`: Mật khẩu của file `.p12`.
* `APPLE_PROVISIONING_PROFILE_BASE64`: File `.mobileprovision` đã mã hóa dạng Base64.

> **Mẹo mã hóa file sang Base64 trên Windows (PowerShell):**
> ```powershell
> [Convert]::ToBase64String([IO.File]::ReadAllBytes("path\to\cert.p12")) | Set-Clipboard
> ```
> Sau đó chỉ cần dán (Paste) vào trường Secret trên GitHub!

---

## 3. CÁCH CHẠY WORKFLOW BUILD IPA

### Cách 1: Chạy thủ công trên GitHub (Workflow Dispatch)
1. Truy cập vào GitHub repo của bạn.
2. Bấm vào tab **Actions**.
3. Ở menu bên trái, chọn workflow **Build iOS IPA**.
4. Nhấn nút **Run workflow**:
   - Chọn nhánh (mặc định: `main`).
   - Chọn chế độ build: `unsigned` (khuyên dùng nếu không có tk trả phí) hoặc `signed`.
5. Bấm **Run workflow** màu xanh để bắt đầu.

### Cách 2: Tự động build khi gắn Tag Release
Mỗi khi bạn tạo và push một Git tag (ví dụ: `v1.0.0`):
```bash
git tag v1.0.0
git push origin v1.0.0
```
GitHub Actions sẽ tự động kích hoạt, build file `.ipa` và tạo một bản **GitHub Release** đính kèm file `.ipa` sẵn sàng để tải về.

---

## 4. TẢI FILE IPA SAU KHI BUILD THÀNH CÔNG

1. Vào tab **Actions** -> Chọn lần chạy vừa hoàn thành (có dấu tích xanh ✅).
2. Cuộn xuống phần **Artifacts** ở cuối trang.
3. Nhấp vào **cinema-booking-ipa** để tải file zip về máy tính.
4. Giải nén file zip, bạn sẽ nhận được file `cinema_booking_v1.ipa`.

---

## 5. HƯỚNG DẪN CÀI FILE IPA VÀO IPHONE (TRÊN WINDOWS)

### Cách khuyên dùng: Dùng Sideloadly (Miễn phí, chỉ mất 1 phút)
1. Tải và cài đặt **Sideloadly** trên máy tính Windows: [sideloadly.io](https://sideloadly.io/).
2. Đảm bảo máy tính đã cài **iTunes** (bản tải từ trang chủ Apple, không dùng bản Microsoft Store).
3. Cắm cáp kết nối iPhone vào máy tính (chọn "Tin cậy máy tính này" trên iPhone).
4. Mở Sideloadly:
   - Kéo và thả file `cinema_booking_v1.ipa` vào ô IPA.
   - Nhập Apple ID cá nhân của bạn vào ô `Apple ID`.
   - Bấm nút **Start**.
5. Nhập mật khẩu Apple ID (hoặc mã xác thực 2 bước gửi về iPhone).
6. Sau khi hoàn tất (hiển thị `Done`), trên iPhone:
   - Vào `Cài đặt (Settings)` -> `Cài đặt chung (General)` -> `Quản lý VPN & Thiết bị (VPN & Device Management)`.
   - Nhấn vào Apple ID của bạn -> Chọn **Tin cậy (Trust)**.
   - (Trên iOS 16+) Vào `Cài đặt` -> `Quyền riêng tư & Bảo mật` -> Bật **Chế độ nhà phát triển (Developer Mode)** và khởi động lại máy.
7. Mở app và trải nghiệm!

### Cách khác:
- **AltStore**: [altstore.io](https://altstore.io/) (Cài đặt tương tự, hỗ trợ tự động gia hạn chứng chỉ qua Wi-Fi).
- **TrollStore**: Nếu iPhone đang chạy phiên bản iOS được TrollStore hỗ trợ, bạn chỉ cần chia sẻ file `.ipa` vào iPhone và mở bằng TrollStore để cài vĩnh viễn không bao giờ hết hạn.
