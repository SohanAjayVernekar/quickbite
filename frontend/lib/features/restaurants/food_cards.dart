import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/ui.dart';
import '../cart/cart_effects.dart';

class RestaurantCard extends StatelessWidget {
  final Restaurant restaurant;
  final VoidCallback onTap;
  final bool? selected;
  final ValueChanged<bool>? onSelect;
  final bool showAdminControls;
  final ValueChanged<bool>? onAvailabilityChanged;
  final VoidCallback? onDelete;
  const RestaurantCard({
    super.key,
    required this.restaurant,
    required this.onTap,
    this.selected,
    this.onSelect,
    this.showAdminControls = false,
    this.onAvailabilityChanged,
    this.onDelete,
  });
  @override
  Widget build(BuildContext context) => GlassCard(
    onTap: onTap,
    padding: const EdgeInsets.all(10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            FoodImage(restaurant.image, height: 202, cuisine: restaurant.cuisine),
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: QB.ink.withValues(alpha: .9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  restaurant.cuisine,
                  style: const TextStyle(
                    fontSize: 11,
                    color: QB.onDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: QB.green,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '★ ${restaurant.rating}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            if (selected != null && onSelect != null)
              Positioned(
                top: 8,
                right: 8,
                child: Material(
                  color: QB.surface,
                  borderRadius: BorderRadius.circular(22),
                  child: Tooltip(
                    message: selected == true
                        ? 'Remove ${restaurant.name} from comparison'
                        : 'Select ${restaurant.name} to compare',
                    child: Checkbox(
                      value: selected,
                      onChanged: (value) => onSelect!(value ?? false),
                    ),
                  ),
                ),
              ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 17, 8, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                restaurant.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  color: QB.text,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                restaurant.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: QB.muted, fontSize: 13),
              ),
              const SizedBox(height: 15),
              Wrap(
                spacing: 14,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.schedule_rounded,
                        size: 15,
                        color: QB.muted,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '~${restaurant.etaMinutes} min',
                        style: const TextStyle(fontSize: 12, color: QB.muted),
                      ),
                    ],
                  ),
                  Text(
                    restaurant.available ? 'View menu ↗' : 'Currently closed',
                    style: TextStyle(
                      fontSize: 12,
                      color: restaurant.available ? QB.gold : QB.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (showAdminControls)
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 4, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    restaurant.available ? 'Available for orders' : 'Not available',
                    style: const TextStyle(color: QB.muted, fontSize: 12),
                  ),
                ),
                Switch.adaptive(
                  value: restaurant.available,
                  onChanged: onAvailabilityChanged,
                ),
                IconButton(
                  tooltip: 'Delete restaurant',
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded, color: QB.red),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

class DishCard extends StatelessWidget {
  final MenuItem item;
  final String? Function()? onAdd;
  final VoidCallback? onTap;
  /// Optional bulk-selection checkbox. Omitted where selection makes no sense,
  /// such as the small dashboard cards.
  final bool? selected;
  final ValueChanged<bool>? onSelect;
  final bool showAdminControls;
  final ValueChanged<bool>? onAvailabilityChanged;
  final VoidCallback? onDelete;
  const DishCard(
      {super.key,
      required this.item,
      this.onAdd,
      this.onTap,
      this.selected,
      this.onSelect,
      this.showAdminControls = false,
      this.onAvailabilityChanged,
      this.onDelete});
  @override
  Widget build(BuildContext context) => GlassCard(
    onTap: onTap,
    padding: const EdgeInsets.all(10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            // Dish artwork is square. Keep the full plate visible instead of
            // cropping the top and bottom into the old fixed-height banner.
            AspectRatio(
              aspectRatio: 1,
              child: FoodImage(item.image, dishName: item.name),
            ),
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: QB.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  item.vegetarian ? '●  VEG' : '●  NON-VEG',
                  style: TextStyle(
                    color: item.vegetarian ? QB.green : QB.red,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
            if (selected != null && onSelect != null)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  decoration: BoxDecoration(
                    color: QB.surface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Tooltip(
                    message: selected == true
                        ? 'Remove ${item.name} from selection'
                        : 'Select ${item.name}',
                    child: Checkbox(
                      value: selected,
                      onChanged: (v) => onSelect!(v ?? false),
                    ),
                  ),
                ),
              ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                style: const TextStyle(
                  fontSize: 18,
                  color: QB.text,
                  height: 1.3,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: QB.muted,
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 18,
                runSpacing: 10,
                children: [
                  Text(
                    money(item.priceMinor, item.currency),
                    style: const TextStyle(
                      fontSize: 20,
                      color: QB.text,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (showAdminControls)
                    const Text(
                      'Manage dish',
                      style: TextStyle(color: QB.gold, fontWeight: FontWeight.w700),
                    )
                  else if (onAdd != null)
                    BurstAddButton(
                      onAdd: onAdd!,
                      enabled: item.available,
                      itemName: item.name,
                    )
                  else
                    const Text(
                      'Discover ↗',
                      style: TextStyle(
                        color: QB.gold,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'View in 3D',
                    icon: const Icon(Icons.view_in_ar, size: 20),
                    onPressed: () => context.go(
                      '/dishes/${Uri.encodeComponent(item.id)}/3d?name=${Uri.encodeComponent(item.name)}',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (showAdminControls)
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 4, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    item.available ? 'Available' : 'Not available',
                    style: const TextStyle(color: QB.muted, fontSize: 12),
                  ),
                ),
                Switch.adaptive(
                  value: item.available,
                  onChanged: onAvailabilityChanged,
                ),
                IconButton(
                  tooltip: 'Delete dish',
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded, color: QB.red),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}
