import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../booking/data/models/room_model.dart';
import '../controllers/management_provider.dart';

/// Screen S24: Interactive Room Seat Map Designer with dynamic S/V/C/_ cycling & safety lock.
/// References: ROLE_FLOWS.md Section 5.3 & 5.4, BUSINESS_RULES.md Section 3.2
class SeatMapDesignerScreen extends StatefulWidget {
  final RoomModel? room;
  final String? roomId;
  final String? cinemaId;
  final String? roomName;

  const SeatMapDesignerScreen({
    super.key,
    this.room,
    this.roomId,
    this.cinemaId,
    this.roomName,
  });

  @override
  State<SeatMapDesignerScreen> createState() => _SeatMapDesignerScreenState();
}

class _SeatMapDesignerScreenState extends State<SeatMapDesignerScreen> {
  late String _roomId;
  late String _cinemaId;
  late String _roomName;
  late int _rows;
  late int _cols;
  late List<List<String>> _grid; // 2D matrix of cell types
  String _selectedBrush = 'CYCLE'; // 'CYCLE', 'S', 'V', 'C', '_'

  @override
  void initState() {
    super.initState();
    final r = widget.room;
    _roomId = r?.id ?? widget.roomId ?? '';
    _cinemaId = r?.cinemaId ?? widget.cinemaId ?? 'cn_q1';
    _roomName = r?.name ?? widget.roomName ?? 'Phòng chiếu';
    _rows = r?.rows ?? 8;
    _cols = r?.cols ?? 10;

    _initGrid(r?.seatLayout);
  }

  void _initGrid(List<String>? layout) {
    _grid = [];
    if (layout != null && layout.isNotEmpty) {
      for (int i = 0; i < _rows; i++) {
        if (i < layout.length) {
          final cells = layout[i].split(',').map((c) => c.trim()).toList();
          while (cells.length < _cols) {
            cells.add('S');
          }
          _grid.add(cells.sublist(0, _cols));
        } else {
          _grid.add(List.generate(_cols, (_) => 'S'));
        }
      }
    } else {
      for (int i = 0; i < _rows; i++) {
        _grid.add(List.generate(_cols, (_) => 'S'));
      }
    }
  }

  void _cycleCell(int r, int c) {
    setState(() {
      if (_selectedBrush == 'CYCLE') {
        final current = _grid[r][c];
        switch (current) {
          case 'S':
            _grid[r][c] = 'V';
            break;
          case 'V':
            _grid[r][c] = 'C';
            break;
          case 'C':
            _grid[r][c] = '_';
            break;
          case '_':
          default:
            _grid[r][c] = 'S';
            break;
        }
      } else {
        _grid[r][c] = _selectedBrush;
      }
    });
  }

  int get _standardCount {
    int count = 0;
    for (final row in _grid) {
      for (final cell in row) {
        if (cell == 'S') count++;
      }
    }
    return count;
  }

  int get _vipCount {
    int count = 0;
    for (final row in _grid) {
      for (final cell in row) {
        if (cell == 'V') count++;
      }
    }
    return count;
  }

  int get _coupleCount {
    int count = 0;
    for (final row in _grid) {
      for (final cell in row) {
        if (cell == 'C') count++;
      }
    }
    return count;
  }

  int get _totalSeatCount => _standardCount + _vipCount + _coupleCount;

  List<String> get _serializedLayout {
    return _grid.map((row) => row.join(',')).toList();
  }

  void _updateDimensions(int newRows, int newCols) {
    if (newRows < 3 || newRows > 20 || newCols < 4 || newCols > 20) return;

    setState(() {
      // Adjust rows
      if (newRows > _rows) {
        for (int i = _rows; i < newRows; i++) {
          _grid.add(List.generate(_cols, (_) => 'S'));
        }
      } else if (newRows < _rows) {
        _grid = _grid.sublist(0, newRows);
      }
      _rows = newRows;

      // Adjust cols
      for (int i = 0; i < _rows; i++) {
        if (newCols > _cols) {
          _grid[i].addAll(List.generate(newCols - _cols, (_) => 'S'));
        } else if (newCols < _cols) {
          _grid[i] = _grid[i].sublist(0, newCols);
        }
      }
      _cols = newCols;
    });
  }

  Future<void> _saveLayout() async {
    final provider = context.read<ManagementProvider>();

    // Safety lock check: does room have active future showtimes with sold tickets?
    final hasSold = await provider.checkRoomHasFutureSoldShowtimes(_roomId);
    if (hasSold) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (dialogCtx) => AlertDialog(
            backgroundColor: AppColors.canvasElevated,
            shape: const RoundedRectangleBorder(borderRadius: AppRadius.zeroRadius),
            title: Text(
              'KHÔNG THỂ THAY ĐỔI SƠ ĐỒ GHẾ'.toUpperCase(),
              style: AppTextStyles.titleSm.copyWith(color: AppColors.warning),
            ),
            content: Text(
              'Phòng "$_roomName" đang có suất chiếu trong tương lai đã phát sinh vé bán. Bạn không thể sửa đổi sơ đồ ghế để tránh tranh chấp chỗ ngồi của khách hàng.',
              style: AppTextStyles.bodyMd.copyWith(color: AppColors.ink),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: Text(
                  'ĐÃ HIỂU'.toUpperCase(),
                  style: AppTextStyles.button.copyWith(color: AppColors.primary),
                ),
              ),
            ],
          ),
        );
      }
      return;
    }

    final success = await provider.saveRoomSeatLayout(
      roomId: _roomId,
      cinemaId: _cinemaId,
      rows: _rows,
      cols: _cols,
      seatLayout: _serializedLayout,
      seatCount: _totalSeatCount,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lưu sơ đồ ghế thành công'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Lưu sơ đồ thất bại'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'THIẾT KẾ SƠ ĐỒ GHẾ'.toUpperCase(),
              style: AppTextStyles.titleSm.copyWith(color: AppColors.ink),
            ),
            const SizedBox(height: AppSpacing.xxxs),
            Text(
              '$_roomName · RẠP ${_cinemaId.toUpperCase()}',
              style: AppTextStyles.caption.copyWith(color: AppColors.muted),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Dimension Controls (Rows and Columns steppers)
          _buildDimensionControls(),

          // Brush Palette
          _buildBrushPalette(),

          // Seat Canvas inside InteractiveViewer
          Expanded(
            child: _buildSeatCanvas(),
          ),

          // Tally Bar & Save Button
          _buildTallyBarAndSave(context),
        ],
      ),
    );
  }

  Widget _buildDimensionControls() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: const BoxDecoration(
        color: AppColors.canvasElevated,
        border: Border(bottom: BorderSide(color: AppColors.hairline)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStepper(
            label: 'HÀNG (A-${String.fromCharCode(64 + _rows)})',
            value: _rows,
            onDecrement: () => _updateDimensions(_rows - 1, _cols),
            onIncrement: () => _updateDimensions(_rows + 1, _cols),
          ),
          _buildStepper(
            label: 'CỘT (1-$_cols)',
            value: _cols,
            onDecrement: () => _updateDimensions(_rows, _cols - 1),
            onIncrement: () => _updateDimensions(_rows, _cols + 1),
          ),
        ],
      ),
    );
  }

  Widget _buildStepper({
    required String label,
    required int value,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
  }) {
    return Row(
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.captionUppercase.copyWith(
            color: AppColors.muted,
            fontSize: 10,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        IconButton(
          icon: const Icon(Icons.remove, size: 16, color: AppColors.ink),
          onPressed: onDecrement,
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          padding: EdgeInsets.zero,
        ),
        Text(
          '$value',
          style: AppTextStyles.bodyMd.copyWith(
            color: AppColors.ink,
            fontWeight: FontWeight.w700,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add, size: 16, color: AppColors.ink),
          onPressed: onIncrement,
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          padding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildBrushPalette() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xxs,
      ),
      decoration: const BoxDecoration(
        color: AppColors.canvas,
        border: Border(bottom: BorderSide(color: AppColors.hairline)),
      ),
      child: Row(
        children: [
          Text(
            'CHẾ ĐỘ CỌ: ',
            style: AppTextStyles.captionUppercase.copyWith(
              color: AppColors.muted,
              fontSize: 10,
            ),
          ),
          _buildBrushChip('XOAY VÒNG', 'CYCLE', Colors.transparent, AppColors.ink),
          const SizedBox(width: AppSpacing.xxs),
          _buildBrushChip('THƯỜNG (S)', 'S', AppColors.canvasElevated, AppColors.ink),
          const SizedBox(width: AppSpacing.xxs),
          _buildBrushChip('VIP (V)', 'V', AppColors.primary, AppColors.ink),
          const SizedBox(width: AppSpacing.xxs),
          _buildBrushChip('ĐÔI (C)', 'C', AppColors.warning, AppColors.ink),
          const SizedBox(width: AppSpacing.xxs),
          _buildBrushChip('LỐI ĐI (_)', '_', AppColors.canvasElevated, AppColors.muted),
        ],
      ),
    );
  }

  Widget _buildBrushChip(String label, String value, Color color, Color textColor) {
    final isSelected = _selectedBrush == value;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? AppColors.ink : AppColors.muted,
          fontSize: 9,
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
      padding: EdgeInsets.zero,
      onSelected: (_) => setState(() => _selectedBrush = value),
    );
  }

  Widget _buildSeatCanvas() {
    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 2.5,
      boundaryMargin: const EdgeInsets.all(AppSpacing.xl),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Screen Arc Indicator
              Container(
                width: 240,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                'MÀN HÌNH',
                style: AppTextStyles.captionUppercase.copyWith(
                  color: AppColors.muted,
                  letterSpacing: 2.0,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Rows of Seats
              for (int r = 0; r < _rows; r++) ...[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Row Letter
                    SizedBox(
                      width: 20,
                      child: Text(
                        String.fromCharCode(65 + r),
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.muted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),

                    // Cells in Row
                    for (int c = 0; c < _cols; c++) ...[
                      _buildSeatCell(r, c),
                      const SizedBox(width: 4),
                    ],

                    const SizedBox(width: AppSpacing.xs),
                    // Row Actions popup
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, size: 14, color: AppColors.muted),
                      color: AppColors.canvasElevated,
                      onSelected: (action) {
                        setState(() {
                          for (int c = 0; c < _cols; c++) {
                            _grid[r][c] = action;
                          }
                        });
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(value: 'S', child: Text('Cả hàng Thường (S)', style: TextStyle(color: AppColors.ink))),
                        const PopupMenuItem(value: 'V', child: Text('Cả hàng VIP (V)', style: TextStyle(color: AppColors.ink))),
                        const PopupMenuItem(value: 'C', child: Text('Cả hàng Đôi (C)', style: TextStyle(color: AppColors.ink))),
                        const PopupMenuItem(value: '_', child: Text('Xóa thành Lối đi (_)', style: TextStyle(color: AppColors.muted))),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeatCell(int r, int c) {
    final type = _grid[r][c];

    if (type == '_') {
      return InkWell(
        onTap: () => _cycleCell(r, c),
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border.all(color: AppColors.hairline.withValues(alpha: 0.3)),
          ),
          child: const Center(
            child: Text(
              '·',
              style: TextStyle(color: AppColors.muted, fontSize: 10),
            ),
          ),
        ),
      );
    }

    Color cellColor;
    String label;
    if (type == 'V') {
      cellColor = AppColors.primary;
      label = 'V';
    } else if (type == 'C') {
      cellColor = AppColors.warning;
      label = 'C';
    } else {
      cellColor = AppColors.canvasElevated;
      label = 'S';
    }

    return InkWell(
      onTap: () => _cycleCell(r, c),
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: cellColor,
          borderRadius: AppRadius.zeroRadius,
          border: Border.all(color: AppColors.ink.withValues(alpha: 0.3)),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.ink,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildTallyBarAndSave(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.canvasElevated,
        border: Border(top: BorderSide(color: AppColors.hairline)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTallyItem('THƯỜNG', '$_standardCount', AppColors.ink),
              _buildTallyItem('VIP', '$_vipCount', AppColors.primary),
              _buildTallyItem('ĐÔI', '$_coupleCount', AppColors.warning),
              _buildTallyItem('TỔNG SỐ GHẾ', '$_totalSeatCount', AppColors.success),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton.primary(
            label: 'LƯU SƠ ĐỒ PHÒNG CHIẾU',
            onPressed: _saveLayout,
          ),
        ],
      ),
    );
  }

  Widget _buildTallyItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: AppTextStyles.captionUppercase.copyWith(
            color: AppColors.muted,
            fontSize: 9,
          ),
        ),
        const SizedBox(height: AppSpacing.xxxs),
        Text(
          value,
          style: AppTextStyles.titleSm.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
