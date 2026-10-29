# MILESTONE 2: TECHNICAL IMPLEMENTATION PLAN
## Auth & Customer Discovery (S01–S04, S17, S17B, S30)

**Project:** Cinema Booking & Operation Management System  
**Milestone:** M2 (Auth & Customer Discovery)  
**Authoritative References:** `docs/ROLE_FLOWS.md`, `docs/DESIGN_TOKENS.md`, `docs/BUSINESS_RULES.md`, `docs/TECH_STACK.md`, `PROJECT.md`  
**Target Screens:**
1. **S01 Login** (`/login`) — `lib/features/auth/presentation/screens/login_screen.dart`
2. **S02 Register** (`/register`) — `lib/features/auth/presentation/screens/register_screen.dart`
3. **S03 Home / Discovery** (`/home`) — `lib/features/movies/presentation/screens/home_screen.dart`
4. **S04 Movie Detail** (`/movie-detail`) — `lib/features/movies/presentation/screens/movie_detail_screen.dart`
5. **S17 Cinema Locator** (`/cinemas`) — `lib/features/cinemas/presentation/screens/cinema_map_screen.dart`
6. **S17B Cinema Detail** (`/cinema-detail`) — `lib/features/cinemas/presentation/screens/cinema_detail_screen.dart`
7. **S30 Notifications** (`/notifications`) — `lib/features/notifications/presentation/screens/notification_center_screen.dart`
8. **Navigation & Router Wiring** — `lib/core/routes/app_router.dart`, `lib/core/routes/route_guards.dart`, `lib/main.dart`

---

## 1. Architectural & Design Token Compliance Standards

All M2 implementations must strictly satisfy the following invariants:
1. **100% Token Discipline:**
   - Colors: Exclusively from `AppColors` (`canvas` `#181818`, `canvasElevated` `#303030`, `primary` `#DA291C`, `ink` `#FFFFFF`, `body` `#969696`, `muted` `#666666`, `hairline` `#303030`, `warning` `#F13A2C`, `success` `#03904A`, `info` `#4C98B9`, `focusRing` `#F6E500`, `shimmerHighlight` `#3C3C3C`).
   - Zero hardcoded colors: `Color(0x...)` is strictly forbidden.
   - Zero shadows / elevation: `elevation: 0`, `BoxShadow` is strictly forbidden.
   - Typography: Exclusively `AppTextStyles` (`displayMega`, `displayXl`, `displayLg`, `displayMd`, `titleMd`, `titleSm`, `bodyMd`, `bodySm`, `caption`, `captionUppercase`, `button`, `numberDisplay`).
   - Spacing: Standard 8px grid scale (`AppSpacing.xxxs` = 4, `xxs` = 8, `xs` = 16, `sm` = 24, `md` = 32, `lg` = 48, `xl` = 64).
   - Corner Radius: `AppRadius.none` (0px) default for cards/buttons/posters; `AppRadius.smRadius` (4px) for inputs; `AppRadius.xlRadius` (12px) for bottom sheets; `AppRadius.fullRadius` for pills/badges.
2. **Button & Label Invariants:**
   - Button labels and navigation items must be UPPERCASE (`label.toUpperCase()`).
   - Maximum **1 primary button** (`AppButton.primary`) visible per screen at any time.
3. **Mandatory 3 UI States:**
   - **Loading:** Always handled by `SkeletonBox` (custom shimmer structure matching layout). No generic spinner screens.
   - **Empty:** Handled by `EmptyState` (muted icon, title, friendly subtitle, optional outline button).
   - **Error:** Handled by `ErrorState` (warning icon, message, outline retry button `THỬ LẠI`).
4. **State Management:**
   - Exclusively `provider` (`ChangeNotifierProvider`, `ProxyProvider`).
   - Controllers: `AuthProvider`, `MovieProvider`, `CinemaProvider`, `NotificationProvider`.

---

## 2. Screen Specifications & Implementation Architecture

### 2.1 S01 Login Screen (`/login`)
- **File:** `lib/features/auth/presentation/screens/login_screen.dart`
- **Roles Authorized:** Guest, Customer, Staff, Manager, Admin
- **Dependencies & Providers:**
  - `AuthProvider` (`lib/features/auth/presentation/controllers/auth_provider.dart`)
- **Key Responsibilities:**
  1. Authenticate user via Supabase Auth email/password.
  2. Detect locked accounts (`is_locked == true`): Display warning banner, call `signOut()`, remain on S01.
  3. Perform role-based redirect upon successful authentication:
     - `UserRole.customer` ➔ Return to pending route if specified in route arguments, else `AppRoutes.home` (S03)
     - `UserRole.staff` ➔ `AppRoutes.staffCheckin` (S18)
     - `UserRole.manager` ➔ `AppRoutes.dashboard` (S22)
     - `UserRole.admin` ➔ `AppRoutes.managementHome` (S12)
  4. Guest bypass: Allow continuing as guest without credentials directly to S03.
  5. Navigation link to S02 Register.

- **Component Hierarchy & Layout:**
  ```
  Scaffold (backgroundColor: AppColors.canvas)
  └── SafeArea
      └── Center
          └── SingleChildScrollView (padding: AppSpacing.md)
              └── Form (key: _formKey)
                  ├── AppBrandingHeader
                  │   ├── Icon(Icons.movie_outlined, color: AppColors.primary, size: 48)
                  │   ├── SizedBox(height: AppSpacing.xs)
                  │   ├── Text('CINEMA STAR', style: AppTextStyles.captionUppercase.copyWith(color: AppColors.muted))
                  │   ├── SizedBox(height: AppSpacing.xxs)
                  │   └── Text('ĐĂNG NHẬP', style: AppTextStyles.displayXl)
                  ├── SizedBox(height: AppSpacing.md)
                  ├── if (errorMessage != null) ErrorBanner
                  │   └── Container (color: AppColors.canvasElevated, border: Border.all(color: AppColors.warning))
                  ├── AppTextField
                  │   ├── label: 'EMAIL'
                  │   ├── controller: _emailController
                  │   ├── keyboardType: TextInputType.emailAddress
                  │   ├── prefixIcon: Icon(Icons.email_outlined, color: AppColors.muted)
                  │   └── validator: email regex check
                  ├── SizedBox(height: AppSpacing.xs)
                  ├── AppTextField
                  │   ├── label: 'MẬT KHẨU'
                  │   ├── controller: _passwordController
                  │   ├── obscureText: _obscurePassword
                  │   ├── prefixIcon: Icon(Icons.lock_outline, color: AppColors.muted)
                  │   ├── suffixIcon: IconButton(visibility toggle)
                  │   └── validator: min length >= 6
                  ├── SizedBox(height: AppSpacing.md)
                  ├── AppButton.primary (label: 'ĐĂNG NHẬP', width: double.infinity, isLoading: auth.isLoading)
                  ├── SizedBox(height: AppSpacing.xs)
                  ├── AppButton.outline (label: 'CHƯA CÓ TÀI KHOẢN? ĐĂNG KÝ', width: double.infinity, onPressed: -> S02)
                  └── SizedBox(height: AppSpacing.xxs)
                      └── AppButton.text (label: 'TIẾP TỤC VỚI TƯ CÁCH KHÁCH', onPressed: -> S03)
  ```

---

### 2.2 S02 Register Screen (`/register`)
- **File:** `lib/features/auth/presentation/screens/register_screen.dart`
- **Roles Authorized:** Guest, Customer
- **Dependencies & Providers:**
  - `AuthProvider` (`signUp`)
- **Key Responsibilities:**
  1. Capture: Full Name, Email, Phone Number (10 digits starting with 0), Password (>= 6 chars), Confirm Password.
  2. Client-side validation:
     - Full Name: Not empty, >= 2 characters.
     - Email: Regex format `r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$'`.
     - Phone: Regex `r'^0[0-9]{9}$'`.
     - Password: >= 6 characters.
     - Confirm Password: Must match password exactly.
  3. On submit, invoke `AuthProvider.signUp(...)`.
  4. Auto-created profile is `role = customer`, `is_locked = false`.
  5. Upon success, redirect to `AppRoutes.home` (or pending route) with success message.
  6. On failure (e.g. duplicate email), show descriptive error banner.

- **Component Hierarchy & Layout:**
  ```
  Scaffold (backgroundColor: AppColors.canvas)
  ├── AppBar (leading: BackButton, title: 'ĐĂNG KÝ', backgroundColor: AppColors.canvas, elevation: 0)
  └── SafeArea
      └── SingleChildScrollView (padding: AppSpacing.md)
          └── Form (key: _formKey)
              ├── Text('TẠO TÀI KHOẢN', style: AppTextStyles.displayXl)
              ├── SizedBox(height: AppSpacing.xxs)
              ├── Text('Đăng ký để nhận ưu đãi và quản lý vé tiện lợi', style: AppTextStyles.bodyMd.copyWith(color: AppColors.muted))
              ├── SizedBox(height: AppSpacing.md)
              ├── if (errorMessage != null) ErrorBanner
              ├── AppTextField (label: 'HỌ VÀ TÊN', controller: _nameController, validator: ...)
              ├── SizedBox(height: AppSpacing.xs)
              ├── AppTextField (label: 'EMAIL', controller: _emailController, keyboardType: email, validator: ...)
              ├── SizedBox(height: AppSpacing.xs)
              ├── AppTextField (label: 'SỐ ĐIỆN THOẠI', controller: _phoneController, keyboardType: phone, hintText: '0901234567', validator: ...)
              ├── SizedBox(height: AppSpacing.xs)
              ├── AppTextField (label: 'MẬT KHẨU', controller: _passwordController, obscureText: true, validator: ...)
              ├── SizedBox(height: AppSpacing.xs)
              ├── AppTextField (label: 'NHẬP LẠI MẬT KHẨU', controller: _confirmController, obscureText: true, validator: ...)
              ├── SizedBox(height: AppSpacing.md)
              ├── AppButton.primary (label: 'TẠO TÀI KHOẢN', width: double.infinity, isLoading: auth.isLoading)
              └── SizedBox(height: AppSpacing.xs)
                  └── AppButton.text (label: 'ĐÃ CÓ TÀI KHOẢN? ĐĂNG NHẬP', onPressed: Navigator.pop)
  ```

---

### 2.3 S03 Home / Discovery Screen (`/home`)
- **File:** `lib/features/movies/presentation/screens/home_screen.dart`
- **Roles Authorized:** Guest, Customer
- **Dependencies & Providers:**
  - `MovieProvider` (`nowShowing`, `upcoming`, `searchResults`, `searchQuery`, `loadMovies()`, `search()`)
  - `NotificationProvider` (`unreadCount`, `loadNotifications()`)
  - `AuthProvider` (`isAuthenticated`)
- **Key Responsibilities:**
  1. Hero Backdrop Carousel:
     - Up to 5 now-showing movies in a `PageView` (height ~380px).
     - Full-width backdrop poster with cinematic bottom gradient fade to `canvas`.
     - Overlay displays Age Badge, Title (`displayMega`), Genres/Duration, Page Indicator dots, and `ĐẶT VÉ` CTA.
  2. Client-side Search:
     - Real-time search by movie title via `AppTextField`.
     - Search active: Displays search results grid. If empty, displays `EmptyState` ("Không tìm thấy phim phù hợp").
  3. Now Showing Section ("ĐANG CHIẾU"):
     - 2-column Grid of `MovieCard` components.
     - Tapping card opens S04 (`/movie-detail`).
  4. Upcoming Section ("SẮP CHIẾU"):
     - Horizontal scrolling row of `MovieCard` components (width ~140px).
  5. Top App Bar:
     - Logo / Branding ("CINEMA STAR").
     - `NotificationBadge` with live unread count. Tap opens S30 (if authenticated) or S01 (if guest).
  6. Bottom Navigation Bar:
     - Custom 4-tab bar: `PHIM` (active), `RẠP` (S17), `VÉ CỦA TÔI` (S10), `TÀI KHOẢN` (S11).
     - Guest guard: Tapping `VÉ CỦA TÔI` or `TÀI KHOẢN` checks `auth.isAuthenticated`. If false, navigates to S01.
  7. Full 3-State Support:
     - Loading: Skeleton hero carousel + 4-card grid shimmer.
     - Empty: `EmptyState` when database has no active movies.
     - Error: `ErrorState` with retry button.

- **Component Hierarchy & Layout:**
  ```
  Scaffold (backgroundColor: AppColors.canvas, bottomNavigationBar: CustomerBottomNav(currentIndex: 0))
  ├── AppBar
  │   ├── title: Text('CINEMA STAR', style: AppTextStyles.titleMd.copyWith(color: AppColors.primary, letterSpacing: 2))
  │   └── actions: [NotificationBadge(unreadCount: notif.unreadCount, onTap: _onNotifTap)]
  └── SafeArea
      └── RefreshIndicator (onRefresh: movieProvider.loadMovies)
          └── SingleChildScrollView
              ├── Padding (horizontal: AppSpacing.xs, top: AppSpacing.xs)
              │   └── AppTextField (Search bar with search icon & clear button)
              ├── if (isLoading) MovieHomeSkeleton
              ├── else if (errorMessage != null) ErrorState(message: ..., onRetry: ...)
              ├── else if (searchQuery.isNotEmpty)
              │   ├── if (searchResults.isEmpty) EmptyState(icon: search_off, title: 'Không tìm thấy phim phù hợp')
              │   └── else SearchResultsGrid (2 columns of MovieCard)
              └── else
                  ├── HeroBackdropCarousel (height: 380, max 5 movies)
                  │   ├── PageView.builder
                  │   └── PageIndicators (active Rosso Corsa, inactive hairline)
                  ├── SizedBox(height: AppSpacing.md)
                  ├── SectionHeader('ĐANG CHIẾU')
                  ├── Padding (horizontal: AppSpacing.xs)
                  │   └── GridView.builder (shrinkWrap: true, physics: NeverScrollableScrollPhysics, crossAxisCount: 2, MovieCard)
                  ├── SizedBox(height: AppSpacing.md)
                  ├── SectionHeader('SẮP CHIẾU')
                  └── SizedBox(height: 240)
                      └── ListView.separated (scrollDirection: Axis.horizontal, upcoming MovieCard)
  ```

---

### 2.4 S04 Movie Detail Screen (`/movie-detail`)
- **File:** `lib/features/movies/presentation/screens/movie_detail_screen.dart`
- **Roles Authorized:** Guest, Customer
- **Arguments:** `MovieModel` or `String movieId` (with fallback fetch via `MovieRepository`)
- **Key Responsibilities:**
  1. Full-bleed backdrop image fading smoothly into `canvas` background.
  2. Overlay custom circular back button.
  3. Prominent Title (`displayMega`) and Age Badge pill.
  4. SpecCell row:
     - Duration in minutes (`${movie.durationMin} PHÚT`)
     - Age rating (`${movie.ageRating} ĐỘ TUỔI`)
     - First genre / format (`${movie.genres.first} THỂ LOẠI`)
  5. Trailer action:
     - `AppButton.outline(label: 'XEM TRAILER', icon: Icon(Icons.play_arrow_outlined))`
     - Uses `url_launcher`: `launchUrl(Uri.parse(movie.trailerUrl), mode: LaunchMode.externalApplication)`.
     - Validates URL format; shows SnackBar if invalid.
  6. Synopsis & Crew:
     - "TÓM TẮT NỘI DUNG" in `AppTextStyles.captionUppercase`.
     - Director & Cast members list.
  7. Sticky Bottom Bar:
     - Fixed bottom container in `canvasElevated` with hairline border.
     - If `movie.isNowShowing`: `AppButton.primary(label: 'ĐẶT VÉ', onPressed: -> S05 /showtimes)`.
     - If `movie.isUpcoming`: Disabled button `AppButton.primary(label: 'CHƯA MỞ BÁN', onPressed: null)`.

- **Component Hierarchy & Layout:**
  ```
  Scaffold (backgroundColor: AppColors.canvas)
  ├── Stack
  │   ├── SingleChildScrollView (padding bottom for sticky bar: 90)
  │   │   ├── AspectRatio(16/10) Full-bleed Backdrop with Gradient
  │   │   ├── Padding (horizontal: AppSpacing.xs)
  │   │   │   ├── Row([AppBadge.age(movie.ageRating), SizedBox(width: AppSpacing.xxs), Text(movie.genresText)])
  │   │   │   ├── SizedBox(height: AppSpacing.xxs)
  │   │   │   ├── Text(movie.title, style: AppTextStyles.displayMega)
  │   │   │   ├── SizedBox(height: AppSpacing.sm)
  │   │   │   ├── Container(canvasElevated, hairline border, padding: 16)
  │   │   │   │   └── Row(3 x SpecCell with vertical hairline dividers)
  │   │   │   ├── SizedBox(height: AppSpacing.sm)
  │   │   │   ├── AppButton.outline(label: 'XEM TRAILER', width: double.infinity, onPressed: _launchTrailer)
  │   │   │   ├── SizedBox(height: AppSpacing.md)
  │   │   │   ├── Text('TÓM TẮT NỘI DUNG', style: AppTextStyles.captionUppercase)
  │   │   │   ├── SizedBox(height: AppSpacing.xxs)
  │   │   │   ├── Text(movie.description, style: AppTextStyles.bodyMd)
  │   │   │   ├── SizedBox(height: AppSpacing.sm)
  │   │   │   ├── Text('ĐẠO DIỄN: ${movie.director}')
  │   │   │   └── Text('DIỄN VIÊN: ${movie.castMembers.join(", ")}')
  │   │   └── SizedBox(height: AppSpacing.xl)
  │   ├── Positioned(top: SafeArea.top, left: AppSpacing.xs) BackButtonCircle
  │   └── Positioned(bottom: 0, left: 0, right: 0) StickyBottomBar
  │       └── Container(color: AppColors.canvasElevated, border: Border(top: hairline), padding: 16)
  │           └── isNowShowing ? AppButton.primary('ĐẶT VÉ') : AppButton.primary('CHƯA MỞ BÁN', onPressed: null)
  ```

---

### 2.5 S17 Cinema Locator (`/cinemas`)
- **File:** `lib/features/cinemas/presentation/screens/cinema_map_screen.dart`
- **Roles Authorized:** Guest, Customer
- **Dependencies & Providers:**
  - `CinemaProvider` (`cinemas`, `selectedCinema`, `isLoading`, `errorMessage`, `loadCinemas()`, `selectCinema()`)
- **Key Responsibilities:**
  1. Google Maps integration:
     - Centered on current user GPS or default Ho Chi Minh City coordinates (`LatLng(10.7769, 106.7009)`).
     - Renders map markers for all active cinemas in `CinemaProvider`.
     - Tapping a marker centers camera and selects cinema.
     - "My Location" button in AppBar animates camera to user's GPS coordinates.
     - Graceful GPS permission handling: If denied, continues rendering map with fallback center and "—" for distances.
  2. Distance-sorted list in `DraggableScrollableSheet`:
     - Initial size: 0.35, min size: 0.15, max size: 0.85.
     - Rounded top corners (`AppRadius.xlRadius` = 12px), background `AppColors.canvasElevated`.
     - Drag handle pill.
     - Header: "DANH SÁCH RẠP ([count])" and outline CTA `TÌM RẠP GẦN NHẤT`.
     - List of cinemas showing Name, Distance (km), Address, and tap handler to S17B (`/cinema-detail`).
  3. Bottom Navigation Bar: Tab index 1 (`RẠP`) active.

- **Component Hierarchy & Layout:**
  ```
  Scaffold (backgroundColor: AppColors.canvas, bottomNavigationBar: CustomerBottomNav(currentIndex: 1))
  ├── AppBar
  │   ├── title: Text('CỤM RẠP', style: AppTextStyles.titleSm)
  │   └── actions: [
  │       IconButton(Icons.my_location, onPressed: _centerUserLocation),
  │       NotificationBadge(...)
  │     ]
  └── Stack
      ├── GoogleMap (initialCameraPosition, markers, onMapCreated)
      └── DraggableScrollableSheet (initial: 0.35, min: 0.15, max: 0.85)
          └── Container (canvasElevated, top corners 12px)
              ├── DragHandleBar
              ├── HeaderRow ('DANH SÁCH RẠP', AppButton.outline('TÌM RẠP GẦN NHẤT'))
              ├── if (isLoading) 3 x SkeletonBox list item
              ├── else if (errorMessage != null) ErrorState(onRetry: loadCinemas)
              ├── else if (cinemas.isEmpty) EmptyState('Không tìm thấy rạp chiếu')
              └── else ListView.separated (CinemaListItem -> tap -> S17B)
  ```

---

### 2.6 S17B Cinema Detail Screen (`/cinema-detail`)
- **File:** `lib/features/cinemas/presentation/screens/cinema_detail_screen.dart`
- **Roles Authorized:** Guest, Customer
- **Arguments:** `CinemaModel` or `String cinemaId`
- **Key Responsibilities:**
  1. Display Cinema Name, Address, Hotline phone, Opening hours.
  2. Distance pill (`${cinema.distanceKm} KM TỪ BẠN`) if distance is calculated.
  3. Directions CTA:
     - `AppButton.outline(label: 'CHỈ ĐƯỜNG', icon: Icon(Icons.directions_outlined))`
     - Launches Google Maps route URL via `url_launcher`: `https://www.google.com/maps/dir/?api=1&destination=${cinema.lat},${cinema.lng}`.
  4. Primary CTA:
     - `AppButton.primary(label: 'XEM SUẤT CHIẾU HÔM NAY', onPressed: ...)`
     - Navigates to S05 (`/showtimes`) passing `{'cinemaId': cinema.id, 'cinemaName': cinema.name}`.

- **Component Hierarchy & Layout:**
  ```
  Scaffold (backgroundColor: AppColors.canvas)
  ├── AppBar (leading: BackButton, title: cinema.name, backgroundColor: AppColors.canvas)
  └── SingleChildScrollView (padding: AppSpacing.xs)
      ├── CinemaBannerPlaceholder (height: 200, canvasElevated, icon Icons.movie_filter_outlined)
      ├── SizedBox(height: AppSpacing.sm)
      ├── Text(cinema.name, style: AppTextStyles.displayLg)
      ├── if (cinema.distanceKm != null) AppBadge('${cinema.distanceKm} KM TỪ VỊ TRÍ CỦA BẠN')
      ├── SizedBox(height: AppSpacing.sm)
      ├── DetailTile(icon: Icons.location_on_outlined, label: 'ĐỊA CHỈ', value: cinema.address)
      ├── DetailTile(icon: Icons.phone_outlined, label: 'HOTLINE', value: cinema.phone ?? '1900 6017')
      ├── DetailTile(icon: Icons.access_time_outlined, label: 'GIỜ MỞ CỬA', value: cinema.openingHours ?? '08:00 - 24:00 (Hàng ngày)')
      ├── SizedBox(height: AppSpacing.md)
      ├── AppButton.outline(label: 'CHỈ ĐƯỜNG', width: double.infinity, icon: Icon(Icons.directions_outlined), onPressed: _openMapDirections)
      ├── SizedBox(height: AppSpacing.xs)
      └── AppButton.primary(label: 'XEM SUẤT CHIẾU HÔM NAY', width: double.infinity, onPressed: _viewShowtimes)
  ```

---

### 2.7 S30 Notification Center Screen (`/notifications`)
- **File:** `lib/features/notifications/presentation/screens/notification_center_screen.dart`
- **Roles Authorized:** Customer, Manager, Admin
- **Dependencies & Providers:**
  - `NotificationProvider` (`notifications`, `isLoading`, `errorMessage`, `loadNotifications()`, `markAllAsRead()`)
- **Key Responsibilities:**
  1. Fetch and list notifications ordered newest to oldest.
  2. Distinct visual badge / indicator for unread vs read notifications:
     - Unread: Primary red dot indicator (`AppColors.primary`), bolder title.
     - Read: Muted styling.
  3. Type-based icon mapping:
     - `bookingPaid`: `Icons.check_circle_outline`, color `AppColors.success`
     - `showReminder`: `Icons.alarm_outlined`, color `AppColors.info`
     - `showtimeCancelled`: `Icons.cancel_outlined`, color `AppColors.warning`
     - `bookingRefunded`: `Icons.currency_exchange_outlined`, color `AppColors.warning`
     - `foodDelivered`: `Icons.fastfood_outlined`, color `AppColors.success`
  4. Header action: `ĐÁNH DẤU TẤT CẢ ĐÃ ĐỌC` calling `notificationProvider.markAllAsRead()`.
  5. Tap to navigate: If `bookingCode != null`, navigates to S10 (`/my-tickets`) or ticket details.
  6. 3 States:
     - Loading: `SkeletonBox` tile list.
     - Empty: `EmptyState` ("Bạn không có thông báo nào").
     - Error: `ErrorState` with retry.

- **Component Hierarchy & Layout:**
  ```
  Scaffold (backgroundColor: AppColors.canvas)
  ├── AppBar
  │   ├── leading: BackButton
  │   ├── title: Text('THÔNG BÁO', style: AppTextStyles.titleSm)
  │   └── actions: [
  │       AppButton.text(label: 'ĐÃ ĐỌC TẤT CẢ', onPressed: notifProvider.markAllAsRead)
  │     ]
  └── SafeArea
      ├── if (isLoading) 5 x SkeletonNotificationTile
      ├── else if (errorMessage != null) ErrorState(onRetry: loadNotifications)
      ├── else if (notifications.isEmpty) EmptyState(icon: Icons.notifications_off_outlined, title: 'Bạn không có thông báo nào')
      └── else ListView.separated
          ├── separator: Divider(color: AppColors.hairline, height: 1)
          └── NotificationTile (icon, title, body, timestamp, unreadDot, onTap)
  ```

---

## 3. Shared Reusable Bottom Navigation Component

To guarantee strict DRY architecture and identical navigation behavior across Customer tabs (S03 Home, S17 Cinemas, S10 Tickets, S11 Profile), a dedicated reusable component will be created:

- **File:** `lib/shared/widgets/customer_bottom_nav.dart`
- **Properties:**
  - `final int currentIndex` (0: Phim, 1: Rạp, 2: Vé của tôi, 3: Tài khoản)
- **Design Token Spec:**
  - Background: `AppColors.canvas`
  - Border: Top 1px `AppColors.hairline`
  - Elevation: 0
  - Height: 64px
  - Selected tab: Label in `AppColors.ink`, Icon in `AppColors.primary`
  - Unselected tab: Label in `AppColors.muted`, Icon in `AppColors.muted`
  - Labels: Strictly UPPERCASE (`PHIM`, `RẠP`, `VÉ CỦA TÔI`, `TÀI KHOẢN`)
- **Navigation Handler:**
  - Index 0 ➔ `AppRoutes.home` (S03)
  - Index 1 ➔ `AppRoutes.cinemas` (S17)
  - Index 2 ➔ If authenticated: `AppRoutes.myTickets` (S10); if Guest: redirect to `AppRoutes.login` with redirect route.
  - Index 3 ➔ If authenticated: `AppRoutes.profile` (S11); if Guest: redirect to `AppRoutes.login` with redirect route.

---

## 4. Router & Route Guards Configuration

### 4.1 Update `lib/core/routes/route_guards.dart`
Align `RouteGuards.getInitialRoute` with role redirect invariants:
```dart
abstract final class RouteGuards {
  static String getInitialRoute(AppUser? user) {
    if (user == null) {
      return AppRoutes.home; // S03 Guest
    }
    if (user.isLocked) {
      return AppRoutes.login;
    }
    switch (user.role) {
      case UserRole.customer:
        return AppRoutes.home; // S03
      case UserRole.staff:
        return AppRoutes.staffCheckin; // S18
      case UserRole.manager:
        return AppRoutes.dashboard; // S22
      case UserRole.admin:
        return AppRoutes.managementHome; // S12 (Admin Management Menu)
    }
  }
}
```

### 4.2 Route Registration in `lib/core/routes/app_router.dart`
Extend `app_router.dart` with `onGenerateRoute` to cleanly handle typed parameters:
- `AppRoutes.login`: returns `LoginScreen`
- `AppRoutes.register`: returns `RegisterScreen`
- `AppRoutes.home`: returns `HomeScreen`
- `AppRoutes.movieDetail`: extracts `settings.arguments` (`MovieModel` or `String movieId`), returns `MovieDetailScreen`
- `AppRoutes.cinemas`: returns `CinemaMapScreen`
- `AppRoutes.cinemaDetail`: extracts `settings.arguments` (`CinemaModel` or `String cinemaId`), returns `CinemaDetailScreen`
- `AppRoutes.notifications`: returns `NotificationCenterScreen`
- Stub handlers for future milestones (S05–S31) rendering clean placeholder scaffolds until implemented.

### 4.3 App Initialization in `lib/main.dart`
Update `main.dart` MaterialApp:
```dart
MaterialApp(
  title: 'Cinema Booking',
  debugShowCheckedModeBanner: false,
  theme: AppTheme.dark,
  initialRoute: initialRoute,
  onGenerateRoute: AppRouter.onGenerateRoute,
)
```

---

## 5. Screen File Inventory & Deliverable Checklist

| Component / Screen | Target File Path | Milestone 2 Scope |
|---|---|---|
| **S01 Login** | `lib/features/auth/presentation/screens/login_screen.dart` | Form, locked account banner, role-based redirects |
| **S02 Register** | `lib/features/auth/presentation/screens/register_screen.dart` | Form, 10-digit phone regex, password match, auto-customer |
| **S03 Home** | `lib/features/movies/presentation/screens/home_screen.dart` | Hero carousel, search bar, now-showing grid, upcoming row |
| **S04 Movie Detail** | `lib/features/movies/presentation/screens/movie_detail_screen.dart` | Backdrop fade, 3 SpecCells, synopsis, trailer launcher, sticky CTA |
| **S17 Cinema Map** | `lib/features/cinemas/presentation/screens/cinema_map_screen.dart` | Google Maps, GPS calculation, DraggableScrollableSheet list |
| **S17B Cinema Detail** | `lib/features/cinemas/presentation/screens/cinema_detail_screen.dart` | Detail info, hotline, directions launcher, showtimes CTA |
| **S30 Notifications** | `lib/features/notifications/presentation/screens/notification_center_screen.dart` | Unread badge, type icons, mark all as read, tap to route |
| **Shared Bottom Nav** | `lib/shared/widgets/customer_bottom_nav.dart` | 4 uppercase tabs, guest check, active/inactive tokens |
| **Route Guards** | `lib/core/routes/route_guards.dart` | Admin -> S12, Manager -> S22, Staff -> S18, Customer -> S03 |
| **App Router** | `lib/core/routes/app_router.dart` | `onGenerateRoute` supporting typed models & IDs |
| **Main App** | `lib/main.dart` | Wire `onGenerateRoute: AppRouter.onGenerateRoute` |

---

## 6. Verification Criteria & Automated Testing Plan

### 6.1 Unit & Widget Test Suites for M2
1. **`test/features/auth/login_screen_test.dart`**:
   - Verify validation errors on empty email/password.
   - Verify locked account banner when `is_locked = true`.
   - Verify role redirection to appropriate routes (Customer -> S03, Staff -> S18, Manager -> S22, Admin -> S12).
2. **`test/features/auth/register_screen_test.dart`**:
   - Verify phone number validation rejects non-10-digit strings.
   - Verify password confirmation mismatch displays error.
   - Verify successful registration calls `signUp` and routes to home.
3. **`test/features/movies/home_screen_test.dart`**:
   - Verify 3 UI states: renders `SkeletonBox` when loading, `EmptyState` when empty, `ErrorState` when error.
   - Verify search filters now-showing movies in real time.
   - Verify tapping `MovieCard` navigates to `/movie-detail`.
4. **`test/features/movies/movie_detail_screen_test.dart`**:
   - Verify `SpecCell` row displays duration, age rating, format.
   - Verify upcoming movie disables CTA button with label `CHƯA MỞ BÁN`.
   - Verify now-showing movie enables CTA button with label `ĐẶT VÉ`.
5. **`test/features/cinemas/cinema_map_screen_test.dart`**:
   - Verify Google Maps and DraggableScrollableSheet render correctly.
   - Verify distance sorting and graceful fallback when location permission denied.
6. **`test/features/notifications/notification_center_screen_test.dart`**:
   - Verify unread badges and "ĐÃ ĐỌC TẤT CẢ" CTA marks all read.

### 6.2 Static Analysis & Quality Gate
```bash
# Must produce 0 errors and 0 warnings
flutter analyze

# All existing and new widget/unit tests must pass
flutter test
```

---
*Vinh Pro*
