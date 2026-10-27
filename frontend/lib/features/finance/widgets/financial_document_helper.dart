import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../utils/file_download_helper.dart';

enum FinancialDocumentType {
  societyIncome,
  societyExpense,
  maintenanceBill,
  paymentReceipt,
}

class FinancialDocument {
  final FinancialDocumentType type;
  final String docNumber;
  final String title;
  final String societyName;
  final String societyCity;
  final String categoryOrHead;
  final double amount;
  final String date;
  final String status;
  final String payerOrPayee;
  final String paymentMethod;
  final String description;
  final Map<String, String> extraDetails;

  FinancialDocument({
    required this.type,
    required this.docNumber,
    required this.title,
    this.societyName = 'Zenith Square Co-Op Housing Society Ltd.',
    this.societyCity = 'Ahmedabad, Gujarat',
    required this.categoryOrHead,
    required this.amount,
    required this.date,
    required this.status,
    required this.payerOrPayee,
    this.paymentMethod = 'ONLINE / BANK TRANSFER',
    this.description = '',
    this.extraDetails = const {},
  });

  bool get isIncome =>
      type == FinancialDocumentType.societyIncome ||
      type == FinancialDocumentType.paymentReceipt;

  Color get themeColor {
    switch (type) {
      case FinancialDocumentType.societyIncome:
        return Colors.teal.shade700;
      case FinancialDocumentType.societyExpense:
        return Colors.red.shade700;
      case FinancialDocumentType.maintenanceBill:
        return Colors.indigo.shade700;
      case FinancialDocumentType.paymentReceipt:
        return Colors.green.shade700;
    }
  }

  IconData get icon {
    switch (type) {
      case FinancialDocumentType.societyIncome:
        return Icons.savings_outlined;
      case FinancialDocumentType.societyExpense:
        return Icons.money_off_outlined;
      case FinancialDocumentType.maintenanceBill:
        return Icons.receipt_long_outlined;
      case FinancialDocumentType.paymentReceipt:
        return Icons.verified_outlined;
    }
  }
}

class FinancialDocumentHelper {
  /// Open in-app visual receipt / bill modal
  static void viewDocument(BuildContext context, FinancialDocument doc) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => _FinancialDocumentDialog(doc: doc),
    );
  }

  /// Download the document directly as an official PDF file (not HTML)
  static Future<void> downloadDocument(BuildContext context, FinancialDocument doc) async {
    final cleanDocNo = doc.docNumber.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
    final fileName = '${doc.type.name.toUpperCase()}_$cleanDocNo.pdf';

    try {
      final pdfBytes = await generatePdfBytes(doc);

      downloadWebBinaryFile(
        fileName: fileName,
        bytes: pdfBytes,
        mimeType: 'application/pdf',
      );

      if (!context.mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.clearSnackBars();
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: doc.themeColor,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 2200),
          showCloseIcon: true,
          closeIconColor: Colors.white,
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Downloaded $fileName',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 13),
                ),
              ),
            ],
          ),
          action: SnackBarAction(
            label: 'Open',
            textColor: Colors.amberAccent,
            onPressed: () {
              messenger.hideCurrentSnackBar();
              openWebPdf(pdfBytes);
            },
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.clearSnackBars();
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade800,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          showCloseIcon: true,
          content: Text('Failed to generate PDF: $e'),
        ),
      );
    }
  }

  /// Open or Print PDF directly in browser
  static Future<void> printDocument(FinancialDocument doc) async {
    try {
      final pdfBytes = await generatePdfBytes(doc);
      openWebPdf(pdfBytes);
    } catch (_) {
      final html = generateHtmlDocument(doc);
      printWebDocument(html);
    }
  }

  /// Convert numbers to English words (Rupees)
  static String numberToWords(double number) {
    final n = number.floor();
    if (n == 0) return 'Zero Rupees Only';

    final units = [
      '', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine',
      'Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen', 'Sixteen',
      'Seventeen', 'Eighteen', 'Nineteen'
    ];
    final tens = [
      '', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety'
    ];

    String convertLessThanThousand(int val) {
      if (val == 0) return '';
      if (val < 20) return '${units[val]} ';
      if (val < 100) return '${tens[val ~/ 10]} ${units[val % 10]} ';
      return '${units[val ~/ 100]} Hundred ${convertLessThanThousand(val % 100)}';
    }

    int remaining = n;
    String words = '';

    if (remaining >= 10000000) {
      final crore = remaining ~/ 10000000;
      words += '${convertLessThanThousand(crore)}Crore ';
      remaining %= 10000000;
    }
    if (remaining >= 100000) {
      final lakh = remaining ~/ 100000;
      words += '${convertLessThanThousand(lakh)}Lakh ';
      remaining %= 100000;
    }
    if (remaining >= 1000) {
      final thousand = remaining ~/ 1000;
      words += '${convertLessThanThousand(thousand)}Thousand ';
      remaining %= 1000;
    }
    if (remaining > 0) {
      words += convertLessThanThousand(remaining);
    }

    final paise = ((number - n) * 100).round();
    final paiseStr = paise > 0 ? ' and $paise Paise' : '';

    return 'Rupees ${words.trim()}$paiseStr Only';
  }

  /// Generate high-resolution, vector-crisp PDF document bytes
  static Future<List<int>> generatePdfBytes(FinancialDocument doc) async {
    final pdf = pw.Document();
    final isIncome = doc.isIncome;
    final primaryColor = isIncome ? PdfColor.fromInt(0xFF00796B) : PdfColor.fromInt(0xFFC62828);
    final badgeBg = isIncome ? PdfColor.fromInt(0xFFE0F2F1) : PdfColor.fromInt(0xFFFFEBEE);
    final words = numberToWords(doc.amount);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(22),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300, width: 1.5),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                // 1. Header Banner
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            doc.societyName.toUpperCase(),
                            style: pw.TextStyle(
                              fontSize: 15,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColor.fromInt(0xFF1A237E),
                            ),
                          ),
                          pw.SizedBox(height: 3),
                          pw.Text(
                            'Treasury & Financial Management | ${doc.societyCity}',
                            style: pw.TextStyle(fontSize: 9.5, color: PdfColors.grey700),
                          ),
                          pw.Text(
                            'Registration No: SOC/GJ/AHM/2024/0981 | Contact: accounts@zenithsquare.com',
                            style: pw.TextStyle(fontSize: 8.5, color: PdfColors.grey600),
                          ),
                        ],
                      ),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: pw.BoxDecoration(
                        color: badgeBg,
                        border: pw.Border.all(color: primaryColor, width: 1),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
                      ),
                      child: pw.Text(
                        doc.status.toUpperCase(),
                        style: pw.TextStyle(
                          color: primaryColor,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 12),
                pw.Divider(color: PdfColors.grey300, thickness: 1),
                pw.SizedBox(height: 8),

                // 2. Document Meta Ribbon
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    border: pw.Border(left: pw.BorderSide(color: primaryColor, width: 4)),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('DOCUMENT TYPE', style: pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600)),
                          pw.SizedBox(height: 2),
                          pw.Text(doc.title, style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('RECEIPT / VOUCHER NO.', style: pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600)),
                          pw.SizedBox(height: 2),
                          pw.Text(doc.docNumber, style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text('TRANSACTION DATE', style: pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600)),
                          pw.SizedBox(height: 2),
                          pw.Text(doc.date, style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 14),

                // 3. Details Table
                pw.Table(
                  border: pw.TableBorder(
                    bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5),
                    horizontalInside: pw.BorderSide(color: PdfColors.grey200, width: 0.5),
                  ),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(3.5),
                    1: const pw.FlexColumnWidth(6.5),
                  },
                  children: [
                    _pdfTableRow(isIncome ? 'Received From / Head' : 'Paid To / Head', doc.categoryOrHead),
                    _pdfTableRow('Payer / Beneficiary Details', doc.payerOrPayee.isNotEmpty ? doc.payerOrPayee : 'Society Treasury Fund'),
                    _pdfTableRow('Payment Mode', doc.paymentMethod),
                    if (doc.description.isNotEmpty)
                      _pdfTableRow('Particulars / Remarks', doc.description),
                    ...doc.extraDetails.entries.map((e) => _pdfTableRow(e.key, e.value)),
                  ],
                ),
                pw.SizedBox(height: 16),

                // 4. Amount Box
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: pw.BoxDecoration(
                    color: badgeBg,
                    border: pw.Border.all(color: primaryColor, width: 1.2),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'TOTAL AMOUNT ${isIncome ? 'RECEIVED' : 'DISBURSED'}',
                              style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: primaryColor),
                            ),
                            pw.SizedBox(height: 3),
                            pw.Text(
                              words,
                              style: pw.TextStyle(fontSize: 8.5, fontStyle: pw.FontStyle.italic, color: PdfColors.grey800),
                            ),
                          ],
                        ),
                      ),
                      pw.Text(
                        'INR ${doc.amount.toStringAsFixed(2)}',
                        style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: primaryColor),
                      ),
                    ],
                  ),
                ),

                pw.Spacer(),

                // 5. Verification & Signature Footer
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    // Official Seal Stamp
                    pw.Container(
                      width: 75,
                      height: 75,
                      decoration: pw.BoxDecoration(
                        shape: pw.BoxShape.circle,
                        border: pw.Border.all(color: primaryColor, width: 1.5),
                      ),
                      child: pw.Center(
                        child: pw.Column(
                          mainAxisAlignment: pw.MainAxisAlignment.center,
                          children: [
                            pw.Text('ZENITH SQUARE', style: pw.TextStyle(fontSize: 5.5, fontWeight: pw.FontWeight.bold, color: primaryColor)),
                            pw.Text('OFFICIAL SEAL', style: pw.TextStyle(fontSize: 5, fontWeight: pw.FontWeight.bold, color: primaryColor)),
                            pw.Text('VERIFIED', style: pw.TextStyle(fontSize: 5.5, fontWeight: pw.FontWeight.bold, color: primaryColor)),
                          ],
                        ),
                      ),
                    ),
                    pw.Column(
                      children: [
                        pw.Text('This is a computer-generated verified document.', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                        pw.Text('No physical signature required.', style: pw.TextStyle(fontSize: 7.5, color: PdfColors.grey500)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Container(width: 130, height: 1, color: PdfColors.grey800),
                        pw.SizedBox(height: 3),
                        pw.Text('Authorized Signatory / Treasurer', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                        pw.Text('Zenith Square Co-Op Housing Society', style: pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    return await pdf.save();
  }

  static pw.TableRow _pdfTableRow(String label, String value) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 8),
          child: pw.Text(label, style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 8),
          child: pw.Text(value, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
        ),
      ],
    );
  }

  /// Generate self-contained HTML (for print fallback)
  static String generateHtmlDocument(FinancialDocument doc) {
    final isIncome = doc.isIncome;
    final primaryColorHex = isIncome ? '#00796B' : '#C62828';
    final badgeBgHex = isIncome ? '#E0F2F1' : '#FFEBEE';
    final words = numberToWords(doc.amount);

    final extraRows = doc.extraDetails.entries.map((e) {
      return '''
        <tr>
          <td class="label">${e.key}</td>
          <td class="val">${e.value}</td>
        </tr>
      ''';
    }).join('');

    return '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>${doc.title} - ${doc.docNumber}</title>
  <style>
    @page { size: A4 portrait; margin: 15mm; }
    * { box-sizing: border-box; margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; }
    body { background: #f4f6f8; padding: 24px; color: #222; }
    .action-bar { max-width: 780px; margin: 0 auto 16px auto; display: flex; justify-content: flex-end; gap: 10px; }
    .btn { background: $primaryColorHex; color: #fff; border: none; padding: 10px 18px; border-radius: 6px; font-weight: 600; cursor: pointer; font-size: 14px; text-decoration: none; display: inline-flex; align-items: center; gap: 6px; }
    .btn:hover { opacity: 0.9; }
    .receipt-card { max-width: 780px; margin: 0 auto; background: #fff; border-radius: 12px; border: 2px solid #e0e0e0; box-shadow: 0 4px 20px rgba(0,0,0,0.06); padding: 36px 40px; position: relative; overflow: hidden; }
    .header { display: flex; justify-content: space-between; align-items: flex-start; border-bottom: 2px solid #f0f0f0; padding-bottom: 20px; }
    .society-title { font-size: 20px; font-weight: 800; color: #1a237e; letter-spacing: 0.5px; }
    .society-sub { font-size: 13px; color: #666; margin-top: 4px; }
    .badge { background: $badgeBgHex; color: $primaryColorHex; font-size: 13px; font-weight: 700; padding: 6px 14px; border-radius: 20px; display: inline-block; text-transform: uppercase; border: 1px solid $primaryColorHex; }
    .doc-meta { display: flex; justify-content: space-between; margin: 24px 0 16px 0; background: #fafafa; padding: 14px 18px; border-radius: 8px; border-left: 4px solid $primaryColorHex; }
    .meta-item { font-size: 13px; }
    .meta-item span { display: block; font-size: 11px; color: #888; text-transform: uppercase; margin-bottom: 2px; }
    .meta-item strong { font-size: 14px; color: #111; font-family: monospace; }
    .table-container { margin: 20px 0; }
    table { width: 100%; border-collapse: collapse; }
    td { padding: 12px 14px; border-bottom: 1px solid #eee; font-size: 14px; }
    td.label { color: #666; width: 35%; font-weight: 500; }
    td.val { font-weight: 600; color: #111; }
    .amount-box { margin: 24px 0; padding: 18px 24px; background: $badgeBgHex; border-radius: 10px; display: flex; justify-content: space-between; align-items: center; border: 1.5px solid $primaryColorHex; }
    .amount-title { font-size: 13px; font-weight: 700; color: #444; }
    .amount-val { font-size: 28px; font-weight: 800; color: $primaryColorHex; }
    .words { font-size: 12px; color: #555; margin-top: 4px; font-style: italic; }
    .footer { margin-top: 40px; display: flex; justify-content: space-between; align-items: flex-end; border-top: 1px dashed #ccc; padding-top: 24px; }
    @media print {
      body { background: #fff; padding: 0; }
      .action-bar { display: none !important; }
      .receipt-card { border: none; box-shadow: none; padding: 10px 0; }
    }
  </style>
</head>
<body>
  <div class="action-bar">
    <button class="btn" onclick="window.print()">🖨️ Print / Save as PDF</button>
  </div>
  <div class="receipt-card">
    <div class="header">
      <div>
        <div class="society-title">${doc.societyName}</div>
        <div class="society-sub">Treasury & Financial Management • ${doc.societyCity}</div>
        <div class="society-sub">Registration No: SOC/GJ/AHM/2024/0981 • Contact: accounts@zenithsquare.com</div>
      </div>
      <div class="badge">${doc.status}</div>
    </div>

    <div class="doc-meta">
      <div class="meta-item">
        <span>Document Type</span>
        <strong>${doc.title}</strong>
      </div>
      <div class="meta-item">
        <span>Receipt / Voucher No.</span>
        <strong>${doc.docNumber}</strong>
      </div>
      <div class="meta-item">
        <span>Date of Transaction</span>
        <strong>${doc.date}</strong>
      </div>
    </div>

    <div class="table-container">
      <table>
        <tr>
          <td class="label">${isIncome ? 'Received From / Head' : 'Paid To / Head'}</td>
          <td class="val">${doc.categoryOrHead}</td>
        </tr>
        <tr>
          <td class="label">Payer / Beneficiary Details</td>
          <td class="val">${doc.payerOrPayee.isNotEmpty ? doc.payerOrPayee : 'Society Treasury Fund'}</td>
        </tr>
        <tr>
          <td class="label">Payment Mode</td>
          <td class="val">${doc.paymentMethod}</td>
        </tr>
        ${doc.description.isNotEmpty ? '''
        <tr>
          <td class="label">Particulars / Remarks</td>
          <td class="val">${doc.description}</td>
        </tr>
        ''' : ''}
        $extraRows
      </table>
    </div>

    <div class="amount-box">
      <div>
        <div class="amount-title">TOTAL AMOUNT ${isIncome ? 'RECEIVED' : 'DISBURSED'}</div>
        <div class="words">$words</div>
      </div>
      <div class="amount-val">₹${doc.amount.toStringAsFixed(2)}</div>
    </div>

    <div class="footer">
      <div style="font-size: 11px; color: #777;">
        <div>Electronic Computer Generated Record</div>
        <div>Zenith Square Co-Op Housing Society Ltd.</div>
      </div>
      <div style="text-align: center;">
        <div style="width: 180px; border-bottom: 1px solid #333; margin-bottom: 6px;"></div>
        <div style="font-size: 12px; font-weight: 600;">Authorized Signatory</div>
        <div style="font-size: 11px; color: #888;">Treasurer / Accounts</div>
      </div>
    </div>
  </div>
</body>
</html>
    ''';
  }
}

/// Visual Dialog Modal in Flutter with full responsive wrapping to prevent overflow
class _FinancialDocumentDialog extends StatelessWidget {
  final FinancialDocument doc;
  const _FinancialDocumentDialog({required this.doc});

  @override
  Widget build(BuildContext context) {
    final themeColor = doc.themeColor;
    final isIncome = doc.isIncome;
    final words = FinancialDocumentHelper.numberToWords(doc.amount);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Header Banner with Integrated Close Button
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                color: themeColor,
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.white24,
                      child: Icon(doc.icon, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            doc.societyName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            doc.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        doc.status,
                        style: TextStyle(
                          color: themeColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 2. Document Number & Date ribbon
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'RECEIPT / VOUCHER NO',
                                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  doc.docNumber,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'TRANSACTION DATE',
                                style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                doc.date,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // 3. Key Details List
                    _infoTile('Category / Head', doc.categoryOrHead),
                    _infoTile('Payer / Beneficiary', doc.payerOrPayee.isNotEmpty ? doc.payerOrPayee : 'Society Treasury'),
                    _infoTile('Payment Method', doc.paymentMethod),
                    if (doc.description.isNotEmpty) _infoTile('Remarks / Details', doc.description),
                    ...doc.extraDetails.entries.map((e) => _infoTile(e.key, e.value)),

                    const Divider(height: 22),

                    // 4. Amount Card
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: themeColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: themeColor.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            isIncome ? 'TOTAL AMOUNT RECEIVED' : 'TOTAL AMOUNT DISBURSED',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: themeColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '₹${doc.amount.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: themeColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            words,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // 5. Verification Stamp row - Responsive Wrap to completely prevent overflow
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified, size: 16, color: Colors.green.shade700),
                            const SizedBox(width: 6),
                            const Text(
                              'Verified Electronic Record',
                              style: TextStyle(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        Text(
                          'Zenith Square Treasury Desk',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // 6. Action Buttons - Download PDF & Print / View PDF
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              backgroundColor: themeColor,
                              foregroundColor: Colors.white,
                              elevation: 1,
                            ),
                            icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                            label: const Text('Download PDF', style: TextStyle(fontWeight: FontWeight.bold)),
                            onPressed: () {
                              FinancialDocumentHelper.downloadDocument(context, doc);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: BorderSide(color: themeColor),
                              foregroundColor: themeColor,
                            ),
                            icon: const Icon(Icons.print_outlined, size: 18),
                            label: const Text('Print / View PDF'),
                            onPressed: () {
                              FinancialDocumentHelper.printDocument(doc);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
