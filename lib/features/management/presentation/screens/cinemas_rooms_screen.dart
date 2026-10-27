import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/models/app_user.dart';
import '../../../../shared/widgets/app_badge.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/skeleton_box.dart';
import '../../../auth/presentation/controllers/auth_provider.dart';
import '../../../booking/data/models/room_model.dart';
import '../controllers/management_provider.dart';

/// Screen S25: Cinemas & Rooms Configuration with navigation to S24 Seat Map Designer.
/// References: ROLE_FLOWS.md Section 5.3, BUSINESS_RULES.md Section 3.2
class CinemasRoomsScreen extends StatefulWidget {
  const CinemasRoomsScreen({super.key});

  @override
  State<CinemasRoomsScreen> createState() => _CinemasRoomsScreenState();
}

class _CinemasRoomsScreenState extends State<CinemasRoomsScreen> {
  String _selectedCinemaId = 'cn_q1';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().currentUser;
      if (user?.cinemaId != null && user!.cinemaId!.isNotEmpty) {
        _selectedCinemaId = user.cinemaId!;
      }
      _loadData();
    });
  }

  void _loadData() {
    final provider = context.read<ManagementProvider>();
    provider.loadCinemas();
    provider.loadRooms(_selectedCinemaId);
  }

  void _openAddEditRoomModal(BuildContext context, {RoomModel? room}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.canvasElevated,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.zeroRadius),
      builder: (_) => _RoomFormSheet(
        cinemaId: _selectedCinemaId,
        room: room,
        onSaved: () => context.read<ManagementProvider>().loadRooms(_selectedCinemaId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final isAdmin = user?.role == UserRole.admin;
    final provider = context.watch<ManagementProvider>();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        title: Text(
          'RẠP VÀ PHÒNG CHIẾU'.toUpperCase(),
          style: AppTextStyles.titleSm.copyWith(color: AppColors.ink),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => _openAddEditRoomModal(context),
            icon: const Icon(Icons.add, color: AppColors.primary, size: 20),
            label: Text(
              'THÊM PHÒNG'.toUpperCase(),
              style: AppTextStyles.button.copyWith(color: AppColors.primary),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Cinema Selector Bar (if Admin)
          if (isAdmin) ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              child: Row(
                children: provider.cinemas.map((cinema) {
                  final isSelected = _selectedCinemaId == cinema.id;
                  return Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xs),
                    child: ChoiceChip(
                      label: Text(
                        cinema.name.toUpperCase(),
                        style: AppTextStyles.caption.copyWith(
                          color: isSelected ? AppColors.ink : AppColors.muted,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.canvasElevated,
                      shape: const RoundedRectangleBorder(
                        borderRadius: AppRadius.zeroRadius,
                        side: BorderSide(color: AppColors.hairline),
                      ),
                      elevation: 0,
                      pressElevation: 0,
                      onSelected: (_) {
                        setState(() => _selectedCinemaId = cinema.id);
                        provider.loadRooms(cinema.id);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.xs),

          // Rooms List
          Expanded(
            child: _buildRoomsList(context, provider),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomsList(BuildContext context, ManagementProvider provider) {
    if (provider.isLoading) {
      return ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (_, __) => const SkeletonBox(
          width: double.infinity,
          height: 120,
        ),
      );
    }

    if (provider.errorMessage != null) {
      return Center(
        child: ErrorState(
          message: provider.errorMessage!,
          onRetry: () => _loadData(),
        ),
      );
    }

    if (provider.rooms.isEmpty) {
      return Center(
        child: EmptyState(
          title: 'CHƯA CÓ PHÒNG CHIẾU',
          message: 'Chưa có phòng chiếu nào cho rạp $_selectedCinemaId',
          actionLabel: 'THÊM PHÒNG CHIẾU',
          onAction: () => _openAddEditRoomModal(context),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => provider.loadRooms(_selectedCinemaId),
      color: AppColors.primary,
      backgroundColor: AppColors.canvasElevated,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: provider.rooms.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          final room = provider.rooms[index];
          return _buildRoomCard(context, room);
        },
      ),
    );
  }

  Widget _buildRoomCard(BuildContext context, RoomModel room) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.canvasElevated,
        borderRadius: AppRadius.zeroRadius,
        border: Border.all(color: AppColors.hairline, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  room.name,
                  style: AppTextStyles.titleSm.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              ...room.formats.map((fmt) => Padding(
                padding: const EdgeInsets.only(left: AppSpacing.xxs),
                child: AppBadge.format(fmt),
              )),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),

          Text(
            'Quy mô: ${room.rows} hàng × ${room.cols} cột · Tổng: ${room.seatCount} ghế',
            style: AppTextStyles.caption.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: AppSpacing.md),

          Row(
            children: [
              Expanded(
                child: AppButton.outline(
                  label: 'THIẾT KẾ SƠ ĐỒ GHẾ',
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.configSeatMap,
                      arguments: room,
                    );
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: AppColors.ink),
                onPressed: () => _openAddEditRoomModal(context, room: room),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoomFormSheet extends StatefulWidget {
  final String cinemaId;
  final RoomModel? room;
  final VoidCallback onSaved;

  const _RoomFormSheet({
    required this.cinemaId,
    this.room,
    required this.onSaved,
  });

  @override
  State<_RoomFormSheet> createState() => _RoomFormSheetState();
}

class _RoomFormSheetState extends State<_RoomFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _rowsController;
  late TextEditingController _colsController;
  final Set<String> _selectedFormats = {'2D'};

  @override
  void initState() {
    super.initState();
    final r = widget.room;
    _nameController = TextEditingController(text: r?.name ?? 'Phòng ');
    _rowsController = TextEditingController(text: r != null ? '${r.rows}' : '8');
    _colsController = TextEditingController(text: r != null ? '${r.cols}' : '10');
    if (r != null && r.formats.isNotEmpty) {
      _selectedFormats.clear();
      _selectedFormats.addAll(r.formats);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _rowsController.dispose();
    _colsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final isEditing = widget.room != null;
    final rows = int.tryParse(_rowsController.text.trim()) ?? 8;
    final cols = int.tryParse(_colsController.text.trim()) ?? 10;
    final id = widget.room?.id ?? 'room_${DateTime.now().millisecondsSinceEpoch}';

    List<String> layout = widget.room?.seatLayout ?? [];
    if (layout.isEmpty) {
      layout = List.generate(rows, (_) => List.generate(cols, (_) => 'S').join(','));
    }

    final room = RoomModel(
      id: id,
      cinemaId: widget.cinemaId,
      name: _nameController.text.trim(),
      formats: _selectedFormats.toList(),
      rows: rows,
      cols: cols,
      seatLayout: layout,
      seatCount: widget.room?.seatCount ?? (rows * cols),
    );

    final provider = context.read<ManagementProvider>();
    final success = await provider.saveRoom(room, isEditing: isEditing, cinemaId: widget.cinemaId);

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        widget.onSaved();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? 'Cập nhật phòng thành công' : 'Thêm phòng mới thành công'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Lưu phòng thất bại'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.room != null;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                (isEditing ? 'CHỈNH SỬA PHÒNG CHIẾU' : 'THÊM PHÒNG CHIẾU MỚI').toUpperCase(),
                style: AppTextStyles.titleSm.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              AppTextField(
                controller: _nameController,
                label: 'TÊN PHÒNG CHIẾU *',
                hintText: 'Phòng 1 (IMAX)',
                validator: (val) => val == null || val.trim().isEmpty ? 'Bắt buộc' : null,
              ),
              const SizedBox(height: AppSpacing.sm),

              // Format Multi-select chips
              Text('ĐỊNH DẠNG HỖ TRỢ *', style: AppTextStyles.captionUppercase.copyWith(color: AppColors.muted)),
              const SizedBox(height: AppSpacing.xxs),
              Row(
                children: ['2D', '3D', 'IMAX'].map((fmt) {
                  final isSelected = _selectedFormats.contains(fmt);
                  return Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xs),
                    child: FilterChip(
                      label: Text(fmt),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.canvas,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedFormats.add(fmt);
                          } else if (_selectedFormats.length > 1) {
                            _selectedFormats.remove(fmt);
                          }
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.sm),

              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _rowsController,
                      label: 'SỐ HÀNG *',
                      hintText: '8',
                      keyboardType: TextInputType.number,
                      validator: (val) {
                        final n = int.tryParse(val ?? '');
                        if (n == null || n < 3 || n > 20) return 'Từ 3 đến 20';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppTextField(
                      controller: _colsController,
                      label: 'SỐ CỘT *',
                      hintText: '10',
                      keyboardType: TextInputType.number,
                      validator: (val) {
                        final n = int.tryParse(val ?? '');
                        if (n == null || n < 4 || n > 20) return 'Từ 4 đến 20';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              AppButton.primary(
                label: 'LƯU PHÒNG CHIẾU',
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
