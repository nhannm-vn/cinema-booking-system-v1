# KẾ HOẠCH TRIỂN KHAI KỸ THUẬT MILESTONE 3 (M3 PLAN)
## Booking Flow & Checkout (S05–S09, S11, S11B)

---

## 1. TỔNG QUAN VÀ MỤC TIÊU (EXECUTIVE SUMMARY)

Milestone 3 là cột mốc trung tâm (core revenue flow) của ứng dụng Cinema Booking & Operation Management, triển khai toàn bộ hành trình đặt vé và thanh toán trực tuyến của khách hàng từ khi chọn suất chiếu đến khi nhận vé điện tử, cùng hai màn hình quản lý hồ sơ tài khoản:
- **S05 Chọn suất chiếu (`/showtimes`)**: Chọn ngày (7 ngày), gom suất theo rạp, hiển thị định dạng và giá tối thiểu, trạng thái "HẾT VÉ", cảnh báo độ tuổi T16/T18, chặn Guest yêu cầu đăng nhập.
- **S06 Chọn ghế (`/seat-select`)**: Banner cong "MÀN HÌNH", sơ đồ ghế `InteractiveViewer` đồng bộ Realtime từ Supabase, chú thích ghế (`SeatLegend`), giới hạn tối đa 8 ghế, khóa ghế nguyên tử bằng Postgres RPC `hold_seats` (`FOR UPDATE`), thanh dính đáy `BookingSummaryBar`, xử lý xung đột `SeatTakenException`.
- **S07 Chọn đồ ăn (`/food-select`)**: Đồng hồ đếm ngược `HoldTimer` 5 phút (chuyển đỏ khi < 60 giây), danh mục món ăn (COMBO · BẮP · NƯỚC · SNACK), bộ tăng giảm `QuantityStepper`, vô hiệu món hết hàng, nút phụ outline `BỎ QUA`, nút chính primary `TIẾP TỤC`.
- **S08 Thanh toán & Mã giảm giá (`/checkout`)**: Tóm tắt đơn hàng, đồng hồ `HoldTimer`, nhập & xác thực mã voucher (giảm trên tiền vé), chọn phương thức VNPay Sandbox, gọi Supabase Edge Function `create-vnpay-url` với chữ ký HMAC-SHA512.
- **S08B Cổng thanh toán VNPay WebView (`/vnpay-webview`)**: Tích hợp `webview_flutter`, theo dõi URL redirect về Edge Function `vnpay-return` và deep link `cinemaapp://payment-success`, điều hướng S09 khi thành công hoặc thông báo lỗi khi hủy.
- **S09 Vé điện tử thành công (`/ticket-success`)**: Biểu tượng hoàn tất, thẻ vé `TicketCard` hiển thị mã đặt vé 8 ký tự và mã QR (`qr_flutter`), nút chính `XEM VÉ CỦA TÔI`, nút phụ `VỀ TRANG CHỦ`, khóa điều hướng quay lại luồng đặt vé.
- **S11 Hồ sơ tài khoản (`/profile`) & S11B Sửa hồ sơ (`/edit-profile`)**: Hiển thị thông tin cá nhân, avatar chữ cái đầu, badge role, điều hướng S11B cập nhật họ tên và số điện thoại, đăng xuất an toàn.

Đồng thời, kế hoạch giải quyết dứt điểm khiếm khuyết serialization của `BookingModel.toMap()` tại dòng 122 để đảm bảo chu kỳ tuần hoàn dữ liệu (round-trip) 100% không lỗi.

---

## 2. SỬA LỖI SERIALIZATION: `BookingModel.toMap()`

### 2.1 Vấn đề quan sát
- File: `lib/features/booking/data/models/booking_model.dart`
- `BookingModel.fromMap(map)` dòng 118:
  ```dart
  createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
  ```
- `BookingModel.toMap()` dòng 122–150: trường `created_at` bị bỏ quên không ghi vào `Map<String, dynamic>`.
- **Hậu quả:** Khi gọi `BookingModel.fromMap(model.toMap())`, biểu thức `map['created_at'] as String` trả về `null as String`, ném ngoại lệ:
  `TypeError: type 'Null' is not a subtype of type 'String' in type cast`.

### 2.2 Giải pháp khắc phục
Tại `lib/features/booking/data/models/booking_model.dart`, thêm `'created_at': createdAt.toIso8601String(),` vào `toMap()`:
```dart
  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'user_id': userId,
      'channel': channel,
      'sold_by': soldBy,
      'status': status,
      'hold_until': holdUntil?.toIso8601String(),
      'showtime_id': showtimeId,
      'cinema_id': cinemaId,
      'movie_title': movieTitle,
      'poster_url': posterUrl,
      'age_rating': ageRating,
      'cinema_name': cinemaName,
      'room_name': roomName,
      'format': format,
      'showtime_start': showtimeStart.toIso8601String(),
      'seats': seats,
      'foods': foods,
      'food_status': foodStatus,
      'price_snapshot': priceSnapshot,
      'payment_method': paymentMethod,
      'vnp_transaction_no': vnpTransactionNo,
      'paid_at': paidAt?.toIso8601String(),
      'checked_in_by': checkedInBy,
      'checked_in_at': checkedInAt?.toIso8601String(),
      'cancel_reason': cancelReason,
      'created_at': createdAt.toIso8601String(),
    };
  }
```

---

## 3. CHI TIẾT KỸ THUẬT TỪNG MÀN HÌNH MILESTONE 3

### 3.1 S05 — Showtime Selection Screen (`/showtimes`)
- **Đường dẫn file:** `lib/features/booking/presentation/screens/showtime_selection_screen.dart`
- **Tuyến đường:** `AppRoutes.showtimes`
- **Tham số nhận vào (arguments):**
  - Hỗ trợ đa dạng đầu vào: `movieId` (String), `movieTitle` (String), `movie` (MovieModel), `cinemaId` (String), `cinemaName` (String).
- **Hành vi & Luồng logic:**
  1. **Dải 7 ngày (`DateChip`):**
     - Sinh danh sách 7 ngày liên tiếp tính từ `DateTime.now()`.
     - Mỗi ngày hiển thị qua `DateChip`: thứ (`DateFormatter.formatWeekdayAbbr(date)`: T2, T3, T4, T5, T6, T7, CN) và ngày (`date.day.toString().padLeft(2, '0')`).
     - Ngày được chọn có nền `AppColors.primary`, chữ trắng `AppColors.onPrimary`.
     - Nhấn ngày: gọi `ShowtimeRepository().getShowtimes(movieId: ..., date: selectedDate, cinemaId: ...)` và làm mới danh sách.
  2. **Nhóm suất chiếu theo rạp (hoặc theo phim nếu xem từ chi tiết rạp):**
     - Gom nhóm theo `cinema_name` / `cinema_id`.
     - Header rạp: Icon rạp, tên rạp (`titleMd`), đường kẻ `hairline`.
     - Danh sách suất chiếu hiển thị qua widget chuẩn `ShowtimeRow`:
       - `startTime`: `DateFormatter.formatTime(showtime.startTime)` (ví dụ `19:30`).
       - `roomName`: `showtime.roomName`.
       - `format`: `showtime.format` (2D, 3D, IMAX).
       - `minPrice`: `showtime.minPrice`.
       - `isSoldOut`: `showtime.isSoldOut || showtime.isPast`.
  3. **Tương tác chạm suất chiếu:**
     - Nếu chưa đăng nhập (Guest): Chuyển hướng sang S01 `AppRoutes.login` với `redirectRoute: AppRoutes.showtimes` để sau đăng nhập tự động quay lại.
     - Kiểm tra cảnh báo độ tuổi: Nếu phim có nhãn `T16` hoặc `T18`:
       - Hiển thị Dialog cảnh báo độ tuổi:
         - Tiêu đề: "XÁC NHẬN ĐỘ TUỔI" (`titleMd`, `AppColors.ink`).
         - Nội dung: "Phim dành cho khán giả từ [16/18] tuổi trở lên. Quý khách vui lòng mang theo giấy tờ tùy thân để nhân viên kiểm tra tại rạp."
         - Nút hành động: "HỦY" (outline) và "TÔI ĐÃ ĐỦ TUỔI" (primary).
     - Khi xác nhận:
       - Lưu suất chiếu vào `BookingProvider`: `context.read<BookingProvider>().setShowtime(showtime)`.
       - Điều hướng sang S06 `AppRoutes.seatSelect`.
  4. **3 trạng thái UI:**
     - Loading: Danh sách 4 `SkeletonBox` giả lập hàng suất chiếu.
     - Empty: `EmptyState` với biểu tượng lịch và thông điệp "Chưa có suất chiếu trong ngày này".
     - Error: `ErrorState` có nút `AppButton.outline` nhãn "THỬ LẠI".

---

### 3.2 S06 — Seat Map Selection Screen (`/seat-select`)
- **Đường dẫn file:** `lib/features/booking/presentation/screens/seat_selection_screen.dart`
- **Tuyến đường:** `AppRoutes.seatSelect`
- **Hành vi & Luồng logic:**
  1. **Khởi tạo dữ liệu & Realtime Stream:**
     - Lấy `showtime` hiện tại từ `BookingProvider`.
     - Tải thông tin phòng chiếu (`room_layout`, số hàng, số cột) qua `ShowtimeRepository.getShowtimeWithRoom(showtime.id)`.
     - Lắng nghe Realtime stream từ `SeatRepository.streamSeats(showtime.id)`. Khi có bất kỳ ai giữ ghế hoặc mua vé, trạng thái ghế trên sơ đồ tự động cập nhật ngay lập tức.
  2. **Banner "MÀN HÌNH" (Curved Screen Display):**
     - Đặt phía trên ma trận ghế.
     - Vẽ đường cong viền trắng/xám đại diện cho màn chiếu cong lớn, ở giữa là chữ "MÀN HÌNH" (`AppTextStyles.captionUppercase`, `AppColors.muted`).
  3. **Ma trận ghế tương tác (`InteractiveViewer`):**
     - Đặt trong `InteractiveViewer` (minScale: 0.8, maxScale: 2.5) cho phép phóng to thu nhỏ và cuộn mượt mà trên mọi kích thước màn hình.
     - Nhãn chữ cái hàng ghế (A, B, C...) ở hai bên cột.
     - Mỗi ghế dựng bằng widget chuẩn `SeatWidget`:
       - Trạng thái `SeatState.selected`: Ghế nằm trong `BookingProvider.selectedSeatIds`. Nền Rosso Corsa `#DA291C`, số ghế trắng.
       - Trạng thái `SeatState.sold`: Ghế trong DB có `status == 'sold'`. Nền tối, viền xám, icon ×.
       - Trạng thái `SeatState.held`: Ghế trong DB có `status == 'holding'` và `holdUntil > now()` và không thuộc phiên hiện tại. Nền `AppColors.muted`.
       - Trạng thái `SeatState.available`: Ghế còn trống (hoặc giữ quá hạn - lazy expiration).
       - Loại ghế `SeatType`: `standard`, `vip` (có viền 1px trắng), `couple` (rộng gấp đôi).
     - Khi người dùng chạm vào ghế:
       - Nếu ghế đã bán hoặc đang bị người khác giữ: Thông báo nhẹ SnackBar "Ghế này không còn trống".
       - Nếu ghế trống / đang chọn: Gọi `BookingProvider.toggleSeat(seatId, seatType)`.
       - Rung phản hồi: `HapticFeedback.selectionClick()`.
  4. **Quy tắc giới hạn 8 ghế (BUSINESS_RULES mục 5):**
     - `BookingProvider.toggleSeat` kiểm tra: nếu đã chọn đủ 8 ghế và cố chọn thêm ghế thứ 9, giữ nguyên 8 ghế và gán thông báo lỗi "Bạn chỉ được chọn tối đa 8 ghế mỗi lần".
     - UI hiển thị SnackBar cảnh báo `AppColors.warning`.
  5. **Thanh dính đáy `BookingSummaryBar`:**
     - Tóm tắt ghế: Số lượng ghế & danh sách mã ghế (ví dụ "2 GHẾ · A5, A6").
     - Tổng tiền tạm tính: `BookingProvider.calculateTicketTotal()`.
     - Nút "TIẾP TỤC" (primary, enabled khi số ghế > 0).
  6. **Gọi RPC `hold_seats`:**
     - Khi bấm "TIẾP TỤC": nút chuyển loading (`isLoading: true`).
     - Gọi `await bookingProvider.holdSelectedSeats()`.
     - Thành công: `hold_until` được gán (now + 5 phút), chuyển sang S07 `AppRoutes.foodSelect`.
     - Xung đột ghế: Nếu bắt được ngoại lệ `SeatTakenException(conflictedSeatId)` (do PostgreSQL ném `SEAT_TAKEN:<seat_id>`):
       - Hiển thị hộp thoại cảnh báo: "Ghế [X] vừa có người chọn. Vui lòng chọn ghế khác."
       - Làm mới sơ đồ ghế, giữ lại các ghế hợp lệ còn lại.
  7. **Hộp xác nhận khi thoát:**
     - Bắt sự kiện Back qua `PopScope`: Nếu ghế đã được giữ (`holdUntil != null`), hiển thị hộp thoại: "Rời khỏi và nhả ghế? Ghế bạn đang giữ sẽ được nhả cho người khác."
     - Nếu đồng ý: gọi `bookingProvider.releaseCurrentHold()` (chạy RPC `release_hold`) và thoát.

---

### 3.3 S07 — Food & Concessions Selection Screen (`/food-select`)
- **Đường dẫn file:** `lib/features/booking/presentation/screens/food_selection_screen.dart`
- **Tuyến đường:** `AppRoutes.foodSelect`
- **Hành vi & Luồng logic:**
  1. **Đồng hồ giữ ghế (`HoldTimer`):**
     - Đặt tại phần đầu màn hình: `HoldTimer(holdUntil: bookingProvider.holdUntil!, onExpired: ...)`
     - Nhãn `GIỮ GHẾ CÒN MM:SS`.
     - Dưới 60 giây: Chuyển sang màu đỏ cảnh báo `AppColors.warning` (theo DESIGN_TOKENS mục 7.14).
     - Khi hết giờ (`onExpired`): Hiển thị Dialog "Hết thời gian giữ ghế. Ghế đã được nhả.", gọi `bookingProvider.reset()` và pop về S06.
  2. **Danh mục món ăn:**
     - Tải món theo rạp qua `FoodRepository.getFoodsByCinema(cinemaId)`.
     - Tab thanh điều hướng phân loại: `COMBO` · `BẮP` · `NƯỚC` · `SNACK`.
  3. **Thẻ món ăn:**
     - Ảnh vuông món ăn với `cached_network_image`.
     - Tên món (`titleSm`), mô tả (`bodySm`, `muted`), giá bán định dạng VND (`CurrencyFormatter.format(price)`).
     - Bộ tăng giảm `QuantityStepper`:
       - Hiển thị số lượng hiện tại đã chọn trong `bookingProvider.selectedFoods`.
       - Nút - và + thay đổi số lượng qua `bookingProvider.updateFoodQuantity(food, newQty)`.
       - Nếu món hết hàng (`isAvailable == false`): làm mờ thẻ, nhãn "HẾT HÀNG", vô hiệu hóa nút tăng.
  4. **Thanh dính đáy 2 nút:**
     - Nút phụ: `AppButton.outline` nhãn `BỎ QUA` (không chọn đồ ăn, xóa món đã chọn, chuyển sang S08).
     - Nút chính: `AppButton.primary` nhãn `TIẾP TỤC` (lưu món đã chọn, đồng bộ với booking, chuyển sang S08).
     - Tuân thủ quy tắc: tối đa đúng 1 nút primary trên màn hình.
  5. **Đồng bộ dữ liệu booking:**
     - Khi nhấn `TIẾP TỤC`: Gọi `bookingProvider.syncBookingDetails()` (gọi lại RPC `hold_seats` với cùng mã booking để cập nhật cột `foods` và `price_snapshot` trong PostgreSQL an toàn trước khi vào checkout).

---

### 3.4 S08 — Checkout & Voucher Screen (`/checkout`)
- **Đường dẫn file:** `lib/features/booking/presentation/screens/checkout_screen.dart`
- **Tuyến đường:** `AppRoutes.checkout`
- **Hành vi & Luồng logic:**
  1. **Đồng hồ giữ ghế (`HoldTimer`):**
     - Duy trì hiển thị thời gian còn lại. Hết giờ sẽ tự động mở hộp thoại thông báo và điều hướng về S06.
  2. **Tóm tắt đơn hàng:**
     - Khối thông tin phim: Tên phim (`displayMd`), badge độ tuổi, định dạng chiếu.
     - Khối địa điểm & thời gian: Tên rạp, phòng chiếu, ngày giờ chiếu formatted.
     - Khối ghế: Danh sách ghế và tổng tiền vé.
     - Khối đồ ăn: Danh sách các món ăn đã chọn kèm số lượng và thành tiền (nếu có).
  3. **Nhập và kiểm tra mã giảm giá (Voucher):**
     - Ô nhập mã `AppTextField` tự động viết hoa (`textCapitalization: TextCapitalization.characters`).
     - Nút `AppButton.outline` nhãn `ÁP DỤNG`.
     - Logic xác thực voucher trong `BookingProvider.applyVoucher(code)`:
       - Truy vấn bảng `vouchers` theo `code`:
         - Không tìm thấy: báo lỗi cụ thể "Mã không tồn tại".
         - `is_active == false`: báo "Mã không còn hoạt động".
         - `expires_at < now()`: báo "Mã đã hết hạn".
         - `used_count >= max_uses`: báo "Mã đã hết lượt".
       - Hợp lệ:
         - Tính giảm giá: Loại `percent` -> `discount = (ticketTotal * value / 100).round()`. Loại `amount` -> `discount = min(ticketTotal, value)`.
         - **Quy tắc quan trọng (BUSINESS_RULES mục 11):** Giảm giá CHỈ áp dụng trên tiền vé (`ticketTotal`), KHÔNG giảm trên tiền đồ ăn (`foodTotal`).
         - Hiển thị badge xanh `AppColors.success` thể hiện số tiền đã giảm, kèm nút `XÓA` để hủy mã nếu muốn đổi mã khác.
  4. **Chi tiết bảng giá (`priceSnapshot`):**
     - Tiền vé: `CurrencyFormatter.format(ticketTotal)`
     - Tiền đồ ăn: `CurrencyFormatter.format(foodTotal)`
     - Giảm giá: `- CurrencyFormatter.format(discount)` (chỉ hiện khi discount > 0)
     - Tổng thanh toán: `CurrencyFormatter.format(grandTotal)` (`displayLg`, `AppColors.ink`)
  5. **Chọn phương thức thanh toán:**
     - Mặc định: VNPay Sandbox (Logo/Icon VNPay, chữ `ink`, viền được chọn).
  6. **Kích hoạt thanh toán VNPay:**
     - Nút chính `AppButton.primary` nhãn `THANH TOÁN QUA VNPAY`.
     - Kiểm tra booking còn hiệu lực giữ ghế.
     - Tạo mã giao dịch duy nhất: `txnRef = '${booking.code}-${DateTime.now().millisecondsSinceEpoch}'`.
     - Gọi `PaymentRepository.createVNPayUrl(bookingCode: booking.code, txnRef: txnRef)` (kết nối Supabase Edge Function `create-vnpay-url`).
     - Nhận URL thanh toán đã ký HMAC-SHA512.
     - Điều hướng sang S08B `AppRoutes.vnpayWebview` truyền `paymentUrl`, `bookingCode`, `txnRef`.

---

### 3.5 S08B — VNPay Sandbox WebView Screen (`/vnpay-webview`)
- **Đường dẫn file:** `lib/features/booking/presentation/screens/vnpay_webview_screen.dart`
- **Tuyến đường:** `AppRoutes.vnpayWebview`
- **Hành vi & Luồng logic:**
  1. **Khởi tạo WebView (`webview_flutter`):**
     - Sử dụng `WebViewController`:
       - `setJavaScriptMode(JavaScriptMode.unrestricted)`
       - Cấu hình `NavigationDelegate` để theo dõi và chặn các URL chuyển hướng:
         ```dart
         onNavigationRequest: (NavigationRequest request) {
           final url = request.url;
           // Bắt deep link thành công từ Edge Function vnpay-return
           if (url.startsWith('cinemaapp://payment-success') || url.contains('vnp_ResponseCode=00')) {
             _handlePaymentSuccess(context, bookingCode);
             return NavigationDecision.prevent;
           }
           // Bắt deep link thất bại / hủy
           if (url.startsWith('cinemaapp://payment-failed') || (url.contains('vnp_ResponseCode=') && !url.contains('vnp_ResponseCode=00'))) {
             _handlePaymentFailed(context);
             return NavigationDecision.prevent;
           }
           return NavigationDecision.navigate;
         }
         ```
  2. **Xử lý kết quả giao dịch:**
     - **Thành công:**
       - Edge Function `vnpay-return` đã chạy RPC `confirm_payment` ở backend (chuyển booking sang `paid`, ghế sang `sold`, food sang `pending`).
       - Điều hướng ngay sang S09 `AppRoutes.ticketSuccess` với tham số `bookingCode`.
       - Xóa sạch các màn hình thanh toán cũ khỏi ngăn xếp (`pushNamedAndRemoveUntil`).
     - **Thất bại hoặc Khách bấm hủy trên cổng VNPay:**
       - Đóng WebView, quay lại S08 `checkout`.
       - Hiển thị Dialog thông báo: "Giao dịch thanh toán không thành công. Quý khách có thể thử lại nếu thời gian giữ ghế vẫn còn."
       - Booking vẫn giữ trạng thái `holding` để khách thử lại với mã tham chiếu mới.
  3. **Hết giờ giữ ghế khi đang ở WebView:**
     - Kiểm tra thời gian còn lại: nếu hết giờ, đóng WebView ngay lập tức, thông báo hết hạn và đưa khách về lại S06.

---

### 3.6 S09 — Ticket Success Screen (`/ticket-success`)
- **Đường dẫn file:** `lib/features/tickets/presentation/screens/ticket_success_screen.dart`
- **Tuyến đường:** `AppRoutes.ticketSuccess`
- **Hành vi & Luồng logic:**
  1. **Khối hoàn tất giao dịch:**
     - Icon dấu tick tròn màu xanh lá (`Icons.check_circle_outline`, `AppColors.success`, size 56).
     - Tiêu đề: "ĐẶT VÉ THÀNH CÔNG" (`AppTextStyles.displayLg`, `AppColors.ink`).
     - Mô tả: "Vé điện tử của bạn đã sẵn sàng. Vui lòng xuất trình mã QR tại quầy soát vé."
  2. **Thẻ vé điện tử (`TicketCard`):**
     - Tải thông tin `BookingModel` qua `TicketRepository.getTicketByCode(bookingCode)`.
     - Nền thẻ sáng `AppColors.canvasLight`, chữ tối `AppColors.bodyOnLight`.
     - Đầy đủ thông tin:
       - Tên phim (`displayMd`, đậm)
       - Rạp chiếu, Phòng chiếu & Định dạng (ví dụ: `Phòng 1 · 2D`)
       - Giờ chiếu (`DateFormatter.formatFullDateTime(showtimeStart)`)
       - Danh sách ghế (`A5, A6`)
       - Đồ ăn đi kèm: "Nhận tại quầy: 1x Combo Solo" (nếu có)
       - Đường đứt nét ngăn cách vé
       - Mã QR lớn ở giữa (`QrImageView`, size 160, tạo từ `qr_flutter` với dữ liệu là mã booking 8 ký tự).
       - Dòng mã booking 8 ký tự in hoa (ví dụ: `K7M2QX9P`, letter spacing 2.0).
  3. **Các nút hành động cuối trang:**
     - Nút chính (primary): `AppButton.primary` nhãn `XEM VÉ CỦA TÔI`. Chuyển sang màn hình quản lý vé S10 (`AppRoutes.myTickets`).
     - Nút phụ (outline): `AppButton.outline` nhãn `VỀ TRANG CHỦ`. Xóa toàn bộ navigation stack và quay về S03 (`AppRoutes.home`).
  4. **Chặn quay lại (Back Prevention):**
     - Dùng `PopScope(canPop: false)`: khi người dùng bấm nút Back vật lý hoặc cử chỉ vuốt, app tự động chuyển về S03 Home, tuyệt đối không cho phép Back ngược lại luồng checkout/thanh toán.

---

### 3.7 S11 — Profile Screen (`/profile`) & S11B — Edit Profile Screen (`/edit-profile`)
- **Đường dẫn file:**
  - `lib/features/profile/presentation/screens/profile_screen.dart`
  - `lib/features/profile/presentation/screens/edit_profile_screen.dart`
- **Tuyến đường:** `AppRoutes.profile` và `AppRoutes.editProfile`
- **Hành vi & Luồng logic:**

#### S11 Hồ sơ tài khoản (`profile_screen.dart`):
1. **Thông tin người dùng:**
   - Đọc `authProvider.currentUser`.
   - Avatar tròn chứa chữ cái đầu của họ tên (nền `AppColors.primary`, chữ trắng `displayLg`).
   - Họ tên người dùng (`AppTextStyles.titleLg`, `AppColors.ink`).
   - Email (`AppTextStyles.bodyMd`, `AppColors.body`).
   - Số điện thoại (`AppTextStyles.bodySm`, `AppColors.muted`).
   - Badge vai trò người dùng qua `AppBadge(label: user.role.toUpperCase())`.
2. **Menu thao tác:**
   - Mục "SỬA HỒ SƠ": Biểu tượng `Icons.edit_outlined`, chữ in hoa, mũi tên chevron phải -> Điều hướng sang S11B `AppRoutes.editProfile`.
   - Mục "HỘP THƯ HỖ TRỢ": Biểu tượng `Icons.headset_mic_outlined`, chữ in hoa, mũi tên chevron phải -> Điều hướng sang S31 `AppRoutes.supportChat`.
   - Mục "ĐĂNG XUẤT": Biểu tượng `Icons.logout`, chữ màu `AppColors.primary`.
     - Mở hộp thoại xác nhận: "Bạn có chắc chắn muốn đăng xuất khỏi tài khoản?"
     - Xác nhận: Gọi `authProvider.signOut()`, đưa về S03 Home (chế độ Guest).
3. **Thanh điều hướng dưới cùng:**
   - Tích hợp `CustomerBottomNav(currentIndex: 3)` giúp chuyển đổi tab tức thì.

#### S11B Chỉnh sửa hồ sơ (`edit_profile_screen.dart`):
1. **Form nhập liệu:**
   - Họ và tên: `AppTextField` có giá trị khởi tạo là `user.fullName`. Validate không được để trống.
   - Số điện thoại: `AppTextField`, bàn phím số `TextInputType.phone`. Validate định dạng 10 chữ số (hoặc rỗng nếu không bắt buộc).
   - Email: `AppTextField` chế độ đọc (`readOnly: true`, `enabled: false`), ghi rõ caption bên dưới: "Email không thể thay đổi".
   - Vai trò: `AppTextField` chế độ đọc (`readOnly: true`, `enabled: false`).
2. **Lưu cập nhật:**
   - Nút duy nhất `AppButton.primary` nhãn `LƯU THAY ĐỔI`.
   - Gọi `authProvider.updateProfile(fullName: ..., phone: ...)`.
   - Thành công: SnackBar `AppColors.success` thông báo "Cập nhật hồ sơ thành công", quay lại S11.
   - Thất bại: SnackBar `AppColors.warning` hiển thị lỗi.

---

## 4. BỔ SUNG CONTROLLER & REPOSITORY NỀN TẢNG

### 4.1 Cập nhật `AuthProvider`
Bổ sung hàm cập nhật thông tin hồ sơ khách hàng tại `lib/features/auth/presentation/controllers/auth_provider.dart`:
```dart
Future<bool> updateProfile({
  required String fullName,
  String? phone,
}) async {
  _status = AuthStatus.loading;
  _errorMessage = null;
  notifyListeners();

  try {
    _currentUser = await _repo.updateProfile(
      fullName: fullName,
      phone: phone,
    );
    _status = AuthStatus.authenticated;
    notifyListeners();
    return true;
  } catch (e) {
    _errorMessage = e.toString().replaceFirst('Exception: ', '');
    _status = AuthStatus.authenticated;
    notifyListeners();
    return false;
  }
}
```

### 4.2 Cập nhật `BookingProvider`
Mở rộng `lib/features/booking/presentation/controllers/booking_provider.dart` để quản lý mã giảm giá (voucher) và đồng bộ trạng thái đơn giữ ghế:
1. **Quản lý Voucher:**
   - `String? _appliedVoucherCode;`
   - `int _discount = 0;`
   - `String? _voucherError;`
   - `Future<bool> applyVoucher(String code)`: Truy vấn bảng `vouchers` trong Supabase, kiểm tra `is_active`, `expires_at`, `max_uses`.
   - Tính giảm giá chỉ trên `ticketTotal`:
     - Nếu `type == 'percent'`: `(ticketTotal * value / 100).round()`.
     - Nếu `type == 'amount'`: `min(ticketTotal, value)`.
   - `void removeVoucher()`: Hủy voucher, gán lại `discount = 0`.
2. **Tính tổng thanh toán có voucher:**
   - `int calculateGrandTotal() => max(0, calculateTicketTotal() + calculateFoodTotal() - _discount);`
3. **Đồng bộ hóa booking trước thanh toán:**
   - Phương thức `Future<bool> syncBookingDetails()`: Gọi RPC `hold_seats` với cùng `_currentBookingCode` và `_selectedSeatIds` để cập nhật `foods` và `price_snapshot` trong bảng `bookings` trên PostgreSQL trước khi tạo URL VNPay.

---

## 5. ĐẤU NỐI ROUTER (`AppRouter`) VÀ `main.dart`

### 5.1 Cấu hình `AppRouter.onGenerateRoute`
File `lib/core/routes/app_router.dart`:
Đăng ký các case trong hàm `onGenerateRoute`:
1. `AppRoutes.showtimes` -> `ShowtimeSelectionScreen`
2. `AppRoutes.seatSelect` -> `SeatSelectionScreen`
3. `AppRoutes.foodSelect` -> `FoodSelectionScreen`
4. `AppRoutes.checkout` -> `CheckoutScreen`
5. `AppRoutes.vnpayWebview` -> `VNPayWebviewScreen`
6. `AppRoutes.ticketSuccess` -> `TicketSuccessScreen`
7. `AppRoutes.profile` -> `ProfileScreen`
8. `AppRoutes.editProfile` -> `EditProfileScreen`

### 5.2 Kiểm tra `main.dart`
Tất cả các Provider cốt lõi (`AuthProvider`, `BookingProvider`, `MovieProvider`, `CinemaProvider`, `TicketProvider`) đã được đăng ký chuẩn trong `MultiProvider` tại `lib/main.dart`. Không cần thay đổi kiến trúc dependency injection.

---

## 6. MA TRẬN TUÂN THỦ THIẾT KẾ VÀ LUẬT HỆ THỐNG

| Tiêu chuẩn | Yêu cầu bắt buộc | Giải pháp trên M3 |
|---|---|---|
| **Zero Style Hardcoding** | 100% token, không mã màu `Color(0x...)`, không font size số cứng | Dùng `AppColors`, `AppTextStyles`, `AppSpacing`, `AppRadius` trên 100% màn hình M3 |
| **Độ sâu phẳng** | `elevation: 0`, không `BoxShadow` | Phân tầng bằng `canvas` (#181818), `canvasElevated` (#303030) và viền `hairline` |
| **Nút bấm & Nhãn** | Viết hoa UPPERCASE bằng `.toUpperCase()` | Mọi nút `AppButton` và tiêu đề hành động đều `.toUpperCase()` |
| **Giới hạn nút chính** | Tối đa 1 nút primary mỗi màn hình | S05: 1 CTA; S06: 1 CTA; S07: 1 outline BỎ QUA + 1 primary TIẾP TỤC; S08: 1 primary; S09: 1 primary + 1 outline; S11B: 1 primary |
| **3 Trạng thái UI** | Bắt buộc có đủ Loading, Empty, Error | Áp dụng `SkeletonBox`, `EmptyState`, `ErrorState` (có nút THỬ LẠI) trên các màn tải dữ liệu |
| **Giữ ghế chống trùng** | Khóa ghế nguyên tử qua Postgres RPC | Gọi `hold_seats` (`FOR UPDATE`), bắt lỗi `SeatTakenException` |
| **Tiền tệ** | Kiểu `int` VND, không dùng `double` | 100% thuộc tính tiền là `int`, định dạng qua `CurrencyFormatter` |
| **Bảo mật** | Không gọi ghi trực tiếp vào `bookings`, `seats` | Sử dụng hoàn toàn RPC `hold_seats` và Supabase Edge Functions |

---

## 7. CHI TIẾT TỪNG BƯỚC THỰC THI (STEP-BY-STEP EXECUTION ROADMAP)

- **Bước 1:** Chỉnh sửa `BookingModel.toMap()` tại `lib/features/booking/data/models/booking_model.dart` line 122 bổ sung `'created_at': createdAt.toIso8601String(),`.
- **Bước 2:** Bổ sung phương thức `updateProfile` trong `AuthProvider` và hỗ trợ voucher + sync trong `BookingProvider`.
- **Bước 3:** Tạo màn hình S05 `ShowtimeSelectionScreen` tại `lib/features/booking/presentation/screens/showtime_selection_screen.dart`.
- **Bước 4:** Tạo màn hình S06 `SeatSelectionScreen` tại `lib/features/booking/presentation/screens/seat_selection_screen.dart`.
- **Bước 5:** Tạo màn hình S07 `FoodSelectionScreen` tại `lib/features/booking/presentation/screens/food_selection_screen.dart`.
- **Bước 6:** Tạo màn hình S08 `CheckoutScreen` tại `lib/features/booking/presentation/screens/checkout_screen.dart`.
- **Bước 7:** Tạo màn hình S08B `VNPayWebviewScreen` tại `lib/features/booking/presentation/screens/vnpay_webview_screen.dart`.
- **Bước 8:** Tạo màn hình S09 `TicketSuccessScreen` tại `lib/features/tickets/presentation/screens/ticket_success_screen.dart`.
- **Bước 9:** Tạo màn hình S11 `ProfileScreen` và S11B `EditProfileScreen` tại `lib/features/profile/presentation/screens/`.
- **Bước 10:** Đấu nối các tuyến đường trong `lib/core/routes/app_router.dart`.
- **Bước 11:** Kiểm tra biên dịch và phân tích tĩnh: Chạy `flutter analyze` đảm bảo 0 issues, kiểm tra test suite `flutter test`.
