import 'package:flutter/material.dart';

class ReceiptContent extends StatelessWidget {
  final Map<String, dynamic> receiptData;
  final Map<String, dynamic> memberData;
  final bool isMobile;

  const ReceiptContent({
    super.key,
    required this.receiptData,
    required this.memberData,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFDF8F5),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 40,
        vertical: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          Divider(color: const Color(0xFF5D1712), thickness: 1),
          const SizedBox(height: 16),
          
          _buildBillInfo(),
          const SizedBox(height: 24),
          
          _buildDetailRow('பெயர் / Name', memberData['Name'] ?? '-'),
          _buildDetailRow('உறுப்பினர் எண் / ID', memberData['Familymembershipid'] ?? '-'),
          _buildDetailRow('முகவரி / Address', memberData['Village'] ?? '-'),
          _buildDetailRow('நிகழ்ச்சி / Event', receiptData['eventname'] ?? receiptData['EventName'] ?? '-'),
          _buildDetailRow('வகை / Type', receiptData['paymenttype'] ?? receiptData['cashtype'] ?? '-'),
          _buildDetailRow('வங்கி / Bank', receiptData['bankname'] ?? receiptData['banknameforcheckque'] ?? '-'),
          _buildDetailRow('பரிவர்த்தனை ID / Ref', (receiptData['transactionid'] ?? receiptData['upitransactionid'] ?? receiptData['checkqueno'] ?? receiptData['bankrefid'] ?? '-').toString()),
          
          const SizedBox(height: 16),
          const Divider(color: Colors.black12),
          const SizedBox(height: 16),
          
          _buildDetailRow('மொத்த தொகை / Total Amount', '₹${receiptData['TaxAmount'] ?? receiptData['Taxamount'] ?? receiptData['taxamount'] ?? '0.00'}', isBold: true),
          _buildDetailRow('தற்போதைய கட்டணம் / Current Paid', '₹${receiptData['paidamount'] ?? receiptData['paid_amount'] ?? '0.00'}', isBlue: true),
          _buildDetailRow('மொத்தமாக செலுத்தியது / Total Collected', '₹${receiptData['Collectedamount'] ?? receiptData['collected_amount'] ?? receiptData['paidamount'] ?? '0.00'}', isBold: true),
          _buildDetailRow('இருப்பு தொகை / Balance', '₹${receiptData['balanceamount'] ?? receiptData['balance_amount'] ?? '0.00'}', isBold: true, isRed: true),
          _buildDetailRow('பெறப்பட்டவர் / Agent', receiptData['receivedby'] ?? receiptData['receivername'] ?? receiptData['received_by'] ?? '-'),
          
          const SizedBox(height: 40),
          
          _buildSignature(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Image.asset(
          'assets/images/poondurai kaadaikulam image.png',
          width: isMobile ? 60 : 70,
          height: isMobile ? 60 : 70,
        ),
        const SizedBox(height: 12),
        Text(
          'Poondurai Kadai Kulam',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isMobile ? 20 : 24,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E3A8A),
          ),
        ),
        Text(
          'PAYMENT RECEIPT',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isMobile ? 12 : 14,
            letterSpacing: isMobile ? 2 : 3,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildBillInfo() {
    final billNo = (receiptData['id'] ?? receiptData['Id'])?.toString() ?? '-';
    final date = receiptData['paymentdate'] ?? '-';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(4),
      ),
      child: isMobile 
        ? Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('சீட்டு எண் / Bill No:', style: TextStyle(fontSize: 13)),
                  Text(billNo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('தேதி / Date:', style: TextStyle(fontSize: 13)),
                  Text(date, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
            ],
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('சீட்டு எண் / Bill No: ', style: TextStyle(fontSize: 14)),
                  Text(billNo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ],
              ),
              Row(
                children: [
                  const Text('தேதி / Date: ', style: TextStyle(fontSize: 14)),
                  Text(date, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ],
              ),
            ],
          ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false, bool isBlue = false, bool isRed = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: isMobile 
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 2),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isBold || isBlue || isRed ? FontWeight.bold : FontWeight.w600,
                    color: isBlue ? const Color(0xFF5D1712) : (isRed ? Colors.red.shade700 : Colors.black87),
                  ),
                ),
              ),
            ],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 4,
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 15, color: Colors.black87),
                ),
              ),
              const Text(':', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 20),
              Expanded(
                flex: 6,
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isBold || isBlue || isRed ? FontWeight.bold : FontWeight.w600,
                    color: isBlue ? const Color(0xFF5D1712) : (isRed ? Colors.red.shade700 : Colors.black87),
                  ),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildSignature() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Column(
          children: [
            Container(width: isMobile ? 140 : 180, height: 1, color: Colors.black26),
            const SizedBox(height: 8),
            Text('மேலாளர் கையொப்பம்', style: TextStyle(fontSize: isMobile ? 11 : 13, color: Colors.black54)),
            Text('Manager Signature', style: TextStyle(fontSize: isMobile ? 12 : 14, fontWeight: FontWeight.bold, color: Colors.black87)),
          ],
        ),
      ],
    );
  }
}
