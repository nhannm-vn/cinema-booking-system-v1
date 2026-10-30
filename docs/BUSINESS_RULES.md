# BUSINESS_RULES.md — Nghiệp vụ Cinema Booking App

> Tổng hợp từ `PROJECT.md`, `SCREENS.md`, `DATA.md` và file kit. Mã quy tắc (PAY-01, SEAT-03…) lấy từ kit.
> Nếu có `REQUIREMENTS.md` gốc, đối chiếu lại. Khi xung đột, `REQUIREMENTS.md` thắng.

---

## 1. Mô tả dự án

Ứng dụng đặt vé xem phim cho một chuỗi rạp, gồm hai mặt:
- **Khách hàng:** xem phim, chọn rạp, chọn suất, chọn ghế, mua đồ ăn, thanh toán qua SePay (VietQR), nhận vé điện tử QR, quản lý vé, nhận thông báo.
- **Vận hành:** nhân viên soát vé tại cửa, giao đồ ăn, bán vé tại quầy. Quản lý và admin quản lý suất chiếu, phim, nhân viên, bảng giá, voucher, báo cáo.

Phạm vi chia hai mức:
- **M (bắt buộc):** luồng khách đặt vé đầy đủ, soát vé, giao đồ ăn, quản lý suất và booking cơ bản.
- **S (mức sau):** bán vé quầy, hủy suất, voucher, chat hỗ trợ, nhật ký thao tác, sơ đồ ghế tùy chỉnh, tổng quan doanh thu.

---

## 2. Vai trò và phạm vi dữ liệu

| Role | Mã trong DB | Gắn với | Phạm vi dữ liệu |
|---|---|---|---|
| Guest | — (chưa đăng nhập) | — | Xem phim, rạp, suất. Không đặt vé |
| Customer | `customer` | — | Vé và thông tin của chính mình |
| Staff | `staff` | `cinemaId` | Booking, suất, đồ ăn của rạp mình |
| Manager | `manager` | `cinemaId` | Như Staff, cộng quản lý suất, phim (xem), giá (xem), nhân viên của rạp mình |
| Admin | `admin` | — | Toàn hệ thống, có bộ lọc rạp |

Ma trận quyền chi tiết theo màn: xem `ROLE_FLOWS.md`.

**Tài khoản mặc định (seed):**

| Email | Role | cinemaId |
|---|---|---|
| admin@cinema.vn | admin | — |
| manager1@cinema.vn | manager | cn_q1 |
| manager2@cinema.vn | manager | cn_tb |
| staff1@cinema.vn | staff | cn_q1 |
| staff2@cinema.vn | staff | cn_tb |
| khach1@cinema.vn | customer | — |

Mật khẩu mặc định: `123456`.

---

## 3. Phim và suất chiếu

### 3.1 Phim
- **Đang chiếu:** `isActive == true` và `releaseDate <= now`.
- **Sắp chiếu:** `isActive == true` và `releaseDate > now`. Chưa mở bán, nút đặt vé hiện "CHƯA MỞ BÁN".
- **Ngừng chiếu:** `isActive == false`. Ẩn khỏi trang chủ.
- **Độ tuổi:** `P`, `T13`, `T16`, `T18`.
- **Xóa phim:** không cho xóa nếu còn suất tương lai. Thông báo lý do.
- **Tìm theo tên:** tải toàn bộ phim rồi lọc trên client.

### 3.2 Rạp và phòng
- Mỗi rạp có tọa độ `GeoPoint` để hiển thị bản đồ và tính khoảng cách.
- Mỗi phòng có `formats` (2D, 3D, IMAX), `seatLayout`, `seatCount`.
- Ghế đôi tính 1 vào `seatCount`.

### 3.3 Suất chiếu
- `endTime = startTime + durationMin` của phim. Tính lúc lưu.
- **Không chồng suất trong cùng phòng:** khoảng nghỉ tối thiểu **15 phút** giữa hai suất. Lỗi hiển thị rõ: "Phòng 2 đã có suất 19:00–21:10".
- **Xóa suất:** từ chối nếu đã có booking `paid`. Thông báo "Suất đã có vé bán. Hãy dùng HỦY SUẤT".
- **Hủy suất (S):** `status = cancelled`, kèm `cancelReason`. Suất hủy vẫn hiện trong danh sách nhưng mờ.
- Suất tạo với `soldSeats = 0`, `totalSeats = room.seatCount`.

---

## 4. Giá vé và phụ thu (PAY-01)

Cấu hình đọc từ `settings/pricing`. Chỉ Admin được sửa.

| Tham số | Giá trị mặc định |
|---|---|
| Giá cơ sở 2D | 80.000 đ |
| Giá cơ sở 3D | 100.000 đ |
| Giá cơ sở IMAX | 120.000 đ |
| Phụ thu VIP | 20.000 đ |
| Phụ thu ghế đôi | 20.000 đ |
| Phụ thu cuối tuần (Thứ 6, 7, CN) | 10.000 đ |
| Phụ thu giờ vàng (18:00–22:00) | 10.000 đ |

**Công thức:**

```text
Ghế thường = base[format] + (cuối tuần ? weekend : 0) + (giờ vàng ? prime : 0)
Ghế VIP    = base[format] + vip + (cuối tuần ? weekend : 0) + (giờ vàng ? prime : 0)
Ghế đôi    = 2 × base[format] + couple + (cuối tuần ? weekend : 0) + (giờ vàng ? prime : 0)
```

- Ghế đôi: phụ thu thời điểm tính **một lần** cho cả cặp.
- "Cuối tuần" và "giờ vàng" xét theo `startTime` của suất, không theo giờ mua.
- Đơn vị: VND, kiểu `int`.

**Snapshot (PAY-01, 4.1):** khi tạo booking, lưu `priceSnapshot = { ticketTotal, foodTotal, discount, total }`. Thay đổi bảng giá sau đó **không** ảnh hưởng vé cũ. Thay đổi giá chỉ áp dụng cho booking tạo sau thời điểm lưu.

---

## 5. Giữ ghế (SEAT-01 đến SEAT-05)

| Quy tắc | Nội dung |
|---|---|
| Số ghế tối đa | **8 ghế** mỗi lần đặt. Vượt quá: cảnh báo `warning` |
| Thời gian giữ online | **5 phút** kể từ khi bấm TIẾP TỤC ở S06 |
| Thời gian giữ quầy | **3 phút** |
| Ghế trống | Không có dòng trong bảng `seats` với `(showtime_id, seat_id)` |
| Ghế đang giữ | Dòng trong `seats` có `status = 'holding'` và `hold_until > now()` |
| Ghế đã bán | Dòng trong `seats` có `status = 'sold'` |
| Chống trùng (SEAT-03) | Postgres RPC `hold_seats` khóa suất chiếu (`for update`), kiểm tra các ghế. Nếu có ghế `sold` hoặc `holding` còn hạn của người khác → ném lỗi `SEAT_TAKEN:<seat_id>`, client nhận và ném `SeatTakenException(seatId)` |
| Hết hạn lười | Ghế `holding` quá `hold_until` được coi là trống ở client. Không cần cronjob xóa |
| Tối đa một đơn giữ | Khi khách bắt đầu đơn mới, nhả đơn `holding` cũ trong cùng RPC `hold_seats` |

**Nhả ghế:** thoát S06/S07/S08 hoặc hết giờ → gọi RPC `release_hold(code)`, xóa các dòng ghế của mình trong `seats`, `booking.status = 'expired'`, payment `pending` → `expired`.

**Thoát S06 sau khi đã giữ ghế:** hộp xác nhận "Rời khỏi và nhả ghế?".

---

## 6. Đặt vé và thanh toán (PAY-02)

### 6.1 Trạng thái booking

Lưu trong DB: `holding`, `paid`, `used`, `cancelled`, `expired`.

Hiển thị ở client (tính khi đọc, không lưu):
- `holding` quá `holdUntil` → `expired`.
- `paid` quá **15 phút** sau giờ chiếu mà chưa soát vé → `noShow`.

### 6.2 Luồng thanh toán SePay (VietQR / Chuyển khoản ngân hàng tự động)
1. Kiểm tra booking còn `holding` và chưa quá `hold_until`.
2. Tạo dòng trong bảng `payments` với `status = pending`, `txn_ref = ${bookingCode}-${yyMMddHHmmss}`.
3. App gọi Supabase Edge Function `create-sepay-url` gửi `booking_code` và `txn_ref`:
   - Edge Function đọc `bookings.price_snapshot` trực tiếp từ DB (không nhận tiền từ client).
   - Tạo mã VietQR động chuẩn SePay (`https://qr.sepay.vn/img?...`) và thông tin chuyển khoản gồm: ngân hàng, số tài khoản, số tiền và nội dung chuyển khoản chứa `booking_code`.
   - Trả về dữ liệu thanh toán VietQR / SePay checkout URL cho app client.
4. Mở màn hình thanh toán SePay (hoặc WebView thanh toán) hiển thị mã QR VietQR, thông tin chuyển khoản và nút sao chép nhanh số tài khoản/nội dung.
5. Khi khách hàng chuyển khoản qua ứng dụng ngân hàng:
   - SePay tự động phát hiện giao dịch khớp nội dung và số tiền, gửi Webhook đến Supabase Edge Function `sepay-webhook`.
   - Edge Function xác thực API Key SePay (`SEPAY_API_KEY`), kiểm tra số tiền `transferAmount >= price_snapshot.total`.
   - Edge Function gọi RPC `confirm_payment` bằng service role: booking chuyển sang `paid`, ghế `sold`, tăng `sold_seats`, `food_status = pending` nếu có món ăn, cập nhật `payments.status = success`, tạo notification và điều hướng S09.
6. Người dùng hủy hoặc có sự cố: giữ booking `holding`, hiển thị lỗi, cho phép thử lại nếu còn thời gian giữ ghế.
7. Hết giờ giữ ghế khi đang ở màn hình thanh toán: đóng thanh toán, về S06, booking `expired`.

### 6.3 Thanh toán tại quầy (S21)
- Không tạo doc `payments`. Ghi `paymentMethod` (`cash` hoặc `card`) và `paidAt` trên booking.
- Tiền mặt: nhập "KHÁCH ĐƯA", tiền thừa = khách đưa − tổng. Nút xác nhận khóa nếu khách đưa thiếu.

### 6.4 Đặt vé quầy
- Không cần tài khoản khách. `channel = counter`, `soldBy = uid nhân viên`, `userId = null`.
- Giữ ghế 3 phút.

---

## 7. Vé điện tử (S09, S10)

- Vé hiển thị QR chứa **mã booking 8 ký tự**.
- Tab VÉ CỦA TÔI chia ba nhóm:
  - **SẮP TỚI:** `paid` chưa qua giờ.
  - **ĐÃ XEM:** `used` và `noShow`. Vé `noShow` có badge "KHÔNG SỬ DỤNG".
  - **ĐÃ HỦY:** `cancelled`. Ẩn `expired` và `holding`.
- Vé ở trạng thái `paid` và còn trước giờ chiếu ≥ 2 giờ có nút HỦY VÉ.

---

## 8. Soát vé tại cửa (S18)

Staff quét QR, nội dung là `bookingCode`. Kiểm tra theo thứ tự:

| # | Điều kiện | Thông báo lỗi |
|---|---|---|
| 1 | Không tồn tại | "Mã vé không tồn tại trong hệ thống" |
| 2 | `status == cancelled` | "Vé đã bị hủy và hoàn tiền" |
| 3 | `status == used` | "Vé đã sử dụng lúc [giờ:phút]" |
| 4 | `cinemaId` khác rạp của Staff | "Vé thuộc rạp khác ([Tên rạp])" |
| 5 | Bây giờ < giờ chiếu − 30 phút | "Chưa đến giờ vào rạp (Chỉ vào trước tối đa 30 phút)" |
| 6 | Bây giờ > giờ chiếu + 15 phút | "Vé đã quá hạn sử dụng (Quá 15 phút sau giờ chiếu)" |
| 7 | Phim T16 hoặc T18 | Bắt buộc tick "Đã kiểm tra giấy tờ tùy thân" mới bấm được "XÁC NHẬN CHO VÀO" |

Nếu hợp lệ: `status = used`, `checkedInBy`, `checkedInAt`, ghi `auditLogs` (action `checkIn`). Rung nhẹ, đóng sheet, sẵn sàng quét tiếp.

**Trường hợp quét đúng nhưng vé đang `paid` và đã qua 15 phút sau giờ chiếu:** hiển thị `noShow` và báo lỗi mục 6.

---

## 9. Đồ ăn (S07, S19)

- Đồ ăn nằm trong booking (`foods`), `foodStatus` là `none`, `pending`, `delivered`, `cancelled`.
- Chỉ đơn `paid` mới có `foodStatus = pending`. Đơn chưa thanh toán không vào hàng đợi quầy.
- **Quầy đồ ăn:** hiện đơn `pending` của rạp, sắp theo `showtimeStart`.
- **ĐÃ GIAO:** `foodStatus = delivered`, ghi `foodDeliveredBy`, `foodDeliveredAt`, gửi thông báo cho khách. Không giao lại.
- **Món hết hàng** (`isAvailable = false`): hiển thị mờ, không cho thêm vào giỏ.
- Bỏ qua đồ ăn: đơn có `foods` rỗng, `foodStatus = none`.

---

## 10. Hủy vé và hủy suất

### 10.1 Khách hủy vé online
- Điều kiện: `status == paid` và còn **≥ 2 giờ** trước giờ chiếu.
- Kết quả: `status = cancelled`, ghế xóa khỏi `showtimes/{sid}/seats`, `soldSeats` giảm, `foodStatus = cancelled`, hoàn tiền **100%**, tạo thông báo, ghi `auditLogs`.

### 10.2 Hủy vé quầy (Manager, S15, mức S)
- Nhập lý do bắt buộc. Cùng kết quả như 10.1. Ghi `cancelledBy`.

### 10.3 Hủy suất (Manager, mức S)
- Hộp xác nhận nêu rõ số vé sẽ hủy và hoàn 100%. Bắt buộc nhập lý do.
- Mọi booking `paid` của suất → `cancelled`, gửi thông báo cho từng khách.
- **Không xóa seat docs** (suất đã hủy, sơ đồ không hiển thị nữa).
- Ghi chia batch tối đa 200 booking mỗi lần commit (mỗi booking khoảng 2 lần ghi, giới hạn Firestore 500 mỗi batch).
- Ghi `auditLogs` (action `cancelShowtime`).

---

## 11. Voucher (S, mức S)

- Mã là doc ID trong `vouchers/{CODE}`, duy nhất.
- Loại: `percent` hoặc `amount`.
- Điều kiện: `isActive`, chưa hết hạn, `usedCount < maxUses`.
- Chỉ giảm **tiền vé** (`ticketTotal`), không giảm đồ ăn.
- Áp dụng trong transaction xác nhận thanh toán: tăng `usedCount`.
- Lỗi cụ thể cho khách: "Mã không tồn tại", "Mã đã hết hạn", "Mã đã hết lượt".

---

## 12. Quản lý nhân sự

- **Tạo Manager (Admin):** họ tên, email, mật khẩu tạm, chọn rạp. Ghi `profiles` với `role = 'manager'`.
- **Tạo Staff (Manager, Admin):** gọi Edge Function `create-staff` (sử dụng service role key ở server). Rạp tự gán theo Manager; Admin chọn rạp. Không bị đăng xuất Manager đang thao tác.
- **Khóa tài khoản:** đặt `profiles.is_locked = true` và gọi `signOut` cưỡng chế. RLS tự động vô hiệu hóa toàn bộ quyền truy cập dữ liệu của user bị khóa.
- **Lỗi trùng email:** thông báo rõ, không tạo bản ghi nửa vời.

---

## 13. Nhật ký thao tác (S29, mức S)

Ghi các hành động: `checkIn`, `cancelShowtime`, `refund`, `changePrice`, `lockUser`, `unlockUser`. Mỗi bản ghi: người làm (tên, role), rạp, loại đối tượng, mã đối tượng, lý do, thời điểm. Chỉ Admin xem.

---

## 14. Thông báo (S30)

| Loại | Khi nào | Nội dung mẫu |
|---|---|---|
| `bookingPaid` | Thanh toán thành công | "Đặt vé thành công" · tên phim · rạp |
| `showReminder` | 1 giờ trước giờ chiếu (local notification) | "Suất chiếu bắt đầu sau 1 giờ" |
| `showtimeCancelled` | Admin hoặc Manager hủy suất | Lý do hủy |
| `bookingRefunded` | Hoàn vé | Số tiền hoàn |
| `foodDelivered` | Quầy đã giao đồ | "Đồ ăn của bạn đã sẵn sàng" |
| `chatMessage` | Có tin nhắn hỗ trợ (S) | Tên rạp · đoạn đầu tin nhắn |

Badge chuông = số thông báo `isRead == false`. Chạm vào thông báo vé → mở S09 hoặc S10.

---

## 15. Hỗ trợ khách hàng (S31, mức S)

- Mỗi cặp khách và rạp có một hội thoại duy nhất (`conversations/{uid_cinemaId}`).
- Khách có thể đính kèm mã booking khi nhắn để nhân viên tra cứu.
- Nhân viên và Manager của rạp đó đọc và trả lời. Admin đọc được.

---

## 16. Hằng số nghiệp vụ (không lưu DB)

Đặt trong `core/config/app_constants.dart`:

```dart
abstract final class AppConstants {
  static const int maxSeatsPerBooking = 8;
  static const Duration holdOnline = Duration(minutes: 5);
  static const Duration holdCounter = Duration(minutes: 3);
  static const Duration gapBetweenShowtimes = Duration(minutes: 15);
  static const Duration checkInEarly = Duration(minutes: 30);
  static const Duration checkInLate = Duration(minutes: 15);
  static const Duration noShowAfter = Duration(minutes: 15);
  static const Duration cancelBefore = Duration(hours: 2);
  static const Duration paymentWarning = Duration(seconds: 60);
  static const int cancelBatchLimit = 200;
}
```

---

## 17. Tóm tắt trạng thái và chuyển đổi

```text
Ghế:      (trống) ──chọn & TIẾP TỤC──► holding ──thanh toán OK──► sold
                                          │                         │
                                          └──quá holdUntil──► (trống) └──hủy vé──► (trống)

Booking:  holding ──thanh toán OK──► paid ──soát vé──► used
             │                        │   ├──quá 15' sau giờ chiếu──► noShow (hiển thị)
             └──quá hạn──► expired    │   ├──khách hủy (≥2h)──► cancelled (hoàn 100%)
                                      │   └──admin/manager hủy suất──► cancelled
                                      
Đồ ăn:    none | pending ──ĐÃ GIAO──► delivered
                    └──booking hủy──► cancelled
```

---

## 18. Quyết định cần chốt với nhóm (đã ghi nhận trong tài liệu)

| # | Câu hỏi | Mặc định trong tài liệu |
|---|---|---|
| 1 | Phụ thu giờ vàng cho ghế đôi tính một lần hay theo từng ghế? | Một lần cho cả cặp |
| 2 | Có kênh "Demo Giả lập" ở S08 không? | Chưa rõ. Đưa vào `payments.provider = 'demo'` nếu cần |
| 3 | Manager có được hủy vé quầy không? | Có, mức S |
| 4 | Khách có được đổi suất sau khi thanh toán không? | Không. Phải hủy và đặt lại |
| 5 | Voucher có áp dụng cho đơn có đồ ăn không? | Chỉ giảm tiền vé |
| 6 | Thời gian soát vé sớm 30 phút có tính theo giờ máy Staff không? | Có, dùng `DateTime.now()` |

---

## 19. Giới hạn kỹ thuật và phương án kiến trúc
- Logic nhạy cảm (giữ ghế, thanh toán, hủy vé) chạy an toàn bằng Postgres RPC functions phía DB.
- Secret Key `SEPAY_API_KEY` và Supabase Service Role Key được bảo vệ tuyệt đối trong Supabase Edge Functions.
- Sơ đồ ghế cập nhật thời gian thực bằng Supabase Realtime lắng nghe bảng `seats`.
- Hủy suất được thực hiện qua RPC `cancel_showtime` chạy trọn vẹn trong một transaction PostgreSQL.

---

## 20. Đối chiếu nhanh khi viết code

- [ ] Giá đọc từ bảng `pricing_settings`, không hardcode. Snapshot vào `price_snapshot` khi tạo booking.
- [ ] Ghế đổi trạng thái qua RPC `hold_seats` (khóa dòng `for update` trên bảng `showtimes`).
- [ ] Mọi query của Staff và Manager có `.eq('cinema_id', currentCinemaId)` (và được RLS bảo vệ kép).
- [ ] Thanh toán SePay tạo mã VietQR và xác thực qua Webhook Edge Function, gọi RPC `confirm_payment`.
- [ ] Thông báo lỗi dùng đúng câu trong mục 8 và mục 5.
- [ ] Hủy vé kiểm tra ≥ 2 giờ trước giờ chiếu qua RPC `cancel_booking`.
- [ ] Soát vé kiểm tra đủ 6 điều kiện theo thứ tự mục 8 qua RPC `check_in`.
