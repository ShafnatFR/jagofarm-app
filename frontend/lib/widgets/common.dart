import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Format angka ke Rupiah
String formatRp(int amount) {
  final formatter = NumberFormat('#,###', 'id_ID');
  return 'Rp ${formatter.format(amount)}';
}

/// Warna brand JagoFarm
class AppColors {
  static const primary = Color(0xFF2E7D32);
  static const primaryLight = Color(0xFF4CAF50);
  static const primaryDark = Color(0xFF1B5E20);
  static const accent = Color(0xFFFF8F00);
  static const surface = Color(0xFFF5F5F5);
  static const cardBg = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF212121);
  static const textSecondary = Color(0xFF757575);
  static const positive = Color(0xFF2E7D32);
  static const negative = Color(0xFFC62828);
  static const warning = Color(0xFFF57F17);
}

/// Card dengan shadow
class InfoCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;

  const InfoCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: color,
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}

/// Loading shimmer placeholder
class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const ShimmerBox({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.radius = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Label jumlah nominal dengan warna
class NominalLabel extends StatelessWidget {
  final String label;
  final int jumlah;
  final bool showColor;

  const NominalLabel({
    super.key,
    required this.label,
    required this.jumlah,
    this.showColor = false,
  });

  @override
  Widget build(BuildContext context) {
    Color? color;
    if (showColor) {
      color = jumlah >= 0 ? AppColors.positive : AppColors.negative;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(child: Text(label, style: const TextStyle(fontSize: 14))),
          const SizedBox(width: 8),
          Text(
            formatRp(jumlah.abs()),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
