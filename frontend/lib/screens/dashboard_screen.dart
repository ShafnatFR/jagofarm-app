import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../widgets/common.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Ringkasan? _ringkasan;
  List<RingkasanBiaya>? _biaya;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        ApiService.getRingkasan(),
        ApiService.getRingkasanBiaya(),
      ]);
      setState(() {
        _ringkasan = results[0] as Ringkasan;
        _biaya = results[1] as List<RingkasanBiaya>;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('JagoFarm', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _loading
          ? const ShimmerDashboard()
          : _error != null ? _buildError() : _buildBody(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Gagal memuat data', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildRingkasanGrid(),
          const SizedBox(height: 20),
          if (_biaya != null && _biaya!.isNotEmpty) ...[
            InfoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Distribusi Biaya',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 220,
                    child: _buildPieChart(),
                  ),
                  const SizedBox(height: 12),
                  ..._buildBiayaLegend(),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRingkasanGrid() {
    final r = _ringkasan;
    if (r == null) return const SizedBox.shrink();

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _ringkasanCard('Total Modal', r.totalModal, Icons.account_balance, AppColors.primary)),
            const SizedBox(width: 12),
            Expanded(child: _ringkasanCard('Total Biaya', r.totalPengeluaran, Icons.shopping_cart, AppColors.accent)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _ringkasanCard('Saldo Kas', r.saldoKas, Icons.account_balance_wallet, r.saldoKas >= 0 ? AppColors.primary : AppColors.negative)),
            const SizedBox(width: 12),
            Expanded(child: _ringkasanCard('Jumlah Ikan', r.jumlahIkan, Icons.set_meal, AppColors.primaryLight, isNumber: true)),
          ],
        ),
      ],
    );
  }

  Widget _ringkasanCard(String label, int value, IconData icon, Color color, {bool isNumber = false}) {
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isNumber ? value.toString() : formatRp(value),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart() {
    final data = _biaya!.where((b) => b.jumlah > 0).toList();
    final colors = [
      Colors.blue,
      Colors.orange,
      Colors.red,
      Colors.purple,
      Colors.teal,
    ];

    return PieChart(
      PieChartData(
        sections: List.generate(data.length, (i) {
          return PieChartSectionData(
            value: data[i].jumlah.toDouble(),
            title: data[i].proporsi,
            radius: 60,
            titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
            color: colors[i % colors.length],
          );
        }),
        sectionsSpace: 2,
        centerSpaceRadius: 30,
      ),
    );
  }

  List<Widget> _buildBiayaLegend() {
    final colors = [Colors.blue, Colors.orange, Colors.red, Colors.purple, Colors.teal];
    return List.generate(_biaya!.length, (i) {
      final b = _biaya![i];
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Container(width: 12, height: 12, decoration: BoxDecoration(color: colors[i], borderRadius: BorderRadius.circular(3))),
            const SizedBox(width: 8),
            Expanded(child: Text(b.kategori, style: const TextStyle(fontSize: 13))),
            Text(formatRp(b.jumlah), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    });
  }
}
