import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:barcode/barcode.dart';
import '../../features/billing/domain/entities/bill.dart';

class PdfHelper {
  static Future<Uint8List> generateReceiptPdf({
    required Bill bill,
    required String address1,
    required String address2,
    required String upiId,
    required String footerText,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80, // A standard 80mm thermal receipt format is perfect
        margin: const pw.EdgeInsets.all(8),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Shop Header
              pw.Center(
                child: pw.Text(
                  bill.shopName.toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              if (address1.isNotEmpty)
                pw.Center(
                  child: pw.Text(
                    address1,
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                ),
              if (address2.isNotEmpty)
                pw.Center(
                  child: pw.Text(
                    address2,
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                ),
              if (bill.shopPhone.isNotEmpty)
                pw.Center(
                  child: pw.Text(
                    'Phone: ${bill.shopPhone}',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                ),
              pw.SizedBox(height: 6),
              pw.Divider(thickness: 1, borderStyle: pw.BorderStyle.dashed),
              
              // Invoice Meta
              pw.Text('Bill ID: ${bill.id.substring(0, 8)}...', style: const pw.TextStyle(fontSize: 8)),
              pw.Text('Date: ${bill.dateTime.toString().split('.')[0]}', style: const pw.TextStyle(fontSize: 8)),
              pw.SizedBox(height: 6),
              pw.Divider(thickness: 1, borderStyle: pw.BorderStyle.dashed),

              // Items Table Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    child: pw.Text('Item', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                    flex: 3,
                  ),
                  pw.Text('Qty', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(width: 8),
                  pw.Text('Rate', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(width: 8),
                  pw.Text('Total', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.Divider(thickness: 0.5),

              // Items Rows
              ...bill.items.map((item) {
                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(
                        child: pw.Text(item.productName, style: const pw.TextStyle(fontSize: 8)),
                        flex: 3,
                      ),
                      pw.Text('${item.quantity}', style: const pw.TextStyle(fontSize: 8)),
                      pw.SizedBox(width: 8),
                      pw.Text('₹${item.price.toStringAsFixed(1)}', style: const pw.TextStyle(fontSize: 8)),
                      pw.SizedBox(width: 8),
                      pw.Text('₹${(item.price * item.quantity).toStringAsFixed(1)}', style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                );
              }),

              pw.Divider(thickness: 1, borderStyle: pw.BorderStyle.dashed),
              pw.SizedBox(height: 4),

              // Grand Total
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('GRAND TOTAL', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  pw.Text('₹${bill.totalAmount.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.SizedBox(height: 8),

              // UPI QR Code (if UPI configured)
              if (upiId.isNotEmpty) ...[
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text('Scan to Pay', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 4),
                      pw.Container(
                        width: 70,
                        height: 70,
                        child: pw.BarcodeWidget(
                          barcode: Barcode.qrCode(),
                          data: 'upi://pay?pa=$upiId&pn=${bill.shopName}&am=${bill.totalAmount.toStringAsFixed(2)}&cu=INR',
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 8),
              ],

              // Footer
              pw.Divider(thickness: 0.5),
              pw.SizedBox(height: 4),
              pw.Center(
                child: pw.Text(
                  footerText.isNotEmpty ? footerText : 'Thank you! Visit again.',
                  style: const pw.TextStyle(fontSize: 8),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static Future<void> sharePdf({
    required Bill bill,
    required String address1,
    required String address2,
    required String upiId,
    required String footerText,
  }) async {
    final pdfBytes = await generateReceiptPdf(
      bill: bill,
      address1: address1,
      address2: address2,
      upiId: upiId,
      footerText: footerText,
    );

    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'receipt_${bill.id.substring(0, 8)}.pdf',
    );
  }
}
