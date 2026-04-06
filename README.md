# Sketcher — ứng dụng vẽ vector đơn giản

Ứng dụng **Flutter** cho phép vẽ các hình cơ bản (điểm, đường thẳng, ellipse, tròn, vuông, chữ nhật), tô màu vùng kín bằng **bucket fill**, điều chỉnh độ dày nét, hoàn tác thao tác, xóa toàn bộ và **lưu/nạp ảnh** theo file nhị phân tự định nghĩa.

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

| Đường dẫn                      | Vai trò                              |
| ------------------------------ | ------------------------------------ |
| `main.dart`                    | `main()` — khởi chạy app             |
| `app.dart`                     | `MaterialApp`, theme, màn hình chính |
| `models/draw_shape.dart`       | `DrawShape`, `ShapeType`             |
| `drawing/drawing_page.dart`    | Canvas, gesture, toolbar, flyout     |
| `drawing/drawing_painter.dart` | `CustomPainter` vẽ hình              |
| `drawing/shape_hit_test.dart`  | Hit-test cho tô màu                  |
| `drawing/scene_codec.dart`     | Encode / decode file nhị phân        |
| `drawing/undo_entry.dart`      | Stack undo (thêm hình / hoàn tác tô) |
| `drawing/toolbar_tool.dart`    | `ToolbarTool` (draw / fill)          |
