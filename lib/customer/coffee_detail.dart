import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/app_colors.dart';
import '../providers/cart_provider.dart';
import '../widgets/coffee_data.dart';

class CoffeeDetail extends ConsumerStatefulWidget {
  final Coffee coffee;
  final String shopId;
  final String shopName;
  final List<Coffee> snackOptions;

  const CoffeeDetail({
    super.key,
    required this.coffee,
    required this.shopId,
    required this.shopName,
    required this.snackOptions,
  });

  @override
  ConsumerState<CoffeeDetail> createState() => _CoffeeDetailState();
}

class _CoffeeDetailState extends ConsumerState<CoffeeDetail> {
  final List<String> _sizes = ['Small', 'Medium', 'Large'];
  final List<String> _milkTypes = ['Regular', 'Oat', 'Almond'];
  final List<String> _sugarLevels = ['0%', '25%', '50%', '100%'];
  final List<String> _extras = ['Extra Shot', 'Vanilla Syrup', 'Caramel Drizzle'];

  String _selectedSize = 'Medium';
  String _selectedMilk = 'Regular';
  String _selectedSugar = '100%';
  final Set<String> _selectedExtras = {};
  final Set<String> _selectedSnackIds = {};

  void _addToCart() {
    final cart = ref.read(cartProvider.notifier);
    final notes = [
      'Size: $_selectedSize',
      'Milk: $_selectedMilk',
      'Sugar: $_selectedSugar',
      if (_selectedExtras.isNotEmpty) 'Extras: ${_selectedExtras.join(', ')}',
    ].join(' | ');
    cart.addItem(widget.coffee, notes: notes);

    final selectedSnacks = widget.snackOptions
        .where((snack) => _selectedSnackIds.contains(snack.itemId))
        .toList();
    for (final snack in selectedSnacks) {
      cart.addItem(snack);
    }

    final extrasLabel =
        _selectedExtras.isEmpty ? 'No extras' : _selectedExtras.join(', ');
    final snackLabel = selectedSnacks.isEmpty
        ? 'No snacks'
        : selectedSnacks.map((snack) => snack.name).join(', ');

    final totalQty = ref.read(cartProvider).totalQty;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
      SnackBar(
        content: Text(
          'Added ${widget.coffee.name} '
          '($_selectedSize, $_selectedMilk, $_selectedSugar, $extrasLabel) '
          '+ $snackLabel. Cart items: $totalQty',
        ),
        action: SnackBarAction(
          label: 'View Cart',
          onPressed: () => Navigator.pushNamed(context, '/cart'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final nutrition = widget.coffee.nutrition;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: AppColors.espresso,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  _buildImage(widget.coffee.image),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacityValue(0.55),
                          Colors.transparent,
                        ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.coffee.name,
                    style: textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'From: ${widget.shopName}',
                    style: textTheme.bodyLarge?.copyWith(
                      color: AppColors.ink.withOpacityValue(0.6),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      _InfoChip(
                        label: widget.coffee.category,
                        icon: Icons.local_cafe,
                      ),
                      const _InfoChip(
                        label: '200 ml',
                        icon: Icons.coffee,
                      ),
                      if (widget.coffee.isDairyFree)
                        const _InfoChip(
                          label: 'Dairy-Free',
                          icon: Icons.eco,
                        ),
                      if (widget.coffee.badges.isNotEmpty)
                        _InfoChip(
                          label: widget.coffee.badges.first,
                          icon: Icons.local_fire_department,
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Description',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.coffee.description,
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.ink.withOpacityValue(0.7),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Nutrition',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _NutritionRow(
                    kcal: nutrition.kcal,
                    protein: nutrition.protein,
                    carbs: nutrition.carbs,
                    fat: nutrition.fat,
                    caffeineMg: nutrition.caffeineMg,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Personalize your order',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _OptionGroup(
                    title: 'Size',
                    options: _sizes,
                    selected: _selectedSize,
                    onSelected: (value) {
                      setState(() => _selectedSize = value);
                    },
                  ),
                  const SizedBox(height: 14),
                  _OptionGroup(
                    title: 'Milk',
                    options: _milkTypes,
                    selected: _selectedMilk,
                    onSelected: (value) {
                      setState(() => _selectedMilk = value);
                    },
                  ),
                  const SizedBox(height: 14),
                  _OptionGroup(
                    title: 'Sugar',
                    options: _sugarLevels,
                    selected: _selectedSugar,
                    onSelected: (value) {
                      setState(() => _selectedSugar = value);
                    },
                  ),
                  const SizedBox(height: 14),
                  _ExtrasGroup(
                    title: 'Extras',
                    options: _extras,
                    selected: _selectedExtras,
                    onToggle: (value) {
                      setState(() {
                        if (_selectedExtras.contains(value)) {
                          _selectedExtras.remove(value);
                        } else {
                          _selectedExtras.add(value);
                        }
                      });
                    },
                  ),
                  if (widget.snackOptions.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Add snacks',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _SnackOptions(
                      snacks: widget.snackOptions,
                      selectedSnackIds: _selectedSnackIds,
                      onToggle: (value) {
                        setState(() {
                          if (_selectedSnackIds.contains(value)) {
                            _selectedSnackIds.remove(value);
                          } else {
                            _selectedSnackIds.add(value);
                          }
                        });
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacityValue(0.08),
                blurRadius: 16,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: Row(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Price',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.ink.withOpacityValue(0.6),
                    ),
                  ),
                  Text(
                    '${'\u{20B9}'} ${widget.coffee.price}',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.espresso,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _addToCart,
                  child: const Text('Add to Cart'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage(String imagePath) {
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
        child: Icon(
          Icons.local_cafe,
          size: 60,
          color: AppColors.espresso,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _InfoChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.oat,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.espresso),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.espresso,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _NutritionRow extends StatelessWidget {
  final int kcal;
  final double protein;
  final double carbs;
  final double fat;
  final int caffeineMg;

  const _NutritionRow({
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.caffeineMg,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _NutritionTile(label: 'Kcal', value: '$kcal'),
          _NutritionTile(
            label: 'Protein',
            value: '${protein.toStringAsFixed(1)}g',
          ),
          _NutritionTile(label: 'Carbs', value: '${carbs.toStringAsFixed(1)}g'),
          _NutritionTile(label: 'Fat', value: '${fat.toStringAsFixed(1)}g'),
          _NutritionTile(label: 'Caffeine', value: '${caffeineMg}mg'),
        ],
      ),
    );
  }
}

class _NutritionTile extends StatelessWidget {
  final String label;
  final String value;

  const _NutritionTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.oat,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.ink.withOpacityValue(0.6),
                ),
          ),
        ],
      ),
    );
  }
}

class _OptionGroup extends StatelessWidget {
  final String title;
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;

  const _OptionGroup({
    required this.title,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          children: options.map((option) {
            final isSelected = option == selected;
            return ChoiceChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (_) => onSelected(option),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _ExtrasGroup extends StatelessWidget {
  final String title;
  final List<String> options;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  const _ExtrasGroup({
    required this.title,
    required this.options,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = selected.contains(option);
            return FilterChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (_) => onToggle(option),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _SnackOptions extends StatelessWidget {
  final List<Coffee> snacks;
  final Set<String> selectedSnackIds;
  final ValueChanged<String> onToggle;

  const _SnackOptions({
    required this.snacks,
    required this.selectedSnackIds,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: snacks.map((snack) {
        final isSelected = selectedSnackIds.contains(snack.itemId);
        return FilterChip(
          label: Text('${snack.name} (${'\u{20B9}'}${snack.price})'),
          selected: isSelected,
          onSelected: (_) => onToggle(snack.itemId),
        );
      }).toList(),
    );
  }
}

