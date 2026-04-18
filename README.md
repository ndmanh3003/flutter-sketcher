# Sketcher - ứng dụng vẽ vector bằng Flutter

Sketcher là một ứng dụng vẽ 2D nhẹ, tập trung vào các thao tác cơ bản như vẽ hình, tô màu hình, quản lý lịch sử thao tác và nhập/xuất file ảnh/binary.


## Thành viên nhóm

1. 22127259 - Nguyễn Đức Mạnh
2. 23127075 - Lê Trung Kiên
3. 23127205 - Lâm Hữu Khánh
4. 23127303 - Hồ Tấn Quốc
5. 23127326 - Lê Mai Hoài Bảo
6. 23127510 - Phùng Ngọc Tuấn

## Chức năng chính

- Vẽ các hình cơ bản: point, line, ellipse, circle, square, rectangle.
- 3 chế độ thao tác: Draw, Fill và Move.
- Tô màu bucket fill cho các hình (ellipse, circle, square, rectangle).
- Điều chỉnh stroke width, stroke color và fill color.
- Pan/Zoom canvas trong chế độ Move (zoom in, zoom out, reset view).
- Undo/Redo cho nhiều loại thao tác: thêm hình, fill, clear canvas, load scene.
- Lưu và nạp scene nhị phân `.bin` (định dạng riêng `DRW1`).
- Export ảnh ra PNG/JPEG từ canvas hiện tại.

**[Video demo](https://www.youtube.com/)**

## Yêu cầu

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Dự án dùng Dart SDK `^3.11.4` theo `pubspec.yaml`.)

Kiểm tra môi trường:

```bash
flutter doctor
```

## Cách chạy

Trong thư mục dự án (`sketcher/`):

```bash
flutter pub get
flutter run
```

Chạy trên một thiết bị cụ thể (ví dụ Chrome hoặc Windows desktop):

```bash
flutter devices
flutter run -d chrome
flutter run -d windows
```

Chạy test:

```bash
flutter test
```

Phân tích tĩnh:

```bash
flutter analyze
```

## Cấu trúc mã nguồn (`lib/`)

```text
lib/
├── main.dart                     # Điểm vào main(), khởi tạo và chạy app
├── app.dart                      # Cấu hình MaterialApp, theme và màn hình gốc
├── drawing_page.dart             # Màn hình vẽ chính: bố cục stack, gesture, toolbar/flyout
├── controllers/
│   └── drawing_controller.dart   # Trạng thái trung tâm của canvas: draw/fill/move, pan/zoom, undo/redo
├── models/
│   ├── draw_shape.dart           # Model hình vẽ: DrawShape, ShapeType
│   ├── undo_entry.dart           # Định nghĩa các entry cho undo stack
│   ├── redo_entry.dart           # Định nghĩa các entry cho redo stack
│   └── save_format.dart          # Enum định dạng lưu (bin/png/jpeg) và metadata hiển thị
├── services/
│   ├── shape_hit_test.dart       # Hit-test cho từng loại hình (dùng cho bucket fill)
│   ├── scene_codec.dart          # Mã hóa/giải mã scene nhị phân (DRW1)
│   └── file_operations.dart      # Save/Load qua file picker, xuất PNG/JPEG, thông báo kết quả
└── widgets/
    ├── canvas_area.dart          # Vùng canvas có gesture và biến đổi pan/zoom
    ├── drawing_painter.dart      # CustomPainter vẽ shapes và preview shape
    ├── toolbar_widgets.dart      # Toolbar trên/dưới, mode bar, các nút thao tác chính
    ├── flyout_panels.dart        # Các panel flyout: shape, stroke, color, save format
    └── shape_icon_helpers.dart   # Helper icon/glyph cho các loại hình (bao gồm SVG ellipse)
```
