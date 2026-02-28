const functions = require("firebase-functions");
const Omise = require("omise");

// ใส่ Secret Key ของ Omise (Test Key)
const omise = Omise({
  secretKey: "skey_test_66uzucfwulvh2l42bhy", // ← เปลี่ยนเป็นของคุณ
});

exports.createOmiseCharge = functions.https.onCall(async (data, context) => {
  try {
    const amount = data.amount;   // หน่วยเป็นบาท เช่น 65.0
    const orderId = data.orderId;

    // Omise ใช้หน่วยสตางค์ (x100) และต้องเป็น Integer
    const amountSatang = Math.round(amount * 100);

    // สร้าง PromptPay Source
    const source = await omise.sources.create({
      amount: amountSatang,
      currency: "thb",
      type: "promptpay",
      metadata: { order_id: orderId },
    });

    // ── สำคัญ: ส่งตัวเลขทั้งหมดกลับเป็น String ──
    // เพื่อป้องกัน Int64 error บน Flutter Web (dart2js)
    return {
      sourceId: String(source.id),
      qrImageUrl: source.scannable_code?.image?.download_uri ?? "",
      qrString: source.scannable_code?.qr_code ?? "",
      // expiresAt ส่งกลับเป็น ISO String ปกติ
      expiresAt: source.expires_at ?? "",
      // amount ส่งกลับเป็น String ด้วย
      amount: String(amountSatang),
    };
  } catch (e) {
    throw new functions.https.HttpsError(
      "internal",
      `Omise Error: ${e.message}`
    );
  }
});