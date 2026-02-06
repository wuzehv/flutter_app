import 'package:flutter/material.dart';

/// 通用复选组件，用于处理多选列表
class ChoiceSelector extends StatelessWidget {
  final List<String> options;
  final List<String> selectedValues;
  final String title;
  final ValueChanged<String> onSelectionChanged;
  final ValueChanged<List<String>>? onSelectAll;
  final bool isRequired;
  final bool showSelectAll;
  final bool isMultiSelect;
  final String? selectedValue;

  const ChoiceSelector({
    super.key,
    required this.options,
    required this.selectedValues,
    required this.title,
    required this.onSelectionChanged,
    this.onSelectAll,
    this.isRequired = true,
    this.showSelectAll = false,
    this.isMultiSelect = true,
    this.selectedValue,
  });

  @override
  Widget build(BuildContext context) {
    final isAllSelected = selectedValues.length == options.length && options.isNotEmpty;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$title ${isRequired ? "*" : ""}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (showSelectAll && options.isNotEmpty && isMultiSelect)
              ElevatedButton(
                onPressed: () {
                  if (onSelectAll != null) {
                    if (isAllSelected) {
                      onSelectAll!([]); // 取消全选
                    } else {
                      onSelectAll!(List.from(options)); // 全选
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isAllSelected ? Colors.red : Colors.green,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  isAllSelected ? '取消全选' : '全选',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        if (options.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              '暂无可用选项',
              style: TextStyle(color: Colors.grey),
            ),
          )
        else
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: options.map((option) {
              final isSelected = isMultiSelect 
                  ? selectedValues.contains(option)
                  : (selectedValue != null && selectedValue == option);
                  
              return _CustomChip(
                label: option,
                isSelected: isSelected,
                onTap: () {
                  if (isMultiSelect) {
                    onSelectionChanged(option);
                  } else {
                    if (!isSelected) {
                      onSelectionChanged(option);
                    }
                  }
                },
              );
            }).toList(),
          ),
        SizedBox(height: 16),
      ],
    );
  }
}

/// 完全自定义的Chip组件，无对勾图标
class _CustomChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CustomChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green : Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.green : Colors.grey[300]!,
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}