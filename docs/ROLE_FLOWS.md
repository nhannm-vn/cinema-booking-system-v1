# ROLE_FLOWS.md — Luồng chi tiết theo từng role

> Đọc cùng `SCREENS.md` (chi tiết giao diện từng màn), `BUSINESS_RULES.md` (nghiệp vụ) và `DATA.md` (dữ liệu).
> Mục M = bắt buộc. Mục S = mức sau.

---

## 0. Điều hướng theo role

| Role | Bottom navigation | Màn mở đầu sau đăng nhập |
|---|---|---|
| Guest | PHIM · RẠP · VÉ CỦA TÔI · TÀI KHOẢN | S03 (VÉ CỦA TÔI và TÀI KHOẢN yêu cầu đăng nhập) |
| Customer | PHIM · RẠP · VÉ CỦA TÔI · TÀI KHOẢN | S03, hoặc màn đang chờ trước khi đăng nhập |
| Staff | SOÁT VÉ · ĐỒ ĂN · BÁN VÉ · TÀI KHOẢN | S18 |
| Manager | TỔNG QUAN · QUẢN LÝ · TÀI KHOẢN | S22 |
| Admin | TỔNG QUAN · QUẢN LÝ · TÀI KHOẢN | S22 |

**Quy tắc chung:**
- Sau đăng nhập, app đọc `users/{uid}.role` và vào đúng bộ tab.
- Tài khoản `isLocked == true`: báo "Tài khoản đã bị khóa", gọi `signOut()`, quay về S01.
- Luồng đặt vé không hiện bottom nav và có nút back về bước trước.
- Chuông thông báo (S30) có badge chưa đọc ở AppBar của S03, S17, S10, S11, S18, S22.

---

## 1. Guest (chưa đăng nhập)

### 1.1 Được phép
- Xem S03 trang chủ, tìm phim.
- Xem S04 chi tiết phim.
- Xem S17 danh sách và bản đồ rạp, S17B chi tiết rạp.
- Xem S05 danh sách suất chiếu (chỉ xem).

### 1.2 Bị chặn và chuyển sang đăng nhập
| Hành động | Chuyển đến | Sau khi đăng nhập |
|---|---|---|
| Bấm TIẾP TỤC/chọn suất ở S05 | S01 | Quay lại đúng suất đang chọn |
| Mở tab VÉ CỦA TÔI | S01 | Về tab VÉ CỦA TÔI |
| Mở tab TÀI KHOẢN | S01 | Về tab TÀI KHOẢN |
| Nhấn chuông thông báo | S01 | Về S30 |

### 1.3 Đăng ký
1. S01 → chọn "CHƯA CÓ TÀI KHOẢN? ĐĂNG KÝ".
2. S02: họ tên, email, SĐT (10 số), mật khẩu (≥6 ký tự), nhập lại mật khẩu.
3. Validate từng trường. Email trùng: "Email đã được sử dụng".
4. Tạo Firebase Auth user, ghi `users/{uid}` với `role = customer`, `isLocked = false`.
5. Đăng nhập luôn, quay về màn đang chờ (nếu có) hoặc S03.

---

## 2. Customer (khách đã đăng nhập)

### Bước 1: Khám phá phim (S03)
- Hero: PageView các backdrop đang chiếu (tối đa 5). Nút ĐẶT VÉ và CHI TIẾT.
- Ô tìm kiếm: lọc phim trên client. Không có kết quả: "Không tìm thấy phim phù hợp".
- Lưới ĐANG CHIẾU (2 cột). Hàng cuộn ngang SẮP CHIẾU.
- Loading: skeleton hero và lưới. Error: `ErrorState` với THỬ LẠI.

### Bước 2: Chi tiết phim (S04)
- Backdrop fade xuống `canvas`. Tên phim, `SpecCell` (phút, độ tuổi, định dạng).
- Mô tả, đạo diễn, diễn viên.
- XEM TRAILER (outline, mở link ngoài bằng `url_launcher`).
- Thanh dính đáy: ĐẶT VÉ. Phim sắp chiếu: "CHƯA MỞ BÁN" (disabled).

### Bước 3: Chọn suất chiếu (S05)
- Dải 7 ngày. Chọn ngày, danh sách suất gom theo rạp.
- Suất hết chỗ hoặc đã qua giờ: chữ `muted`, nhãn "HẾT VÉ", không bấm được.
- Chạm suất:
  1. Chưa đăng nhập → S01 (xem Guest 1.2).
  2. Phim T16 hoặc T18 → hộp xác nhận "Phim dành cho khán giả từ 16 tuổi. Xác nhận bạn đủ tuổi." (chỉ hiện cảnh báo, kiểm tra thật ở quầy).
  3. Sang S06.
- Ngày không có suất: "Chưa có suất chiếu trong ngày này".

### Bước 4: Chọn ghế (S06) — màn trọng tâm
1. Mở sơ đồ từ `seatLayout` của phòng ghép với `showtimes/{sid}/seats`. Loading: skeleton lưới.
2. Chạm ghế trống: chọn. Chạm lại: bỏ chọn.
3. Ghế đã bán hoặc người khác đang giữ: thông báo nhẹ "Ghế này không còn trống".
4. Chọn đến 8 ghế. Vượt quá: snackbar `warning`.
5. Thanh dưới: "2 GHẾ · A5, A6" và tổng tiền (tính tạm từ bảng giá đã cache, chốt lại ở bước 8).
6. Bấm TIẾP TỤC → transaction `holdSeats` (BUSINESS_RULES mục 5):
   - Thành công: ghi booking `holding`, `holdUntil = now + 5 phút`. Sang S07.
   - Lỗi `SeatTakenException`: "Ghế [X] vừa có người chọn. Vui lòng chọn ghế khác." Làm mới sơ đồ, giữ các ghế còn lại.
7. Thoát khi đã giữ ghế → hộp xác nhận "Rời khỏi và nhả ghế?". Đồng ý: `releaseHold()`.

### Bước 5: Chọn đồ ăn (S07, có thể bỏ qua)
1. Đồng hồ giữ ghế ở đầu màn. Dưới 60 giây: chuyển `warning`.
2. Tab: COMBO · BẮP · NƯỚC · SNACK.
3. Mỗi món: ảnh vuông, tên, mô tả, giá, `QuantityStepper`. Món hết hàng: mờ.
4. TIẾP TỤC hoặc BỎ QUA → S08. Cập nhật `foods` trong booking (hoặc để rỗng khi bỏ qua).
5. Hết giờ giữ ghế: dialog "Hết thời gian giữ ghế" → về S06, ghế đã nhả.

### Bước 6: Thanh toán (S08)
1. Hiển thị tóm tắt: poster nhỏ, tên phim, rạp · phòng · giờ, ghế, đồ ăn. Chi tiết giá: tiền vé, tiền đồ ăn, giảm giá (nếu có), tổng.
2. Voucher (S): nhập mã, ÁP DỤNG. Lỗi cụ thể theo BUSINESS_RULES mục 11.
3. Chọn phương thức: VNPay Sandbox (mặc định). Có "Demo" nếu đã chốt (BUSINESS_RULES mục 18).
4. Đồng hồ giữ ghế hiển thị.
5. Bấm THANH TOÁN QUA VNPAY:
   - Kiểm tra booking còn `holding`. Quá hạn → dialog, về S06.
   - Tạo payment `pending`, tạo URL ký HMAC-SHA512.
   - Mở `VNPayWebViewScreen` với URL.
6. Trong WebView:
   - Khách thanh toán bằng thẻ test sandbox.
   - Chặn return URL, xác minh chữ ký.
   - `00` → `confirmPaid` → S09.
   - Mã khác hoặc hủy → đóng WebView, thông báo lỗi, ở lại S08, booking vẫn `holding`.
   - Hết giờ giữ ghế → đóng WebView, về S06.

### Bước 7: Vé thành công (S09)
- Dấu tick `success`, "ĐẶT VÉ THÀNH CÔNG".
- `TicketCard`: phim, rạp, phòng, ngày giờ, ghế, đồ ăn ("Nhận tại quầy"), mã booking, QR.
- Nút XEM VÉ CỦA TÔI (primary) và VỀ TRANG CHỦ (text).
- Back hệ thống về S03, không quay lại luồng đặt.
- Thông báo `bookingPaid` được tạo.

### Bước 8: Quản lý vé (S10)
- Tab SẮP TỚI · ĐÃ XEM · ĐÃ HỦY (xem BUSINESS_RULES mục 7).
- Chạm vé: mở chi tiết giống S09.
- Vé SẮP TỚI còn ≥ 2 giờ: nút HỦY VÉ (outline) → hộp xác nhận → `cancelBooking()`, hoàn tiền 100%, thông báo.
- Rỗng: "Bạn chưa có vé nào" + ĐẶT VÉ NGAY.

### Bước 9: Tài khoản (S11)
- Avatar chữ cái đầu, họ tên, email.
- SỬA HỒ SƠ → họ tên, SĐT → LƯU THAY ĐỔI (không đổi email, không đổi role).
- HỘP THƯ HỖ TRỢ (S31, mức S).
- ĐĂNG XUẤT → S01 hoặc S03 (guest).

### Bước 10: Rạp (S17, S17B)
1. Xin quyền vị trí. Từ chối vẫn dùng được, không hiện khoảng cách.
2. Bản đồ với marker các rạp và vị trí người dùng. Nút "Định vị vị trí của tôi".
3. Danh sách rạp dạng `DraggableScrollableSheet`: tên, khoảng cách (nếu có GPS), địa chỉ, số phòng.
4. Chạm marker hoặc hàng rạp → S17B: ảnh, tên, địa chỉ, hotline, CHỈ ĐƯỜNG (mở Google Maps ngoài), XEM SUẤT CHIẾU HÔM NAY → S05 lọc theo rạp.

### Bước 11: Thông báo (S30)
- Danh sách mới → cũ, chấm chưa đọc.
- ĐÁNH DẤU TẤT CẢ ĐÃ ĐỌC.
- Chạm thông báo vé → S09 hoặc S10.
- Nhắc giờ chiếu: local notification đặt lúc đặt vé thành công, trước 1 giờ giờ chiếu.

### Bước 12: Hỗ trợ (S31, mức S)
- Chọn rạp, khung chat hai chiều, đính kèm mã booking.

---

## 3. Staff (nhân viên rạp)

Tất cả query đều lọc `cinemaId` của Staff.

### 3.1 Soát vé (S18) — tab SOÁT VÉ, M
1. Mở tab, xin quyền camera. Chưa cấp: giải thích và nút mở cài đặt.
2. Khung camera chiếm phần lớn màn hình. Dòng đầu: tên rạp đang làm việc.
3. Quét QR → lấy `bookingCode` → `get(bookings/{code})`.
4. Kiểm tra theo thứ tự BUSINESS_RULES mục 8.
5. Kết quả trong `ResultSheet`:
   - **Hợp lệ:** tick `success`, phim, phòng, giờ, ghế, đồ ăn (nếu có). Với T16/T18: khối cảnh báo `warning` và ô tick "Đã kiểm tra giấy tờ tùy thân". Nút XÁC NHẬN CHO VÀO (primary).
   - **Không hợp lệ:** dấu × `warning`, lý do cụ thể. Nút QUÉT TIẾP.
6. Xác nhận: transaction soát vé, `status = used`, ghi `auditLogs`. Rung nhẹ, đóng sheet, tiếp tục quét.
7. Nhập mã tay: nút NHẬP MÃ TAY (outline), ô nhập 8 ký tự, cùng kiểm tra như quét.
8. Lỗi mạng: `ErrorState`, không cho xác nhận khi chưa đọc được vé.

### 3.2 Quầy đồ ăn (S19) — tab ĐỒ ĂN, M
1. Hai tab: CHỜ GIAO · ĐÃ GIAO.
2. Ô tìm theo mã booking, icon QR mở camera.
3. Danh sách CHỜ GIAO: `foodStatus == pending` của rạp, sắp theo giờ chiếu. Mỗi đơn: mã, giờ · phòng, món × số lượng, nút ĐÃ GIAO.
4. ĐÃ GIAO → hộp xác nhận ngắn → transaction: `foodStatus = delivered`, `foodDeliveredBy`, `foodDeliveredAt`, thông báo cho khách. Chuyển sang tab ĐÃ GIAO.
5. Đơn của booking đã hủy: ẩn hoặc gắn nhãn HỦY.
6. Rỗng: "Chưa có đơn đồ ăn cần giao".

### 3.3 Bán vé tại quầy (S20, S21) — tab BÁN VÉ, S
1. Danh sách suất hôm nay của rạp, còn trong khung bán quầy, nhóm theo phim (`ShowtimeRow`).
2. Chọn suất → S06 (giữ 3 phút, `channel = counter`, `soldBy = uid`) → S07 → S21.
3. S21: tóm tắt đơn. Chọn TIỀN MẶT hoặc THẺ/CHUYỂN KHOẢN.
   - Tiền mặt: nhập KHÁCH ĐƯA bằng bàn phím số. TIỀN THỪA tính tự động (`displayLg`). Nút xác nhận khóa nếu đưa thiếu.
   - Thẻ/chuyển khoản: xác nhận đã nhận tiền.
4. Xác nhận: booking `paid`, `paymentMethod`, `paidAt`, ghế `sold`, `foodStatus` nếu có món.
5. Hiện vé với QR (như S09), nút IN / CHIA SẺ tùy chọn.
6. Giữ ghế quá 3 phút: hết giờ, ghế nhả.

### 3.4 Tài khoản (TÀI KHOẢN)
- Thông tin Staff, rạp đang làm, ĐĂNG XUẤT.
- Không đổi rạp, không đổi role.

### 3.5 Giới hạn của Staff
- Không xem danh sách booking toàn rạp (S15), không sửa suất, phim, giá, nhân viên.
- Đọc được vé rạp khác để báo "Vé thuộc rạp khác" (rule `get`), nhưng không soát vé đó.

---

## 4. Manager (quản lý rạp)

Phạm vi: `cinemaId` của Manager. Không có bộ lọc rạp.

### 4.1 Tổng quan (S22) — tab TỔNG QUAN, S
- Chọn khoảng: HÔM NAY · 7 NGÀY · THÁNG.
- Lưới `SpecCell`: doanh thu vé, doanh thu đồ ăn, số vé bán, tỉ lệ lấp đầy.
- Hàng ONLINE / QUẦY.
- SUẤT SẮP CHIẾU: giờ, phim, phòng, đã bán/tổng ghế, thanh tiến độ mảnh.
- Nếu chưa làm mức S: chỉ hiện số booking hôm nay và doanh thu hôm nay.
- Chỉ tính booking có `paidAt`, bỏ `cancelled`.

### 4.2 Quản lý (S12) — tab QUẢN LÝ
Hiển thị đúng bảng quyền dưới đây:

| Mục | Manager |
|---|---|
| Suất chiếu (S14) | Có |
| Danh sách booking (S15) | Có |
| Nhân viên (S23) | Có |
| Menu đồ ăn (S16) | Có |
| Hộp thư hỗ trợ (S31) | Có |
| Phim (S13) | Chỉ xem |
| Bảng giá (S26) | Chỉ xem |
| Rạp và phòng (S25) | Không |
| Voucher (S27) | Không |
| Quản lý Manager (S28) | Không |
| Nhật ký (S29) | Không |

### 4.3 Suất chiếu (S14)
1. Danh sách lọc theo ngày. Hàng: giờ, phim, phòng, định dạng, số ghế đã bán.
2. THÊM SUẤT: chọn phim, phòng (chỉ phòng của rạp mình), ngày, giờ bắt đầu, định dạng. Giờ kết thúc tự tính.
3. Lưu: kiểm tra chồng giờ và khoảng nghỉ 15 phút. Lỗi hiện đúng suất đang chồng.
4. Sửa: chỉ cho sửa giờ, phòng khi chưa có vé bán.
5. Xóa: từ chối nếu có booking `paid`. Gợi ý dùng HỦY SUẤT.
6. HỦY SUẤT (S): hộp xác nhận, số vé bị hủy, bắt buộc lý do → theo BUSINESS_RULES mục 10.3.

### 4.4 Booking (S15)
1. Chip lọc trạng thái: TẤT CẢ · PAID · USED · NOSHOW · CANCELLED · EXPIRED.
2. Chip kênh: ONLINE · QUẦY.
3. Hàng: mã booking, tên khách, phim, giờ, tổng tiền, badge trạng thái và kênh.
4. Chạm hàng: ghế, đồ ăn và trạng thái, phương thức thanh toán, mã giao dịch VNPay, thời gian tạo, ai soát vé và lúc nào, nhân viên bán.
5. Vé quầy: HỦY / HOÀN VÉ (S), nhập lý do, ghi nhật ký.

### 4.5 Menu đồ ăn (S16)
- Danh sách theo nhóm. Mỗi hàng: ảnh, tên, giá, công tắc CÒN HÀNG / HẾT HÀNG.
- THÊM MÓN: tên, nhóm, giá, link ảnh, mô tả ngắn.
- Chỉ sửa món của rạp mình.

### 4.6 Phim (S13) — chỉ xem
- Danh sách phim, trạng thái đang chiếu hoặc sắp chiếu.
- Chạm phim: xem thông tin, không có nút sửa.

### 4.7 Bảng giá (S26) — chỉ xem
- Xem giá cơ sở, phụ thu. Không có nút LƯU.
- Khối VÍ DỤ tính giá để tham khảo.

### 4.8 Nhân viên (S23)
1. Danh sách nhân viên của rạp: họ tên, email, ĐANG HOẠT ĐỘNG hoặc ĐÃ KHÓA.
2. THÊM NHÂN VIÊN: họ tên, email, SĐT, mật khẩu tạm. Rạp tự gán. Tạo bằng FirebaseApp phụ.
3. Chạm nhân viên: KHÓA TÀI KHOẢN hoặc MỞ KHÓA, có hộp xác nhận.
4. Rỗng: "Rạp chưa có nhân viên". Lỗi trùng email: thông báo rõ.

### 4.9 Hỗ trợ khách (S31, S)
- Danh sách hội thoại của rạp, trả lời khách.

### 4.10 Giới hạn của Manager
- Không tạo hay xóa phim, không sửa giá, không tạo voucher, không xem nhật ký.
- Không thấy suất hoặc booking của rạp khác.

---

## 5. Admin

Có toàn bộ quyền Manager, cộng thêm:

### 5.1 Bộ lọc rạp
- Mọi màn quản lý có chip chọn rạp (TẤT CẢ hoặc từng rạp).
- Chọn rạp trước khi thêm món (S16), chọn rạp khi thêm nhân viên (S23).

### 5.2 Phim (S13) — CRUD
1. Danh sách: poster nhỏ, tên, trạng thái. THÊM PHIM ở app bar.
2. Form: tên, thể loại, thời lượng, độ tuổi (P, T13, T16, T18), ngày khởi chiếu, mô tả, đạo diễn, diễn viên, link poster, backdrop, trailer. LƯU.
3. Xóa: không cho nếu còn suất tương lai. Có hộp xác nhận.
4. Ẩn phim: đặt `isActive = false`.

### 5.3 Rạp và phòng (S25)
1. Danh sách rạp: tên, địa chỉ, số phòng, tọa độ. THÊM RẠP.
2. Chạm rạp: danh sách phòng (tên, số ghế, định dạng). THÊM PHÒNG.
3. Chạm phòng: mở S24.
4. Form rạp: tên, địa chỉ, SĐT, kinh độ, vĩ độ.
5. Form phòng: tên, định dạng hỗ trợ.

### 5.4 Sơ đồ ghế (S24)
1. Nhập số hàng, số cột.
2. Lưới ghế dùng `SeatWidget`. Chạm để đổi loại: Thường → VIP → Đôi → Lối đi/Trống.
3. Ghế đôi chiếm hai ô liền kề.
4. Không sửa sơ đồ của phòng đang có suất tương lai đã bán vé.
5. LƯU SƠ ĐỒ: cập nhật `seatLayout` và `seatCount`.

### 5.5 Bảng giá (S26) — sửa được
1. Ba nhóm: Giá cơ sở (2D, 3D, IMAX), Phụ thu ghế (VIP, Đôi), Phụ thu thời điểm (cuối tuần, giờ vàng và khung giờ).
2. Mỗi dòng là ô nhập số (hậu tố "đ").
3. LƯU: áp dụng cho booking tạo sau thời điểm lưu. Ghi `auditLogs` (action `changePrice`).
4. Khối VÍ DỤ tính giá một ghế VIP, 3D, cuối tuần giờ vàng để kiểm tra công thức.

### 5.6 Voucher (S27)
1. Danh sách: mã, loại, giá trị, hạn, đã dùng/tổng lượt, badge CÒN HẠN / HẾT HẠN / HẾT LƯỢT.
2. THÊM VOUCHER: mã (duy nhất), loại (% hoặc số tiền), giá trị, hạn dùng, số lượt tối đa.

### 5.7 Quản lý Manager (S28)
1. Danh sách Manager: họ tên, rạp phụ trách, trạng thái.
2. THÊM MANAGER: họ tên, email, mật khẩu tạm, chọn rạp.
3. Khóa và mở khóa, có xác nhận.

### 5.8 Nhật ký thao tác (S29)
- Danh sách mới → cũ: ai (tên, role), làm gì, đối tượng, lúc nào.
- Lọc theo loại thao tác và rạp.

### 5.9 Quyền khác
- Xem toàn bộ booking, suất, nhân viên của mọi rạp.
- Tổng quan toàn hệ thống, có lọc rạp.

---

## 6. Ma trận nhanh theo màn

| Màn | Guest | Customer | Staff | Manager | Admin |
|---|:-:|:-:|:-:|:-:|:-:|
| S01 Đăng nhập | ✔ | ✔ | ✔ | ✔ | ✔ |
| S02 Đăng ký | ✔ | ✔ | | | |
| S03 Trang chủ | ✔ | ✔ | | | |
| S04 Chi tiết phim | ✔ | ✔ | | | |
| S05 Chọn suất | xem | ✔ | | | |
| S06 Chọn ghế | | ✔ | ✔ (quầy) | | |
| S07 Đồ ăn | | ✔ | ✔ (quầy) | | |
| S08 Thanh toán VNPay | | ✔ | | | |
| S09 Vé thành công | | ✔ | ✔ (quầy) | | |
| S10 Vé của tôi | | ✔ | | | |
| S11 Tài khoản | | ✔ | ✔ | ✔ | ✔ |
| S12 Quản lý | | | | ✔ | ✔ |
| S13 Phim | | | | xem | ✔ |
| S14 Suất chiếu | | | | ✔ | ✔ |
| S15 Booking | | | | ✔ | ✔ |
| S16 Menu đồ ăn | | | | ✔ | ✔ |
| S17 Rạp (bản đồ) | ✔ | ✔ | | | |
| S17B Chi tiết rạp | ✔ | ✔ | | | |
| S18 Soát vé | | | ✔ | ✔ | |
| S19 Quầy đồ ăn | | | ✔ | ✔ | |
| S20 Bán vé quầy | | | ✔ | ✔ | |
| S21 Thanh toán quầy | | | ✔ | ✔ | |
| S22 Tổng quan | | | | ✔ | ✔ |
| S23 Nhân viên | | | | ✔ | ✔ |
| S24 Sơ đồ ghế | | | | | ✔ |
| S25 Rạp và phòng | | | | | ✔ |
| S26 Bảng giá | | | | xem | ✔ |
| S27 Voucher | | | | | ✔ |
| S28 Quản lý Manager | | | | | ✔ |
| S29 Nhật ký | | | | | ✔ |
| S30 Thông báo | | ✔ | | ✔ | ✔ |
| S31 Hỗ trợ/Chat | | ✔ | ✔ | ✔ | ✔ |

---

## 7. Luồng lỗi chung (mọi role)

| Tình huống | Xử lý |
|---|---|
| Mất mạng khi đang tải | `ErrorState` với THỬ LẠI. Giữ dữ liệu cũ nếu có |
| Mất mạng giữa lúc giữ ghế | Transaction thất bại: báo "Không kết nối được. Thử lại." Không ghi gì |
| Token Auth hết hạn | Đăng xuất, về S01 |
| Tài khoản bị khóa giữa phiên | Lần đọc user tiếp theo thấy `isLocked`: signOut và về S01 |
| Hết giờ giữ ghế ở bất kỳ bước nào | Dialog, về S06, ghế đã nhả |
| Camera bị từ chối (Staff) | Giải thích và nút mở cài đặt. Vẫn dùng được NHẬP MÃ TAY |
| Thay đổi giá khi khách đang ở S08 | Không ảnh hưởng: giá đã snapshot khi tạo booking |
