import 'dart:convert';
import 'package:http/http.dart' as http;

class OmiseService {
  // ใส่ Test Public Key ของคุณตรงนี้
  static const String _publicKey = 'pkey_test_66uzucfc9riyx5wjjbx';
  static const String _baseUrl = 'https://api.omise.co';

  /// สร้าง PromptPay Source → ได้ QR Code กลับมา
  static Future<OmiseQRResult> createPromptPaySource({
    required double amount, // หน่วยเป็น บาท (ไม่ใช่ สตางค์)
    required String orderId,
  }) async {
    try {
      // Omise ใช้หน่วยเป็นสตางค์ (x100)
      final amountSatang = (amount * 100).toInt();

      final response = await http.post(
        Uri.parse('$_baseUrl/sources'),
        headers: {
          // ใช้ Public Key สำหรับ create source
          'Authorization': 'Basic ${base64Encode(utf8.encode('$_publicKey:'))}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'amount': amountSatang,
          'currency': 'thb',
          'type': 'promptpay',
          // reference ส่งเพื่อ track order
          'metadata': {'order_id': orderId},
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return OmiseQRResult(
          sourceId: data['id'] ?? '',
          // scannable_code.image.download_uri คือ URL รูป QR จาก Omise
          qrImageUrl: data['scannable_code']?['image']?['download_uri'] ?? '',
          // qr_code คือ string สำหรับสร้าง QR เอง
          qrString: data['scannable_code']?['qr_code'] ?? '',
          amount: amount,
          expiresAt: data['expires_at'] ?? '',
        );
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Omise API Error');
      }
    } catch (e) {
      throw Exception('เชื่อมต่อ Omise ไม่ได้: $e');
    }
  }
}

/// Model เก็บผลลัพธ์จาก Omise
class OmiseQRResult {
  final String sourceId;
  final String qrImageUrl; // URL รูป QR จาก Omise
  final String qrString; // String สำหรับสร้าง QR เอง
  final double amount;
  final String expiresAt;

  OmiseQRResult({
    required this.sourceId,
    required this.qrImageUrl,
    required this.qrString,
    required this.amount,
    required this.expiresAt,
  });
}
