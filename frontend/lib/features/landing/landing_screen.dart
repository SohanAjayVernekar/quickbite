import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/api/repository.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/ui.dart';
import '../../core/widgets/delight.dart';
import '../restaurants/food_cards.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});
  @override
  State<LandingScreen> createState() => _LandingState();
}

class _LandingState extends State<LandingScreen> {
  final kitchensKey = GlobalKey();
  late Future<Catalog> catalog;
  @override
  void initState() {
    super.initState();
    load();
  }

  void load() {
    catalog = context.read<Repository>().catalog();
  }

  void browse([String cuisine = '']) => context.go(
    '/restaurants${cuisine.isEmpty ? '' : '?cuisine=${Uri.encodeQueryComponent(cuisine)}'}',
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: SingleChildScrollView(
        child: PageBody(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Brand(),
                  const Spacer(),
                  if (MediaQuery.sizeOf(context).width > 700)
                    TextButton(
                      onPressed: () => Scrollable.ensureVisible(
                        kitchensKey.currentContext!,
                        duration: MediaQuery.disableAnimationsOf(context)
                            ? Duration.zero
                            : const Duration(milliseconds: 500),
                      ),
                      child: const Text('Explore the menu'),
                    ),
                  IconButton(
                    tooltip: context.watch<MotionPreferences>().enabled
                        ? 'Pause animations'
                        : 'Enable animations',
                    onPressed: context.read<MotionPreferences>().toggle,
                    icon: Icon(
                      context.watch<MotionPreferences>().enabled
                          ? Icons.motion_photos_on_outlined
                          : Icons.motion_photos_off_outlined,
                    ),
                  ),
                  const SizedBox(width: 6),
                  FilledButton(
                    onPressed: () => context.go('/login'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                    ),
                    child: const Text('Log In'),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              FoodHero(onExplore: browse),
              const SizedBox(height: 36),
              FutureBuilder<Catalog>(
                future: catalog,
                builder: (context, s) {
                  if (s.connectionState != ConnectionState.done)
                    return const LoadingBlock(count: 4);
                  if (s.hasError)
                    return StateMessage(
                      title: 'The kitchen is warming up',
                      message:
                          'Connect to the QuickBite API to discover the menu.',
                      retry: () => setState(load),
                    );
                  final c = s.data!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 28,
                        runSpacing: 16,
                        children: [
                          _Stat(
                            '${c.totalRestaurants}',
                            'restaurants to discover',
                          ),
                          _Stat(
                            '${c.cuisines.length}',
                            'cuisines. endless cravings.',
                          ),
                          const _Stat('One bite', 'away from your happy place'),
                        ],
                      ),
                      const SizedBox(height: 42),
                      const SectionHeading(
                        'Follow your cravings.',
                        subtitle:
                            'Something comforting. Something adventurous. Something you.',
                      ),
                      CuisineStrip(cuisines: c.cuisines, onSelected: browse),
                      const SizedBox(height: 42),
                      SectionHeading(
                        'Your next favourite is here.',
                        key: kitchensKey,
                        subtitle:
                            'Big flavours from our featured demo kitchens.',
                        action: TextButton.icon(
                          onPressed: browse,
                          icon: const Icon(Icons.arrow_forward),
                          label: Text(
                            'Explore all ${c.totalRestaurants} restaurants',
                          ),
                        ),
                      ),
                      ResponsiveCards(
                        children: c.restaurants
                            .take(8)
                            .map(
                              (r) => RestaurantCard(
                                restaurant: r,
                                onTap: () => context.go('/restaurants/${r.id}'),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 44),
                      const SectionHeading(
                        'A little taste of happiness.',
                        subtitle:
                            'Comfort classics and new favourites, waiting for you.',
                      ),
                      ResponsiveCards(
                        children: c.dishes
                            .take(4)
                            .map(
                              (d) => DishCard(
                                item: d,
                                onTap: () => context.go(
                                  '/restaurants/${d.restaurantId}',
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 48),
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: QB.ink,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Good food. Zero guesswork.',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Wrap(
                      spacing: 28,
                      runSpacing: 18,
                      children: [
                        _Step(
                          '01',
                          'Find your flavour',
                          'Explore kitchens and their menus.',
                        ),
                        _Step(
                          '02',
                          'Make it yours',
                          'Pick your food and portion.',
                        ),
                        _Step(
                          '03',
                          'Follow every step',
                          'Track your demo order in one place.',
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: browse,
                      child: const Text('Let’s eat  →'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 38),
              const Brand(size: 20),
              const SizedBox(height: 12),
              const Text(
                'A little joy in every order.',
                style: TextStyle(color: QB.muted),
              ),
              const SizedBox(height: 12),
              const Text(
                'QuickBite demo · Fictional restaurants, illustrative food images and simulated orders, payments and delivery. Ratings and times are sample data.',
                style: TextStyle(fontSize: 11, color: QB.muted),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _Stat extends StatelessWidget {
  final String value, label;
  const _Stat(this.value, this.label);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.w900,
            color: QB.text,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: QB.muted)),
      ],
    ),
  );
}

class _Step extends StatelessWidget {
  final String number, title, description;
  const _Step(this.number, this.title, this.description);
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 245,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          number,
          style: const TextStyle(
            color: Color(0xFFFFB28B),
            fontSize: 13,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          description,
          style: const TextStyle(color: QB.mutedOnDark, fontSize: 13),
        ),
      ],
    ),
  );
}
