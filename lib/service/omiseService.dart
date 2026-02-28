import 'dart:convert';

class OmiseQRResult {
  final String sourceId;
  final String qrImageUrl;
  final String qrString;
  final String expiresAt;
  final double amount;

  OmiseQRResult({
    required this.sourceId,
    required this.qrImageUrl,
    required this.qrString,
    required this.expiresAt,
    required this.amount,
  });
}

class OmiseService {
  // ── ใส่ Public Key ของ Omise ตรงนี้ (Test Key) ──
  static const String _publicKey = 'pkey_test_66uzucfc9riyx5wjjbx';

  static Future<OmiseQRResult> createPromptPaySource({
    required double amount,
    required String orderId,
  }) async {
    const promptPayNumber = '0972949796';

    final qrString = _buildPromptPayPayload(promptPayNumber, amount);

    // สร้าง expiry 15 นาทีข้างหน้า
    final expiresAt = DateTime.now()
        .add(const Duration(minutes: 15))
        .toIso8601String();

    return OmiseQRResult(
      sourceId: 'local_${DateTime.now().millisecondsSinceEpoch}',
      qrImageUrl: '', // ไม่ใช้ image URL แล้ว ใช้ qrString แทน
      qrString: qrString,
      expiresAt: expiresAt,
      amount: amount,
    );
  }

  // ── สร้าง PromptPay EMVCo Payload มาตรฐาน ──
  // ธนาคารไทยทุกเจ้ารองรับ format นี้
  static String _buildPromptPayPayload(String phoneNumber, double amount) {
    // แปลงเบอร์โทร เป็นเลข 0066812345678
    String normalized = phoneNumber.replaceAll(RegExp(r'[\s\-]'), '');
    if (normalized.startsWith('0') && normalized.length == 10) {
      normalized = '0066${normalized.substring(1)}';
    }

    // จำนวนเงิน format: 65.00
    final amountStr = amount.toStringAsFixed(2);

    // สร้าง EMVCo TLV payload
    String payload = '';
    payload += _tlv('00', '01'); // Payload Format
    payload += _tlv('01', '12'); // Static QR
    payload += _tlv(
      '29', // PromptPay
      _tlv('00', 'A000000677010111') + _tlv('01', normalized),
    );
    payload += _tlv('53', '764'); // THB
    payload += _tlv('54', amountStr); // Amount
    payload += _tlv('58', 'TH'); // Country
    payload += _tlv('62', _tlv('07', 'WanWanCafe')); // Reference
    payload += '6304'; // CRC tag

    // คำนวณ CRC-16
    final crc = _crc16(payload);
    payload += crc;

    return payload;
  }

  static String _tlv(String tag, String value) {
    final len = value.length.toString().padLeft(2, '0');
    return '$tag$len$value';
  }

  // CRC-16/CCITT-FALSE — มาตรฐาน EMVCo
  static String _crc16(String data) {
    int crc = 0xFFFF;
    for (int i = 0; i < data.length; i++) {
      crc ^= data.codeUnitAt(i) << 8;
      for (int j = 0; j < 8; j++) {
        crc = (crc & 0x8000) != 0
            ? ((crc << 1) ^ 0x1021) & 0xFFFF
            : (crc << 1) & 0xFFFF;
      }
    }
    return crc.toRadixString(16).toUpperCase().padLeft(4, '0');
  }
}
