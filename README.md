# Dak Rosa Portal App 🇻🇳 🇺🇸

Ứng dụng giám sát vận hành thời gian thực (Real-time SCADA & Solar Cloud Monitor) dành cho cụm Nhà máy Thủy điện và Điện mặt trời Đăk Rosa.
*A real-time SCADA & Solar Cloud monitoring application for the Dak Rosa Hydroelectric and Solar Power Plant Cluster. Built with Flutter for a highly responsive, modern, and high-performance mobile workspace.*

---

## 🌟 Tính Năng Chính / Key Features

### 📊 Bảng Điều Khiển Tổng Quan / Overview Dashboard
- **VI**: Giám sát công suất tức thời (kW/MW), sản lượng tích lũy trong ngày, số tổ máy đang hoạt động và số inverter trực tuyến. Hiển thị tuổi thọ dữ liệu (Data Age) và trạng thái kết nối mạng SCADA thời gian thực.
- **EN**: Monitor instantaneous generation capacity (kW/MW), cumulative daily yield, active generators, and online solar inverters. View live SCADA network connection status and data latency metrics.

### ☀️ Điện Mặt Trời / Solar Monitoring
- **VI**: Đồng bộ chỉ số thời tiết, bức xạ GHI ($W/m^2$), nhiệt độ tấm pin, nhiệt độ môi trường. Theo dõi trạng thái chi tiết từng bộ biến tần (Inverters) và biểu đồ sản lượng theo Ngày / Tháng / Năm.
- **EN**: Synchronizes live weather indicators, GHI solar irradiance ($W/m^2$), module temperature, and ambient temperature. Displays inverter status logs and historical energy yield charts (Day / Month / Year).

### 💧 Thủy Điện WinCC / Hydro SCADA
- **VI**: Giám sát toàn diện các chỉ số đo lường của 2 nhà máy **Dakrosa 1** và **Dakrosa 2** (Công suất P/Q/S, Điện áp/Dòng điện thanh cái, Tần số, Hệ số công suất $cos\phi$, chỉ số chi tiết của từng tổ máy).
- **EN**: Comprehensive monitoring of measurement metrics for both **Dakrosa 1** and **Dakrosa 2** stations (Active/Reactive/Apparent power, bus voltage, phase current, frequency, power factor $cos\phi$, and individual generator details).

### 🔍 Sơ Đồ SCADA Trực Tuyến / Interactive SCADA Explorer
- **VI**: Bản vẽ sơ đồ đơn tuyến (Single Line Diagram) động hiển thị trực quan trạng thái máy cắt đóng/mở và các trị số đo lường. Hỗ trợ phóng to thu nhỏ đa điểm (Pinch-to-Zoom) và chế độ xem ngang toàn màn hình (Fullscreen).
- **EN**: Dynamic Single Line Diagrams reflecting live breaker states and telemetry overlays. Supports Pinch-to-Zoom gestures, canvas panning, and a dedicated auto-rotating Fullscreen operator view.

### 📈 Hiệu Suất & Môi Trường / Performance & Environmental Impact
- **VI**: Thống kê sản lượng tích lũy và so sánh với mục tiêu kế hoạch. Quy đổi lượng khí thải CO2 giảm thiểu được thành số lượng cây xanh tương đương.
- **EN**: Visualizes cumulative generation against production targets. Translates clean energy output into equivalent metric tons of CO2 offset and trees planted.

### 🗺️ Đa Ngôn Ngữ / Multi-language Support
- **VI**: Hỗ trợ đầy đủ **Tiếng Việt** và **Tiếng Anh**. Tự động định dạng dấu phân cách số theo chuẩn từng vùng địa lý (Việt Nam: `12.345,67` / Anh: `12,345.67`).
- **EN**: Native **English** and **Vietnamese** localizations. Automatically formats decimal and digit separators based on the active locale (Vietnamese: `12.345,67` / English: `12,345.67`).

---

## 🛠️ Công Nghệ Sử Dụng / Tech Stack

- **Flutter SDK**: High-performance cross-platform UI rendering.
- **State Management**: `ValueNotifier` & `ValueListenableBuilder` for reactive, low-overhead dynamic localizations and dashboard updates.
- **Custom Painters**: Renders analog gauge needles and flow indicators dynamically inside the SCADA dashboards.
- **SVG Rendering**: Sharp, scalable vector graphics across varying device DPI profiles using `flutter_svg`.

---

## 📁 Cấu Trúc Thư Mục Dự Án / Project Structure

```text
lib/
├── main.dart                      # App entry point & Locale notifier binding
├── theme/
│   └── app_theme.dart             # Unified color tokens, typography & shadow styles
├── models/
│   ├── wincc_model.dart           # Hydro SCADA WinCC snapshot model
│   ├── solar_model.dart           # Solar Cloud data model
│   └── alert_item.dart            # Incident and health alert definitions
├── services/
│   └── localization_service.dart  # Localization keys, lookup maps & number formatters
├── screens/
│   └── dashboard_screen.dart      # Main coordinate shell with tab controller & header toggle
└── widgets/
    ├── dashboard/                 # Tab panel views
    │   ├── overview_tab.dart
    │   ├── solar_tab.dart
    │   ├── hydro_tab.dart
    │   ├── performance_tab.dart
    │   └── alerts_tab.dart
    └── scada/                     # Vector diagrams & expansion telemetry panels
        ├── dakrosa1_scada_canvas.dart
        ├── dakrosa2_scada_canvas.dart
        └── dakrosa2_unit_pdl_canvas.dart
```

---

## 🚀 Hướng Dẫn Cài Đặt / Getting Started

### Yêu Cầu Hệ Thống / Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) installed.
- iOS Simulator, Android Emulator, or a physical debugging device connected.

### Các Bước Cài Đặt / Installation Steps

1. Clone repository:
   ```bash
   git clone https://github.com/nguyendangkhoa150600/dakrosa-portal-app.git
   ```

2. Fetch pub dependencies:
   ```bash
   flutter pub get
   ```

3. Perform static analysis check:
   ```bash
   flutter analyze
   ```

4. Launch the application in debug mode:
   ```bash
   flutter run
   ```

---

<p align="center">
  Developed by <b>Savina dev</b>
</p>
