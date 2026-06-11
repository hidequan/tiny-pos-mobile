import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/bill.dart';

/// Builds + prints thermal-style receipts and bar labels for the cashier/KDS.
/// Uses bundled Roboto (Vietnamese-capable) so diacritics render in the PDF.
class ReceiptService {
  static pw.Font? _regular;
  static pw.Font? _medium;

  static Future<void> _loadFonts() async {
    _regular ??= pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Regular.ttf'));
    _medium ??= pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Medium.ttf'));
  }

  static String _money(int v) {
    final s = v.abs().toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
      b.write(s[i]);
    }
    return '${v < 0 ? '-' : ''}$b₫';
  }

  static String _dt(DateTime? d) {
    final x = (d ?? DateTime.now()).toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(x.day)}/${two(x.month)}/${x.year} ${two(x.hour)}:${two(x.minute)}';
  }

  static const _methodLabel = {
    'cash': 'Tiền mặt',
    'qr': 'Chuyển khoản / QR',
    'card': 'Thẻ ngân hàng',
    'momo': 'Ví MoMo',
  };

  /// Customer receipt (80mm roll). [received]/[method] come from the pay step.
  static Future<void> printReceipt(
    Bill bill, {
    required String method,
    int received = 0,
    String branchName = 'Chi nhánh Cầu Giấy',
  }) async {
    await _loadFonts();
    final reg = _regular!, med = _medium!;
    final doc = pw.Document();

    pw.Widget divider() => pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 4),
          child: pw.Row(
            children: List.generate(
              48,
              (_) => pw.Expanded(child: pw.Text('-', style: pw.TextStyle(font: reg, fontSize: 7, color: PdfColors.grey600))),
            ),
          ),
        );

    pw.Widget kv(String k, String v, {bool bold = false, double size = 9}) => pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 1),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(k, style: pw.TextStyle(font: bold ? med : reg, fontSize: size)),
              pw.Text(v, style: pw.TextStyle(font: bold ? med : reg, fontSize: size)),
            ],
          ),
        );

    final change = received - bill.grandTotal;

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80.copyWith(marginTop: 10, marginBottom: 10, marginLeft: 8, marginRight: 8),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Center(child: pw.Text('TINY POS', style: pw.TextStyle(font: med, fontSize: 16))),
            pw.Center(child: pw.Text('Cà phê & Trà · $branchName', style: pw.TextStyle(font: reg, fontSize: 8))),
            pw.Center(child: pw.Text('Hotline 1900 0000', style: pw.TextStyle(font: reg, fontSize: 8))),
            divider(),
            kv('Hoá đơn', bill.billCode, bold: true),
            kv('Thời gian', _dt(bill.paidAt ?? bill.createdAt)),
            kv('Hình thức', bill.serviceType == 'DINE_IN' ? 'Tại bàn' : 'Mang đi'),
            divider(),
            // items
            for (final it in bill.items)
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 2),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [
                    pw.Text(it.variantName?.isNotEmpty == true ? it.variantName! : it.productName,
                        style: pw.TextStyle(font: med, fontSize: 9)),
                    pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                      pw.Text('${it.quantity} x ${_money(it.unitPrice)}', style: pw.TextStyle(font: reg, fontSize: 8.5)),
                      pw.Text(_money(it.lineTotal), style: pw.TextStyle(font: reg, fontSize: 8.5)),
                    ]),
                  ],
                ),
              ),
            divider(),
            kv('Tạm tính', _money(bill.subtotal)),
            if (bill.discountTotal > 0) kv('Giảm giá', _money(-bill.discountTotal)),
            kv('TỔNG CỘNG', _money(bill.grandTotal), bold: true, size: 11),
            divider(),
            kv('Thanh toán', _methodLabel[method] ?? method),
            if (method == 'cash' && received > 0) ...[
              kv('Khách đưa', _money(received)),
              kv('Tiền thối', _money(change < 0 ? 0 : change)),
            ],
            pw.SizedBox(height: 8),
            pw.Center(child: pw.Text('Cảm ơn quý khách!', style: pw.TextStyle(font: med, fontSize: 9))),
            pw.Center(child: pw.Text('Hẹn gặp lại ♥', style: pw.TextStyle(font: reg, fontSize: 8))),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (_) => doc.save(), name: 'HD-${bill.billCode}');
  }

  /// One drink label (tem) per item in a ticket — a multi-page 58×40mm sheet.
  static Future<void> printLabels(String ticketCode, List<LabelItem> items) async {
    if (items.isEmpty) return;
    await _loadFonts();
    final reg = _regular!, med = _medium!;
    final doc = pw.Document();
    for (final it in items) {
      doc.addPage(
        pw.Page(
          pageFormat: const PdfPageFormat(58 * PdfPageFormat.mm, 40 * PdfPageFormat.mm, marginAll: 6),
          build: (ctx) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                pw.Text(ticketCode, style: pw.TextStyle(font: med, fontSize: 9)),
                pw.Text('x${it.quantity}', style: pw.TextStyle(font: med, fontSize: 9)),
              ]),
              pw.SizedBox(height: 4),
              pw.Text(it.variantName?.isNotEmpty == true ? it.variantName! : it.productName,
                  style: pw.TextStyle(font: med, fontSize: 12)),
              if (it.mods.isNotEmpty)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 3),
                  child: pw.Text(it.mods, style: pw.TextStyle(font: reg, fontSize: 9)),
                ),
              pw.Spacer(),
              pw.Text('TINY POS', style: pw.TextStyle(font: reg, fontSize: 7, color: PdfColors.grey600)),
            ],
          ),
        ),
      );
    }
    await Printing.layoutPdf(onLayout: (_) => doc.save(), name: 'TEM-$ticketCode');
  }
}

/// Minimal data for one bar label (decoupled from the KDS model).
class LabelItem {
  final String productName;
  final String? variantName;
  final String mods;
  final int quantity;
  LabelItem({required this.productName, this.variantName, this.mods = '', this.quantity = 1});
}
