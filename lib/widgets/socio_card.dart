import 'package:flutter/material.dart';
import '../models/socio.dart';
import '../utils/constants.dart';

class SocioCard extends StatelessWidget {
  final Socio socio;
  final bool isPresent;
  final ValueChanged<bool?>? onChanged;

  const SocioCard({
    super.key,
    required this.socio,
    required this.isPresent,
    this.onChanged,
  });

  Color _getCategoryColor() {
    switch (socio.categoria.toLowerCase()) {
      case 'infantil':
        return Colors.blue;
      case 'juvenil':
        return Colors.orange;
      case 'senior':
        return Colors.green;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingMedium),
      elevation: isPresent ? 4 : 1,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
          border: isPresent
              ? Border.all(color: AppColors.success, width: 2)
              : null,
        ),
        child: CheckboxListTile(
          value: isPresent,
          onChanged: onChanged,
          title: Text(
            socio.nombre,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: isPresent ? FontWeight.w600 : FontWeight.normal,
              color: isPresent ? AppColors.success : AppColors.textPrimary,
            ),
          ),
          subtitle: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getCategoryColor().withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  socio.categoria.toUpperCase(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _getCategoryColor(),
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          secondary: CircleAvatar(
            backgroundColor: isPresent
                ? AppColors.success
                : AppColors.textSecondary.withOpacity(0.2),
            child: Text(
              socio.nombre[0].toUpperCase(),
              style: TextStyle(
                color: isPresent ? Colors.white : AppColors.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          activeColor: AppColors.success,
          checkColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingMedium,
            vertical: AppDimensions.paddingSmall,
          ),
        ),
      ),
    );
  }
}
