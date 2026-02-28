import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../service/omiseService.dart';

class PaymentScreen extends StatefulWidget {
  final double totalAmount;
  final String orderId;

  const PaymentScreen({
    super.key,
    required this.totalAmount,
    required this.orderId,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  OmiseQRResult? _qrResult;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _createQR();
  }

  Future<void> _createQR() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final result = await OmiseService.createPromptPaySource(
        amount: widget.totalAmount,
        orderId: widget.orderId,
      );
      if (mounted) {
        setState(() {
          _qrResult = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  String _formatExpiry(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')} น.';
    } catch (_) {
      return '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ชำระเงิน PromptPay'),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _isLoading
              ? const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'กำลังสร้าง QR Code...',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                )
              : _errorMessage.isNotEmpty
              ? _buildErrorView()
              : _buildQRView(),
        ),
      ),
    );
  }

  Widget _buildQRView() {
    final qr = _qrResult!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Header ──
        const Icon(Icons.qr_code_2, size: 40, color: Colors.purple),
        const SizedBox(height: 8),
        const Text(
          'สแกน QR Code เพื่อชำระเงิน',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        Text(
          'รองรับทุกธนาคารในไทย',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        const SizedBox(height: 20),

        // ── QR Code Box ──
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.purple.shade100, width: 2),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.coffee, color: Colors.brown, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'WanWan Cafe',
                    style: TextStyle(
                      color: Colors.brown[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── QrImageView: ไม่มี Int64 ไม่มี network โหลด ──
              QrImageView(
                data: qr.qrString,
                version: QrVersions.auto,
                size: 240,
                backgroundColor: Colors.white,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: Colors.black,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Colors.black,
                ),
                errorStateBuilder: (_, error) => SizedBox(
                  width: 240,
                  height: 240,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 40,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$error',
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),
              Text(
                'สแกนด้วยแอปธนาคาร',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ── ยอดเงิน ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.purple.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.purple.shade100),
          ),
          child: Text(
            '฿${widget.totalAmount.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.purple,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // ── หมดอายุ ──
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.timer_outlined, size: 14, color: Colors.red),
            const SizedBox(width: 4),
            Text(
              'QR หมดอายุ: ${_formatExpiry(qr.expiresAt)}',
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // ── PromptPay badge ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.blue.shade100),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.verified_user, size: 14, color: Colors.blue.shade400),
              const SizedBox(width: 6),
              Text(
                'PromptPay มาตรฐาน BOT',
                style: TextStyle(
                  color: Colors.blue.shade400,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── ปุ่มสร้าง QR ใหม่ ──
        OutlinedButton.icon(
          onPressed: _createQR,
          icon: const Icon(Icons.refresh, size: 16),
          label: const Text('สร้าง QR ใหม่'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.purple,
            side: BorderSide(color: Colors.purple.shade200),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.error_outline, size: 60, color: Colors.red),
        ),
        const SizedBox(height: 16),
        const Text(
          'ไม่สามารถสร้าง QR ได้',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            _errorMessage,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: _createQR,
          icon: const Icon(Icons.refresh),
          label: const Text('ลองใหม่'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.brown,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}
