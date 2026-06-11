/// A bar/kitchen ticket item (one drink/dish to make).
class KdsTicketItem {
  final String id;
  final String status; // WAITING | PREPARING | READY | SERVED | CANCELLED
  final String productName;
  final String? variantName;
  final int quantity;
  final String mods; // modifiers + note, display-ready
  KdsTicketItem({
    required this.id,
    required this.status,
    required this.productName,
    required this.variantName,
    required this.quantity,
    required this.mods,
  });

  static String _mods(dynamic modifiers, String? note) {
    final parts = <String>[];
    if (modifiers is String && modifiers.isNotEmpty) parts.add(modifiers);
    if (modifiers is List) {
      for (final m in modifiers) {
        if (m is String) {
          parts.add(m);
        } else if (m is Map) {
          parts.add((m['name'] ?? m['toppingName'] ?? '').toString());
        }
      }
    }
    if (note != null && note.isNotEmpty) parts.add('“$note”');
    return parts.where((s) => s.isNotEmpty).join(' · ');
  }

  factory KdsTicketItem.fromJson(Map j) => KdsTicketItem(
        id: j['id'] as String,
        status: (j['status'] ?? 'WAITING') as String,
        productName: (j['productName'] ?? '') as String,
        variantName: j['variantName'] as String?,
        quantity: (j['quantity'] as num?)?.toInt() ?? 1,
        mods: _mods(j['modifiers'], j['note'] as String?),
      );

  /// Made / done — checked off on the KDS card.
  bool get done => status == 'READY' || status == 'SERVED' || status == 'COMPLETED';
}

class KdsTicket {
  final String id;
  final String ticketCode;
  final String status;
  final String? tableLabel;
  final String serviceType; // DINE_IN | TAKE_AWAY
  final DateTime? sentAt;
  final List<KdsTicketItem> items;
  KdsTicket({
    required this.id,
    required this.ticketCode,
    required this.status,
    required this.tableLabel,
    required this.serviceType,
    required this.sentAt,
    required this.items,
  });

  factory KdsTicket.fromJson(Map j) => KdsTicket(
        id: j['id'] as String,
        ticketCode: (j['ticketCode'] ?? '') as String,
        status: (j['status'] ?? 'WAITING') as String,
        tableLabel: j['tableLabel'] as String?,
        serviceType: (j['serviceType'] ?? 'TAKE_AWAY') as String,
        sentAt: j['sentAt'] != null ? DateTime.tryParse(j['sentAt'].toString()) : null,
        items: ((j['items'] as List?) ?? const []).map((e) => KdsTicketItem.fromJson(e as Map)).toList(),
      );

  bool get isDineIn => serviceType == 'DINE_IN';
  bool get allDone => items.isNotEmpty && items.every((i) => i.done);

  /// Seconds since the ticket was sent to the bar.
  int agoSeconds(DateTime now) => sentAt == null ? 0 : now.difference(sentAt!).inSeconds.clamp(0, 1 << 30);
}

class KdsStats {
  final int waiting;
  final int preparing;
  final int completed;
  KdsStats(this.waiting, this.preparing, this.completed);
  factory KdsStats.fromJson(Map j) => KdsStats(
        (j['waiting'] as num?)?.toInt() ?? 0,
        (j['preparing'] as num?)?.toInt() ?? 0,
        (j['completed'] as num?)?.toInt() ?? 0,
      );
}
