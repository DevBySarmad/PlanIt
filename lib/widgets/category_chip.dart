import 'package:flutter/material.dart';
import 'package:todo_app/theme/app_theme.dart';

class CategoryChip extends StatelessWidget {
  const CategoryChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) => ChoiceChip(
    label: Text(label),
    selected: selected,
    showCheckmark: false,
    onSelected: onSelected,
    labelStyle: TextStyle(
      color: selected ? Colors.white : AppTheme.ink,
      fontWeight: FontWeight.w600,
      fontSize: 13,
    ),
    backgroundColor: Colors.white,
    selectedColor: AppTheme.primary,
    side: BorderSide(color: selected ? AppTheme.primary : AppTheme.border),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
  );
}
