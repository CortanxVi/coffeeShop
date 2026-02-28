import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'omiseService.dart';

class OmisePaymentDialog extends StatefulWidget {
  final String docId;
  final String menuName;
  final double price;
  final Future<void> Function() onPaymentConfirmed;

  const OmisePaymentDialog({
    super.key,
    required this.docId,
    required this.menuName,
    required this.price,
    required this.onPaymentConfirmed,
  });

  @override
  State<OmisePaymentDialog> createState() => _OmisePaymentDialogState();
}

class _OmisePaymentDialogState extends State<OmisePaymentDialog> {
  // 3 states: loading → showQR → success
  _PaymentState _state = _PaymentState.loading;
  OmiseQRResult? _qrResult;
  String _errorMessage = '';
  bool _isConfirming = false;

  @override
  void initState() {
    super.initState();
    _createQR();
  }

  Future<void> _createQR() async {
    setState(() => _state = _PaymentState.loading);
    try {
      final result = await OmiseService.createPromptPaySource(
        amount: widget.price,
        orderId: widget.docId,
      );
      if (mounted) {
        setState(() {
          _qrResult = result;
          _state = _PaymentState.showQR;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _state = _PaymentState.error;
        });
      }
    }
  }

  Future<void> _confirmPayment() async {
    setState(() => _isConfirming = true);
    await widget.onPaymentConfirmed();
    if (mounted) setState(() => _state = _PaymentState.success);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: _buildTitle(),
      content: SizedBox(width: 300, child: _buildContent()),
      actions: _buildActions(),
    );
  }

  Widget _buildTitle() {
    return Row(
      children: [
        Icon(
          _state == _PaymentState.success
              ? Icons.check_circle
              : Icons.qr_code_2,
          color: _state == _PaymentState.success ? Colors.green : Colors.purple,
          size: 28,
        ),
        const SizedBox(width: 8),
        Text(
          _state == _PaymentState.success
              ? 'ชำระเงินสำเร็จ!'
              : 'ชำระเงินด้วย PromptPay',
        ),
      ],
    );
  }

  Widget _buildContent() {
    switch (_state) {
      case _PaymentState.loading:
        return const SizedBox(
          height: 200,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.purple),
              SizedBox(height: 16),
              Text(
                'กำลังสร้าง QR Code...',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        );

      case _PaymentState.showQR:
        return _buildQRContent();

      case _PaymentState.success:
        return _buildSuccessContent();

      case _PaymentState.error:
        return SizedBox(
          height: 150,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 12),
              Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
    }
  }

  Widget _buildQRContent() {
    final qr = _qrResult!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── ชื่อเมนู + ราคา ──
        Text(
          widget.menuName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 4),
        Text(
          '฿${widget.price.toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 28,
            color: Colors.purple,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        // ── QR Code ──
        // ถ้า Omise ส่ง qrString กลับมา → สร้าง QR เอง (คมชัดกว่า)
        // ถ้าไม่มี → โหลดรูปจาก URL ที่ Omise ให้มา
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.purple.shade100),
            borderRadius: BorderRadius.circular(12),
          ),
          child: qr.qrString.isNotEmpty
              ? QrImageView(
                  data: qr.qrString,
                  version: QrVersions.auto,
                  size: 220,
                  backgroundColor: Colors.white,
                )
              : qr.qrImageUrl.isNotEmpty
              ? Image.network(
                  qr.qrImageUrl,
                  width: 220,
                  height: 220,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, progress) => progress == null
                      ? child
                      : const SizedBox(
                          width: 220,
                          height: 220,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                )
              : const Icon(Icons.qr_code, size: 180, color: Colors.grey),
        ),
        const SizedBox(height: 12),

        // ── Omise badge ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.purple.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.purple.shade100),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.verified_user,
                size: 14,
                color: Colors.purple.shade400,
              ),
              const SizedBox(width: 6),
              Text(
                'Secured by Omise',
                style: TextStyle(
                  color: Colors.purple.shade400,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'สแกนด้วยแอปธนาคารได้ทุกเจ้า',
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),

        // ── แสดงเวลาหมดอายุ ──
        if (qr.expiresAt.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            'QR หมดอายุ: ${_formatExpiry(qr.expiresAt)}',
            style: const TextStyle(color: Colors.red, fontSize: 11),
          ),
        ],
      ],
    );
  }

  Widget _buildSuccessContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle, color: Colors.green, size: 80),
        const SizedBox(height: 12),
        Text(
          widget.menuName,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          '฿${widget.price.toStringAsFixed(2)}',
          style: const TextStyle(color: Colors.grey, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'บันทึกลง History แล้ว ✓',
            style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildActions() {
    if (_state == _PaymentState.loading) {
      return [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('ยกเลิก'),
        ),
      ];
    }

    if (_state == _PaymentState.success) {
      return [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () => Navigator.pop(context),
            child: const Text('ปิด', style: TextStyle(color: Colors.white)),
          ),
        ),
      ];
    }

    if (_state == _PaymentState.error) {
      return [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('ปิด'),
        ),
        ElevatedButton(
          onPressed: _createQR, // retry
          child: const Text('ลองใหม่'),
        ),
      ];
    }

    // showQR state
    return [
      TextButton(
        onPressed: _isConfirming ? null : () => Navigator.pop(context),
        child: const Text('ยกเลิก'),
      ),
      ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
        onPressed: _isConfirming ? null : _confirmPayment,
        child: _isConfirming
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text(
                'รับเงินแล้ว ✓',
                style: TextStyle(color: Colors.white),
              ),
      ),
    ];
  }

  String _formatExpiry(String isoString) {
    try {
      final dt = DateTime.parse(isoString).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')} น.';
    } catch (_) {
      return isoString;
    }
  }
}

enum _PaymentState { loading, showQR, success, error }
