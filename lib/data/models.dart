// Plain data models mirroring the seed structures in `tinypos.html`.

enum Role { cashier, kds, admin }

class Category {
  final String id;
  final String name;
  final String emoji;
  const Category(this.id, this.name, this.emoji);
}

class Product {
  String id;
  String name;
  String cat;
  int price;
  String emoji;
  bool opt;
  bool sold;
  Product({
    required this.id,
    required this.name,
    required this.cat,
    required this.price,
    required this.emoji,
    this.opt = false,
    this.sold = false,
  });
}

/// A selectable option with an optional surcharge (size / topping).
class PriceOption {
  final String name;
  final int price;
  final bool def;
  const PriceOption(this.name, {this.price = 0, this.def = false});
}

/// The per-line modifier selection (size / sugar / ice / toppings / note).
class ModSel {
  final String? size;
  final String? sugar;
  final String? ice;
  final List<String> tops;
  final String note;
  final int extra;
  const ModSel({
    this.size,
    this.sugar,
    this.ice,
    this.tops = const [],
    this.note = '',
    this.extra = 0,
  });

  Map<String, dynamic> toJson() => {
        'size': size,
        'sugar': sugar,
        'ice': ice,
        'tops': tops,
        'note': note,
        'extra': extra,
      };

  factory ModSel.fromJson(Map<String, dynamic> j) => ModSel(
        size: j['size'] as String?,
        sugar: j['sugar'] as String?,
        ice: j['ice'] as String?,
        tops: (j['tops'] as List?)?.map((e) => e as String).toList() ?? const [],
        note: (j['note'] as String?) ?? '',
        extra: (j['extra'] as int?) ?? 0,
      );

  /// Human-readable modifier summary — port of `modText(o)`.
  String get text {
    final hasAny = (size != null && size!.isNotEmpty) ||
        (sugar != null && sugar!.isNotEmpty) ||
        (ice != null && ice!.isNotEmpty) ||
        tops.isNotEmpty ||
        note.isNotEmpty;
    if (!hasAny) return '';
    final parts = <String>[];
    if (size != null && size!.isNotEmpty) parts.add(size!);
    if (sugar != null && sugar!.isNotEmpty) parts.add('$sugar đường');
    if (ice != null && ice!.isNotEmpty) parts.add('$ice đá');
    if (tops.isNotEmpty) parts.add('+ ${tops.join(', ')}');
    var s = parts.join(' · ');
    if (note.isNotEmpty) s += '${s.isNotEmpty ? ' · ' : ''}“$note”';
    return s;
  }
}

class CartLine {
  final String lid;
  final String pid;
  final String name;
  final String emoji;
  final int price;
  int qty;
  final ModSel mods;
  final String station; // 'bar' | 'kitchen'
  final String? variantId; // API variant (for real bill creation)
  final List<String> toppingIds;
  CartLine({
    required this.lid,
    required this.pid,
    required this.name,
    required this.emoji,
    required this.price,
    required this.qty,
    required this.mods,
    required this.station,
    this.variantId,
    this.toppingIds = const [],
  });

  Map<String, dynamic> toJson() => {
        'lid': lid,
        'pid': pid,
        'name': name,
        'emoji': emoji,
        'price': price,
        'qty': qty,
        'mods': mods.toJson(),
        'station': station,
        'variantId': ?variantId,
        'toppingIds': toppingIds,
      };

  factory CartLine.fromJson(Map<String, dynamic> j) => CartLine(
        lid: j['lid'] as String,
        pid: j['pid'] as String,
        name: j['name'] as String,
        emoji: j['emoji'] as String,
        price: j['price'] as int,
        qty: j['qty'] as int,
        mods: ModSel.fromJson(Map<String, dynamic>.from(j['mods'] as Map)),
        station: j['station'] as String,
        variantId: j['variantId'] as String?,
        toppingIds: ((j['toppings'] as List?) ?? (j['toppingIds'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(),
      );
}

class Order {
  final String code;
  final String type; // 'dinein' | 'takeaway'
  final String? table;
  final int items;
  final int total;
  final String pay; // cash | qr | card | momo
  final String status; // done | void | pending
  final int min;
  Order(this.code, this.type, this.table, this.items, this.total, this.pay, this.status, this.min);

  Map<String, dynamic> toJson() =>
      {'code': code, 'type': type, 'table': table, 'items': items, 'total': total, 'pay': pay, 'status': status, 'min': min};

  factory Order.fromJson(Map<String, dynamic> j) => Order(
        j['code'] as String,
        j['type'] as String,
        j['table'] as String?,
        j['items'] as int,
        j['total'] as int,
        j['pay'] as String,
        j['status'] as String,
        j['min'] as int,
      );
}

class TableModel {
  final String id;
  final int seats;
  final String st; // free | busy | bill
  final int min;
  final int total;
  TableModel(this.id, this.seats, this.st, {this.min = 0, this.total = 0});
}

class KdsItem {
  final int q;
  final String n;
  final String mod;
  bool ok;
  final String st; // bar | kitchen
  KdsItem(this.q, this.n, this.mod, this.ok, this.st);
}

class KdsTicket {
  final String code;
  final String type;
  final String? table;
  int ago; // seconds
  bool isNew;
  final String station;
  final List<KdsItem> items;
  KdsTicket({
    required this.code,
    required this.type,
    this.table,
    required this.ago,
    required this.isNew,
    required this.station,
    required this.items,
  });
}

class KdsDone {
  final String code;
  final String min;
  final int items;
  KdsDone(this.code, this.min, this.items);
}

class InvItem {
  final String id;
  final String name;
  final String unit;
  final double qty;
  final double max;
  final String emoji;
  InvItem(this.id, this.name, this.unit, this.qty, this.max, this.emoji);
}

class BomRecipe {
  final String product;
  final List<List<String>> items; // [name, qty]
  BomRecipe(this.product, this.items);
}

class Staff {
  final String id;
  final String name;
  final String role; // admin | cashier | barista
  final String phone;
  final String br;
  bool active;
  Staff(this.id, this.name, this.role, this.phone, this.br, this.active);
}

class Branch {
  final String id;
  final String name;
  final String addr;
  final int staff;
  final int rev;
  final bool open;
  Branch(this.id, this.name, this.addr, this.staff, this.rev, this.open);
}

class Promo {
  final String name;
  final String desc;
  final String type;
  bool on;
  final String emoji;
  Promo(this.name, this.desc, this.type, this.on, this.emoji);
}
