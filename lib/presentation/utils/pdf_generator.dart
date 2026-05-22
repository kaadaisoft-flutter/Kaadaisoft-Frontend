import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'tamil_reshaper.dart';

class PdfGenerator {
  // New methods for image-based generation
  static Future<Uint8List> generateReceiptPdfFromImage(Uint8List imageBytes) async {
    final pdf = pw.Document();
    final image = pw.MemoryImage(imageBytes);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(0), // No margin to allow scaling
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Padding(
              padding: const pw.EdgeInsets.all(40),
              child: pw.Image(image),
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  static Future<void> printReceiptImage(Uint8List imageBytes) async {
    final pdfBytes = await generateReceiptPdfFromImage(imageBytes);
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdfBytes);
  }

  static Future<void> downloadReceiptImage(Uint8List imageBytes, String filename) async {
    final pdfBytes = await generateReceiptPdfFromImage(imageBytes);
    await Printing.sharePdf(bytes: pdfBytes, filename: '$filename.pdf');
  }

  // Original methods (retained for reference or fallback)
  static Future<Uint8List> generateReceiptPdf(
    Map<String, dynamic> receiptData,
    Map<String, dynamic> memberData,
  ) async {
    final pdf = pw.Document();

    // Load Fonts
    final tamilFont = await PdfGoogleFonts.hindMaduraiRegular();
    final boldFont = await PdfGoogleFonts.hindMaduraiBold();
    final standardFont = pw.Font.helvetica();
    final standardBold = pw.Font.helveticaBold();

    // Load Logo
    pw.ImageProvider? logo;
    try {
      final logoData = await rootBundle.load('assets/images/poondurai kaadaikulam image.png');
      logo = pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (e) {
      print('Error loading logo: $e');
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(30),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.blueAccent, width: 1),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Center(
                  child: pw.Column(
                    children: [
                      if (logo != null) pw.Image(logo, width: 70, height: 70),
                      pw.SizedBox(height: 12),
                      pw.Text(
                        'Poondurai Kadai Kulam',
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                      pw.Text(
                        'PAYMENT RECEIPT',
                        style: pw.TextStyle(
                          font: standardFont,
                          fontSize: 14,
                          letterSpacing: 3,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.SizedBox(height: 15),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        color: PdfColors.grey100,
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(TamilReshaper.reshape('சீட்டு எண் / Bill No: ${receiptData['id'] ?? '-'}'), style: pw.TextStyle(font: tamilFont, fontSize: 10, fontWeight: pw.FontWeight.bold)),
                            pw.Text(TamilReshaper.reshape('தேதி / Date: ${receiptData['paymentdate'] ?? '-'}'), style: pw.TextStyle(font: tamilFont, fontSize: 10, fontWeight: pw.FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 25),

                // Details
                _buildPdfDetailRow('பெயர் / Name', memberData['Name'] ?? '-', tamilFont, boldFont),
                _buildPdfDetailRow('உறுப்பினர் எண் / ID', memberData['Familymembershipid'] ?? '-', tamilFont, boldFont),
                _buildPdfDetailRow('முகவரி / Address', memberData['Village'] ?? '-', tamilFont, boldFont),
                _buildPdfDetailRow('நிகழ்ச்சி / Event', receiptData['eventname'] ?? '-', tamilFont, boldFont),
                _buildPdfDetailRow('வகை / Type', receiptData['paymenttype'] ?? '-', tamilFont, boldFont),
                _buildPdfDetailRow('வங்கி / Bank', receiptData['bankname'] ?? '-', tamilFont, boldFont),
                _buildPdfDetailRow('பரிவர்த்தனை ID / Ref', (receiptData['transactionid'] ?? receiptData['upitransactionid'] ?? receiptData['checkqueno'] ?? '-').toString(), tamilFont, boldFont),

                pw.SizedBox(height: 20),
                pw.Divider(thickness: 0.5, color: PdfColors.grey300),
                pw.SizedBox(height: 15),

                // Summary
                _buildPdfDetailRow('மொத்த தொகை / Total', 'Rs. ${receiptData['Taxamount'] ?? '0.00'}', tamilFont, boldFont, isBold: true),
                _buildPdfDetailRow('தற்போதைய கட்டணம் / Current Paid', 'Rs. ${receiptData['paidamount'] ?? '0.00'}', tamilFont, boldFont, isBlue: true),
                _buildPdfDetailRow('மொத்தமாக செலுத்தியது / Total Collected', 'Rs. ${receiptData['Collectedamount'] ?? '0.00'}', tamilFont, boldFont, isBold: true),
                _buildPdfDetailRow('இருப்பு தொகை / Balance', 'Rs. ${receiptData['balanceamount'] ?? '0.00'}', tamilFont, boldFont, isBold: true, isRed: true),

                pw.Spacer(),

                // Signature
                pw.Align(
                  alignment: pw.Alignment.bottomRight,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Container(width: 180, height: 0.5, color: PdfColors.grey),
                      pw.SizedBox(height: 8),
                      pw.Text(TamilReshaper.reshape('மேலாளர் கையொப்பம்'), style: pw.TextStyle(font: tamilFont, fontSize: 9, color: PdfColors.grey700)),
                      pw.Text('Manager Signature', style: pw.TextStyle(font: boldFont, fontSize: 11, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildPdfDetailRow(
    String label, 
    String value, 
    pw.Font font, 
    pw.Font boldFont, {
    bool isBold = false, 
    bool isBlue = false,
    bool isRed = false,
  }) {
    final textColor = isBlue ? PdfColors.blue700 : (isRed ? PdfColors.red700 : PdfColors.black);
    final textFont = isBold || isBlue || isRed ? boldFont : font;
    
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            flex: 5,
            child: pw.Text(TamilReshaper.reshape(label), style: pw.TextStyle(fontSize: 10, font: font, color: PdfColors.grey800)),
          ),
          pw.Text(':', style: pw.TextStyle(fontSize: 10, font: boldFont)),
          pw.SizedBox(width: 20),
          pw.Expanded(
            flex: 5,
            child: pw.Text(
              TamilReshaper.reshape(value),
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(
                fontSize: 11,
                font: textFont,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> printReceipt(Map<String, dynamic> receiptData, Map<String, dynamic> memberData) async {
    final pdfBytes = await generateReceiptPdf(receiptData, memberData);
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdfBytes);
  }

  static Future<void> downloadReceipt(Map<String, dynamic> receiptData, Map<String, dynamic> memberData) async {
    final pdfBytes = await generateReceiptPdf(receiptData, memberData);
    await Printing.sharePdf(bytes: pdfBytes, filename: 'receipt_${receiptData['id']}.pdf');
  }
}
