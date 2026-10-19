import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/ui.dart';
import 'cart_store.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartStore>();
    return SingleChildScrollView(
      child: PageBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeading(
              'Your delicious decisions.',
              subtitle: 'One restaurant. All your favourites.',
            ),
            if (cart.restoring)
              const LoadingBlock()
            else if (cart.lines.isEmpty && cart.pending == null)
              StateMessage(
                title: 'Your cart is waiting',
                message: 'Discover a restaurant and add something delicious.',
                retry: () => context.go('/restaurants'),
                retryLabel: 'Explore restaurants',
                icon: Icons.shopping_bag_outlined,
              )
            else ...[
              if (cart.pending != null)
                const ErrorBanner(
                  'A checkout is awaiting confirmation. The saved request is locked so you can retry safely.',
                ),
              if (cart.error != null) ErrorBanner(cart.error!),
              ...cart.lines.map(
                (line) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: GlassCard(
                    child: LayoutBuilder(
                      builder: (context, c) => Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 20,
                        runSpacing: 16,
                        children: [
                          SizedBox(
                            width: 100,
                            child: FoodImage(line.item.image, height: 90, dishName: line.item.name),
                          ),
                          SizedBox(
                            width: c.maxWidth > 600
                                ? c.maxWidth - 360
                                : c.maxWidth - 120,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  line.item.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${money(line.item.priceMinor)} each',
                                  style: const TextStyle(color: QB.muted),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Decrease ${line.item.name}',
                                onPressed: cart.locked
                                    ? null
                                    : () => cart.quantity(
                                        line.item.id,
                                        line.quantity - 1,
                                      ),
                                icon: const Icon(Icons.remove_circle_outline),
                              ),
                              Text(
                                '${line.quantity}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              IconButton(
                                tooltip: 'Increase ${line.item.name}',
                                onPressed: cart.locked || line.quantity >= 20
                                    ? null
                                    : () => cart.quantity(
                                        line.item.id,
                                        line.quantity + 1,
                                      ),
                                icon: const Icon(Icons.add_circle_outline),
                              ),
                              IconButton(
                                tooltip: 'Remove ${line.item.name}',
                                onPressed: cart.locked
                                    ? null
                                    : () => cart.quantity(line.item.id, 0),
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: QB.muted,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            money(line.item.priceMinor * line.quantity),
                            style: const TextStyle(
                              color: QB.gold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 30,
                      runSpacing: 14,
                      children: [
                        const Text('Subtotal', style: TextStyle(fontSize: 20)),
                        Text(
                          money(cart.subtotal),
                          style: const TextStyle(
                            color: QB.gold,
                            fontSize: 26,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Prices are confirmed by the server when your order is accepted. No real payment will be taken.',
                      style: TextStyle(color: QB.muted),
                    ),
                    const SizedBox(height: 22),
                    FilledButton.icon(
                      onPressed: () => context.go('/checkout'),
                      icon: const Icon(Icons.arrow_forward),
                      label: Text(
                        cart.pending == null
                            ? 'Continue to Checkout'
                            : 'Resolve saved checkout',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});
  @override
  State<CheckoutScreen> createState() => _CheckoutState();
}

class _CheckoutState extends State<CheckoutScreen> {
  final form = GlobalKey<FormState>();
  late final TextEditingController address;
  @override
  void initState() {
    super.initState();
    address = TextEditingController(text: context.read<CartStore>().address);
  }

  @override
  void dispose() {
    address.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    final cart = context.read<CartStore>();
    if (cart.pending == null && !form.currentState!.validate()) return;
    cart.setAddress(address.text);
    final receipt = await cart.submit();
    if (mounted && receipt != null)
      context.go('/accepted/${receipt.orderId}', extra: receipt);
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartStore>();
    return SingleChildScrollView(
      child: PageBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeading(
              'One last detail.',
              subtitle: 'Tell us where your next great bite belongs.',
            ),
            if (cart.lines.isEmpty && cart.pending == null)
              StateMessage(
                title: 'Your cart is empty',
                message: 'Choose your food before checking out.',
                retry: () => context.go('/restaurants'),
                retryLabel: 'Explore restaurants',
              )
            else
              GlassCard(
                child: Form(
                  key: form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (cart.error != null) ErrorBanner(cart.error!),
                      if (cart.pending != null) ...[
                        const ErrorBanner(
                          'The outcome of your saved checkout is not yet confirmed. Retry uses the same request and key.',
                        ),
                        SelectableText(
                          'Reference: ${cart.pending!['key']}',
                          style: const TextStyle(color: QB.muted, fontSize: 12),
                        ),
                        const SizedBox(height: 20),
                      ],
                      TextFormField(
                        controller: address,
                        enabled: !cart.locked,
                        maxLines: 3,
                        maxLength: 500,
                        textInputAction: TextInputAction.newline,
                        decoration: const InputDecoration(
                          labelText: 'Delivery address',
                          hintText:
                              'Building / flat, street, area, city and postal code',
                        ),
                        validator: (v) => (v?.trim().length ?? 0) < 10
                            ? 'Enter a complete address (at least 10 characters).'
                            : null,
                        onChanged: cart.setAddress,
                      ),
                      const SizedBox(height: 22),
                      Text(
                        '${cart.count} items  ·  ${money(cart.subtotal)}',
                        style: const TextStyle(
                          color: QB.gold,
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Payment is simulated. Your order is accepted first, then processed in the background. Final prices come from the restaurant’s current menu.',
                        style: TextStyle(color: QB.muted),
                      ),
                      const SizedBox(height: 26),
                      Wrap(
                        spacing: 16,
                        runSpacing: 14,
                        children: [
                          FilledButton.icon(
                            onPressed: cart.busy || cart.restoring
                                ? null
                                : submit,
                            icon: const Icon(Icons.check_circle_outline),
                            label: Text(
                              cart.busy
                                  ? 'Confirming acceptance…'
                                  : cart.pending != null
                                  ? 'Retry saved checkout'
                                  : 'Place Order',
                            ),
                          ),
                          OutlinedButton(
                            onPressed: cart.busy
                                ? null
                                : () => context.go('/cart'),
                            child: const Text('Back to cart'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
