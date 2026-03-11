import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/cart_provider.dart';
import '../../../core/network/api_client.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});
  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _placing = false;
  String _payment = 'COD';

  Future<void> _checkout() async {
    final cart = context.read<CartProvider>();
    if (cart.itemCount == 0) return;

    setState(() => _placing = true);
    try {
      await ApiClient.instance.dio.post('/orders', data: {
        'items': cart.toOrderItems(),
        'paymentMethod': _payment,
        'deliveryAddress': {'line1': '123 Main St', 'city': 'Bangalore', 'state': 'Karnataka', 'pincode': '560001'},
      });
      cart.clear();
      if (mounted) {
        Navigator.pop(context);
        showDialog(context: context, builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 64, height: 64,
              decoration: BoxDecoration(color: AppTheme.accentSoft, shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded, color: AppTheme.primary, size: 36)),
            const SizedBox(height: 16),
            const Text('Order Placed!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textDark)),
            const SizedBox(height: 8),
            const Text('Your medicines will be delivered in 3 business days.', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textMid, fontSize: 14)),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Great!'),
            )),
          ]),
        ));
      }
    } catch (_) {
      setState(() => _placing = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Failed to place order. Try again.'), backgroundColor: AppTheme.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('Cart (${cart.totalQty})'),
        leading: GestureDetector(onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_ios_new_rounded, size: 20)),
        actions: [
          if (cart.itemCount > 0) TextButton(
            onPressed: () => showDialog(context: context, builder: (_) => AlertDialog(
              title: const Text('Clear Cart?'),
              content: const Text('Remove all items from cart?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                TextButton(onPressed: () { cart.clear(); Navigator.pop(context); }, child: const Text('Clear', style: TextStyle(color: AppTheme.error))),
              ],
            )),
            child: const Text('Clear', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
      body: cart.itemCount == 0
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.shopping_cart_outlined, size: 80, color: AppTheme.divider),
              const SizedBox(height: 16),
              const Text('Your cart is empty', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textMid)),
              const SizedBox(height: 8),
              const Text('Browse medicines and add to cart', style: TextStyle(color: AppTheme.textLight)),
              const SizedBox(height: 24),
              ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Browse Medicines')),
            ]))
          : Column(children: [
              // Items list
              Expanded(child: ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: cart.itemList.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) {
                  final item = cart.itemList[i];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.divider)),
                    child: Row(children: [
                      Container(width: 52, height: 52,
                        decoration: BoxDecoration(color: AppTheme.accentSoft, borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.medication_rounded, color: AppTheme.primary, size: 28)),
                      const SizedBox(width: 14),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(item.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textDark)),
                        Text(item.brand, style: const TextStyle(fontSize: 12, color: AppTheme.textLight)),
                        const SizedBox(height: 4),
                        Text('₹${item.price.toStringAsFixed(0)} × ${item.quantity} = ₹${item.total.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.primary)),
                      ])),
                      Column(children: [
                        Row(children: [
                          GestureDetector(
                            onTap: () => context.read<CartProvider>().decrement(item.id),
                            child: Container(width: 28, height: 28,
                              decoration: BoxDecoration(color: AppTheme.divider, borderRadius: BorderRadius.circular(8)),
                              child: const Icon(Icons.remove_rounded, size: 16, color: AppTheme.textDark)),
                          ),
                          Padding(padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15))),
                          GestureDetector(
                            onTap: () => context.read<CartProvider>().increment(item.id),
                            child: Container(width: 28, height: 28,
                              decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(8)),
                              child: const Icon(Icons.add_rounded, size: 16, color: Colors.white)),
                          ),
                        ]),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => context.read<CartProvider>().removeItem(item.id),
                          child: const Icon(Icons.delete_outline_rounded, color: AppTheme.error, size: 20)),
                      ]),
                    ]),
                  );
                },
              )),

              // Order summary
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, -4))],
                ),
                child: Column(children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Subtotal', style: TextStyle(color: AppTheme.textMid, fontSize: 14)),
                    Text('₹${cart.subtotal.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.textDark)),
                  ]),
                  const SizedBox(height: 6),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Delivery', style: TextStyle(color: AppTheme.textMid, fontSize: 14)),
                    const Text('FREE', style: TextStyle(color: AppTheme.success, fontWeight: FontWeight.w700, fontSize: 14)),
                  ]),
                  const SizedBox(height: 12),
                  const Divider(color: AppTheme.divider),
                  const SizedBox(height: 12),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Total', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppTheme.textDark)),
                    Text('₹${cart.total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: AppTheme.primary)),
                  ]),
                  const SizedBox(height: 16),

                  // Payment selector
                  Row(children: ['COD', 'UPI', 'Card'].map((p) {
                    final sel = _payment == p;
                    return Expanded(child: GestureDetector(
                      onTap: () => setState(() => _payment = p),
                      child: AnimatedContainer(duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: sel ? AppTheme.primary : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: sel ? AppTheme.primary : AppTheme.divider)),
                        child: Text(p, textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: sel ? Colors.white : AppTheme.textMid))),
                    ));
                  }).toList()),
                  const SizedBox(height: 16),

                  SizedBox(width: double.infinity, height: 54, child: ElevatedButton(
                    onPressed: _placing ? null : _checkout,
                    child: _placing
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                        : const Text('Place Order', style: TextStyle(fontSize: 17)),
                  )),
                ]),
              ),
            ]),
    );
  }
}
