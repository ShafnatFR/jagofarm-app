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

/// ============================================================
/// SKELETON SHIMMER — animasi loading seperti placeholder
/// ============================================================
class ShimmerWidget extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerWidget({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius = 4,
  });

  @override
  State<ShimmerWidget> createState() => _ShimmerWidgetState();
}

class _ShimmerWidgetState extends State<ShimmerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.08, end: 0.3).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          color: Colors.grey.withValues(alpha: _animation.value),
        ),
      ),
    );
  }
}

/// Skeleton untuk dashboard ringkasan (4 shimmer card)
class ShimmerDashboard extends StatelessWidget {
  const ShimmerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _ShimmerCard()),
              SizedBox(width: 12),
              Expanded(child: _ShimmerCard()),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _ShimmerCard()),
              SizedBox(width: 12),
              Expanded(child: _ShimmerCard()),
            ],
          ),
          SizedBox(height: 24),
          ShimmerWidget(height: 220, borderRadius: 12),
          SizedBox(height: 16),
          ShimmerWidget(height: 14),
          SizedBox(height: 8),
          ShimmerWidget(height: 14, width: 150),
        ],
      ),
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  const _ShimmerCard();

  @override
  Widget build(BuildContext context) {
    return const InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerWidget(width: 80, height: 12),
          SizedBox(height: 10),
          ShimmerWidget(width: 120, height: 22),
        ],
      ),
    );
  }
}

/// Skeleton untuk transaksi (5 baris card)
class ShimmerTransaksi extends StatelessWidget {
  const ShimmerTransaksi({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(12),
      child: Column(
        children: [
          _ShimmerTransaksiCard(),
          _ShimmerTransaksiCard(),
          _ShimmerTransaksiCard(),
          _ShimmerTransaksiCard(),
          _ShimmerTransaksiCard(),
        ],
      ),
    );
  }
}

class _ShimmerTransaksiCard extends StatelessWidget {
  const _ShimmerTransaksiCard();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: InfoCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ShimmerWidget(width: 80, height: 20, borderRadius: 6),
                ShimmerWidget(width: 50, height: 20, borderRadius: 6),
              ],
            ),
            SizedBox(height: 10),
            ShimmerWidget(height: 16),
            SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ShimmerWidget(width: 180, height: 12),
                ShimmerWidget(width: 80, height: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton untuk laporan (tab content)
class ShimmerLaporan extends StatelessWidget {
  const ShimmerLaporan({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          ShimmerWidget(height: 16),
          SizedBox(height: 8),
          ShimmerWidget(height: 14),
          SizedBox(height: 6),
          ShimmerWidget(height: 14),
          SizedBox(height: 6),
          ShimmerWidget(height: 14, width: 200),
          SizedBox(height: 20),
          ShimmerWidget(height: 16),
          SizedBox(height: 8),
          ShimmerWidget(height: 14, width: 180),
          SizedBox(height: 20),
          ShimmerWidget(height: 16),
          SizedBox(height: 8),
          ShimmerWidget(height: 14, width: 120),
        ],
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
