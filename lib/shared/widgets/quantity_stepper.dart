import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_text_styles.dart';

/// Quantity Stepper component following DESIGN_TOKENS.md Section 7.15
class QuantityStepper extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;
  final bool isAvailable;

  const QuantityStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 99,
    this.isAvailable = true,
  });

  @override
  Widget build(BuildContext context) {
    final bool canDecrement = isAvailable && value > min;
    final bool canIncrement = isAvailable && value < max;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Decrement button
        InkWell(
          onTap: canDecrement ? () => onChanged(value - 1) : null,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.transparent,
              border: Border.all(
                color: canDecrement ? AppColors.ink : AppColors.hairline,
                width: 1,
              ),
              borderRadius: AppRadius.zeroRadius,
            ),
            child: Icon(
              Icons.remove,
              size: 16,
              color: canDecrement ? AppColors.ink : AppColors.muted,
            ),
          ),
        ),

        // Value display
        SizedBox(
          width: 36,
          child: Center(
            child: Text(
              '$value',
              style: AppTextStyles.titleSm.copyWith(
                color: isAvailable ? AppColors.ink : AppColors.muted,
              ),
            ),
          ),
        ),

        // Increment button
        InkWell(
          onTap: canIncrement ? () => onChanged(value + 1) : null,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.transparent,
              border: Border.all(
                color: canIncrement ? AppColors.ink : AppColors.hairline,
                width: 1,
              ),
              borderRadius: AppRadius.zeroRadius,
            ),
            child: Icon(
              Icons.add,
              size: 16,
              color: canIncrement ? AppColors.ink : AppColors.muted,
            ),
          ),
        ),
      ],
    );
  }
}
