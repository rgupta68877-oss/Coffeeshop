import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/app_colors.dart';

class CoffeeCard extends StatelessWidget {
  final String name;
  final String price;
  final String imagePath;
  final String? badgeText;
  final VoidCallback? onAddToCart;
  final VoidCallback? onEditPrice;
  final VoidCallback? onToggleAvailability;
  final bool isAvailable;
  final bool showOwnerControls;

  const CoffeeCard({
    super.key,
    required this.name,
    required this.price,
    required this.imagePath,
    this.badgeText,
    this.onAddToCart,
    this.onEditPrice,
    this.onToggleAvailability,
    this.isAvailable = true,
    this.showOwnerControls = false,
  });
  final String? badgeText;
  final VoidCallback? onAddToCart;
  final VoidCallback? onEditPrice;
  final VoidCallback? onToggleAvailability;
  final bool isAvailable;
  final bool showOwnerControls;

  const CoffeeCard({
    super.key,
    required this.name,
    required this.price,
    required this.imagePath,
    this.badgeText,
    this.onAddToCart,
    this.onEditPrice,
    this.onToggleAvailability,
    this.isAvailable = true,
    this.showOwnerControls = false,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final textTheme = Theme.of(context).textTheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(child: _buildImage()),
                if (badgeText != null)
                  Positioned(
                    left: 12,
                    top: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.espresso,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        badgeText!,
                        style: textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  left: 12,
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacityValue(0.92),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacityValue(0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      '${'\u{20B9}'} $price',
                      style: textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.espresso,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                if (showOwnerControls) ...[
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isAvailable
                              ? AppColors.matcha.withOpacityValue(0.15)
                              : AppColors.caramel.withOpacityValue(0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          isAvailable ? 'Available' : 'Unavailable',
                          style: textTheme.labelMedium?.copyWith(
                            color: isAvailable
                                ? AppColors.matcha
                                : AppColors.caramel,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Switch(
                        value: isAvailable,
                        onChanged: (value) => onToggleAvailability?.call(),
                        activeThumbColor: AppColors.matcha,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: onEditPrice,
                      child: const Text('Edit Price'),
                    ),
                  ),
                ] else if (onAddToCart != null) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onAddToCart,
                      icon: const Icon(Icons.add),
                      label: const Text('Add to Cart'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    if (imagePath.startsWith('http')) {
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _fallbackImage(),
      );
    }
    return Image.asset(
      imagePath,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _fallbackImage(),
    );
  }

  Widget _fallbackImage() {
    return Container(
      color: AppColors.oat,
      child: const Center(
        child: Icon(Icons.local_cafe, size: 42, color: AppColors.espresso),
      ),
    );
  }
}
