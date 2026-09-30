import 'package:flutter/material.dart';

/// Header chuẩn dùng chung cho các màn hình theo phong cách iOS
class CustomHeaderAppBar extends StatelessWidget {
  final String title;
  final String subtitle;
  final String roleBadge;
  final Color backgroundColor;
  final bool isDark;

  const CustomHeaderAppBar({
    super.key,
    required this.title,
    required this.subtitle,
    required this.roleBadge,
    this.backgroundColor = const Color(0xFF1A56DB),
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      padding: const EdgeInsets.only(top: 48, bottom: 14, left: 20, right: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  subtitle.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: isDark ? Colors.grey[400] : const Color(0xFFBFDBFE),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.4,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F2937) : Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? Colors.grey[700]! : Colors.white.withOpacity(0.25),
              ),
            ),
            child: Text(
              roleBadge,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey[200] : Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Nút bấm bo tròn pill-shaped lớn ở đáy màn hình
class CustomPrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color textColor;

  const CustomPrimaryButton({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
    this.backgroundColor = const Color(0xFF059669),
    this.textColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          elevation: 4,
          shadowColor: backgroundColor.withOpacity(0.35),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.2,
              ),
            ),
            if (icon != null) ...[
              const SizedBox(width: 8),
              Icon(icon, size: 18),
            ],
          ],
        ),
      ),
    );
  }
}

/// Thẻ thông tin tiêu chuẩn Material 3
class CustomCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color backgroundColor;
  final Color borderColor;

  const CustomCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.backgroundColor = Colors.white,
    this.borderColor = const Color(0xFFF3F4F6),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Thanh trượt xác nhận lấy hàng dành cho tài xế (Swipe to Confirm)
class SwipeToConfirmSlider extends StatefulWidget {
  final String label;
  final VoidCallback onConfirmed;

  const SwipeToConfirmSlider({
    super.key,
    required this.label,
    required this.onConfirmed,
  });

  @override
  State<SwipeToConfirmSlider> createState() => _SwipeToConfirmSliderState();
}

class _SwipeToConfirmSliderState extends State<SwipeToConfirmSlider> {
  double _dragPosition = 0.0;
  bool _isFinished = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxDrag = constraints.maxWidth - 52;
        return Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFF172554), // blue-950
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFF1E40AF).withOpacity(0.6)),
          ),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              // Thanh gradient nền
              Container(
                width: _dragPosition + 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF1E3A8A).withOpacity(0.5),
                      const Color(0xFF2563EB).withOpacity(0.3),
                    ],
                  ),
                ),
              ),
              // Nhãn chữ hướng dẫn
              Center(
                child: Text(
                  widget.label,
                  style: const TextStyle(
                    color: Color(0xFFBFDBFE),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              // Nút tròn kéo
              Positioned(
                left: _dragPosition,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    if (_isFinished) return;
                    setState(() {
                      _dragPosition = (_dragPosition + details.delta.dx)
                          .clamp(0.0, maxDrag);
                    });
                  },
                  onHorizontalDragEnd: (details) {
                    if (_isFinished) return;
                    if (_dragPosition >= maxDrag * 0.75) {
                      setState(() {
                        _dragPosition = maxDrag;
                        _isFinished = true;
                      });
                      widget.onConfirmed();
                    } else {
                      setState(() {
                        _dragPosition = 0.0;
                      });
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A56DB),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.keyboard_double_arrow_right,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// CustomPainter vẽ bản đồ điều phối y tế
class ClinicalMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Nền bản đồ thành phố
    final bgPaint = Paint()..color = const Color(0xFFEBF0F5);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Vẽ các khối nhà đô thị
    final blockPaint = Paint()..color = const Color(0xFFDFE5EC);
    final r = (double l, double t, double w, double h) => RRect.fromRectAndRadius(
      Rect.fromLTWH(l, t, w, h),
      const Radius.circular(8),
    );

    canvas.drawRRect(r(20, 40, 80, 55), blockPaint);
    canvas.drawRRect(r(120, 40, 130, 45), blockPaint);
    canvas.drawRRect(r(270, 40, 95, 80), blockPaint);
    canvas.drawRRect(r(20, 115, 120, 65), blockPaint);
    canvas.drawRRect(r(160, 105, 90, 80), blockPaint);
    canvas.drawRRect(r(270, 140, 95, 90), blockPaint);

    // Khối công viên cây xanh
    final parkPaint = Paint()..color = const Color(0xFFDCFCE7);
    canvas.drawRRect(r(20, 200, 120, 70), parkPaint);

    // Vẽ các trục đường chính
    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 18
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(0, 100), Offset(size.width, 100), roadPaint);
    canvas.drawLine(Offset(148, 20), Offset(148, size.height), roadPaint);
    canvas.drawLine(Offset(260, 20), Offset(260, size.height), roadPaint);

    // Lộ trình di chuyển (Màu xanh đậm từ Kho -> Nhà bệnh nhân)
    final routePaint = Paint()
      ..color = const Color(0xFF1A56DB)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(60, 75)
      ..lineTo(148, 75)
      ..lineTo(148, 160)
      ..lineTo(260, 160)
      ..lineTo(260, 210)
      ..lineTo(310, 210);

    canvas.drawPath(path, routePaint);

    // Điểm xuất phát (Kho dược)
    canvas.drawCircle(const Offset(60, 75), 8, Paint()..color = const Color(0xFF1A56DB));
    canvas.drawCircle(const Offset(60, 75), 4, Paint()..color = Colors.white);

    // Điểm đến (Nhà bệnh nhân Margaret Chen)
    canvas.drawCircle(const Offset(310, 210), 9, Paint()..color = const Color(0xFF059669));
    canvas.drawCircle(const Offset(310, 210), 4, Paint()..color = Colors.white);

    // Vị trí tài xế giao hàng hiện tại (Đang di chuyển trên đường)
    canvas.drawCircle(
      const Offset(210, 160),
      16,
      Paint()..color = const Color(0xFF1A56DB).withOpacity(0.25),
    );
    canvas.drawCircle(const Offset(210, 160), 8, Paint()..color = const Color(0xFF1A56DB));
    canvas.drawCircle(const Offset(210, 160), 3.5, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
