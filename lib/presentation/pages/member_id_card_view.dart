import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../utils/api_config.dart';

class MemberIDCardView extends StatefulWidget {
  final Map<String, dynamic> userData;
  final VoidCallback onBack;

  const MemberIDCardView({
    super.key,
    required this.userData,
    required this.onBack,
  });

  @override
  State<MemberIDCardView> createState() => _MemberIDCardViewState();
}

class _MemberIDCardViewState extends State<MemberIDCardView> {
  final ScreenshotController _frontController = ScreenshotController();
  final ScreenshotController _backController = ScreenshotController();

  // ID Card Dimensions (Standard CR80: 85.6 x 54 mm)
  final double cardWidth = 85.6 * 5.0; // High resolution
  final double cardHeight = 54 * 5.0;

  Future<void> _printIDCard() async {
    final frontImage = await _frontController.capture();
    final backImage = await _backController.capture();

    if (frontImage == null || backImage == null) return;

    final pdf = pw.Document();
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Header(level: 0, child: pw.Text("Member ID Card")),
              pw.SizedBox(height: 20),
              pw.Center(
                child: pw.Image(
                  pw.MemoryImage(frontImage),
                  width: PdfPageFormat.mm * 85.6,
                  height: PdfPageFormat.mm * 54,
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Center(
                child: pw.Image(
                  pw.MemoryImage(backImage),
                  width: PdfPageFormat.mm * 85.6,
                  height: PdfPageFormat.mm * 54,
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'ID_Card_${widget.userData['Familymembershipid']}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leadingWidth: 120,
        leading: InkWell(
          onTap: widget.onBack,
          borderRadius: BorderRadius.circular(4),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(width: 16),
              Icon(Icons.arrow_back, color: Colors.black87, size: 20),
              SizedBox(width: 8),
              Text(
                'Back',
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: ElevatedButton.icon(
                onPressed: _printIDCard,
                icon: const Icon(Icons.print, size: 18),
                label: const Text('Print ID Card (85.6x54mm)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B4332), // Dark Green from template
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              // Front Card
              Screenshot(
                controller: _frontController,
                child: _buildFrontCard(),
              ),
              const SizedBox(height: 40),
              // Back Card
              Screenshot(
                controller: _backController,
                child: _buildBackCard(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFrontCard() {
    return Container(
      width: cardWidth,
      height: cardHeight,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF4A0404), // Dark Maroon
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Stack(
        children: [
          // Background Temple Illustration
          Positioned(
            right: -10,
            bottom: 20,
            child: Opacity(
              opacity: 0.08,
              child: Image.asset('assets/images/Kovil.jpeg', height: cardHeight * 0.9),
            ),
          ),
          
          Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Column: Logo and Photo
                      Column(
                        children: [
                          Image.asset(
                            'assets/images/poondurai kaadaikulam image.png',
                            height: 55,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: 90,
                            height: 110,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: const Color(0xFFD4AF37), width: 2.5),
                              borderRadius: BorderRadius.circular(8),
                              image: (widget.userData['Memberimage'] != null && widget.userData['Memberimage'].toString().isNotEmpty)
                                  ? DecorationImage(
                                      image: NetworkImage('${ApiConfig.baseUrl}/assets/uploads/${widget.userData['Memberimage']}'),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: (widget.userData['Memberimage'] == null || widget.userData['Memberimage'].toString().isEmpty)
                                ? const Icon(Icons.person, size: 40, color: Colors.grey)
                                : null,
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              border: Border.all(color: const Color(0xFFD4AF37), width: 1.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              widget.userData['Familymembershipid'] ?? '-',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      // Right Column: Title and Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              'பூந்துறை காடை குல',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFFD700),
                                letterSpacing: 0.5,
                              ),
                            ),
                            const Text(
                              'மக்கள் நற்பணி மன்றம்',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFFD700),
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Divider(color: Color(0xFFD4AF37), thickness: 0.8, height: 8),
                            const SizedBox(height: 8),
                            _buildIconDetail(Icons.account_circle, widget.userData['Name'] ?? '-'),
                            _buildIconDetail(Icons.phone, widget.userData['Phonenumber']?.toString() ?? '-'),
                            _buildIconDetail(Icons.water_drop, widget.userData['Bloodgroup'] ?? '-'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Footer: Emergency Contact
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                decoration: const BoxDecoration(
                  color: Color(0xFF003D2B), // Dark Green
                  border: Border(top: BorderSide(color: Color(0xFFD4AF37), width: 1.5)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.call, color: Color(0xFFFFD700), size: 14),
                    SizedBox(width: 6),
                    Text(
                      'Emergency Contact : 99526 93122 / 99524 93122',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 9),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBackCard() {
    return Container(
      width: cardWidth,
      height: cardHeight,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF4A0404), // Dark Maroon
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Stack(
        children: [
          // Background Temple Illustrations
          Positioned(
            left: -10,
            bottom: 20,
            child: Opacity(
              opacity: 0.08,
              child: Image.asset('assets/images/Kovil.jpeg', height: cardHeight * 0.9),
            ),
          ),
          Positioned(
            right: -10,
            bottom: 20,
            child: Opacity(
              opacity: 0.08,
              child: Image.asset('assets/images/Kovil.jpeg', height: cardHeight * 0.9),
            ),
          ),
          
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 12),
              // QR Code with Logo
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFD4AF37), width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    QrImageView(
                      data: widget.userData['Familymembershipid'] ?? 'N/A',
                      version: QrVersions.auto,
                      size: 100.0,
                    ),
                    Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(2.0),
                        child: Image.asset('assets/images/poondurai kaadaikulam image.png'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Scan to view member details',
                style: TextStyle(color: Color(0xFFFFD700), fontSize: 9, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Divider(color: Color(0xFFD4AF37), thickness: 0.8, indent: 50, endIndent: 50, height: 8),
              const SizedBox(height: 6),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'ஸ்ரீ கிருஷ்ணா டவர், கதவு எண்.75/2, முத்துகுமாரசாமி கோவில் வீதி,\nஅவல்பூந்துறை, ஈரோடு மாவட்டம் - 638115',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w500, height: 1.4),
                ),
              ),
              const Spacer(),
              // Footer
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                decoration: const BoxDecoration(
                  color: Color(0xFF003D2B), // Dark Green
                  border: Border(top: BorderSide(color: Color(0xFFD4AF37), width: 1.5)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.language, color: Color(0xFFFFD700), size: 14),
                    SizedBox(width: 8),
                    Text(
                      'kaadaikulam.org',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconDetail(IconData icon, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: const BoxDecoration(
              color: Color(0xFFFFD700),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 14, color: Colors.black),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
