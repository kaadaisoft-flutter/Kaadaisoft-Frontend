import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import '../utils/pdf_generator.dart';
import 'receipt_content.dart';

class ReceiptDialog extends StatefulWidget {
  final Map<String, dynamic> receiptData;
  final Map<String, dynamic> memberData;

  const ReceiptDialog({
    super.key,
    required this.receiptData,
    required this.memberData,
  });

  @override
  State<ReceiptDialog> createState() => _ReceiptDialogState();
}

class _ReceiptDialogState extends State<ReceiptDialog> {
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isDownloading = false;
  bool _isPrinting = false;

  Future<void> _handlePdfAction(bool isPrint) async {
    setState(() {
      if (isPrint) {
        _isPrinting = true;
      } else {
        _isDownloading = true;
      }
    });
    
    try {
      final image = await _screenshotController.capture(
        pixelRatio: 1.5,
      );

      if (image != null) {
        if (isPrint) {
          await PdfGenerator.printReceiptImage(image);
        } else {
          await PdfGenerator.downloadReceiptImage(image, widget.receiptData['id']?.toString() ?? 'receipt');
        }
      }
    } catch (e) {
      debugPrint('Error capturing receipt: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isPrinting = false;
          _isDownloading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 600;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 20, vertical: 24),
      child: Container(
        width: isMobile ? double.infinity : 800,
        decoration: BoxDecoration(
          color: const Color(0xFFFDF8F5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            
            Flexible(
              child: SingleChildScrollView(
                child: Screenshot(
                  controller: _screenshotController,
                  child: ReceiptContent(
                    receiptData: widget.receiptData,
                    memberData: widget.memberData,
                    isMobile: isMobile,
                  ),
                ),
              ),
            ),
            
            _buildFooterButtons(context, isMobile),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterButtons(BuildContext context, bool isMobile) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.center,
        children: [
          _ActionButton(
            label: 'Close',
            color: Colors.grey.shade600,
            isMobile: isMobile,
            onPressed: () => Navigator.pop(context),
          ),
          _ActionButton(
            label: _isDownloading ? 'Preparing...' : 'Download PDF',
            color: const Color(0xFF10B981),
            icon: _isDownloading ? null : Icons.download,
            isMobile: isMobile,
            onPressed: (_isDownloading || _isPrinting) ? () {} : () => _handlePdfAction(false),
          ),
          _ActionButton(
            label: _isPrinting ? 'Preparing...' : 'Print Receipt',
            color: const Color(0xFF3B82F6),
            icon: _isPrinting ? null : Icons.print,
            isMobile: isMobile,
            onPressed: (_isDownloading || _isPrinting) ? () {} : () => _handlePdfAction(true),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final VoidCallback onPressed;
  final bool isMobile;

  const _ActionButton({
    required this.label,
    required this.color,
    this.icon,
    required this.onPressed,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 24, 
          vertical: isMobile ? 12 : 15,
        ),
        minimumSize: isMobile ? const Size(120, 45) : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 2,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: isMobile ? 16 : 18),
            const SizedBox(width: 8),
          ],
          Text(
            label, 
            style: TextStyle(
              fontWeight: FontWeight.bold, 
              fontSize: isMobile ? 12 : 14,
            ),
          ),
        ],
      ),
    );
  }
}
