import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';

/// Müşteri bazlı filtreleme dropdown widget'ı.
class CustomerFilterDropdown extends StatelessWidget {
  final List<({String id, String name})> customers;
  final String? selectedCustomerId;
  final ValueChanged<String?> onChanged;

  const CustomerFilterDropdown({
    super.key,
    required this.customers,
    required this.selectedCustomerId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.textMutedLighter),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: selectedCustomerId,
          isExpanded: true,
          icon: const Icon(Icons.filter_list, size: 20, color: AppColors.textSecondary),
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
          hint: const Text(
            'Tüm Müşteriler',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('Tüm Müşteriler'),
            ),
            ...customers.map(
              (c) => DropdownMenuItem<String?>(
                value: c.id,
                child: Text(
                  c.name.isNotEmpty ? c.name : 'İsimsiz Müşteri',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}
