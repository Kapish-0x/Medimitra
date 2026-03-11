import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers/cart_provider.dart';
import 'cart_screen.dart';

class MedicinesTab extends StatefulWidget {
  const MedicinesTab({super.key});
  @override
  State<MedicinesTab> createState() => _MedicinesTabState();
}

class _MedicinesTabState extends State<MedicinesTab> {
  List _medicines = [];
  List<String> _categories = ['All'];
  String _selectedCategory = 'All';
  String _searchQuery = '';
  bool _loading = true;
  bool _searching = false;
  int _page = 1;
  int _totalPages = 1;
  final _searchCtrl = TextEditingController();

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _load({bool reset = true}) async {
    if (reset) { setState(() { _loading = true; _page = 1; }); }
    try {
      final params = <String, dynamic>{'page': _page, 'limit': 20};
      if (_searchQuery.isNotEmpty) params['search'] = _searchQuery;
      if (_selectedCategory != 'All') params['category'] = _selectedCategory;

      final res = await ApiClient.instance.dio.get('/medicines', queryParameters: params);
      final meds = List.from(res.data['medicines'] ?? []);
      setState(() {
        _medicines = reset ? meds : [..._medicines, ...meds];
        _totalPages = res.data['pages'] ?? 1;
        _loading = false;
        _searching = false;
      });

      // Load categories once
      if (_categories.length <= 1) {
        final catRes = await ApiClient.instance.dio.get('/medicines/categories');
        setState(() => _categories = List<String>.from(catRes.data['categories'] ?? ['All']));
      }
    } catch (_) { setState(() { _loading = false; _searching = false; }); }
  }

  void _onSearch(String q) {
    setState(() { _searchQuery = q; _searching = true; });
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_searchQuery == q) _load();
    });
  }

  void _onCategory(String c) {
    setState(() => _selectedCategory = c);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Medicines'),
        actions: [
          Padding(padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())),
              child: Stack(children: [
                const Padding(padding: EdgeInsets.all(8),
                  child: Icon(Icons.shopping_cart_outlined, color: AppTheme.textDark, size: 26)),
                if (cart.itemCount > 0) Positioned(right: 4, top: 4, child: Container(
                  width: 18, height: 18,
                  decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
                  child: Center(child: Text('${cart.itemCount}',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700))))),
              ]),
            )),
        ],
      ),
      body: Column(children: [
        // Search bar
        Padding(padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: Container(height: 46,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.divider)),
            child: Row(children: [
              const SizedBox(width: 14),
              const Icon(Icons.search_rounded, color: AppTheme.textLight, size: 20),
              const SizedBox(width: 10),
              Expanded(child: TextField(
                controller: _searchCtrl,
                onChanged: _onSearch,
                style: const TextStyle(fontSize: 14, color: AppTheme.textDark),
                decoration: const InputDecoration(
                  hintText: 'Search medicines, brands...',
                  border: InputBorder.none, filled: false, fillColor: Colors.transparent, contentPadding: EdgeInsets.zero,
                ),
              )),
              if (_searchQuery.isNotEmpty) GestureDetector(
                onTap: () { _searchCtrl.clear(); _onSearch(''); },
                child: const Padding(padding: EdgeInsets.only(right: 12),
                  child: Icon(Icons.close_rounded, color: AppTheme.textLight, size: 18)),
              ),
              if (_searching) const Padding(padding: EdgeInsets.only(right: 12),
                child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary))),
            ]),
          )),
        const SizedBox(height: 12),

        // Categories
        SizedBox(height: 36, child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: _categories.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final sel = _selectedCategory == _categories[i];
            return GestureDetector(
              onTap: () => _onCategory(_categories[i]),
              child: AnimatedContainer(duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: sel ? AppTheme.primary : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: sel ? AppTheme.primary : AppTheme.divider)),
                child: Center(child: Text(_categories[i],
                  style: TextStyle(color: sel ? Colors.white : AppTheme.textMid, fontWeight: FontWeight.w600, fontSize: 13))),
              ),
            );
          },
        )),
        const SizedBox(height: 12),

        // Results count
        if (!_loading) Padding(padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            Text('${_medicines.length} medicines', style: const TextStyle(fontSize: 13, color: AppTheme.textLight, fontWeight: FontWeight.w500)),
            const Spacer(),
            if (_searchQuery.isNotEmpty) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: AppTheme.accentSoft, borderRadius: BorderRadius.circular(6)),
              child: Text('Results for "$_searchQuery"', style: const TextStyle(fontSize: 11, color: AppTheme.primary, fontWeight: FontWeight.w600))),
          ])),
        const SizedBox(height: 8),

        // Grid
        Expanded(child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
            : _medicines.isEmpty
                ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.medication_outlined, size: 64, color: AppTheme.divider),
                    const SizedBox(height: 12),
                    Text(_searchQuery.isNotEmpty ? 'No results for "$_searchQuery"' : 'No medicines available',
                      style: const TextStyle(color: AppTheme.textLight, fontSize: 15)),
                  ]))
                : RefreshIndicator(color: AppTheme.primary, onRefresh: () => _load(),
                    child: GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.7),
                      itemCount: _medicines.length,
                      itemBuilder: (_, i) => _MedCard(medicine: _medicines[i]),
                    ))),
      ]),
    );
  }
}

class _MedCard extends StatelessWidget {
  final dynamic medicine;
  const _MedCard({required this.medicine});

  Color get _catColor {
    switch (medicine['category']) {
      case 'Vitamins': return const Color(0xFF13A89E);
      case 'Antibiotics': return const Color(0xFF6C5CE7);
      case 'Cardiac': return const Color(0xFFE05C5C);
      case 'Diabetes': return const Color(0xFF0A6E6E);
      case 'Pain Relief': return const Color(0xFFFFA743);
      default: return AppTheme.textMid;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final id = medicine['_id'] ?? '';
    final inCart = cart.contains(id);
    final price = (medicine['price'] as num).toDouble();
    final origPrice = (medicine['originalPrice'] as num?)?.toDouble() ?? price;
    final discount = origPrice > price ? ((origPrice - price) / origPrice * 100).round() : 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: inCart ? AppTheme.primary : AppTheme.divider, width: inCart ? 1.5 : 1),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Image area
        Container(height: 100,
          decoration: BoxDecoration(
            color: _catColor.withOpacity(0.08),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15))),
          child: Stack(children: [
            Center(child: Icon(Icons.medication_rounded, size: 50, color: _catColor.withOpacity(0.4))),
            if (discount > 0) Positioned(top: 8, right: 8, child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(color: AppTheme.success, borderRadius: BorderRadius.circular(6)),
              child: Text('$discount% OFF', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)))),
            Positioned(top: 8, left: 8, child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(color: _catColor.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
              child: Text(medicine['category'] ?? '', style: TextStyle(color: _catColor, fontSize: 9, fontWeight: FontWeight.w600)))),
          ]),
        ),

        Padding(padding: const EdgeInsets.all(11), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(medicine['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textDark, height: 1.2), maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(medicine['brand'] ?? '', style: const TextStyle(fontSize: 11, color: AppTheme.textLight)),
          const SizedBox(height: 6),
          Row(children: [
            Text('₹${price.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.textDark)),
            if (origPrice > price) ...[
              const SizedBox(width: 5),
              Text('₹${origPrice.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, color: AppTheme.textLight, decoration: TextDecoration.lineThrough)),
            ],
          ]),
          const SizedBox(height: 8),

          // Cart controls
          if (inCart)
            Row(children: [
              Expanded(child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                GestureDetector(
                  onTap: () => context.read<CartProvider>().decrement(id),
                  child: Container(width: 28, height: 28,
                    decoration: BoxDecoration(color: AppTheme.divider, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.remove_rounded, size: 16, color: AppTheme.textDark)),
                ),
                Text('${cart.items[id]?.quantity ?? 0}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.textDark)),
                GestureDetector(
                  onTap: () => context.read<CartProvider>().increment(id),
                  child: Container(width: 28, height: 28,
                    decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.add_rounded, size: 16, color: Colors.white)),
                ),
              ])),
            ])
          else
            SizedBox(width: double.infinity, height: 34, child: ElevatedButton(
              onPressed: () => context.read<CartProvider>().addItem(
                id: id, name: medicine['name'], brand: medicine['brand'] ?? '',
                price: price, category: medicine['category'] ?? ''),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              child: const Text('Add to Cart', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            )),
        ])),
      ]),
    );
  }
}
