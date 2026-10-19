import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/auth/auth_store.dart';
import '../../core/api/repository.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/ui.dart';
import '../../core/widgets/delight.dart';
import '../cart/cart_store.dart';
import 'food_cards.dart';

class RestaurantsScreen extends StatefulWidget {
  final String initialCuisine;
  const RestaurantsScreen({super.key, this.initialCuisine = ''});
  @override
  State<RestaurantsScreen> createState() => _RestaurantsState();
}

class _RestaurantsState extends State<RestaurantsScreen> {
  static const _batch = 12;
  int page = 1, total = 0, _requestId = 0;
  String query = '', cuisine = '', sort = 'recommended';
  bool vegetarian = false, highlyRated = false;
  bool infiniteScroll = true;
  final List<Restaurant> restaurants = [];
  final Set<String> selected = {};
  bool loading = true, loadingMore = false, reachedEnd = false;
  String? error;
  final search = TextEditingController();
  final scroll = ScrollController();
  Timer? debounce;
  @override
  void initState() {
    super.initState();
    cuisine = widget.initialCuisine;
    scroll.addListener(_onScroll);
    load(reset: true);
  }

  @override
  void didUpdateWidget(covariant RestaurantsScreen old) {
    super.didUpdateWidget(old);
    if (old.initialCuisine != widget.initialCuisine) {
      cuisine = widget.initialCuisine;
      page = 1;
      selected.clear();
      load(reset: true);
    }
  }

  Future<void> load({bool reset = false}) async {
    if (reset) {
      loading = true;
      loadingMore = false;
      reachedEnd = false;
      error = null;
      restaurants.clear();
    } else {
      if (loadingMore || reachedEnd) return;
      loadingMore = true;
    }
    final requestId = ++_requestId;
    if (mounted) setState(() {});
    try {
      final result = await context.read<Repository>().restaurants(
        page: page,
        query: query,
        cuisine: cuisine,
        vegetarian: vegetarian,
        minRating: highlyRated ? 45 : 0,
        sort: sort,
      );
      if (!mounted || requestId != _requestId) return;
      setState(() {
        restaurants.addAll(result.items);
        total = result.total;
        page = result.page;
        loading = false;
        loadingMore = false;
        reachedEnd = restaurants.length >= total || result.items.isEmpty;
        error = null;
      });
    } catch (e) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        loading = false;
        loadingMore = false;
        error = e.toString();
      });
    }
  }

  void filter(VoidCallback change) {
    setState(() {
      change();
      page = 1;
      selected.clear();
    });
    load(reset: true);
  }

  void searchNow(String value) {
    debounce?.cancel();
    filter(() => query = value.trim());
  }

  void _onScroll() {
    if (!infiniteScroll || !scroll.hasClients || loading || loadingMore || reachedEnd || error != null) return;
    if (scroll.position.maxScrollExtent - scroll.position.pixels < 900) {
      page += 1;
      load();
    }
  }

  @override
  void dispose() {
    search.dispose();
    scroll.removeListener(_onScroll);
    scroll.dispose();
    debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthStore>().user?.isAdmin ?? false;
    return SingleChildScrollView(
    controller: scroll,
    child: PageBody(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'YOUR NEXT FOOD STORY',
            style: TextStyle(
              color: QB.green,
              fontSize: 10,
              letterSpacing: 1.8,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          SectionHeading(
            'Find your flavour.',
            subtitle: 'A world of kitchens. A menu for every mood.',
            action: isAdmin
                ? Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: _createRestaurant,
                      icon: const Icon(Icons.add_business_rounded),
                      label: const Text('Add restaurant'),
                    ),
                  )
                : null,
          ),
          TextField(
            controller: search,
            decoration: InputDecoration(
              hintText: 'Try biryani, sushi or a restaurant…',
              prefixIcon: const Icon(Icons.search, color: QB.gold),
              suffixIcon: IconButton(
                tooltip: 'Clear search',
                onPressed: () {
                  search.clear();
                  searchNow('');
                },
                icon: const Icon(Icons.close, size: 18),
              ),
            ),
            onChanged: (v) {
              debounce?.cancel();
              debounce = Timer(const Duration(milliseconds: 350), () {
                if (mounted) searchNow(v);
              });
            },
            onSubmitted: searchNow,
          ),
          const SizedBox(height: 24),
          CuisineStrip(
            selected: cuisine,
            cuisines: cuisineEmoji.keys.toList(),
            onSelected: (v) => filter(() => cuisine = v),
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilterChip(
                label: const Text('Vegetarian options'),
                avatar: const Icon(Icons.eco_outlined, size: 17),
                selected: vegetarian,
                onSelected: (v) => filter(() => vegetarian = v),
              ),
              FilterChip(
                label: const Text('Rating 4.5+'),
                avatar: const Icon(Icons.star_outline_rounded, size: 17),
                selected: highlyRated,
                onSelected: (v) => filter(() => highlyRated = v),
              ),
              DropdownButton<String>(
                value: sort,
                underline: const SizedBox(),
                borderRadius: BorderRadius.circular(16),
                items: const [
                  DropdownMenuItem(
                    value: 'recommended',
                    child: Text('Recommended'),
                  ),
                  DropdownMenuItem(
                    value: 'fastest',
                    child: Text('Fastest delivery'),
                  ),
                  DropdownMenuItem(value: 'rating', child: Text('Top rated')),
                  DropdownMenuItem(value: 'name', child: Text('Name A–Z')),
                ],
                onChanged: (v) {
                  if (v != null) filter(() => sort = v);
                },
              ),
              if (query.isNotEmpty ||
                  cuisine.isNotEmpty ||
                  vegetarian ||
                  highlyRated)
                TextButton(
                  onPressed: () {
                    search.clear();
                    debounce?.cancel();
                    filter(() {
                      query = '';
                      cuisine = '';
                      vegetarian = false;
                      highlyRated = false;
                    });
                  },
                  child: const Text('Reset filters'),
                ),
            ],
          ),
          const SizedBox(height: 26),
          if (loading && restaurants.isEmpty)
            const LoadingBlock()
          else if (error != null && restaurants.isEmpty)
            StateMessage(
              title: 'Unable to load restaurants',
              message: error!,
              retry: () => load(reset: true),
            )
          else if (restaurants.isEmpty && !loading)
            const StateMessage(
              title: 'No kitchens found',
              message: 'Try another food, cuisine or filter.',
            )
          else ...[
            Text(
              '$total restaurants for your cravings',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose infinite scrolling or jump to a page below.',
              style: TextStyle(color: QB.muted, fontSize: 11),
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text('Enable infinite scroll'),
              subtitle: const Text('Load the next restaurant page as you scroll.'),
              value: infiniteScroll,
              onChanged: (value) => setState(() => infiniteScroll = value ?? false),
            ),
            if (restaurants.isNotEmpty)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text('Select loaded restaurants (${restaurants.length})'),
                value: restaurants.isNotEmpty && restaurants.every((r) => selected.contains(r.id)),
                onChanged: (value) => setState(() {
                  if (value == true) {
                    selected.addAll(restaurants.map((r) => r.id));
                  } else {
                    selected.removeAll(restaurants.map((r) => r.id));
                  }
                }),
              ),
            const SizedBox(height: 12),
            ResponsiveCards(
              children: restaurants
                  .map((r) => RestaurantCard(
                        key: ValueKey(r.id),
                        restaurant: r,
                        selected: selected.contains(r.id),
                        showAdminControls: isAdmin,
                        onAvailabilityChanged: isAdmin
                            ? (value) => _setRestaurantAvailability(r, value)
                            : null,
                        onDelete: isAdmin ? () => _deleteRestaurant(r) : null,
                        onSelect: (value) => setState(() => value
                            ? selected.add(r.id)
                            : selected.remove(r.id)),
                        onTap: () => context.go('/restaurants/${r.id}'),
                      ))
                  .toList(),
            ),
            if (loadingMore) const LoadingBlock(count: 3),
            if (error != null && restaurants.isNotEmpty)
              Center(
                child: TextButton.icon(
                  onPressed: () => load(),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Could not load more · retry'),
                ),
              ),
            if (reachedEnd && restaurants.isNotEmpty)
              Center(
                child: Text(
                  'You have reached the end · ${restaurants.length} of $total restaurants',
                  style: const TextStyle(color: QB.muted, fontSize: 12),
                ),
              ),
            if (total > _batch)
              Pagination(
                page: page,
                total: total,
                pageSize: _batch,
                loadedCount: restaurants.length,
                onPage: (value) {
                  setState(() {
                    page = value;
                    selected.clear();
                  });
                  load(reset: true);
                  if (scroll.hasClients) {
                    scroll.animateTo(
                      0,
                      duration: MediaQuery.disableAnimationsOf(context)
                          ? Duration.zero
                          : const Duration(milliseconds: 350),
                      curve: Curves.easeOut,
                    );
                  }
                },
              ),
            if (selected.isNotEmpty) _selectionBar(),
          ],
        ],
      ),
    ),
  );
  }

  void _message(String value) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(value)),
      );

  Future<void> _createRestaurant() async {
    final data = await _restaurantForm(context);
    if (data == null || !mounted) return;
    try {
      await context.read<Repository>().createAdminRestaurant(data);
      if (!mounted) return;
      setState(() {
        page = 1;
        selected.clear();
      });
      await load(reset: true);
      _message('Restaurant added.');
    } catch (error) {
      _message('Could not add restaurant: $error');
    }
  }

  Future<void> _setRestaurantAvailability(Restaurant restaurant, bool available) async {
    try {
      await context.read<Repository>().setRestaurantAvailability(restaurant.id, available);
      if (!mounted) return;
      setState(() {
        page = 1;
        selected.clear();
      });
      await load(reset: true);
      _message(available ? 'Restaurant is available for orders.' : 'Restaurant is not available for orders.');
    } catch (error) {
      _message('Could not update availability: $error');
    }
  }

  Future<void> _deleteRestaurant(Restaurant restaurant) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete restaurant?'),
        content: Text('Delete ${restaurant.name} and its menu? Restaurants with order history cannot be deleted; mark them unavailable instead.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Keep restaurant')),
          FilledButton.tonal(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await context.read<Repository>().deleteAdminRestaurant(restaurant.id);
      if (!mounted) return;
      setState(() {
        page = 1;
        selected.clear();
      });
      await load(reset: true);
      _message('Restaurant deleted.');
    } catch (error) {
      _message('Could not delete restaurant: $error');
    }
  }

  Widget _selectionBar() {
    final chosen = restaurants.where((r) => selected.contains(r.id)).toList();
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: GlassCard(
        child: Row(
          children: [
            Expanded(
              child: Text(
                '${chosen.length} restaurant${chosen.length == 1 ? '' : 's'} selected',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            TextButton(
              onPressed: () => setState(selected.clear),
              child: const Text('Clear'),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: chosen.length < 2 ? null : () => _compare(chosen),
              icon: const Icon(Icons.compare_arrows_rounded),
              label: const Text('Compare'),
            ),
          ],
        ),
      ),
    );
  }

  void _compare(List<Restaurant> chosen) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Compare restaurants'),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: chosen.map((r) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: QB.mint,
                  child: Text(cuisineEmoji[r.cuisine] ?? '🍽️'),
                ),
                title: Text(r.name),
                subtitle: Text('${r.cuisine} · ~${r.etaMinutes} min · ${r.available ? 'Open' : 'Closed'}'),
                trailing: Text('★ ${r.rating}', style: const TextStyle(color: QB.green, fontWeight: FontWeight.w700)),
              )).toList(),
            ),
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Done'))],
      ),
    );
  }
}

class MenuScreen extends StatefulWidget {
  final String id;
  const MenuScreen({super.key, required this.id});

  @override
  State<MenuScreen> createState() => _MenuState();
}

class _MenuState extends State<MenuScreen> {
  static const _batch = 24;

  final scroll = ScrollController();
  final search = TextEditingController();

  // Accumulated pages, so infinite scroll appends instead of replacing.
  final List<MenuItem> dishes = [];
  // Bulk selection for "add every checked dish" across an infinite list.
  final Set<String> selected = {};
  int _cartVersion = 0, _requestId = 0;
  Restaurant? restaurant;
  int page = 1, total = 0;
  // all / veg / non_veg, sent to the API as a server-side filter.
  String diet = 'all';
  bool available = false;
  bool withPhoto = false;
  String sort = 'recommended';
  bool loading = true, loadingMore = false, reachedEnd = false;
  bool infiniteScroll = true;
  String? error;
  String? _notice;

  @override
  void initState() {
    super.initState();
    scroll.addListener(_onScroll);
    load(reset: true);
  }

  @override
  void didUpdateWidget(covariant MenuScreen old) {
    super.didUpdateWidget(old);
    if (old.id != widget.id) resetAll();
  }

  @override
  void dispose() {
    scroll.removeListener(_onScroll);
    scroll.dispose();
    search.dispose();
    super.dispose();
  }

  void resetAll() {
    page = 1;
    dishes.clear();
    search.clear();
    diet = 'all';
    available = false;
    withPhoto = false;
    sort = 'recommended';
    selected.clear();
    reachedEnd = false;
    load(reset: true);
  }

  /// Loads one page. [reset] clears accumulated dishes, otherwise they append.
  Future<void> load({bool reset = false}) async {
    if (reset) {
      loading = true;
      loadingMore = false;
      error = null;
      dishes.clear();
      reachedEnd = false;
    } else {
      if (loadingMore || reachedEnd) return;
      loadingMore = true;
    }
    final requestId = ++_requestId;
    if (mounted) setState(() {});
    try {
      final result = await context.read<Repository>().menu(
            widget.id,
            page: page,
            pageSize: _batch,
            diet: diet,
            available: available,
            withPhoto: withPhoto,
            sort: sort,
            query: search.text.trim(),
          );
      if (!mounted || requestId != _requestId) return;
      setState(() {
        restaurant = result.restaurant;
        total = result.menu.total;
        if (reset) dishes.clear();
        dishes.addAll(result.menu.items);
        loading = false;
        loadingMore = false;
        error = null;
        // A short page means the server has nothing further to send.
        reachedEnd = dishes.length >= total || result.menu.items.isEmpty;
      });
    } catch (e) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        loading = false;
        loadingMore = false;
        error = e.toString();
      });
    }
  }

  void _onScroll() {
    if (!infiniteScroll || !scroll.hasClients) return;
    // Prefetch a screenful early so the next batch has usually landed before
    // the user reaches the bottom, which keeps scrolling continuous.
    final remaining = scroll.position.maxScrollExtent - scroll.position.pixels;
    if (remaining < 1200) {
      if (!loadingMore && !reachedEnd && !loading && error == null) {
        page += 1;
        load();
      }
    }
  }

  /// Any filter change invalidates paging, so start again from page one.
  void applyFilters() {
    page = 1;
    reachedEnd = false;
    selected.clear();
    load(reset: true);
  }

  void _message(String value) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(value)),
      );

  Future<void> _createDish() async {
    final data = await _dishForm(context);
    if (data == null || !mounted) return;
    try {
      await context.read<Repository>().createAdminDish(widget.id, data);
      if (!mounted) return;
      setState(() {
        page = 1;
        selected.clear();
      });
      await load(reset: true);
      _message('Dish added to the menu.');
    } catch (error) {
      _message('Could not add dish: $error');
    }
  }

  Future<void> _setDishAvailability(MenuItem item, bool available) async {
    try {
      await context.read<Repository>().setDishAvailability(item.id, available);
      if (!mounted) return;
      setState(() {
        page = 1;
        selected.clear();
      });
      await load(reset: true);
      _message(available ? 'Dish is available.' : 'Dish is not available.');
    } catch (error) {
      _message('Could not update dish availability: $error');
    }
  }

  Future<void> _deleteDish(MenuItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete dish?'),
        content: Text('Delete ${item.name} from this menu? Dishes used in order history cannot be deleted; mark them unavailable instead.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Keep dish')),
          FilledButton.tonal(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await context.read<Repository>().deleteAdminDish(item.id);
      if (!mounted) return;
      setState(() {
        page = 1;
        selected.clear();
      });
      await load(reset: true);
      _message('Dish deleted.');
    } catch (error) {
      _message('Could not delete dish: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = restaurant;
    final isAdmin = context.watch<AuthStore>().user?.isAdmin ?? false;
    if (loading && r == null)
      return const Scaffold(body: PageBody(child: LoadingBlock()));

    return Scaffold(
      body: SingleChildScrollView(
        controller: scroll,
        child: PageBody(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextButton.icon(
                onPressed: () => context.go('/restaurants'),
                icon: const Icon(Icons.arrow_back),
                label: const Text('All restaurants'),
              ),
              const SizedBox(height: 20),
              if (r != null) _header(r),
              const SizedBox(height: 30),
              SectionHeading(
                'Made for your mood.',
                subtitle:
                    '$total dishes & portions · Choose a regular or sharing portion.',
                action: isAdmin
                    ? Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton.icon(
                          onPressed: _createDish,
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Add dish'),
                        ),
                      )
                    : null,
              ),
              _filters(),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text('Enable infinite scroll'),
                subtitle: const Text('Load the next dish page as you scroll.'),
                value: infiniteScroll,
                onChanged: (value) => setState(() => infiniteScroll = value ?? false),
              ),
              const SizedBox(height: 20),
              if (error != null)
                Column(
                  children: [
                    ErrorBanner(error!),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => load(reset: dishes.isEmpty),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Retry'),
                      ),
                    ),
                  ],
                )
              else if (_notice != null) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: Text(
                    _notice!,
                    style: const TextStyle(color: QB.green, fontSize: 13),
                  ),
                ),
              ]
              else if (dishes.isEmpty && !loading)
                const StateMessage(
                  title: 'No dishes match',
                  message: 'Try clearing the filters or searching another dish.',
                )
              else ...[
                ResponsiveCards(
                  children: dishes
                      .map(
                        (item) => DishCard(
                          key: ValueKey(item.id),
                          item: item,
                          selected: selected.contains(item.id),
                          showAdminControls: isAdmin,
                          onAvailabilityChanged: isAdmin
                              ? (value) => _setDishAvailability(item, value)
                              : null,
                          onDelete: isAdmin ? () => _deleteDish(item) : null,
                          onSelect: (v) => setState(() => v
                              ? selected.add(item.id)
                              : selected.remove(item.id)),
                          onAdd: isAdmin
                              ? null
                              : () => (restaurant?.available ?? false)
                                  ? context.read<CartStore>().add(item)
                                  : 'This restaurant is currently unavailable.',
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 26),
                if (loadingMore) const LoadingBlock(),
                if (!loadingMore && reachedEnd && dishes.isNotEmpty)
                  Center(
                    child: Text(
                      'You have reached the end · ${dishes.length} of $total dishes',
                      style: const TextStyle(color: QB.muted, fontSize: 12),
                    ),
                  ),
              ],
              if (total > _batch)
                Pagination(
                  page: page,
                  total: total,
                  pageSize: _batch,
                  loadedCount: dishes.length,
                  onPage: (v) {
                    setState(() {
                      page = v;
                      reachedEnd = false;
                      selected.clear();
                    });
                    load(reset: true);
                    if (scroll.hasClients) scroll.jumpTo(0);
                  },
                ),
              if (selected.isNotEmpty) _selectionBar(),
            ],
          ),
        ),
      ),
    );
  }

  /// Bulk bar for checkbox selection. Adds every checked dish at once, which
  /// matters with 100 dishes per kitchen where one-by-one tapping is painful.
  Widget _selectionBar() {
    final chosen = dishes.where((d) => selected.contains(d.id)).toList();
    final unavailable = chosen.where((d) => !d.available).length;
    final isAdmin = context.read<AuthStore>().user?.isAdmin ?? false;
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: GlassCard(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${chosen.length} dish${chosen.length == 1 ? '' : 'es'} selected',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isAdmin
                        ? 'Selected from this restaurant menu.'
                        : unavailable == 0
                            ? 'Add them all to your cart in one go.'
                            : '$unavailable currently unavailable and will be skipped.',
                    style: const TextStyle(color: QB.muted, fontSize: 12),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => setState(selected.clear),
              child: const Text('Clear'),
            ),
            const SizedBox(width: 8),
            if (!isAdmin)
              FilledButton(
                onPressed: () => addSelected(),
                child: const Text('Add to cart'),
              ),
          ],
        ),
      ),
    );
  }

  void addSelected() {
    final cart = context.read<CartStore>();
    final chosen = dishes.where((d) => selected.contains(d.id)).toList();
    var added = 0;
    String? blocked;
    for (final item in chosen) {
      // add() returns a reason string when it refuses, e.g. a different
      // restaurant is already in the cart.
      final reason = cart.add(item);
      if (reason == null) {
        added++;
      } else {
        blocked = reason;
      }
    }
    setState(() {
      _cartVersion++;
      selected.clear();
      _notice = added == 0
          ? blocked ?? 'Nothing could be added.'
          : '$added added to your cart${blocked == null ? '' : ' · $blocked'}';
    });
  }

  Widget _header(Restaurant r) => GlassCard(
        child: LayoutBuilder(
          builder: (context, c) {
            final copy = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${cuisineEmoji[r.cuisine] ?? '🍽️'}  ${r.cuisine.toUpperCase()}',
                  style: const TextStyle(
                    color: QB.green,
                    letterSpacing: 1.5,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  r.name,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  r.description,
                  style: const TextStyle(color: QB.muted),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 18,
                  runSpacing: 10,
                  children: [
                    Text(
                      '★ ${r.rating}',
                      style: const TextStyle(
                        color: QB.green,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text('~${r.etaMinutes} min',
                        style: const TextStyle(color: QB.muted)),
                    Text(
                      r.available ? 'Open for orders' : 'Currently unavailable',
                      style: const TextStyle(color: QB.gold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Fictional demo kitchen · Illustrative imagery',
                  style: TextStyle(fontSize: 10, color: QB.muted),
                ),
              ],
            );
            return c.maxWidth > 620
                ? Row(
                    children: [
                      Expanded(flex: 3, child: copy),
                      const SizedBox(width: 32),
                      Expanded(
                        flex: 2,
                        child: FoodImage(r.image, height: 210, cuisine: r.cuisine),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      copy,
                      const SizedBox(height: 22),
                      FoodImage(r.image, height: 200, cuisine: r.cuisine),
                    ],
                  );
          },
        ),
      );

  Widget _filters() => GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: search,
              onSubmitted: (_) => applyFilters(),
              decoration: InputDecoration(
                hintText: 'Search this menu…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  tooltip: 'Search',
                  onPressed: applyFilters,
                  icon: const Icon(Icons.arrow_forward),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Horizontal scroll keeps every segment label on a single
                // line on narrow phone screens (otherwise the labels wrap
                // into unreadable vertical text).
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'all',
                        label: Text('All'),
                        icon: Icon(Icons.restaurant, size: 16),
                      ),
                      ButtonSegment(
                        value: 'veg',
                        label: Text('Veg'),
                        icon: Icon(Icons.eco, size: 16),
                      ),
                      ButtonSegment(
                        value: 'non_veg',
                        label: Text('Non-veg'),
                        icon: Icon(Icons.set_meal, size: 16),
                      ),
                    ],
                    selected: {diet},
                    showSelectedIcon: false,
                    onSelectionChanged: (v) {
                      setState(() => diet = v.first);
                      applyFilters();
                    },
                  ),
                ),
                FilterChip(
                  label: const Text('With photo'),
                  avatar: const Icon(Icons.photo_camera_outlined, size: 18),
                  selected: withPhoto,
                  onSelected: (v) {
                    setState(() => withPhoto = v);
                    applyFilters();
                  },
                ),
                const SizedBox(width: 4),
                // A dropdown instead of a 6-way SegmentedButton: the
                // segmented version squeezed every label into vertical
                // letter columns on phone-width screens.
                InputDecorator(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: sort,
                      isDense: true,
                      items: const [
                        DropdownMenuItem(
                          value: 'photo_first',
                          child: Text('With photo first'),
                        ),
                        DropdownMenuItem(
                          value: 'recommended',
                          child: Text('Recommended'),
                        ),
                        DropdownMenuItem(value: 'name', child: Text('A–Z')),
                        DropdownMenuItem(value: 'price_asc', child: Text('₹ low')),
                        DropdownMenuItem(value: 'price_desc', child: Text('₹ high')),
                        DropdownMenuItem(value: 'veg_first', child: Text('Veg first')),
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => sort = v);
                        applyFilters();
                      },
                    ),
                  ),
                ),
                if (dishes.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      search.clear();
                      setState(() {
                        diet = 'all';
                        available = false;
                        withPhoto = false;
                        sort = 'recommended';
                      });
                      applyFilters();
                    },
                    child: const Text('Clear filters'),
                  ),
              ],
            ),
            if (dishes.isNotEmpty) ...[
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text('Select loaded dishes (${dishes.length})'),
                value: dishes.isNotEmpty && dishes.every((d) => selected.contains(d.id)),
                onChanged: (value) => setState(() {
                  if (value == true) {
                    selected.addAll(dishes.map((d) => d.id));
                  } else {
                    selected.removeAll(dishes.map((d) => d.id));
                  }
                }),
              ),
              const SizedBox(height: 12),
              Text(
                'Showing ${dishes.length} of $total dishes',
                style: const TextStyle(color: QB.muted, fontSize: 12),
              ),
            ],
          ],
        ),
      );
}

Future<Json?> _restaurantForm(BuildContext context) async {
  final name = TextEditingController();
  final cuisine = TextEditingController();
  final description = TextEditingController();
  final image = TextEditingController();
  final eta = TextEditingController(text: '30');
  final form = GlobalKey<FormState>();
  try {
    return await showDialog<Json>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add restaurant'),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Form(
              key: form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _adminField(name, 'Restaurant name', required: true),
                  _adminField(cuisine, 'Cuisine', required: true),
                  _adminField(description, 'Description', required: true, maxLines: 3),
                  _adminField(image, 'Image asset path (optional)', hint: 'Leave blank to use the cuisine image'),
                  _adminField(eta, 'Delivery time in minutes', required: true, numeric: true),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (form.currentState?.validate() != true) return;
              Navigator.pop(dialogContext, {
                'name': name.text.trim(),
                'cuisine': cuisine.text.trim(),
                'description': description.text.trim(),
                'image': image.text.trim(),
                'eta_minutes': int.parse(eta.text.trim()),
                'available': true,
              });
            },
            child: const Text('Add restaurant'),
          ),
        ],
      ),
    );
  } finally {
    name.dispose();
    cuisine.dispose();
    description.dispose();
    image.dispose();
    eta.dispose();
  }
}

Future<Json?> _dishForm(BuildContext context) async {
  final name = TextEditingController();
  final description = TextEditingController();
  final price = TextEditingController();
  final image = TextEditingController();
  final form = GlobalKey<FormState>();
  var vegetarian = true;
  try {
    return await showDialog<Json>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Add dish'),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Form(
                key: form,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _adminField(name, 'Dish name', required: true),
                    _adminField(description, 'Description', required: true, maxLines: 3),
                    _adminField(price, 'Price in rupees', required: true, numeric: true, decimal: true),
                    _adminField(image, 'Image asset path (optional)', hint: 'Leave blank to use matching dish artwork'),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Vegetarian'),
                      value: vegetarian,
                      onChanged: (value) => setDialogState(() => vegetarian = value ?? false),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                if (form.currentState?.validate() != true) return;
                Navigator.pop(dialogContext, {
                  'name': name.text.trim(),
                  'description': description.text.trim(),
                  'price_minor': (double.parse(price.text.trim()) * 100).round(),
                  'image': image.text.trim(),
                  'vegetarian': vegetarian,
                  'available': true,
                });
              },
              child: const Text('Add dish'),
            ),
          ],
        ),
      ),
    );
  } finally {
    name.dispose();
    description.dispose();
    price.dispose();
    image.dispose();
  }
}

Widget _adminField(
  TextEditingController controller,
  String label, {
  bool required = false,
  bool numeric = false,
  bool decimal = false,
  int maxLines = 1,
  String? hint,
}) => Padding(
  padding: const EdgeInsets.only(bottom: 12),
  child: TextFormField(
    controller: controller,
    maxLines: maxLines,
    keyboardType: numeric
        ? TextInputType.numberWithOptions(decimal: decimal)
        : TextInputType.text,
    decoration: InputDecoration(labelText: label, hintText: hint),
    validator: (value) {
      final text = value?.trim() ?? '';
      if (required && text.isEmpty) return 'Enter ${label.toLowerCase()}';
      if (numeric && text.isNotEmpty && (decimal ? double.tryParse(text) : int.tryParse(text)) == null) {
        return 'Enter a valid number';
      }
      if (decimal && double.tryParse(text) != null && double.parse(text) < 0) {
        return 'Price cannot be negative';
      }
      if (decimal && double.tryParse(text) != null && double.parse(text) > 100000) {
        return 'Price cannot exceed ₹100,000';
      }
      if (!decimal && numeric && int.tryParse(text) != null && int.parse(text) < 5) {
        return 'Enter at least 5 minutes';
      }
      if (!decimal && numeric && int.tryParse(text) != null && int.parse(text) > 240) {
        return 'Delivery time cannot exceed 240 minutes';
      }
      return null;
    },
  ),
);
