import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models.dart';
import '../data/seed.dart';
import '../models/menu.dart';

/// Central app state + business logic. A faithful port of the `S` state object
/// and the mutation functions in `tinypos.html`.
class AppState extends ChangeNotifier {
  // ---- session / role ----
  Role? role;

  // ---- cashier ----
  String cashTab = 'sell';
  String cat = 'all';
  final List<CartLine> cart = [];
  String otype = 'takeaway'; // takeaway | dinein
  String? table;
  bool disc = false;
  bool shiftOpen = true;

  // ---- mutable seed data ----
  final List<Product> products = Seed.products();
  final List<Order> orders = Seed.orders();
  final List<TableModel> tables = Seed.tables();
  List<KdsTicket> kds = Seed.kds();
  final List<KdsDone> kdsDone = Seed.kdsDone();
  final List<InvItem> inventory = Seed.inventory();
  final List<Staff> staff = Seed.staff();
  final List<Promo> promos = Seed.promos();
  final List<Branch> branches = Seed.branches();

  int _orderId = 1043;

  // ---- product option draft ----
  String? draftPid;
  int draftSize = 1;
  int draftSugar = 1;
  int draftIce = 1;
  final List<int> draftTops = [];
  int draftQty = 1;
  String draftNote = '';

  // ---- payment ----
  int payTotal = 0;
  String payMethod = 'cash';
  int received = 0;

  // ---- kds ----
  String kdsTab = 'queue';
  String kdsFilter = 'all';
  Timer? _kdsTimer;

  /// Per-second tick for KDS timers. Bumping this (instead of notifyListeners)
  /// lets ONLY the ticket timer/border repaint each second rather than rebuilding
  /// the whole KDS screen (topbar, chips, stat boxes, every card).
  final ValueNotifier<int> kdsTick = ValueNotifier<int>(0);

  // ---- admin ----
  String adminTab = 'home';
  String? adminSub; // sub-page inside "Thêm" (staff/promos/branches/shiftadmin)
  String adminBranch = 'Cầu Giấy';
  String adminCat = 'all';
  String invTab = 'stock';
  String repRange = '7 ngày';

  // ---- v0.1.1: search + dark mode ----
  String sellSearch = '';
  String orderSearch = '';
  bool userDark = false;

  /// KDS is always dark; other roles follow the user's dark-mode preference.
  bool get isDark => role == Role.kds || userDark;

  void setSellSearch(String q) {
    sellSearch = q;
    notifyListeners();
  }

  void setOrderSearch(String q) {
    orderSearch = q;
    notifyListeners();
  }

  void toggleDarkMode() {
    userDark = !userDark;
    _save();
    notifyListeners();
  }

  // =================== ROLE ROUTER ===================
  void enterRole(Role r) {
    role = r;
    if (r == Role.cashier) cashTab = 'sell';
    if (r == Role.kds) {
      kdsTab = 'queue';
      _startKdsTimer();
    }
    if (r == Role.admin) adminTab = 'home';
    notifyListeners();
  }

  void logout() {
    role = null;
    _kdsTimer?.cancel();
    notifyListeners();
  }

  /// Maps the authenticated staffRole (from the API) onto the role-based shell.
  /// Called once after sign-in. Cashiers land on POS, baristas on KDS,
  /// managers/admins on the admin area.
  void applyAuthRole(String staffRole) {
    final Role target;
    switch (staffRole) {
      case 'BARISTA':
        target = Role.kds;
        break;
      case 'MANAGER':
      case 'ADMIN':
      case 'SUPER_ADMIN':
        target = Role.admin;
        break;
      case 'CASHIER':
      default:
        target = Role.cashier;
    }
    if (role == target) return;
    enterRole(target);
  }

  // =================== CASHIER ===================
  void setCashTab(String t) {
    cashTab = t;
    notifyListeners();
  }

  void setCat(String c) {
    cat = c;
    notifyListeners();
  }

  List<Product> productsForCat(String c) =>
      products.where((p) => c == 'all' || p.cat == c).toList();

  int qtyForProduct(String pid) =>
      cart.where((c) => c.pid == pid).fold(0, (a, c) => a + c.qty);

  int get cartCount => cart.fold(0, (a, c) => a + c.qty);
  int get cartSubtotal => cart.fold(0, (a, c) => a + c.price * c.qty);

  // ---- product options draft ----
  void startDraft(String pid) {
    draftPid = pid;
    draftSize = Seed.sizeOpts.indexWhere((o) => o.def);
    draftSugar = Seed.sugarOpts.indexWhere((o) => o.def);
    draftIce = Seed.iceOpts.indexWhere((o) => o.def);
    draftTops.clear();
    draftQty = 1;
    draftNote = '';
    notifyListeners();
  }

  void draftSet(String key, int v) {
    if (key == 'size') draftSize = v;
    if (key == 'sugar') draftSugar = v;
    if (key == 'ice') draftIce = v;
    notifyListeners();
  }

  void draftToggleTop(int i) {
    if (draftTops.contains(i)) {
      draftTops.remove(i);
    } else {
      draftTops.add(i);
    }
    notifyListeners();
  }

  void draftSetQty(int d) {
    draftQty = max(1, draftQty + d);
    notifyListeners();
  }

  int draftUnitPrice() {
    final p = products.firstWhere((x) => x.id == draftPid);
    return p.price +
        Seed.sizeOpts[draftSize].price +
        draftTops.fold(0, (a, i) => a + Seed.topOpts[i].price);
  }

  void confirmDraft() {
    final p = products.firstWhere((x) => x.id == draftPid);
    final extra = Seed.sizeOpts[draftSize].price +
        draftTops.fold<int>(0, (a, i) => a + Seed.topOpts[i].price);
    _addLine(
      p,
      ModSel(
        size: Seed.sizeOpts[draftSize].name,
        sugar: Seed.sugarOpts[draftSugar].name,
        ice: Seed.iceOpts[draftIce].name,
        tops: draftTops.map((i) => Seed.topOpts[i].name).toList(),
        note: draftNote,
        extra: extra,
      ),
      draftQty,
    );
  }

  /// Add a product with no options directly to the cart.
  void addSimple(Product p) => _addLine(p, const ModSel(), 1);

  /// Bridge a REAL menu product (from /pos/menu) into the local cart, so the
  /// existing cart/payment UI works while the bill-write API layer lands next.
  void addMenuFromApi(
    MenuProduct p, {
    ProductVariant? variant,
    List<MenuTopping> toppings = const [],
    String note = '',
    int qty = 1,
  }) {
    final extra = toppings.fold<int>(0, (a, t) => a + t.price);
    final unit = (variant?.price ?? p.basePrice) + extra;
    cart.add(CartLine(
      lid: '${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(99999)}',
      pid: p.id,
      name: p.name,
      emoji: '🥤',
      price: unit,
      qty: qty,
      mods: ModSel(
        size: variant?.sizeName,
        tops: toppings.map((t) => t.name).toList(),
        note: note,
        extra: extra,
      ),
      station: 'bar',
    ));
    _save();
    notifyListeners();
  }

  void _addLine(Product p, ModSel o, int qty) {
    cart.add(CartLine(
      lid: '${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(99999)}',
      pid: p.id,
      name: p.name,
      emoji: p.emoji,
      price: p.price + o.extra,
      qty: qty,
      mods: o,
      station: (p.cat == 'cake' || p.cat == 'top') ? 'kitchen' : 'bar',
    ));
    _save();
    notifyListeners();
  }

  void cartQty(String lid, int d) {
    final c = cart.firstWhere((x) => x.lid == lid);
    c.qty += d;
    if (c.qty <= 0) cart.removeWhere((x) => x.lid == lid);
    _save();
    notifyListeners();
  }

  void clearCart() {
    cart.clear();
    disc = false;
    _save();
    notifyListeners();
  }

  void setOtype(String t) {
    otype = t;
    notifyListeners();
  }

  void toggleDisc() {
    disc = !disc;
    notifyListeners();
  }

  void openTableForSale(String id) {
    otype = 'dinein';
    table = id;
    cashTab = 'sell';
    notifyListeners();
  }

  // ---- totals ----
  int get discountAmount => disc ? (cartSubtotal * 0.2).round() : 0;
  int get cartTotal => cartSubtotal - discountAmount;

  // ---- payment ----
  void openPay(int total) {
    payTotal = total;
    payMethod = 'cash';
    received = 0;
    notifyListeners();
  }

  void setPay(String m) {
    payMethod = m;
    received = 0;
    notifyListeners();
  }

  void setReceived(int v) {
    received = v;
    notifyListeners();
  }

  /// Completes the current cart order: pushes to KDS, records the order, and
  /// resets the cart. Returns the order code for the success screen.
  String completeOrder() {
    final code = '#${++_orderId}';
    final sub = cartSubtotal;
    final d = disc ? (sub * 0.2).round() : 0;
    final tot = sub - d;
    kds.insert(
      0,
      KdsTicket(
        code: code,
        type: otype,
        table: otype == 'dinein' ? (table ?? '—') : null,
        ago: 0,
        isNew: true,
        station: 'mix',
        items: cart
            .map((c) => KdsItem(c.qty, c.name, c.mods.text, false, c.station))
            .toList(),
      ),
    );
    orders.insert(
      0,
      Order(code, otype, otype == 'dinein' ? table : null, cartCount, tot, payMethod, 'done', 0),
    );
    cart.clear();
    disc = false;
    table = null;
    otype = 'takeaway';
    _save();
    notifyListeners();
    return code;
  }

  void afterPay() {
    cashTab = 'sell';
    notifyListeners();
  }

  void toggleShift() {
    shiftOpen = !shiftOpen;
    _save();
    notifyListeners();
  }

  // =================== KDS ===================
  void setKdsTab(String t) {
    kdsTab = t;
    notifyListeners();
  }

  void setKdsFilter(String f) {
    kdsFilter = f;
    notifyListeners();
  }

  void _startKdsTimer() {
    _kdsTimer?.cancel();
    _kdsTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (role != Role.kds) {
        _kdsTimer?.cancel();
        return;
      }
      for (final t in kds) {
        t.ago++;
      }
      // Only nudge the lightweight tick listeners, not the whole screen.
      kdsTick.value++;
    });
  }

  void toggleKdsItem(String code, int idx) {
    final i = kds.indexWhere((x) => x.code == code);
    if (i < 0 || idx < 0 || idx >= kds[i].items.length) return; // ticket bumped away
    kds[i].items[idx].ok = !kds[i].items[idx].ok;
    kds[i].isNew = false;
    notifyListeners();
  }

  void bumpTicket(String code) {
    final i = kds.indexWhere((x) => x.code == code);
    if (i < 0) return; // already removed (e.g. double tap)
    final t = kds[i];
    kds.removeAt(i);
    kdsDone.insert(0, KdsDone(code, fmtAgo(t.ago), t.items.fold(0, (a, it) => a + it.q)));
    notifyListeners();
  }

  // =================== ADMIN ===================
  void setAdminTab(String t) {
    adminTab = t;
    adminSub = null;
    notifyListeners();
  }

  void openAdminSub(String? sub) {
    adminSub = sub;
    notifyListeners();
  }

  void setAdminBranch(String n) {
    adminBranch = n;
    notifyListeners();
  }

  Branch get curBranch =>
      branches.firstWhere((b) => b.name == adminBranch, orElse: () => branches.first);

  void setAdminCat(String c) {
    adminCat = c;
    notifyListeners();
  }

  void setInvTab(String t) {
    invTab = t;
    notifyListeners();
  }

  void setRepRange(String r) {
    repRange = r;
    notifyListeners();
  }

  void toggleAvail(String id) {
    final p = products.firstWhere((x) => x.id == id);
    p.sold = !p.sold;
    notifyListeners();
  }

  void saveProduct(String id, String name, int price, String cat, bool sold) {
    final p = products.firstWhere((x) => x.id == id);
    p.name = name.isNotEmpty ? name : p.name;
    p.price = price > 0 ? price : p.price;
    p.cat = cat;
    p.sold = sold;
    notifyListeners();
  }

  void deleteProduct(String id) {
    products.removeWhere((x) => x.id == id);
    notifyListeners();
  }

  void addProduct(String name, String cat, int price, String emoji) {
    products.insert(
      0,
      Product(
        id: 'np${DateTime.now().microsecondsSinceEpoch}',
        name: name,
        cat: cat,
        price: price,
        emoji: emoji.isNotEmpty ? emoji : '🥤',
        opt: false,
        sold: false,
      ),
    );
    adminCat = 'all';
    notifyListeners();
  }

  void toggleStaff(String id) {
    final s = staff.firstWhere((x) => x.id == id);
    s.active = !s.active;
    notifyListeners();
  }

  void togglePromo(int i) {
    promos[i].on = !promos[i].on;
    notifyListeners();
  }

  // ---- v0.1.2: real add-forms ----
  void addStaff(String name, String role, String phone, String branch) {
    staff.insert(0, Staff('s${DateTime.now().microsecondsSinceEpoch}', name, role, phone, branch, true));
    notifyListeners();
  }

  void addPromo(String name, String desc, String type, String emoji) {
    promos.insert(0, Promo(name, desc, type.isNotEmpty ? type : 'Mới', true, emoji.isNotEmpty ? emoji : '🎁'));
    notifyListeners();
  }

  void addBranch(String name, String addr) {
    branches.add(Branch('b${DateTime.now().microsecondsSinceEpoch}', name, addr, 0, 0, true));
    notifyListeners();
  }

  // =================== PERSISTENCE (v0.1.2) ===================
  static const _key = 'tinypos_state_v1';
  SharedPreferences? _prefs;

  /// Loads persisted state (theme, shift, cart, orders) on startup.
  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs?.getString(_key);
    if (raw == null) return;
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      userDark = (j['userDark'] as bool?) ?? false;
      shiftOpen = (j['shiftOpen'] as bool?) ?? true;
      _orderId = (j['orderId'] as int?) ?? _orderId;
      if (j['cart'] is List) {
        cart
          ..clear()
          ..addAll((j['cart'] as List).map((e) => CartLine.fromJson(Map<String, dynamic>.from(e as Map))));
      }
      if (j['orders'] is List) {
        orders
          ..clear()
          ..addAll((j['orders'] as List).map((e) => Order.fromJson(Map<String, dynamic>.from(e as Map))));
      }
    } catch (_) {
      // Corrupt blob — ignore and start fresh.
    }
    notifyListeners();
  }

  void _save() {
    final p = _prefs;
    if (p == null) return;
    p.setString(
      _key,
      jsonEncode({
        'userDark': userDark,
        'shiftOpen': shiftOpen,
        'orderId': _orderId,
        'cart': cart.map((c) => c.toJson()).toList(),
        'orders': orders.map((o) => o.toJson()).toList(),
      }),
    );
  }

  @override
  void dispose() {
    _kdsTimer?.cancel();
    kdsTick.dispose();
    super.dispose();
  }
}

String fmtAgo(int s) => '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
