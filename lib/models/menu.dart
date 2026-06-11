import 'dart:convert';
import 'dart:typed_data';

/// Parses a price that the API sends as a string ("25000") or number.
int _price(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.round();
  return double.tryParse(v.toString())?.round() ?? 0;
}

class MenuCategory {
  final String id;
  final String name;
  final int sortOrder;
  MenuCategory(this.id, this.name, this.sortOrder);
  factory MenuCategory.fromJson(Map j) =>
      MenuCategory(j['id'] as String, (j['name'] ?? '') as String, (j['sortOrder'] as int?) ?? 0);
}

class MenuSize {
  final String id;
  final String code;
  final String name;
  MenuSize(this.id, this.code, this.name);
  factory MenuSize.fromJson(Map j) =>
      MenuSize(j['id'] as String, (j['code'] ?? '') as String, (j['name'] ?? '') as String);
}

class MenuTopping {
  final String id;
  final String name;
  final int price;
  MenuTopping(this.id, this.name, this.price);
  factory MenuTopping.fromJson(Map j) =>
      MenuTopping(j['id'] as String, (j['name'] ?? '') as String, _price(j['price']));
}

/// A purchasable size of a product (the API calls these "variants").
class ProductVariant {
  final String id;
  final String? sizeId;
  final String? sizeCode;
  final String? sizeName;
  final int price;
  final bool isDefault;
  ProductVariant(this.id, this.sizeId, this.sizeCode, this.sizeName, this.price, this.isDefault);
  factory ProductVariant.fromJson(Map j) => ProductVariant(
        j['id'] as String,
        j['sizeId'] as String?,
        j['sizeCode'] as String?,
        j['sizeName'] as String?,
        _price(j['price']),
        (j['isDefault'] as bool?) ?? false,
      );
}

class MenuProduct {
  final String id;
  final String? categoryId;
  final String name;
  final String? description;
  final int basePrice;
  final bool available;
  final bool hasModifiers;
  final bool isFeatured;
  final String? tag;
  final String? imageRaw; // base64 (possibly a data: URI)
  final List<ProductVariant> variants;
  final List<String> toppingIds; // product-allowed toppings (may be empty = all)

  MenuProduct({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.basePrice,
    required this.available,
    required this.hasModifiers,
    required this.isFeatured,
    required this.tag,
    required this.imageRaw,
    required this.variants,
    required this.toppingIds,
  });

  factory MenuProduct.fromJson(Map j) {
    final tops = (j['toppings'] as List?) ?? const [];
    return MenuProduct(
      id: j['id'] as String,
      categoryId: j['categoryId'] as String?,
      name: (j['name'] ?? '') as String,
      description: j['description'] as String?,
      basePrice: _price(j['basePrice']),
      available: (j['available'] as bool?) ?? true,
      hasModifiers: (j['hasModifiers'] as bool?) ?? false,
      isFeatured: (j['isFeatured'] as bool?) ?? false,
      tag: j['tag'] as String?,
      imageRaw: j['image'] as String?,
      variants: ((j['variants'] as List?) ?? const [])
          .map((e) => ProductVariant.fromJson(e as Map))
          .toList(),
      toppingIds: tops
          .map((e) => e is Map ? (e['id'] ?? e['toppingId']) : e)
          .where((e) => e != null)
          .map((e) => e.toString())
          .toList(),
    );
  }

  ProductVariant? get defaultVariant =>
      variants.isEmpty ? null : variants.firstWhere((v) => v.isDefault, orElse: () => variants.first);

  /// Lowest sellable price (for the grid).
  int get displayPrice {
    if (variants.isEmpty) return basePrice;
    return variants.map((v) => v.price).reduce((a, b) => a < b ? a : b);
  }

  /// Decoded image bytes (cached) — null if the product has no image.
  static final Map<String, Uint8List?> _imgCache = {};
  Uint8List? get imageBytes {
    if (imageRaw == null || imageRaw!.isEmpty) return null;
    if (_imgCache.containsKey(id)) return _imgCache[id];
    Uint8List? bytes;
    try {
      var s = imageRaw!;
      final comma = s.indexOf(',');
      if (s.startsWith('data:') && comma >= 0) s = s.substring(comma + 1);
      bytes = base64Decode(s);
    } catch (_) {
      bytes = null;
    }
    _imgCache[id] = bytes;
    return bytes;
  }
}

/// The full POS menu (GET /pos/menu).
class Menu {
  final List<MenuCategory> categories;
  final List<MenuSize> sizes;
  final List<MenuTopping> toppings;
  final List<MenuProduct> products;
  Menu(this.categories, this.sizes, this.toppings, this.products);

  factory Menu.fromJson(Map j) => Menu(
        ((j['categories'] as List?) ?? const []).map((e) => MenuCategory.fromJson(e as Map)).toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)),
        ((j['sizes'] as List?) ?? const []).map((e) => MenuSize.fromJson(e as Map)).toList(),
        ((j['toppings'] as List?) ?? const []).map((e) => MenuTopping.fromJson(e as Map)).toList(),
        ((j['products'] as List?) ?? const []).map((e) => MenuProduct.fromJson(e as Map)).toList(),
      );

  List<MenuProduct> byCategory(String? categoryId) =>
      categoryId == null ? products : products.where((p) => p.categoryId == categoryId).toList();

  MenuTopping? topping(String id) {
    for (final t in toppings) {
      if (t.id == id) return t;
    }
    return null;
  }
}
