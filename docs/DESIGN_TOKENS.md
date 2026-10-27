# DESIGN_TOKENS.md — Màu sắc, typography, khoảng cách, bo góc, component

> Tóm tắt có cấu trúc để AI tra cứu nhanh. Chi tiết trực quan và code Dart nền tảng nằm trong `DESIGN.md`.
> Nguyên tắc: chỉ dùng token. Không hardcode.

---

## 1. Tinh thần

Điện ảnh, tiết chế, sang. Màn tối như phòng chiếu. Poster và backdrop là nhân vật chính. Màu đỏ xuất hiện ít nên mỗi lần xuất hiện đều có trọng lượng.

Từ khóa: *cinematic · editorial · sharp · restrained · dark*.

---

## 2. Bảng màu

### 2.1 Thương hiệu
| Token | Hex | Dùng cho |
|---|---|---|
| `AppColors.primary` | `#DA291C` | Nút CTA chính, ghế đang chọn, ngày/suất đang chọn, vạch quét QR |
| `AppColors.primaryActive` | `#B01E0A` | Nút đang nhấn (pressed) |
| `AppColors.primaryHover` | `#9D2211` | Dự phòng tablet/web |

### 2.2 Nền và bề mặt
| Token | Hex | Dùng cho |
|---|---|---|
| `canvas` | `#181818` | Nền toàn app. Không dùng đen tuyệt đối |
| `canvasElevated` | `#303030` | Card, bottom sheet, thanh tổng tiền, ghế trống, nền tóm tắt đơn |
| `canvasLight` | `#FFFFFF` | Chỉ cho `TicketCard` và bảng giá |
| `surfaceSoftLight` | `#F7F7F7` | Dải sáng xen kẽ trên vé |
| `surfaceStrongLight` | `#EBEBEB` | Đường chia và badge trên nền sáng |

### 2.3 Đường kẻ (hairline)
| Token | Hex | Dùng cho |
|---|---|---|
| `hairline` | `#303030` | Viền 1px, đường chia trên nền tối, viền ô nhập |
| `hairlineOnLight` | `#D2D2D2` | Viền răng cưa và đường đứt trên vé |
| `hairlineSoft` | `#EBEBEB` | Đường chia nhạt |

### 2.4 Chữ
| Token | Hex | Dùng cho |
|---|---|---|
| `ink` | `#FFFFFF` | Tiêu đề, số lớn, chữ nhấn trên nền tối |
| `body` | `#969696` | Văn bản thường trên nền tối (đạt tương phản) |
| `bodyOnLight` | `#181818` | Chữ trên vé và nền sáng |
| `muted` | `#666666` | Caption, nhãn phụ, icon chưa chọn, ghế A-B-C. **Không dùng cho nội dung quan trọng** |
| `mutedSoft` | `#8F8F8F` | Chữ vô hiệu |
| `onPrimary` | `#FFFFFF` | Chữ trên nền đỏ |

### 2.5 Ngữ nghĩa
| Token | Hex | Dùng cho |
|---|---|---|
| `success` | `#03904A` | Đặt vé thành công, soát vé hợp lệ, thanh toán xong |
| `info` | `#4C98B9` | Thông báo trung tính, tin nhắn chat |
| `warning` | `#F13A2C` | Lỗi form, sắp hết giờ giữ ghế (<60s), soát vé từ chối, cảnh báo quá 8 ghế |
| `focusRing` | `#F6E500` | **Chỉ** viền focus của ô nhập. Không dùng nơi khác |
| `shimmerHighlight` | `#3C3C3C` | Điểm sáng skeleton |

**Tổng cộng:** 1 màu nhấn, 5 màu nền/bề mặt, 3 màu đường kẻ, 6 màu chữ, 4 màu ngữ nghĩa, 1 màu focus, 1 màu shimmer. Không thêm màu mới.

### 2.6 Màu ghế
| Trạng thái ghế | Token | Nền | Viền | Ký hiệu |
|---|---|---|---|---|
| Trống thường | `seatAvailable` | `canvasElevated` | không | — |
| VIP | `seatAvailable` | `canvasElevated` | 1px `ink` | — |
| Ghế đôi | `seatAvailable` | `canvasElevated` | không | rộng gấp đôi |
| Đang chọn | `seatSelected` | `primary` | không | số ghế trắng |
| Đã bán | `seatSold` | `canvas` | 1px `muted` | dấu × `muted` |
| Người khác đang giữ | `seatHeld` | `muted` | không | — |

---

## 3. Typography

**Font:** Inter (`google_fonts`). Hỗ trợ đủ dấu tiếng Việt. Phải test nhãn uppercase có dấu (ví dụ `ĐẶT VÉ`, `THANH TOÁN`).

| Token | Size | Weight | Line h | Letter sp. | Dùng cho |
|---|---|---|---|---|---|
| `displayMega` | 32 | 500 | 1.1 | -0.64 | Tên phim trên hero/backdrop |
| `displayXl` | 28 | 500 | 1.1 | -0.56 | Tiêu đề trang (ĐĂNG NHẬP, TẠO TÀI KHOẢN) |
| `displayLg` | 24 | 500 | 1.2 | -0.24 | Tiêu đề section, "ĐẶT VÉ THÀNH CÔNG", tiền thừa, tổng tiền |
| `displayMd` | 20 | 500 | 1.4 | 0.15 | Tiêu đề phụ, tên phim trong vé |
| `titleMd` | 18 | 700 | 1.2 | 0 | Tiêu đề component, giờ chiếu trong ShowtimeRow |
| `titleSm` | 16 | 500 | 1.4 | 0.08 | Tên phim trong card, nhãn danh sách |
| `bodyMd` | 14 | 400 | 1.5 | 0 | Văn bản mặc định |
| `bodySm` | 13 | 400 | 1.5 | 0 | Văn bản phụ, địa chỉ rạp |
| `caption` | 12 | 400 | 1.4 | 0 | Chú thích, thông báo lỗi trường |
| `captionUppercase` | 11 | 600 | 1.4 | 1.1 | Nhãn section, badge, nhãn bottom nav, hàng ghế, đồng hồ giữ ghế |
| `button` | 14 | 700 | 1.0 | 1.4 | Nhãn nút, UPPERCASE |
| `navLink` | 13 | 600 | 1.4 | 0.65 | Nhãn điều hướng, UPPERCASE |
| `numberDisplay` | 48 | 700 | 1.0 | -0.96 | Thời lượng, tổng tiền lớn, số trong SpecCell |

**Nguyên tắc:**
- Display luôn weight 500 (trừ `titleMd`, `button`, `numberDisplay` đã định sẵn).
- Letter spacing âm chỉ cho cỡ display.
- Nút và navigation luôn UPPERCASE bằng `.toUpperCase()` trong `AppButton` và `NavigationBar`.

---

## 4. Khoảng cách (AppSpacing, thang 8px)

| Token | px | Ghi chú |
|---|---|---|
| `xxxs` | 4 | Khoảng cách trong badge |
| `xxs` | 8 | Khoảng cách giữa phần tử nhỏ |
| `xs` | 16 | Padding ngang màn hình chuẩn |
| `sm` | 24 | Padding trong `TicketCard`, khoảng cách nhóm |
| `md` | 32 | Padding nút primary ngang |
| `lg` | 48 | Khoảng cách section, cao nút |
| `xl` | 64 | Khoảng cách section lớn, cao NavigationBar |
| `xxl` | 96 | Dự phòng |
| `superSpace` | 128 | Dự phòng (đổi tên vì `super` là từ khóa Dart) |

Quy tắc: không dùng số lẻ. Section cách nhau `lg`–`xl`. Trong card thì chặt hơn.

---

## 5. Bo góc (AppRadius)

| Token | px | Dùng cho |
|---|---|---|
| `none` | 0 | Nút, card, poster, banner, ảnh (**mặc định**) |
| `xs` | 2 | Ghế, badge nhỏ |
| `sm` | 4 | Ô nhập `AppTextField` |
| `xl` | 12 | Góc trên của bottom sheet và dialog |
| `full` | 9999 | Badge pill (T13/T16/T18, 2D/3D/IMAX), avatar |

---

## 6. Độ sâu

Không bóng đổ. Tầng được phân bằng:
1. `canvas` (#181818)
2. `canvasElevated` (#303030)
3. Viền hairline 1px
4. Ảnh full-bleed (poster, backdrop)

---

## 7. Component (đặt trong `lib/shared/widgets/`)

### 7.1 Nút
| Component | Nền | Chữ | Viền | Kích thước |
|---|---|---|---|---|
| `AppButton.primary` | `primary` (pressed: `primaryActive`) | `onPrimary` | không | cao 48, ngang 32, góc 0 |
| `AppButton.outline` | trong suốt | `ink` | 1px `ink` | cao 48, góc 0 |
| `AppButton.text` | trong suốt | `ink` | không | link nội tuyến |
| Disabled (mọi loại) | `canvasElevated` | `muted` | — | — |

Mỗi màn tối đa một nút primary hiển thị cùng lúc. Không dùng nút pill.

### 7.2 Badge — `AppBadge`
Nền `canvasElevated`, chữ `ink`, `captionUppercase`, bo `full`, padding 4×12. Dùng cho độ tuổi (P, T13, T16, T18), định dạng (2D, 3D, IMAX), trạng thái (SẮP CHIẾU, HẾT VÉ, ĐÃ HỦY).

### 7.3 Thẻ phim — `MovieCard`
- Poster tỉ lệ 2:3, góc 0, `cached_network_image`.
- Badge độ tuổi góc trên-trái poster.
- Dưới poster: tên phim (`titleSm`, `ink`), thể loại · thời lượng (`bodySm`, `muted`).
- Không viền, không bóng, không nền card.
- Lưới 2 cột (điện thoại), 3 cột (tablet > 600px).

### 7.4 Hàng suất chiếu — `ShowtimeRow`
Ngăn bằng hairline, padding dọc 16. Bố cục: giờ (`titleMd`, trái) · rạp/phòng/định dạng (`bodyMd`, giữa) · giá từ (`bodyMd`, phải). Hết chỗ: chữ `muted`, nhãn "HẾT VÉ", không bấm được.

### 7.5 Chip ngày — `DateChip`
Ô vuông góc 0, viền 1px `ink`, chữ `ink`. Đang chọn: nền `primary`, không viền. Vô hiệu: viền và chữ `muted`. Nhãn thứ (`captionUppercase`) trên, số ngày (`titleMd`) dưới.

### 7.6 Ô nhập — `AppTextField`
Nền `canvas`, viền 1px `hairline`, bo 4px, cao 48, padding 14×16, hint `muted`. Focus: viền `focusRing`. Lỗi: viền `warning`, dòng lỗi `caption` màu `warning`.

### 7.7 Spec cell — `SpecCell`
Số lớn (`numberDisplay`, `ink`) + nhãn (`captionUppercase`, `muted`). Ví dụ: **128** PHÚT · **T16** ĐỘ TUỔI · **2D** ĐỊNH DẠNG.

### 7.8 Banner nhấn — `PromoBand`
Dải full-width nền `primary`, chữ `displayLg` trắng, padding dọc 48. **Tối đa một dải đỏ mỗi màn.**

### 7.9 Thanh tổng tiền — `BookingSummaryBar`
Dính đáy, nền `canvasElevated`, hairline phía trên. Trái: "2 GHẾ · A5, A6" (`bodySm`) + tổng tiền (`displayLg`). Phải: `AppButton.primary` "TIẾP TỤC".

### 7.10 Điều hướng dưới — `NavigationBar`
Nền `canvas`, không indicator, cao 64. Nhãn `captionUppercase`: chọn = `ink`, chưa chọn = `muted`.

### 7.11 Skeleton — `SkeletonBox`
Nền `canvasElevated`, điểm sáng `shimmerHighlight`. Khối góc 0, đúng kích thước nội dung thật.

### 7.12 Vé điện tử — `TicketCard`
Nền `canvasLight`, chữ `bodyOnLight`, góc 0, padding 24. Tên phim `displayMd`. Thông tin (rạp, phòng, ghế, giờ) là nhãn `captionUppercase` + giá trị `titleMd`. Đường răng cưa/đứt nét `hairlineOnLight`. QR (`qr_flutter`) ở giữa-dưới. Đặt trên nền `canvas`.

### 7.13 Sơ đồ ghế — `SeatWidget`, `SeatLegend`
- Ghế 28×28, khoảng cách ghế 6, giữa hàng 8. Vùng chạm tối thiểu 36×36.
- Ghế đôi rộng `2×28 + 6`. Góc 2px.
- Chạm ghế: đổi màu tức thì (≤150ms), không scale, có `HapticFeedback.selectionClick`.
- Lưới trong `InteractiveViewer` (min 1, max 2.5).
- Nhãn hàng A, B, C… hai bên (`captionUppercase`, `muted`). Nhãn "MÀN HÌNH" phía trên.

### 7.14 Đồng hồ giữ ghế — `HoldTimer`
Nhãn `captionUppercase`: "GIỮ GHẾ CÒN 04:32". Dưới 60 giây: chữ đổi sang `warning`. Hết giờ: dialog và quay về S06.

### 7.15 Bộ tăng giảm — `QuantityStepper`
Nút vuông góc 0, viền 1px `hairline`, số ở giữa (`titleSm`). Món hết hàng: mờ, vô hiệu nút tăng.

### 7.16 Trạng thái UI
| Trạng thái | Widget | Thể hiện |
|---|---|---|
| Loading | `SkeletonBox` | Khối vuông góc 0, đúng kích thước thật. Không dùng spinner giữa màn (trừ lúc chờ thanh toán) |
| Empty | `EmptyState` | Icon `muted` + một dòng `titleSm` + một dòng `bodySm` + nút outline nếu có hành động |
| Error | `ErrorState` | Mô tả lỗi + `AppButton.outline` "THỬ LẠI" |
| Hết vé | — | Chữ `muted`, nhãn "HẾT VÉ" |
| Ghế bị lấy | `ErrorState` nhỏ | Nền `canvasElevated`, viền trái 2px `warning` |
| Thành công | — | Dấu tick `success` + `displayLg` |

---

## 8. Chuyển động
- 200–300ms, `Curves.easeOutCubic`.
- Không nảy, không confetti, không xoay.
- Chuyển trang: fade hoặc trượt ngắn. Hero có parallax rất nhẹ.
- Ghế, chip, nút: đổi màu ≤150ms, không scale.

---

## 9. Responsive và truy cập
- Chuẩn: điện thoại dọc ~360×800. `SafeArea`. Không đặt kích thước cứng cho text.
- Điện thoại: lưới 2 cột, tiêu đề hero 32.
- Tablet (>600px): lưới 3 cột, tiêu đề hero 40.
- Vùng chạm: nút 48×48, ghế 36×36.
- Tương phản: `body` (#969696) đạt chuẩn cho văn bản thường. `muted` chỉ cho caption và nhãn phụ.

---

## 10. Icon
Chọn một bộ duy nhất trước khi code: `lucide_icons` hoặc `phosphor_flutter`. Ghi vào `PROJECT_STRUCTURE.md` mục 2 khi đã chốt. Không dùng `Icons.*` của Material xen kẽ.

---

## 11. Checklist trước khi merge UI
- [ ] Không có `Color(0x`, `fontSize:`, số `EdgeInsets` lẻ trong file UI.
- [ ] Nút và card góc 0. Ghế góc 2. Ô nhập góc 4.
- [ ] Không có `BoxShadow`, `elevation` khác 0.
- [ ] Nhãn nút UPPERCASE, kiểm tra chữ có dấu.
- [ ] Có đủ loading, empty, error.
- [ ] Tối đa một nút primary và một dải `PromoBand` trên màn.
