import 'package:flutter/material.dart';

class CoffeeCard extends StatelessWidget {
  final String name;
  final String price;
  final String imagePath;
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
    this.onAddToCart,
    this.onEditPrice,
    this.onToggleAvailability,
    this.isAvailable = true,
    this.showOwnerControls = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            imagePath.startsWith('http')
                ? Image.network(
                    imagePath,
                    height: 60,
                    width: 60,
                    fit: BoxFit.cover,
                  )
                : Image.asset(
                    imagePath,
                    height: 60,
                    width: 60,
                    fit: BoxFit.cover,
                  ),
            const SizedBox(height: 12),
            Text(
              name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text("₹ $price", style: const TextStyle(fontSize: 16)),
            if (showOwnerControls) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isAvailable ? 'Available' : 'Unavailable',
                    style: TextStyle(
                      color: isAvailable ? Colors.green : Colors.red,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isAvailable ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: onEditPrice,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                    child: const Text('Edit Price'),
                  ),
                  const SizedBox(width: 8),
                  Switch(
                    value: isAvailable,
                    onChanged: (value) => onToggleAvailability?.call(),
                    activeColor: const Color(0xFFC47A45),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ],
              ),
            ] else if (onAddToCart != null) ...[
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: onAddToCart,
                child: const Text('Add to Cart'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
