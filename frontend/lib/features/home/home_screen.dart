import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/repository.dart';
import '../../core/auth/auth_store.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/ui.dart';
import '../../core/widgets/delight.dart';
import '../restaurants/food_cards.dart';
import '../cart/cart_store.dart';

class HomeData {
  final Catalog catalog;
  final List<OrderSummary> active;
  final int notifications;
  HomeData(this.catalog, this.active, this.notifications);
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeState();
}

class _HomeState extends State<HomeScreen> {
  late Future<HomeData> data;
  @override
  void initState() {
    super.initState();
    load();
  }

  void load() {
    data = fetch();
  }

  Future<HomeData> fetch() async {
    final repo = context.read<Repository>();
    final values = await Future.wait<dynamic>([
      repo.catalog(),
      repo.orders(status: 'PENDING'),
      repo.orders(status: 'PAID'),
      repo.orders(status: 'CONFIRMED'),
      repo.notifications(),
    ]);
    final active = <OrderSummary>[
      for (var i = 1; i <= 3; i++)
        ...(values[i] as PageResult<OrderSummary>).items,
    ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return HomeData(
      values[0] as Catalog,
      active,
      (values[4] as PageResult<Notice>).total,
    );
  }

  void browse([String cuisine = '']) => context.go(
    '/restaurants${cuisine.isEmpty ? '' : '?cuisine=${Uri.encodeQueryComponent(cuisine)}'}',
  );
  @override
  Widget build(BuildContext context) {
    final name =
        context.watch<AuthStore>().user?.name.trim().split(' ').first ??
        'food lover';
    return RefreshIndicator(
      onRefresh: () async {
        setState(load);
        await data;
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: PageBody(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'HEY ${name.toUpperCase()}, GOOD FOOD AWAITS',
                style: const TextStyle(
                  color: QB.green,
                  fontSize: 10,
                  letterSpacing: 1.8,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'What’s your craving?',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.2,
                ),
              ),
              const SizedBox(height: 22),
              GlassCard(
                onTap: browse,
                padding: const EdgeInsets.all(18),
                child: const Row(
                  children: [
                    Icon(Icons.search, color: QB.gold),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Search restaurants, cuisines or your favourite food',
                        style: TextStyle(color: QB.muted, fontSize: 13),
                      ),
                    ),
                    Icon(Icons.tune_rounded, size: 20, color: QB.muted),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              FoodHero(compact: true, onExplore: browse),
              const SizedBox(height: 32),
              FutureBuilder<HomeData>(
                future: data,
                builder: (context, s) {
                  if (s.connectionState != ConnectionState.done)
                    return const LoadingBlock();
                  if (s.hasError)
                    return StateMessage(
                      title: 'Let’s reconnect',
                      message: s.error.toString(),
                      retry: () => setState(load),
                    );
                  final d = s.data!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (d.active.isNotEmpty) ...[
                        GlassCard(
                          onTap: () =>
                              context.go('/orders/${d.active.first.id}'),
                          child: Wrap(
                            spacing: 20,
                            runSpacing: 12,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const Icon(
                                Icons.delivery_dining_rounded,
                                color: QB.gold,
                                size: 32,
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'YOUR ORDER IS IN PROGRESS',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: QB.green,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  Text(
                                    d.active.first.restaurantName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 17,
                                    ),
                                  ),
                                ],
                              ),
                              StatusPill(d.active.first.status),
                              const Text('Track order →'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                      ],
                      const SectionHeading('Pick your kind of happy.'),
                      CuisineStrip(
                        cuisines: d.catalog.cuisines,
                        onSelected: browse,
                      ),
                      const SizedBox(height: 34),
                      SectionHeading(
                        'Kitchens we’re craving.',
                        subtitle:
                            '${d.catalog.totalRestaurants} demo restaurants. ${d.catalog.cuisines.length} cuisines. Your next favourite.',
                        action: TextButton.icon(
                          onPressed: browse,
                          icon: const Icon(Icons.arrow_forward),
                          label: const Text('Explore all restaurants'),
                        ),
                      ),
                      ResponsiveCards(
                        children: d.catalog.restaurants
                            .take(6)
                            .map(
                              (r) => RestaurantCard(
                                restaurant: r,
                                onTap: () => context.go('/restaurants/${r.id}'),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 38),
                      const SectionHeading(
                        'A little something delicious.',
                        subtitle: 'Big comfort, one tap away.',
                      ),
                      ResponsiveCards(
                        children: d.catalog.dishes
                            .map(
                              (item) => DishCard(
                                item: item,
                                onAdd: () =>
                                    context.read<CartStore>().add(item),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 22),
                      TextButton.icon(
                        onPressed: () => context.go('/notifications'),
                        icon: const Icon(Icons.notifications_outlined),
                        label: Text('${d.notifications} saved notifications'),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
