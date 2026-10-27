# Handoff Report: Milestone 5 — Part B (Catalog Management & Scheduling)

> **Agent:** explorer_m5_2  
> **Milestone:** Milestone 5 — Part B (S13 Movies CRUD, S14 Showtimes, S15 Bookings, S16 Food Catalog)  
> **Parent Orchestrator:** 9a20b4d6-8cae-4f73-9d70-c317f7996130  
> **Status:** HARD HANDOFF (Investigation & Technical Implementation Plan Complete)

---

## 1. OBSERVATION

1. **Trigger xung đột suất chiếu 15 phút (`trg_showtime_conflict`):**
   - File `d:\cinema-booking-system-v1\supabase\migrations\0006_missing_rpcs_and_triggers.sql`: lines 8–53.
   - Hàm `public.check_showtime_conflict()` đã được định nghĩa và kích hoạt bởi trigger `trg_showtime_conflict before insert or update on public.showtimes`.
   - Điều kiện kiểm tra:
     ```sql
     (new.start_time < (s.end_time + interval '15 minutes'))
     and (new.end_time > (s.start_time - interval '15 minutes'))
     ```
   - Ngoại lệ ném ra khi có xung đột:
     ```sql
     raise exception 'SHOWTIME_CONFLICT: % đã có suất từ % đến % (khoảng nghỉ tối thiểu 15 phút)',
       coalesce(v_room_name, 'Phòng chiếu'),
       to_char(v_conflict.start_time at time zone 'Asia/Ho_Chi_Minh', 'HH24:MI'),
       to_char(v_conflict.end_time at time zone 'Asia/Ho_Chi_Minh', 'HH24:MI');
     ```

2. **RPC Hủy suất chiếu (`cancel_showtime`):**
   - File `d:\cinema-booking-system-v1\supabase\migrations\0006_missing_rpcs_and_triggers.sql`: lines 60–140.
   - Hàm `public.cancel_showtime(p_showtime_id uuid, p_reason text)` kiểm tra quyền caller (`manager` của đúng rạp hoặc `admin`).
   - Cập nhật `showtimes.status = 'cancelled'`, `cancel_reason = p_reason`.
   - Vòng lặp cập nhật tất cả đơn vé `paid` sang `cancelled`, hoàn tiền 100%, hủy đồ ăn (`food_status = 'cancelled'`), tạo thông báo `showtimeCancelled` cho từng khách hàng và ghi `audit_logs` với action `cancelShowtime`. Không xóa dữ liệu trong bảng `seats`.

3. **Cơ chế xóa phim trong Database (`0001_schema.sql`):**
   - File `d:\cinema-booking-system-v1\supabase\migrations\0001_schema.sql`: line 88.
   - Cột `showtimes.movie_id` có ràng buộc: `references public.movies(id) on delete cascade`.
   - Hiện tại bảng `movies` chưa có trigger chặn xóa nếu còn suất chiếu tương lai. Nếu client gọi delete trực tiếp, PostgreSQL sẽ xóa cascade các suất chiếu.
   - Tài liệu nghiệp vụ `docs/BUSINESS_RULES.md` line 54 quy định: `Xóa phim: không cho xóa nếu còn suất tương lai. Thông báo lý do.`

4. **Ràng buộc phân loại độ tuổi (`age_rating`):**
   - File `d:\cinema-booking-system-v1\supabase\migrations\0001_schema.sql`: line 56:
     `age_rating text not null check (age_rating in ('P', 'T13', 'T16', 'T18'))`.
   - Mission prompt yêu cầu hỗ trợ cả độ tuổi `K` (phim dành cho khán giả dưới 13 tuổi có người bảo hộ đi cùng).

5. **Chính sách bảo mật RLS trên bảng `profiles`:**
   - File `d:\cinema-booking-system-v1\supabase\migrations\0002_rls.sql`: lines 34–38:
     ```sql
     create policy profiles_select on public.profiles for select using (
       id = auth.uid()
       or public.current_role_name() = 'admin'
       or (public.current_role_name() in ('staff', 'manager') and cinema_id = public.current_cinema())
     );
     ```
   - Hồ sơ khách hàng (`customer`) có `cinema_id = null`. Do đó, khi Staff hoặc Manager truy vấn join thông tin khách hàng từ bảng `bookings`, RLS hiện tại sẽ chặn truy cập dòng profile của khách hàng.

6. **Tái sử dụng các Domain Models hiện hữu:**
   - `MovieModel`: `d:\cinema-booking-system-v1\lib\features\movies\data\movie_model.dart` (đầy đủ các trường `id`, `title`, `genres`, `durationMin`, `ageRating`, `releaseDate`, `isActive`, `description`, `director`, `castMembers`, `posterUrl`, `backdropUrl`, `trailerUrl`).
   - `ShowtimeModel`: `d:\cinema-booking-system-v1\lib\features\booking\data\models\showtime_model.dart` (đầy đủ `roomId`, `format`, `startTime`, `endTime`, `status`, `cancelReason`, `totalSeats`, `soldSeats`, `roomName`, `movieTitle`).
   - `BookingModel`: `d:\cinema-booking-system-v1\lib\features\booking\data\models\booking_model.dart` (đầy đủ `code`, `userId`, `channel`, `status`, `seats`, `foods`, `foodStatus`, `priceSnapshot`, `paymentMethod`, `vnpTransactionNo`, `checkedInBy`, `checkedInAt`, `displayStatus`).
   - `FoodModel`: `d:\cinema-booking-system-v1\lib\features\booking\data\models\food_model.dart` (đầy đủ `id`, `cinemaId`, `name`, `category`, `price`, `isAvailable`, `imageUrl`, `description`).
   - `RoomModel`: `d:\cinema-booking-system-v1\lib\features\booking\data\models\room_model.dart`.
   - Hàm `hasShowtimeConflict`: `d:\cinema-booking-system-v1\test\e2e\test_fixtures.dart`: lines 527–540 (đã kiểm thử và khớp hoàn toàn với trigger DB).

7. **Trạng thái Test Suite hiện tại:**
   - Lệnh `flutter test` chạy thành công 100%: `+1094: All tests passed!`.

---

## 2. LOGIC CHAIN

1. Từ **Observation 1 & 6**, logic kiểm tra khoảng nghỉ 15 phút giữa các suất chiếu trong cùng phòng đã có sẵn cả ở tầng Database Trigger (`check_showtime_conflict`) và thuật toán client (`hasShowtimeConflict`).
   - **Hệ quả thiết kế S14:** Cần áp dụng validation 2 lớp:
     - Tại Client: Gọi `hasShowtimeConflict` trước khi gửi request để chặn ngay và đưa ra thông báo thân thiện: "Phòng [tên phòng] đã có suất từ [start] đến [end] (cần khoảng nghỉ tối thiểu 15 phút)".
     - Tại Backend: PostgreSQL Trigger `trg_showtime_conflict` đóng vai trò phòng thủ tầng cuối chống race conditions.

2. Từ **Observation 2**, RPC `cancel_showtime` đã xử lý toàn bộ luồng giao dịch nguyên tử (transaction atomic): khóa suất, đổi status sang `cancelled`, hủy toàn bộ booking `paid`, hoàn tiền 100%, gửi notification tới từng khách, và ghi audit log.
   - **Hệ quả thiết kế S14:** Màn hình S14 chỉ cần hộp thoại xác nhận yêu cầu nhập lý do bắt buộc, sau đó gọi `ManagementRepository.cancelShowtime(showtimeId, reason)`.

3. Từ **Observation 3**, vì `showtimes.movie_id` có `on delete cascade`, việc xóa phim trực tiếp khi còn suất tương lai sẽ vô tình xóa mất suất chiếu và vi phạm `docs/BUSINESS_RULES.md` mục 3.1.
   - **Hệ quả thiết kế S13:** Cần thiết lập cơ chế bảo vệ 2 lớp:
     - Client/Repository kiểm tra query `showtimes` tương lai đang active, chặn và thông báo lỗi.
     - Database bổ sung Trigger `trg_protect_movie_delete` trong migration `0007_m5_part_b_enhancements.sql` để bảo vệ toàn diện ở cấp độ RDBMS.

4. Từ **Observation 4**, check constraint `movies_age_rating_check` chỉ có `('P', 'T13', 'T16', 'T18')`. Việc nhập độ tuổi `K` sẽ gặp lỗi vi phạm check constraint.
   - **Hệ quả:** Cần cập nhật constraint trong migration `0007_m5_part_b_enhancements.sql` sang `check (age_rating in ('P', 'K', 'T13', 'T16', 'T18'))`.

5. Từ **Observation 5**, Manager cần kiểm tra thông tin khách hàng (tên, SĐT) trên S15, nhưng RLS `profiles_select` lại hạn chế theo `cinema_id = current_cinema()`.
   - **Hệ quả:** Cần cập nhật policy `profiles_select` để Staff và Manager có quyền đọc thông tin của các profile có `role = 'customer'`.

6. Từ **Observation 6**, việc tái sử dụng trực tiếp các Model đã kiểm chứng (`MovieModel`, `ShowtimeModel`, `BookingModel`, `FoodModel`, `RoomModel`) tuân thủ nghiêm ngặt nguyên tắc **Karpathy Rule 7 (Reuse first, create last)**, loại bỏ mã nguồn trùng lặp và đảm bảo tính nhất quán tuyệt đối giữa client và backend.

---

## 3. CAVEATS

1. **Giới hạn quyền của Manager trên S13:** Theo `docs/ROLE_FLOWS.md` mục 4.6 và 4.10, Manager chỉ có quyền xem danh sách phim và chi tiết phim, không được thêm/sửa/xóa phim. Toàn bộ thao tác ghi (C-U-D) trên S13 chỉ dành riêng cho Admin (`ROLE_FLOWS.md` 5.2). Giao diện S13 cần ẩn các nút thao tác này khi người dùng đăng nhập là Manager.
2. **Khách mua vé tại quầy (S15):** Các đơn vé tạo tại quầy POS (`channel = 'counter'`) có thể có `user_id = null`. Màn hình S15 cần xử lý hiển thị fallback "Khách mua tại quầy" khi `user_id == null`.
3. **Phân loại danh mục món ăn (S16):** Database enum trong `0001_schema.sql` là `('combo', 'popcorn', 'drink', 'snack')`. UI hiển thị bằng tiếng Việt: `COMBO`, `BẮP RANG`, `NƯỚC UỐNG`, `ĐỒ ĂN NHẸ`. Khi lưu xuống DB, bắt buộc phải map về đúng 4 giá trị enum này.

---

## 4. CONCLUSION

Kế hoạch triển khai kỹ thuật cho Milestone 5 — Part B đã hoàn tất toàn diện và sẵn sàng cho giai đoạn lập trình (Implementation). 
Tất cả các thành phần kiến trúc, luồng phân quyền (Manager vs Admin), giải pháp bảo vệ dữ liệu, bộ lọc, modal form, và kiểm thử đã được tài liệu hóa chi tiết tại:
`d:\cinema-booking-system-v1\.agents\teamwork\explorer_m5_2\m5_plan.md`

Danh mục 4 màn hình cốt lõi cần phát triển:
1. **S13: ManageMoviesScreen** (`lib/features/management/presentation/screens/manage_movies_screen.dart`)
2. **S14: ManageShowtimesScreen** (`lib/features/management/presentation/screens/manage_showtimes_screen.dart`)
3. **S15: ManageBookingsScreen** (`lib/features/management/presentation/screens/manage_bookings_screen.dart`)
4. **S16: ManageFoodsScreen** (`lib/features/management/presentation/screens/manage_foods_screen.dart`)

Tất cả tuân thủ 100% Design Tokens (`AppColors`, `AppSpacing`, `AppRadius`, `AppTextStyles`), dark cinematic canvas `#181818`, Rosso Corsa `#DA291C`, `elevation: 0`, xử lý đủ 3 trạng thái (Loading, Empty, Error), và tiền tệ `int` VND.

---

## 5. VERIFICATION METHOD

1. **Kiểm tra cú pháp và tĩnh:**
   ```bash
   flutter analyze
   ```
   *Tiêu chí thành công:* 0 errors, 0 warnings.

2. **Kiểm tra Unit và Widget Tests hiện tại:**
   ```bash
   flutter test
   ```
   *Tiêu chí thành công:* 100% tests passing (+1094 tests).

3. **Kiểm tra các kịch bản thực nghiệm khi triển khai Part B:**
   - **S13:** Đăng nhập Admin tạo phim mới -> Xem danh sách -> Thử xóa phim có suất chiếu tương lai -> Bị chặn và báo lỗi rõ ràng. Đăng nhập Manager -> Chỉ xem, không có nút thêm/sửa/xóa.
   - **S14:** Đăng nhập Manager/Admin tạo suất chiếu mới -> Chọn khung giờ cách suất khác < 15 phút -> Bị chặn tức thì tại client và DB trigger. Bấm HỦY SUẤT -> Nhập lý do -> RPC `cancel_showtime` chuyển suất sang mờ và tự động hoàn tiền các đơn vé liên quan.
   - **S15:** Tìm kiếm đơn vé theo mã, SĐT, tên khách -> Lọc theo chip trạng thái (Paid, Used, NoShow, Cancelled, Expired) và kênh (Online, Quầy) -> Chạm vào mở Bottom Sheet hiển thị đầy đủ thông tin vé, ghế, đồ ăn, thanh toán, kiểm toán.
   - **S16:** Lọc đồ ăn theo chip danh mục -> Bật/tắt công tắc `is_available` -> Cập nhật trạng thái CÒN HÀNG / HẾT HÀNG tức thì -> Thêm/sửa món ăn với giá tiền số nguyên VND.

4. **Điều kiện mất hiệu lực (Invalidation Conditions):**
   - Bất kỳ sửa đổi nào làm hỏng các test suite hiện hữu trong `test/e2e/` hoặc `test/features/`.
   - Sử dụng hardcoded style (`Color(0x...)`, `elevation > 0`) trong các file UI của màn hình mới.
   - Bỏ sót xử lý 1 trong 3 trạng thái UI (Loading, Empty, Error).
