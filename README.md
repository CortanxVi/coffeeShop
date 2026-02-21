# Coffee Shop App - Flutter Application

แอปพลิเคชัน Coffee Shop ที่พัฒนาด้วย Flutter สำหรับสั่งกาแฟออนไลน์

## ฟีเจอร์หลัก

### 1. หน้าแรก (Home Screen)
- แสดงเมนูกาแฟทั้งหมด
- กรองเมนูตามหมวดหมู่ (Hot Coffee, Iced Coffee, Special)
- แสดงรายการกาแฟยอดนิยม (Popular)
- ไอคอนตะกร้าพร้อมแจ้งจำนวนสินค้า

### 2. รายละเอียดสินค้า (Coffee Detail Screen)
- แสดงข้อมูลกาแฟแบบละเอียด
- เลือกขนาดเครื่องดื่ม (Small, Medium, Large)
- ปรับจำนวนสินค้า
- เพิ่มหมายเหตุพิเศษ (เช่น น้ำตาลน้อย)
- แสดงราคารวมแบบเรียลไทม์

### 3. ตะกร้าสินค้า (Cart Screen)
- แสดงรายการสินค้าทั้งหมดในตะกร้า
- ปรับจำนวนสินค้าในตะกร้า
- ลบสินค้าออกจากตะกร้า
- แสดงยอดรวมทั้งหมด
- ยืนยันการสั่งซื้อ

### 4. ประวัติการสั่งซื้อ (Orders Screen)
- แสดงรายการคำสั่งซื้อทั้งหมด
- แสดงรายละเอียดแต่ละออเดอร์
- แสดงสถานะการสั่งซื้อ
- แสดงวันที่และเวลาสั่งซื้อ

## โครงสร้างโปรเจค

```
lib/
├── main.dart                          # Entry point
├── models/                            # Data models
│   ├── coffee.dart                    # Coffee model และข้อมูลเมนู
│   ├── cart_item.dart                 # Cart item model
│   └── order.dart                     # Order model
├── providers/                         # State management
│   ├── cart_provider.dart             # จัดการตะกร้าสินค้า
│   └── order_provider.dart            # จัดการออเดอร์
└── screens/                           # UI screens
    ├── home_screen.dart               # หน้าแรก
    ├── coffee_detail_screen.dart      # รายละเอียดสินค้า
    ├── cart_screen.dart               # ตะกร้าสินค้า
    └── orders_screen.dart             # ประวัติการสั่งซื้อ
```

## เมนูกาแฟในแอป

### Hot Coffee
1. Espresso - 65 บาท
2. Cappuccino - 85 บาท (Popular)
3. Latte - 90 บาท (Popular)
4. Americano - 70 บาท
5. Mocha - 95 บาท

### Iced Coffee
6. Iced Latte - 95 บาท (Popular)
7. Iced Americano - 75 บาท
8. Cold Brew - 100 บาท (Popular)

### Special
9. Caramel Macchiato - 110 บาท (Popular)
10. Affogato - 120 บาท

## การติดตั้ง

### ความต้องการของระบบ
- Flutter SDK (3.0.0 หรือสูงกว่า)
- Dart SDK
- Android Studio / VS Code
- Android Emulator หรือ iOS Simulator

### ขั้นตอนการติดตั้ง

1. Clone หรือดาวน์โหลดโปรเจค

2. เข้าไปในโฟลเดอร์โปรเจค:
```bash
cd coffee_shop_app
```

3. ติดตั้ง dependencies:
```bash
flutter pub get
```

4. รันแอปพลิเคชัน:
```bash
flutter run
```

## Packages ที่ใช้

- **provider**: ^6.0.5 - สำหรับ State Management
- **intl**: ^0.18.1 - สำหรับจัดการรูปแบบวันที่และเวลา

## คุณสมบัติพิเศษ

### ระบบราคา
- ราคาปรับตามขนาด:
  - Small: ราคาปกติ
  - Medium: +20%
  - Large: +50%

### State Management
- ใช้ Provider pattern สำหรับจัดการ state
- Cart Provider จัดการตะกร้าสินค้า
- Order Provider จัดการประวัติการสั่งซื้อ

### UI/UX
- ออกแบบด้วยสี Brown theme ตามธีมร้านกาแฟ
- Responsive design
- แสดงผล emoji แทนรูปภาพเพื่อความเบา
- Smooth animations และ transitions

## การพัฒนาเพิ่มเติม

สามารถปรับปรุงแอปได้โดย:
1. เพิ่มระบบ Authentication
2. เชื่อมต่อกับ Backend API
3. เพิ่มระบบ Payment Gateway
4. เพิ่มรูปภาพจริงของเมนู
5. เพิ่มระบบ Push Notification
6. เพิ่ม Favorites/Wishlist
7. เพิ่มระบบ Rating และ Review
8. เพิ่มระบบโปรโมชั่นและคูปอง

## License

MIT License - ใช้งานได้อย่างอิสระ

## ผู้พัฒนา

พัฒนาโดย Claude (Anthropic)
สร้างเพื่อการศึกษาและใช้งานจริง
