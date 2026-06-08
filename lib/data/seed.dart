import 'models.dart';

/// Seed data ported verbatim from `tinypos.html`.
class Seed {
  static const List<Category> cats = [
    Category('all', 'Tất cả', '✨'),
    Category('cf', 'Cà phê', '☕'),
    Category('tea', 'Trà & Trà sữa', '🧋'),
    Category('ice', 'Đá xay', '🥤'),
    Category('cake', 'Bánh', '🍰'),
    Category('top', 'Topping', '🧂'),
  ];

  static List<Product> products() => [
        Product(id: 'p1', name: 'Cà phê sữa đá', cat: 'cf', price: 29000, emoji: '☕', opt: true),
        Product(id: 'p2', name: 'Bạc xỉu', cat: 'cf', price: 32000, emoji: '🥛', opt: true),
        Product(id: 'p3', name: 'Cà phê đen', cat: 'cf', price: 25000, emoji: '☕', opt: true),
        Product(id: 'p4', name: 'Espresso', cat: 'cf', price: 35000, emoji: '☕', opt: false),
        Product(id: 'p5', name: 'Cappuccino', cat: 'cf', price: 45000, emoji: '☕', opt: true),
        Product(id: 'p6', name: 'Latte', cat: 'cf', price: 49000, emoji: '☕', opt: true),
        Product(id: 'p7', name: 'Cold Brew', cat: 'cf', price: 55000, emoji: '🧊', opt: true, sold: true),
        Product(id: 'p8', name: 'Trà đào cam sả', cat: 'tea', price: 45000, emoji: '🍑', opt: true),
        Product(id: 'p9', name: 'Trà sữa trân châu', cat: 'tea', price: 42000, emoji: '🧋', opt: true),
        Product(id: 'p10', name: 'Trà vải', cat: 'tea', price: 42000, emoji: '🍒', opt: true),
        Product(id: 'p11', name: 'Matcha Latte', cat: 'tea', price: 52000, emoji: '🍵', opt: true),
        Product(id: 'p12', name: 'Sinh tố xoài', cat: 'ice', price: 49000, emoji: '🥭', opt: true),
        Product(id: 'p13', name: 'Đá xay socola', cat: 'ice', price: 55000, emoji: '🍫', opt: true),
        Product(id: 'p14', name: 'Croissant bơ', cat: 'cake', price: 35000, emoji: '🥐', opt: false),
        Product(id: 'p15', name: 'Bánh flan', cat: 'cake', price: 25000, emoji: '🍮', opt: false),
        Product(id: 'p16', name: 'Tiramisu', cat: 'cake', price: 45000, emoji: '🍰', opt: false),
        Product(id: 'p17', name: 'Trân châu đen', cat: 'top', price: 8000, emoji: '⚫', opt: false),
        Product(id: 'p18', name: 'Kem cheese', cat: 'top', price: 10000, emoji: '🧀', opt: false),
        Product(id: 'p19', name: 'Pudding', cat: 'top', price: 8000, emoji: '🍮', opt: false),
        Product(id: 'p20', name: 'Espresso shot', cat: 'top', price: 10000, emoji: '☕', opt: false),
      ];

  static const List<PriceOption> sizeOpts = [
    PriceOption('S'),
    PriceOption('M', price: 6000, def: true),
    PriceOption('L', price: 12000),
  ];
  static const List<PriceOption> sugarOpts = [
    PriceOption('100%'),
    PriceOption('70%', def: true),
    PriceOption('50%'),
    PriceOption('30%'),
    PriceOption('0%'),
  ];
  static const List<PriceOption> iceOpts = [
    PriceOption('Nhiều'),
    PriceOption('Bình thường', def: true),
    PriceOption('Ít'),
    PriceOption('Không đá'),
  ];
  static const List<PriceOption> topOpts = [
    PriceOption('Trân châu', price: 8000),
    PriceOption('Kem cheese', price: 10000),
    PriceOption('Pudding', price: 8000),
    PriceOption('Thạch', price: 6000),
  ];

  static List<Order> orders() => [
        Order('#1042', 'dinein', 'B3', 3, 126000, 'cash', 'done', 8),
        Order('#1041', 'takeaway', null, 2, 74000, 'qr', 'done', 14),
        Order('#1040', 'dinein', 'A1', 5, 218000, 'card', 'done', 22),
        Order('#1039', 'takeaway', null, 1, 29000, 'cash', 'void', 35),
        Order('#1038', 'dinein', 'B1', 4, 165000, 'momo', 'done', 41),
      ];

  static List<TableModel> tables() => [
        TableModel('A1', 2, 'busy', min: 22, total: 218000),
        TableModel('A2', 2, 'free'),
        TableModel('A3', 4, 'free'),
        TableModel('B1', 4, 'busy', min: 6, total: 96000),
        TableModel('B2', 4, 'free'),
        TableModel('B3', 6, 'busy', min: 8, total: 126000),
        TableModel('C1', 2, 'bill', min: 30, total: 88000),
        TableModel('C2', 2, 'free'),
        TableModel('VIP', 8, 'free'),
      ];

  static List<KdsTicket> kds() => [
        KdsTicket(code: '#1042', type: 'dinein', table: 'B3', ago: 90, isNew: false, station: 'bar', items: [
          KdsItem(2, 'Cà phê sữa đá', 'M · 70% đường · ít đá', false, 'bar'),
          KdsItem(1, 'Bạc xỉu', 'L · 100% đường', true, 'bar'),
        ]),
        KdsTicket(code: '#1043', type: 'takeaway', table: null, ago: 150, isNew: false, station: 'mix', items: [
          KdsItem(1, 'Trà đào cam sả', 'L · ít đá · thêm trân châu', false, 'bar'),
          KdsItem(2, 'Croissant bơ', 'hâm nóng', false, 'kitchen'),
        ]),
        KdsTicket(code: '#1044', type: 'dinein', table: 'A1', ago: 280, isNew: false, station: 'bar', items: [
          KdsItem(1, 'Matcha Latte', 'M · 50% đường', false, 'bar'),
          KdsItem(1, 'Cappuccino', 'M · nóng', false, 'bar'),
          KdsItem(1, 'Tiramisu', '', false, 'kitchen'),
        ]),
      ];

  static List<KdsDone> kdsDone() => [
        KdsDone('#1039', '2:14', 2),
        KdsDone('#1037', '3:02', 1),
        KdsDone('#1036', '1:48', 3),
      ];

  static List<InvItem> inventory() => [
        InvItem('i1', 'Hạt cà phê Arabica', 'kg', 12.5, 30, '🫘'),
        InvItem('i2', 'Sữa đặc', 'lon', 8, 48, '🥫'),
        InvItem('i3', 'Sữa tươi', 'lít', 24, 40, '🥛'),
        InvItem('i4', 'Trân châu đen', 'kg', 2.2, 20, '⚫'),
        InvItem('i5', 'Bột matcha', 'kg', 0.4, 5, '🍵'),
        InvItem('i6', 'Đào ngâm', 'hộp', 3, 24, '🍑'),
        InvItem('i7', 'Cốc nhựa M', 'cái', 420, 2000, '🥤'),
        InvItem('i8', 'Đường nước', 'lít', 15, 30, '🍯'),
      ];

  static List<BomRecipe> bom() => [
        BomRecipe('Cà phê sữa đá (M)', [
          ['Hạt cà phê Arabica', '18 g'],
          ['Sữa đặc', '30 ml'],
          ['Đường nước', '15 ml'],
          ['Cốc nhựa M', '1 cái'],
          ['Đá', '120 g'],
        ]),
        BomRecipe('Matcha Latte (M)', [
          ['Bột matcha', '5 g'],
          ['Sữa tươi', '150 ml'],
          ['Đường nước', '20 ml'],
          ['Cốc nhựa M', '1 cái'],
        ]),
      ];

  static List<Staff> staff() => [
        Staff('s1', 'Nguyễn Văn An', 'admin', '0901 234 567', 'Cầu Giấy', true),
        Staff('s2', 'Trần Thị Bình', 'cashier', '0912 345 678', 'Cầu Giấy', true),
        Staff('s3', 'Lê Minh Châu', 'cashier', '0987 654 321', 'Đống Đa', true),
        Staff('s4', 'Phạm Quốc Dũng', 'barista', '0934 567 890', 'Cầu Giấy', true),
        Staff('s5', 'Vũ Thu Hà', 'barista', '0976 543 210', 'Đống Đa', false),
      ];

  static const Map<String, List<String>> roleMeta = {
    // role -> [label, badgeClass, emoji]
    'admin': ['Quản trị', 'red', '⚙️'],
    'cashier': ['Thu ngân', 'blue', '🧾'],
    'barista': ['Pha chế', 'green', '🍳'],
  };

  static const List<List<dynamic>> perms = [
    ['Bán hàng (POS)', ['admin', 'cashier']],
    ['Hủy đơn / hoàn tiền', ['admin']],
    ['Màn hình pha chế (KDS)', ['admin', 'barista']],
    ['Quản lý thực đơn', ['admin']],
    ['Quản lý kho & BOM', ['admin']],
    ['Mở / đóng ca', ['admin', 'cashier']],
    ['Xem báo cáo doanh thu', ['admin']],
    ['Quản lý nhân viên', ['admin']],
  ];

  static List<Branch> branches() => [
        Branch('b1', 'Cầu Giấy', '144 Xuân Thủy, Cầu Giấy', 6, 4820000, true),
        Branch('b2', 'Đống Đa', '88 Láng Hạ, Đống Đa', 5, 3950000, true),
        Branch('b3', 'Hà Đông', '215 Quang Trung, Hà Đông', 4, 2710000, false),
      ];

  static List<Promo> promos() => [
        Promo('Giờ vàng 14h–16h', 'Giảm 20% toàn menu', '-20%', true, '⏰'),
        Promo('Mua 2 tặng 1', 'Cà phê sữa đá', 'B2G1', true, '🎁'),
        Promo('Combo sáng', 'Cà phê + Croissant', '-15k', false, '🥐'),
        Promo('Thành viên mới', 'Freeship đơn đầu', 'Free', true, '🆕'),
      ];

  static const List<double> report7 = [2.9, 3.4, 3.1, 3.8, 4.2, 5.6, 4.82];
  static const List<List<dynamic>> topSell = [
    ['Cà phê sữa đá', 184, 29000],
    ['Trà đào cam sả', 142, 45000],
    ['Bạc xỉu', 128, 32000],
    ['Trà sữa trân châu', 97, 42000],
    ['Croissant bơ', 76, 35000],
  ];
  static const List<List<dynamic>> payMix = [
    ['Tiền mặt', 38, 0xFFC75B39],
    ['Chuyển khoản / QR', 34, 0xFF3A1F12],
    ['Thẻ', 16, 0xFFD98A4E],
    ['Ví MoMo', 12, 0xFF3F8F5B],
  ];
}

/// Number formatting helpers — ports of `money`, `VND`, `k`.
String money(num n) {
  final s = n.round().toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return buf.toString();
}

String vnd(num n) => '${money(n)}đ';

String kShort(num n) {
  if (n >= 1000000) {
    final v = n / 1000000;
    return '${(n % 1000000 != 0) ? v.toStringAsFixed(1) : v.toStringAsFixed(0)}tr';
  }
  if (n >= 1000) return '${(n / 1000).round()}k';
  return n.toString();
}
