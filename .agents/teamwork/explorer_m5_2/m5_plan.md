# Kế Hoạch Triển Khai Kỹ Thuật: Milestone 5 — Part B (Catalog Management & Scheduling)

> **Mã công việc:** M5-Part-B  
> **Người thực hiện:** explorer_m5_2  
> **Mục tiêu:** Khảo sát toàn diện, thiết kế kiến trúc và xây dựng kế hoạch triển khai chi tiết cho 4 màn hình quản trị catalog & vận hành:
> 1. **S13: Movies CRUD Management** (`/management/movies`)
> 2. **S14: Showtime Management** (`/management/showtimes`)
> 3. **S15: Bookings & Orders Inspection** (`/management/bookings`)
> 4. **S16: Food & Concessions Catalog Management** (`/management/foods`)
>
> **Tuân thủ quy chuẩn:** `docs/.cursorrules`, `docs/TECH_STACK.md`, `docs/DESIGN_TOKENS.md`, `docs/BUSINESS_RULES.md`, `docs/ROLE_FLOWS.md`, `AGENTS.md`, `GEMINI.md`, và Karpathy Guidelines (`ai-coding-standards`).

---

## 1. TỔNG QUAN VÀ PHÂN ĐỊNH PHẠM VI (SCOPE DEFINITION)

Milestone 5 hoàn thiện bộ công cụ quản trị hệ thống rạp chiếu phim (Manager & Admin Suite). Để đảm bảo tính độc lập và chất lượng cao nhất, Milestone 5 được chia thành 3 phần:
- **Part A (explorer_m5_1):** S10 Vé của tôi, S10B Chi tiết vé, S12 Menu Quản lý, S22 Dashboard vận hành, S31 Chat hỗ trợ.
- **Part B (explorer_m5_2 — Phạm vi tài liệu này):**
  - **S13 Quản lý Phim (Movies CRUD):** Danh sách phim, lọc trạng thái, tìm kiếm, modal form tạo/sửa phim, cơ chế chặn xóa phim nếu có suất chiếu tương lai.
  - **S14 Quản lý Suất Chiếu (Showtimes):** Lọc theo ngày/phòng/định dạng, modal thêm suất chiếu, tính giờ kết thúc tự động, kiểm tra khoảng nghỉ 15 phút (client + trigger DB), hủy suất chiếu qua RPC `cancel_showtime`.
  - **S15 Kiểm Tra Đơn Đặt Vé (Bookings & Orders Inspection):** Tìm kiếm mã booking/SĐT/tên khách, lọc theo trạng thái (`paid`, `used`, `noShow`, `cancelled`, `expired`) và kênh (`online`, `counter`), bottom sheet chi tiết đơn đầy đủ (vé, ghế, đồ ăn, thanh toán, audit).
  - **S16 Quản Lý Thực Đơn Bắp Nước (Food & Concessions Catalog):** Danh sách món theo danh mục (Bắp, Nước, Combo, Snack), công tắc khả dụng `is_available`, modal thêm/sửa món ăn với giá tiền `int` VND.
- **Part C (explorer_m5_3):** S24 Thiết kế sơ đồ ghế, S25 Quản lý Rạp & Phòng, S26 Bảng giá động, S27 Voucher, S28 Quản lý Manager, S29 Nhật ký kiểm toán (Audit Logs).

---

## 2. HIỆN TRẠNG HỆ THỐNG VÀ KHẢO SÁT KỸ THUẬT (TECHNICAL DISCOVERY)

Qua rà soát toàn bộ codebase và hệ thống cơ sở dữ liệu Supabase PostgreSQL:

### 2.1. Cơ sở dữ liệu và RPCs đã có từ Milestone 1:
1. **Trigger khoảng nghỉ 15 phút (`trg_showtime_conflict`):**
   - Đã được triển khai trong migration `supabase/migrations/0006_missing_rpcs_and_triggers.sql`.
   - Hàm `check_showtime_conflict()` kiểm tra trên bảng `showtimes`:
     ```sql
     (new.start_time < (s.end_time + interval '15 minutes'))
     AND (new.end_time > (s.start_time - interval '15 minutes'))
     ```
   - Ném ngoại lệ chính xác: `SHOWTIME_CONFLICT: [Tên phòng] đã có suất từ [HH:mm] đến [HH:mm] (khoảng nghỉ tối thiểu 15 phút)`.
2. **RPC Hủy suất chiếu (`cancel_showtime`):**
   - Đã được triển khai trong `0006_missing_rpcs_and_triggers.sql`.
   - Chạy nguyên tử trong transaction:
     - Kiểm tra quyền: Manager của rạp hoặc Admin.
     - Cập nhật `showtimes.status = 'cancelled'`, `cancel_reason = p_reason`.
     - Cập nhật toàn bộ đơn vé `paid` của suất sang `cancelled`, hoàn tiền 100%, hủy đồ ăn `food_status = 'cancelled'`.
     - Không xóa dữ liệu trong bảng `seats` để đối soát tài chính.
     - Tự động tạo thông báo `showtimeCancelled` gửi tới từng khách hàng có tài khoản.
     - Ghi nhật ký kiểm toán vào `audit_logs` với action `cancelShowtime`.
3. **Quản lý đồ ăn (`foods` table & `toggleFoodAvailability`):**
   - Bảng `foods` có ràng buộc danh mục: `category in ('combo', 'popcorn', 'drink', 'snack')`.
   - `ManagementRepository` đã có hàm `toggleFoodAvailability(foodId, isAvailable)`.

### 2.2. Các phát hiện kiến trúc quan trọng cần xử lý (Critical Insights):
1. **Bảo vệ xóa phim (Deletion Protection - F28):**
   - Trong schema `0001_schema.sql`, bảng `showtimes` có ràng buộc khóa ngoại `references public.movies(id) on delete cascade`.
   - Nếu Admin gọi `delete` phim trực tiếp khi DB chưa có trigger chặn, Postgres sẽ cascade xóa sạch các suất chiếu!
   - **Giải pháp bắt buộc:** Triển khai cơ chế bảo vệ 2 lớp:
     - **Lớp 1 (Client / Repository):** Trước khi xóa, query kiểm tra xem có suất chiếu nào của phim có `status = 'active' AND start_time > now()` hay không. Nếu có, từ chối xóa và hiển thị thông báo lỗi rõ ràng.
     - **Lớp 2 (Database Trigger):** Thêm trigger `trg_protect_movie_delete` trên bảng `public.movies` trong migration bổ sung `0007_m5_part_b_enhancements.sql`. Nếu có suất chiếu tương lai active, trigger ném ngoại lệ `CANNOT_DELETE_MOVIE`.
2. **Hạn định độ tuổi (`age_rating`) trong Database:**
   - Trong `0001_schema.sql`, check constraint là `check (age_rating in ('P', 'T13', 'T16', 'T18'))`.
   - Yêu cầu nhiệm vụ có nhắc đến độ tuổi `K` (dưới 13 tuổi có người bảo hộ đi kèm theo phân loại rạp Việt Nam mới).
   - Trong migration `0007_m5_part_b_enhancements.sql`, cập nhật constraint để hỗ trợ cả 5 mức độ tuổi: `('P', 'K', 'T13', 'T16', 'T18')`.
3. **Quyền truy cập thông tin khách hàng trong S15 (RLS trên `profiles`):**
   - Hiện tại RLS policy `profiles_select` chỉ cho phép Manager/Staff đọc các profile có `cinema_id = current_cinema()`. Khách hàng (`customer`) có `cinema_id = null`.
   - Khi Manager mở màn hình S15 để kiểm tra đơn vé và tìm theo Tên khách/SĐT, truy vấn join `profiles:user_id(full_name, phone)` sẽ trả về null nếu RLS chặn.
   - **Giải pháp:** Cập nhật policy `profiles_select` cho phép Staff/Manager đọc thông tin người dùng có `role = 'customer'` nhằm phục vụ công tác kiểm tra vé và đối soát.
4. **Chiến lược tái sử dụng mã nguồn (Karpathy Rule 7: Reuse first, create last):**
   - ĐÃ CÓ CÁC MODEL CHUẨN:
     - `MovieModel` (`lib/features/movies/data/movie_model.dart`)
     - `ShowtimeModel` (`lib/features/booking/data/models/showtime_model.dart`)
     - `BookingModel` (`lib/features/booking/data/models/booking_model.dart`)
     - `FoodModel` (`lib/features/booking/data/models/food_model.dart`)
     - `RoomModel` (`lib/features/booking/data/models/room_model.dart`)
     - `AppUser` (`lib/shared/models/app_user.dart`)
   - TẤT CẢ các model trên sẽ được TÁI SỬ DỤNG TRỰC TIẾP, không tạo thêm model trùng lặp. Chỉ bổ sung 2 trường tùy chọn vào `BookingModel` (`customerName`, `customerPhone`) để phục vụ tìm kiếm và hiển thị ở S15.

---

## 3. THIẾT KẾ CƠ SỞ DỮ LIỆU & MIGRATION BỔ SUNG

Tạo migration: `supabase/migrations/0007_m5_part_b_enhancements.sql`

```sql
-- ============================================================================
-- 0007_m5_part_b_enhancements.sql
-- Bổ sung hỗ trợ phân loại độ tuổi K, Trigger chặn xóa phim có suất tương lai,
-- và mở rộng RLS profiles_select cho Staff & Manager đọc thông tin khách hàng.
-- ============================================================================

-- 1. Cập nhật phân loại độ tuổi bảng movies (bổ sung K)
alter table public.movies drop constraint if exists movies_age_rating_check;
alter table public.movies add constraint movies_age_rating_check 
  check (age_rating in ('P', 'K', 'T13', 'T16', 'T18'));

-- 2. Trigger chặn xóa phim nếu còn suất chiếu active trong tương lai
create or replace function public.check_movie_deletion()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_future_showtime_count int;
begin
  select count(*) into v_future_showtime_count
  from public.showtimes
  where movie_id = old.id
    and status = 'active'
    and start_time > now();

  if v_future_showtime_count > 0 then
    raise exception 'CANNOT_DELETE_MOVIE: Không thể xóa phim đang có % suất chiếu trong tương lai.', v_future_showtime_count;
  end if;

  return old;
end;
$$;

drop trigger if exists trg_protect_movie_delete on public.movies;
create trigger trg_protect_movie_delete
  before delete on public.movies
  for each row execute function public.check_movie_deletion();

-- 3. Cập nhật RLS policy profiles_select để Staff/Manager đọc được thông tin khách hàng
drop policy if exists profiles_select on public.profiles;
create policy profiles_select on public.profiles for select using (
  id = auth.uid()
  or public.current_role_name() = 'admin'
  or (
    public.current_role_name() in ('staff', 'manager') 
    and (cinema_id = public.current_cinema() or role = 'customer')
  )
);
```

---

## 4. CHI TIẾT THIẾT KẾ 4 MÀN HÌNH (S13, S14, S15, S16)

### 4.1. S13: Movies CRUD Management (`/management/movies`)

#### 4.1.1. Phân quyền người dùng (Role Behavior):
- **Manager:** Chỉ xem (`ROLE_FLOWS.md` 4.6). Xem danh sách, tìm kiếm, lọc phim, mở modal xem chi tiết phim. KHÔNG CÓ nút "THÊM PHIM", KHÔNG CÓ nút Sửa hay Xóa.
- **Admin:** Toàn quyền CRUD (`ROLE_FLOWS.md` 5.2). Có nút "THÊM PHIM" trên AppBar, nút Chỉnh sửa và Xóa trên từng thẻ phim, công tắc bật/tắt `is_active`.

#### 4.1.2. Bộ lọc và Tìm kiếm:
- **Thanh tìm kiếm:** `AppTextField` với icon tìm kiếm (`Icons.search`), tìm theo tên tiếng Việt hoặc tên gốc (case-insensitive).
- **Chip lọc trạng thái (4 chip):**
  - `TẤT CẢ` (Mặc định)
  - `ĐANG CHIẾU` (`movie.isActive && !movie.releaseDate.isAfter(now)`)
  - `SẮP CHIẾU` (`movie.isActive && movie.releaseDate.isAfter(now)`)
  - `NGỪNG CHIẾU` (`!movie.isActive`)

#### 4.1.3. Danh sách phim:
- Mỗi thẻ phim (`MovieManagementCard`):
  - Poster tỉ lệ chuẩn 2:3 (kích thước 64x96 dp) với `ClipRRect` bo góc `AppRadius.none` hoặc fallback `Image.network`.
  - Tên phim in đậm (`AppTextStyles.titleSm`).
  - Badge độ tuổi chuẩn (`AppBadge.age(movie.ageRating)`): `P`, `K`, `T13`, `T16`, `T18`.
  - Thời lượng: `[X] phút` · Khởi chiếu: `dd/MM/yyyy`.
  - Badge trạng thái (`StatusBadge` hoặc `AppBadge`): Đang chiếu (Xanh lá), Sắp chiếu (Xanh dương), Ngừng chiếu (Xám mờ).
  - Phím thao tác (Chỉ hiện cho Admin):
    - Switch bật/tắt nhanh `isActive`.
    - Nút Icon Sửa (`Icons.edit_outlined`).
    - Nút Icon Xóa (`Icons.delete_outline`, màu `AppColors.error`).

#### 4.1.4. Modal Thêm / Chỉnh Sửa Phim:
Mở bằng `showModalBottomSheet(isScrollControlled: true)`:
- Tiêu đề: "THÊM PHIM MỚI" hoặc "CHỈNH SỬA PHIM".
- Các trường nhập liệu (100% dùng `AppTextField`):
  1. **Tên phim:** Bắt buộc, không để trống.
  2. **Đạo diễn:** Tên đạo diễn.
  3. **Diễn viên:** Nhập danh sách phân cách bởi dấu phẩy (parse thành `List<String>`).
  4. **Thể loại:** Chọn qua danh sách chip có sẵn (Hành động, Hài, Kinh dị, Hoạt hình, Tâm lý, Khoa học viễn tưởng, Tình cảm) hoặc nhập tự do.
  5. **Thời lượng (phút):** Bắt buộc, số nguyên > 0 (`keyboardType: TextInputType.number`).
  6. **Ngày khởi chiếu:** Chọn ngày qua DatePicker hoặc nhập `yyyy-MM-dd`.
  7. **Độ tuổi:** Dropdown / Segmented Button 5 giá trị: `P`, `K`, `T13`, `T16`, `T18`.
  8. **Link Poster URL:** Text field kèm khung preview ảnh nhỏ.
  9. **Link Backdrop URL:** Text field.
  10. **Link Trailer URL:** Text field YouTube link.
  11. **Tóm tắt nội dung (Synopsis):** `maxLines: 4`.
  12. **Trạng thái hoạt động:** `SwitchListTile` ("Đang phát hành / Hoạt động").
- Nút bấm:
  - "LƯU THÔNG TIN" (Nút chính duy nhất, Rosso Corsa `#DA291C`, `.toUpperCase()`).
  - "ĐÓNG" / "HỦY" (Nút phụ).

#### 4.1.5. Cơ chế Bảo Vệ Xóa Phim:
- Khi Admin bấm Xóa phim:
  1. Kiểm tra: gọi `ManagementRepository.checkMovieHasActiveShowtimes(movieId)`.
  2. Nếu có suất tương lai: hiển thị Dialog cảnh báo màu vàng/đỏ:
     - Tiêu đề: "KHÔNG THỂ XÓA PHIM"
     - Nội dung: "Phim này hiện đang có [N] suất chiếu trong tương lai. Bạn phải hủy hoặc hoàn tất các suất chiếu đó trước khi có thể xóa phim khỏi hệ thống."
     - Nút: "ĐÃ HIỂU".
  3. Nếu không có suất tương lai: hiển thị Dialog xác nhận:
     - Tiêu đề: "XÁC NHẬN XÓA PHIM"
     - Nội dung: "Bạn có chắc chắn muốn xóa vĩnh viễn phim [Tên Phim]? Thao tác này không thể hoàn tác."
     - Nút: "HỦY" & "XÁC NHẬN XÓA" (Màu đỏ `AppColors.error`).

---

### 4.2. S14: Showtime Management (`/management/showtimes`)

#### 4.2.1. Phân quyền & Phạm vi:
- **Manager:** Tự động cố định rạp theo tài khoản (`cinemaId = currentUser.cinemaId`). Chỉ quản lý suất chiếu tại rạp mình.
- **Admin:** Có Dropdown chọn rạp trên AppBar (`TẤT CẢ` hoặc chọn từng rạp cụ thể như `Vincom Đồng Khởi (cn_q1)`, `Tân Bình (cn_tb)`).

#### 4.2.2. Bộ lọc trên màn hình:
1. **Dải chọn ngày 7 ngày:**
   - Dãy chip ngang (tương tự `DateChip`), hiển thị Thứ, Ngày/Tháng.
   - Nút icon Lịch để chọn ngày xa hơn trong tương lai.
2. **Chip lọc Phòng chiếu:**
   - `TẤT CẢ PHÒNG` và danh sách các phòng thuộc rạp (ví dụ: `Phòng 1 (IMAX)`, `Phòng 2 (2D)`).
3. **Chip lọc Định dạng:**
   - `TẤT CẢ`, `2D`, `3D`, `IMAX`.

#### 4.2.3. Danh sách suất chiếu:
Mỗi hàng suất chiếu (`ShowtimeManagementCard`):
- Khung giờ chiếu: `19:00 — 21:10` (In đậm, font mono/titleSm).
- Thông tin phim: Tên phim, Badge độ tuổi (`AppBadge.age`), Poster thumbnail nhỏ.
- Phòng chiếu & Định dạng: `Phòng 1` · `IMAX` (`AppBadge.format`).
- Tình trạng ghế: Thanh tiến độ mảnh (`LinearProgressIndicator` Rosso Corsa/Grey), text `Đã bán 24/75 ghế` (hoặc `HẾT VÉ`).
- Trạng thái suất:
  - Nếu `status == 'active'`: Badge xanh "HOẠT ĐỘNG". Nút "HỦY SUẤT" (nút viền đỏ Rosso Corsa).
  - Nếu `status == 'cancelled'`: Badge xám "ĐÃ HỦY", làm mờ thông tin (opacity 0.6), kèm lý do hủy: `Lý do: [cancel_reason]`.

#### 4.2.4. Modal Thêm Suất Chiếu Mới:
- Mở bằng nút "THÊM SUẤT" ở AppBar hoặc Floating Action Button.
- Các bước chọn dữ liệu:
  1. **Chọn phim:** Dropdown danh sách các phim `is_active = true`. Hiển thị tên phim kèm thời lượng (ví dụ: `Oppenheimer (180 phút)`).
  2. **Chọn phòng chiếu:** Dropdown danh sách phòng của rạp. Tự động lấy `seatCount` và các định dạng phòng hỗ trợ.
  3. **Chọn định dạng:** Radio/Chip lọc theo các định dạng mà phòng đó hỗ trợ (`formats` của RoomModel, ví dụ `2D`, `IMAX`).
  4. **Chọn ngày & giờ bắt đầu:**
     - DatePicker (mặc định là ngày đang xem).
     - TimePicker (giờ và phút).
  5. **Giờ kết thúc tự động:**
     - Được tính toán tự động ngay khi chọn giờ bắt đầu:
       `endTime = startTime.add(Duration(minutes: selectedMovie.durationMin))`
     - Hiển thị hộp thông tin màu `AppColors.canvasElevated`: "Giờ kết thúc dự kiến: 21:10 (Thời lượng phim: 180 phút)".
  6. **Loại âm thanh / Phụ đề:** Radio/Dropdown `Phụ đề` hoặc `Lồng tiếng`.

#### 4.2.5. Kiểm Tra Xung Đột 15 Phút (Conflict Validation 2 Lớp):
1. **Lớp 1: Kiểm tra tại Client (Pre-check):**
   - Khi người dùng nhấn nút "LƯU SUẤT CHIẾU", client chạy thuật toán `hasShowtimeConflict`:
     ```dart
     bool hasConflict = false;
     ShowtimeModel? conflictedShowtime;
     for (final existing in roomShowtimes) {
       if (existing.status != 'active') continue;
       if (hasShowtimeConflict(
         existingStart: existing.startTime,
         existingEnd: existing.endTime,
         candidateStart: candidateStartTime,
         candidateEnd: candidateEndTime,
       )) {
         hasConflict = true;
         conflictedShowtime = existing;
         break;
       }
     }
     ```
   - Nếu có xung đột: Hiện thông báo tức thì:
     `"Phòng [Tên phòng] đã có suất chiếu từ [HH:mm] đến [HH:mm] (Khoảng nghỉ vệ sinh tối thiểu 15 phút)."`
2. **Lớp 2: Kiểm tra tại Database Trigger:**
   - Dù client có vượt qua hay bị race condition, trigger `trg_showtime_conflict` của PostgreSQL sẽ bắt chặn tại thời điểm `INSERT/UPDATE` và ném lỗi `SHOWTIME_CONFLICT`.
   - Controller bắt exception từ Supabase, bóc tách chuỗi thông báo và hiển thị Snackbar đỏ cho người dùng.

#### 4.2.6. Quy Trình Hủy Suất Chiếu (`cancel_showtime`):
- Nhấn nút "HỦY SUẤT":
  - Mở Dialog xác nhận hủy:
    - Tiêu đề: "XÁC NHẬN HỦY SUẤT CHIẾU" (Icon cảnh báo màu đỏ).
    - Nội dung: "Cảnh báo: Suất chiếu lúc [HH:mm] ngày [dd/MM] sẽ bị hủy vĩnh viễn. Toàn bộ các vé đã thanh toán ([N] vé) sẽ được tự động hủy và hoàn tiền 100% cho khách hàng. Thông báo sẽ được gửi đến từng khách."
    - Ô nhập lý do: `AppTextField` (bắt buộc nhập lý do, ví dụ: "Sự cố kỹ thuật máy chiếu", "Mất điện đột xuất").
    - Nút bấm: "HỦY THAO TÁC" & "XÁC NHẬN HỦY SUẤT" (Rosso Corsa).
  - Khi xác nhận: Gọi `ManagementProvider.cancelShowtime(showtimeId, reason)` -> kích hoạt RPC `cancel_showtime`.

---

### 4.3. S15: Bookings & Orders Inspection (`/management/bookings`)

#### 4.3.1. Phân quyền & Giới hạn:
- **Manager:** Chỉ xem các đơn đặt vé thuộc rạp của mình (`cinema_id = currentCinemaId`).
- **Admin:** Xem được toàn bộ đơn vé của tất cả các rạp (có bộ lọc rạp).

#### 4.3.2. Thanh tìm kiếm đa năng:
- Hỗ trợ tìm kiếm thời gian thực theo:
  - **Mã booking:** Tìm chính xác hoặc tiền tố (ví dụ: `BK892341`).
  - **Số điện thoại khách hàng:** Tìm theo chuỗi số (ví dụ: `0901`).
  - **Họ tên khách hàng:** Tìm theo tên (ví dụ: `Nguyễn Văn Khách`).
  - **Tên phim:** Tìm theo tựa phim.

#### 4.3.3. Bộ lọc trạng thái & Kênh:
- **Hàng 1: Chip trạng thái (6 chip):**
  - `TẤT CẢ`
  - `PAID` (Đã thanh toán)
  - `USED` (Đã soát vé vào rạp)
  - `NOSHOW` (Vắng mặt: quá 15 phút sau giờ chiếu chưa soát vé)
  - `CANCELLED` (Đã hủy / Đã hoàn tiền)
  - `EXPIRED` (Hết hạn giữ ghế)
- **Hàng 2: Chip kênh bán vé (3 chip):**
  - `TẤT CẢ`
  - `ONLINE` (Khách tự đặt qua App)
  - `QUẦY` (Nhân viên bán vé trực tiếp tại quầy POS)

#### 4.3.4. Danh sách đơn vé:
Mỗi thẻ đơn vé (`BookingInspectionCard`):
- Hàng đầu:
  - Mã booking in to, font monospace (`#BK892341`, màu `AppColors.ink`).
  - Badge Kênh: `ONLINE` (`AppColors.info`) hoặc `QUẦY` (`AppColors.warning`).
  - Badge Trạng thái: `StatusBadge` theo màu chuẩn (Xanh lá: Paid, Xanh dương: Used, Xám: Cancelled, Vàng cam: NoShow).
- Thông tin chính:
  - Khách hàng: Họ tên & SĐT (nếu là vé quầy không có user thì ghi "Khách mua tại quầy").
  - Phim & Rạp: `Dune: Part Two` · `Phòng 1 (IMAX)` · `Vincom Đồng Khởi`.
  - Suất chiếu: `19:00 · 28/10/2026`.
  - Ghế đã chọn: `A1, A2 (Ghế thường)` hoặc `C5, C6 (VIP)`.
  - Tổng tiền: Định dạng VND (ví dụ: `240.000 đ`, font bold màu `AppColors.primary`).
- Chạm vào thẻ: Mở Modal Bottom Sheet chi tiết đơn hàng toàn diện.

#### 4.3.5. Bottom Sheet Chi Tiết Đơn Hàng (Order Detail Sheet):
Mở rộng toàn màn hình (`showModalBottomSheet(isScrollControlled: true)`):
1. **Header:**
   - Mã đơn hàng `#BK892341` kèm nút copy mã.
   - Trạng thái vé hiện tại.
2. **Khối Thông tin Khách hàng:**
   - Họ và tên, Số điện thoại, Email tài khoản.
   - Loại tài khoản: Thành viên App / Khách vãng lai tại quầy.
3. **Khối Phim & Suất Chiếu:**
   - Poster phim, Tên phim, Định dạng, Độ tuổi.
   - Tên rạp, Tên phòng chiếu, Giờ bắt đầu, Giờ kết thúc.
4. **Khối Danh sách Ghế:**
   - Chi tiết từng ghế: Tên ghế (A5, B6), Loại ghế (Thường/VIP/Đôi), Giá vé từng ghế.
   - Tổng tiền vé (`ticketTotal`).
5. **Khối Đồ ăn & Bắp nước:**
   - Danh sách món: Tên món, số lượng, đơn giá, thành tiền (ví dụ: `1x Combo Bắp Phô Mai - 85.000 đ`).
   - Trạng thái giao đồ ăn (`foodStatus`): `none`, `pending`, `delivered`, `cancelled`.
   - Nếu đã giao: Hiển thị thời gian giao và nhân viên giao hàng.
6. **Khối Thanh toán & Tài chính:**
   - Phương thức: VNPay Sandbox / Tiền mặt / Thẻ ngân hàng.
   - Mã giao dịch VNPay (nếu có: `vnp_transaction_no`).
   - Thời điểm thanh toán: `dd/MM/yyyy HH:mm:ss`.
   - Bảng phân rã snapshot giá (`price_snapshot`): Tiền vé + Tiền đồ ăn - Giảm giá = **Tổng thanh toán**.
7. **Khối Lịch sử & Kiểm toán (Audit Timeline):**
   - Tạo lúc: `dd/MM/yyyy HH:mm`.
   - Bán bởi: Tên nhân viên bán (đối với vé quầy).
   - Soát vé: Đã soát vé lúc `HH:mm` bởi `[Tên NV Soát Vé]` (hoặc "Chưa soát vé").
   - Hủy vé: Nếu đã hủy -> Lý do hủy, Người thực hiện hủy, Thời gian hủy.
8. **Thao tác quản lý (Manager Actions):**
   - Đối với vé quầy đang ở trạng thái `paid` và chưa chiếu: Hiển thị nút "HỦY / HOÀN VÉ TẠI QUẦY", yêu cầu nhập lý do và gọi RPC `cancel_booking` (mục 10.2 `BUSINESS_RULES.md`).

---

### 4.4. S16: Food & Concessions Catalog Management (`/management/foods`)

#### 4.4.1. Phân quyền & Giới hạn:
- **Manager:** Quản lý thực đơn của rạp mình (`cinema_id = currentCinemaId`). Được thêm, sửa, xóa món và bật/tắt khả dụng.
- **Admin:** Có dropdown chọn rạp để quản lý thực đơn cho từng rạp cụ thể trong chuỗi.

#### 4.4.2. Danh mục & Bộ lọc:
- **Chip phân loại (5 chip):**
  - `TẤT CẢ` (Mặc định)
  - `COMBO` (`combo`)
  - `BẮP RANG` (`popcorn`)
  - `NƯỚC UỐNG` (`drink`)
  - `ĐỒ ĂN NHẸ` (`snack`)
- **Tìm kiếm:** Ô tìm kiếm tên món ăn theo thời gian thực.

#### 4.4.3. Danh sách món ăn:
Mỗi thẻ món ăn (`FoodManagementCard`):
- Ảnh món ăn: Kích thước 64x64 dp, bo góc `AppRadius.none`, hiển thị placeholder nếu không có ảnh.
- Tên món ăn: In đậm, cỡ chữ `AppTextStyles.titleSm`.
- Badge danh mục: `AppBadge` phân biệt màu sắc nhẹ nhàng theo nhóm.
- Đơn giá: Kiểu số nguyên `int` định dạng VND (ví dụ: `85.000 đ`, font `AppTextStyles.titleMedium` màu Rosso Corsa).
- Mô tả ngắn: Tóm tắt thành phần (ví dụ: `1 Bắp rang bơ lớn + 2 Nước ngọt 22oz`).
- Công tắc khả dụng (`is_available`):
  - Nhãn: `CÒN HÀNG` (màu xanh lá) / `HẾT HÀNG` (màu xám đỏ).
  - Thao tác: Bật/tắt gọi ngay `ManagementProvider.toggleFood(foodId, isAvailable)`. Cập nhật trạng thái tức thời không cần tải lại trang.
- Thao tác sửa/xóa:
  - Chạm vào thẻ hoặc bấm nút Icon Sửa -> Mở modal chỉnh sửa món.
  - Nút Xóa (Icon thùng rác đỏ): Xác nhận xóa món ăn khỏi thực đơn.

#### 4.4.4. Modal Thêm / Chỉnh Sửa Món Ăn:
- Tiêu đề: "THÊM MÓN MỚI" hoặc "CHỈNH SỬA MÓN ĂN".
- Form nhập liệu:
  1. **Tên món ăn:** `AppTextField` (bắt buộc, ví dụ: "Combo Solo 1 Bắp 1 Nước").
  2. **Danh mục:** Dropdown chọn 1 trong 4 danh mục chuẩn:
     - `combo`: Combo bắp nước
     - `popcorn`: Bắp rang
     - `drink`: Nước ngọt / Nước suối
     - `snack`: Đồ ăn nhẹ
  3. **Đơn vị giá (VND):** `AppTextField` (chỉ cho phép nhập số nguyên > 0, hậu tố "đ", ví dụ: `75000`).
  4. **Link ảnh (Image URL):** Text field kèm preview ảnh tức thì.
  5. **Mô tả chi tiết:** `AppTextField` nhiều dòng (tùy chọn).
  6. **Trạng thái có sẵn:** `SwitchListTile` ("Đang có sẵn để bán").
  7. **Rạp áp dụng (đối với Admin):** Dropdown chọn rạp. Đối với Manager, tự động gán `currentCinemaId`.
- Nút bấm:
  - "LƯU MÓN ĂN" (Nút chính, Rosso Corsa, `.toUpperCase()`).
  - "HỦY" (Nút phụ).

---

## 5. THIẾT KẾ DATA LAYER & CONTROLLERS (PROVIDERS)

### 5.1. Mở rộng `ManagementRepository`:
Cập nhật file `lib/features/management/data/repositories/management_repository.dart`:

```dart
// ---------------------------------------------------------------------------
// S13: Movies Management
// ---------------------------------------------------------------------------
/// Lấy danh sách tất cả các phim (bao gồm cả active và inactive cho quản trị).
Future<List<MovieModel>> getAllMovies() async {
  final response = await _supabase
      .from('movies')
      .select()
      .order('release_date', ascending: false);
  return (response as List).map((m) => MovieModel.fromMap(m)).toList();
}

/// Tạo phim mới (Admin).
Future<MovieModel> createMovie(MovieModel movie) async {
  final data = movie.toMap()..remove('id');
  final response = await _supabase.from('movies').insert(data).select().single();
  return MovieModel.fromMap(response);
}

/// Cập nhật thông tin phim (Admin).
Future<void> updateMovie(MovieModel movie) async {
  final data = movie.toMap()..remove('id');
  await _supabase.from('movies').update(data).eq('id', movie.id);
}

/// Kiểm tra xem phim có suất chiếu nào trong tương lai không.
Future<bool> hasActiveFutureShowtimes(String movieId) async {
  final response = await _supabase
      .from('showtimes')
      .select('id')
      .eq('movie_id', movieId)
      .eq('status', 'active')
      .gte('start_time', DateTime.now().toUtc().toIso8601String())
      .limit(1);
  return (response as List).isNotEmpty;
}

/// Xóa phim (chặn nếu có suất chiếu tương lai).
Future<void> deleteMovie(String movieId) async {
  final hasShowtimes = await hasActiveFutureShowtimes(movieId);
  if (hasShowtimes) {
    throw Exception('Không thể xóa phim vì đang có suất chiếu trong tương lai.');
  }
  await _supabase.from('movies').delete().eq('id', movieId);
}

// ---------------------------------------------------------------------------
// S14: Showtimes Management
// ---------------------------------------------------------------------------
/// Lấy danh sách suất chiếu của rạp theo ngày, kèm thông tin phim và phòng.
Future<List<ShowtimeModel>> getShowtimes({
  required String cinemaId,
  required DateTime date,
  String? roomId,
  String? format,
}) async {
  final startOfDay = DateTime(date.year, date.month, date.day, 0, 0, 0);
  final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

  var query = _supabase
      .from('showtimes')
      .select('*, rooms(name), cinemas(name), movies(title, duration_min, poster_url, age_rating)')
      .eq('cinema_id', cinemaId)
      .gte('start_time', startOfDay.toUtc().toIso8601String())
      .lte('start_time', endOfDay.toUtc().toIso8601String());

  if (roomId != null && roomId.isNotEmpty) {
    query = query.eq('room_id', roomId);
  }
  if (format != null && format.isNotEmpty) {
    query = query.eq('format', format);
  }

  final response = await query.order('start_time', ascending: true);
  return (response as List).map((row) {
    final enriched = Map<String, dynamic>.from(row);
    enriched['room_name'] = (row['rooms'] as Map?)?['name'];
    enriched['cinema_name'] = (row['cinemas'] as Map?)?['name'];
    enriched['movie_title'] = (row['movies'] as Map?)?['title'];
    return ShowtimeModel.fromMap(enriched);
  }).toList();
}

// ---------------------------------------------------------------------------
// S15: Bookings Inspection
// ---------------------------------------------------------------------------
/// Mở rộng lấy danh sách đơn vé có kèm thông tin khách hàng từ profiles.
Future<List<BookingModel>> getBookingsWithProfiles(
  String cinemaId, {
  String? status,
  String? channel,
  String? search,
}) async {
  var query = _supabase
      .from('bookings')
      .select('*, profiles:user_id(full_name, phone)')
      .eq('cinema_id', cinemaId);

  if (status != null && status != 'ALL') {
    query = query.eq('status', status.toLowerCase());
  }
  if (channel != null && channel != 'ALL') {
    query = query.eq('channel', channel.toLowerCase());
  }

  final response = await query.order('created_at', ascending: false).limit(100);
  return (response as List).map((b) => BookingModel.fromMap(b)).toList();
}

// ---------------------------------------------------------------------------
// S16: Food Catalog Management
// ---------------------------------------------------------------------------
/// Lấy danh sách thực đơn của rạp.
Future<List<FoodModel>> getFoods(String cinemaId, {String? category}) async {
  var query = _supabase.from('foods').select().eq('cinema_id', cinemaId);
  if (category != null && category != 'ALL') {
    query = query.eq('category', category.toLowerCase());
  }
  final response = await query.order('category').order('name');
  return (response as List).map((f) => FoodModel.fromMap(f)).toList();
}

/// Tạo món ăn mới.
Future<void> createFood(FoodModel food) async {
  await _supabase.from('foods').insert({
    'cinema_id': food.cinemaId,
    'name': food.name,
    'category': food.category,
    'price': food.price,
    'is_available': food.isAvailable,
    'image_url': food.imageUrl,
    'description': food.description,
  });
}

/// Cập nhật món ăn.
Future<void> updateFood(FoodModel food) async {
  await _supabase.from('foods').update({
    'name': food.name,
    'category': food.category,
    'price': food.price,
    'is_available': food.isAvailable,
    'image_url': food.imageUrl,
    'description': food.description,
  }).eq('id', food.id);
}

/// Xóa món ăn.
Future<void> deleteFood(String foodId) async {
  await _supabase.from('foods').delete().eq('id', foodId);
}
```

### 5.2. Mở rộng `ManagementProvider`:
File `lib/features/management/presentation/controllers/management_provider.dart`:
- Quản lý trạng thái độc lập cho từng module:
  - `_movies`, `_showtimes`, `_bookings`, `_foods`.
  - Các hàm load tương ứng: `loadMovies()`, `loadShowtimes()`, `loadBookings()`, `loadFoods()`.
  - Các hàm mutate:
    - Movies: `saveMovie()`, `deleteMovie()`, `toggleMovieActive()`.
    - Showtimes: `createShowtime()` (bắt lỗi `SHOWTIME_CONFLICT`), `cancelShowtime()`.
    - Bookings: `loadBookings()`, `cancelCounterBooking()`.
    - Foods: `saveFood()`, `deleteFood()`, `toggleFood()`.
- Xử lý thông báo thành công / lỗi chuẩn hóa và `notifyListeners()`.

---

## 6. DANH MỤC FILE CẦN TẠO VÀ CHỈNH SỬA

| STT | Đường dẫn file | Thao tác | Mô tả chi tiết |
|:---:|---|:---:|---|
| 1 | `supabase/migrations/0007_m5_part_b_enhancements.sql` | Tạo mới | Bổ sung độ tuổi K, trigger bảo vệ xóa phim, mở rộng RLS đọc khách hàng. |
| 2 | `lib/features/management/data/repositories/management_repository.dart` | Chỉnh sửa | Bổ sung các phương thức CRUD phim, suất chiếu, đơn vé kèm profiles, thực đơn bắp nước. |
| 3 | `lib/features/management/presentation/controllers/management_provider.dart` | Chỉnh sửa | Mở rộng state và controller methods cho Movies, Showtimes, Bookings, Foods. |
| 4 | `lib/features/management/presentation/screens/manage_movies_screen.dart` | Tạo mới | Màn hình S13: Quản lý phim, danh sách, tìm kiếm, lọc, modal thêm/sửa, bảo vệ xóa. |
| 5 | `lib/features/management/presentation/screens/manage_showtimes_screen.dart` | Tạo mới | Màn hình S14: Quản lý suất chiếu, dải ngày, modal thêm suất, kiểm tra 15 phút, hủy suất. |
| 6 | `lib/features/management/presentation/screens/manage_bookings_screen.dart` | Tạo mới | Màn hình S15: Kiểm tra đơn vé, tìm kiếm, bộ lọc trạng thái & kênh, bottom sheet chi tiết. |
| 7 | `lib/features/management/presentation/screens/manage_foods_screen.dart` | Tạo mới | Màn hình S16: Quản lý menu bắp nước, lọc nhóm, công tắc khả dụng, modal thêm/sửa món. |
| 8 | `lib/core/routes/app_router.dart` | Chỉnh sửa | Đăng ký 4 màn hình vào switch case route generator (`manageMovies`, `manageShowtimes`, `manageBookings`, `manageFoods`). |
| 9 | `test/features/management/manage_movies_screen_test.dart` | Tạo mới | Widget tests cho S13: loading, empty, render movies, filter, search, dialogs. |
| 10 | `test/features/management/manage_showtimes_screen_test.dart` | Tạo mới | Widget tests cho S14: date strip, conflict warning 15 phút, modal thêm, hủy suất. |
| 11 | `test/features/management/manage_bookings_screen_test.dart` | Tạo mới | Widget tests cho S15: filter status/channel, search, order details bottom sheet. |
| 12 | `test/features/management/manage_foods_screen_test.dart` | Tạo mới | Widget tests cho S16: category chips, toggle availability, modal add/edit. |

---

## 7. CHECKLIST TUÂN THỦ QUY CHUẨN (COMPLIANCE CHECKLIST)

- [x] **Zero Style Hardcoding:** 100% màu sắc, khoảng cách, bo góc dùng `AppColors`, `AppSpacing`, `AppRadius`, `AppTextStyles`.
- [x] **Dark Aesthetic:** Nền canvas `#181818` (`AppColors.canvas`), nút chính Rosso Corsa `#DA291C` (`AppColors.primary`), không dùng box shadow (`elevation: 0`).
- [x] **Trạng thái UI:** 100% màn hình xử lý đủ 3 trạng thái: Loading (`SkeletonBox`), Empty (`EmptyState`), Error (`ErrorState` có nút `THỬ LẠI`).
- [x] **Navigation & Button Labels:** Mọi nhãn nút và tab đều được `.toUpperCase()`.
- [x] **Giới hạn Primary Button:** Tối đa 1 nút primary trên một màn hình / modal.
- [x] **Bảo mật RLS:** Truy vấn của Manager luôn có điều kiện theo rạp `cinema_id = currentCinemaId`.
- [x] **Nghiệp vụ tiền:** Tiền tệ VND dùng kiểu `int` tuyệt đối (không dùng `double`).
- [x] **Code Sạch:** Không `print`, không `TODO`.
- [x] **Tái sử dụng (Karpathy Rule 7):** Tái sử dụng toàn bộ `MovieModel`, `ShowtimeModel`, `BookingModel`, `FoodModel`, `RoomModel`, `AppUser`, `hasShowtimeConflict`.

---

## 8. TIÊU CHÍ NGHIỆM THU KIỂM CHỨNG ĐƯỢC (VERIFIABLE ACCEPTANCE CRITERIA)

1. **S13 Movies CRUD:**
   - Đăng nhập tài khoản `manager1@cinema.vn` -> Truy cập S13 -> Chỉ có quyền xem danh sách phim và chi tiết phim, không có nút thêm, sửa, xóa.
   - Đăng nhập tài khoản `admin@cinema.vn` -> Truy cập S13 -> Thấy nút "THÊM PHIM", mở modal nhập đủ thông tin và lưu thành công.
   - Xóa phim đang có suất chiếu tương lai -> Bị chặn và hiển thị dialog cảnh báo rõ ràng.
   - Lọc theo Đang chiếu, Sắp chiếu, Ngừng chiếu và tìm kiếm theo tên hoạt động chính xác.
2. **S14 Showtime Management:**
   - Hiển thị danh sách suất chiếu lọc theo dải ngày 7 ngày và phòng chiếu.
   - Thêm suất chiếu mới: Giờ kết thúc được tự động tính theo thời lượng phim.
   - Chọn khung giờ cách suất chiếu khác trong cùng phòng dưới 15 phút -> Bị chặn với thông báo lỗi cụ thể phòng và khung giờ đang chồng lấn.
   - Bấm HỦY SUẤT -> Hộp thoại xác nhận yêu cầu nhập lý do -> Gọi RPC `cancel_showtime` -> Suất chuyển sang mờ và các đơn vé liên quan được hoàn tiền tự động.
3. **S15 Bookings Inspection:**
   - Tìm kiếm được đơn vé theo mã booking (8 ký tự), số điện thoại, hoặc tên khách hàng.
   - Lọc chính xác theo chip trạng thái (Paid, Used, NoShow, Cancelled, Expired) và kênh (Online, Quầy).
   - Chạm vào đơn vé -> Mở bottom sheet hiển thị đầy đủ thông tin: khách hàng, ghế, đồ ăn, phương thức thanh toán, thời gian soát vé.
4. **S16 Food Catalog:**
   - Lọc danh sách món ăn theo các chip: Tất cả, Bắp, Nước, Combo, Snack.
   - Bật/tắt công tắc khả dụng `is_available` -> Cập nhật DB và giao diện đổi giữa "CÒN HÀNG" và "HẾT HÀNG".
   - Mở modal thêm món ăn mới -> Nhập tên, chọn danh mục, giá tiền (VND nguyên), lưu thành công.
5. **Chất lượng mã nguồn:**
   - `flutter analyze` đạt **0 errors, 0 warnings**.
   - `flutter test` toàn bộ test suite đạt **100% passing**.
