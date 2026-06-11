import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import '../api/reports_repository.dart';
import '../models/report.dart';

enum ReportRange { today, week, month }

extension ReportRangeX on ReportRange {
  String get label => switch (this) {
        ReportRange.today => 'Hôm nay',
        ReportRange.week => '7 ngày',
        ReportRange.month => 'Tháng này',
      };
}

/// Loads admin sales reports for the selected range (online reads only).
class ReportsController extends ChangeNotifier {
  final ReportsRepository repo;
  ReportsController(this.repo);

  ReportRange range = ReportRange.today;
  SalesSummary summary = SalesSummary.empty();
  List<BestSeller> bestSellers = [];
  List<PayMethodStat> payments = [];
  bool loading = false;
  bool loaded = false;
  String? error;

  /// [from, to] window for the current range (to = now).
  (DateTime, DateTime) _window([DateTime? now]) {
    final n = now ?? DateTime.now();
    final from = switch (range) {
      ReportRange.today => DateTime(n.year, n.month, n.day),
      ReportRange.week => DateTime(n.year, n.month, n.day).subtract(const Duration(days: 6)),
      ReportRange.month => DateTime(n.year, n.month, 1),
    };
    return (from, n);
  }

  Future<void> setRange(ReportRange r) async {
    if (r == range && loaded) return;
    range = r;
    notifyListeners();
    await load();
  }

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    final (from, to) = _window();
    try {
      final s = await repo.salesSummary(from: from, to: to);
      final b = await repo.bestSelling(from: from, to: to, limit: 8);
      final p = await repo.paymentMethods(from: from, to: to);
      summary = s;
      bestSellers = b;
      payments = p;
      loaded = true;
      error = null;
    } on ApiException catch (e) {
      error = e.message;
    } catch (_) {
      error = 'Không tải được báo cáo';
    }
    loading = false;
    notifyListeners();
  }

  int get paymentsTotal => payments.fold(0, (a, p) => a + p.amount);

  /// Percentage share of a payment method (0–100), for the donut.
  int sharePct(PayMethodStat p) {
    final tot = paymentsTotal;
    return tot == 0 ? 0 : ((p.amount / tot) * 100).round();
  }

  @visibleForTesting
  void debugSet({
    required SalesSummary summary,
    List<BestSeller> bestSellers = const [],
    List<PayMethodStat> payments = const [],
  }) {
    this.summary = summary;
    this.bestSellers = bestSellers;
    this.payments = payments;
    loaded = true;
    loading = false;
    error = null;
    notifyListeners();
  }
}
