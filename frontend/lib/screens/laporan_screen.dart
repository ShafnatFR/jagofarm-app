import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../widgets/common.dart';

class LaporanScreen extends StatefulWidget {
  const LaporanScreen({super.key});

  @override
  State<LaporanScreen> createState() => _LaporanScreenState();
}

class _LaporanScreenState extends State<LaporanScreen> with SingleTickerProviderStateMixin {
  LaporanKeuangan? _data;
  bool _loading = true;
  String? _error;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getLaporanKeuangan();
      setState(() {
        _data = data;
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
        title: const Text('Laporan', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const ShimmerLaporan()
          : _error != null ? _buildError() : _buildContent(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(onPressed: _load, child: const Text('Coba Lagi')),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        // Tab bar — swipeable
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            unselectedLabelStyle: const TextStyle(fontSize: 12),
            isScrollable: false,
            tabs: const [
              Tab(text: 'Laba Rugi'),
              Tab(text: 'Neraca Saldo'),
              Tab(text: 'Arus Kas'),
              Tab(text: 'Biaya/Ikan'),
            ],
          ),
        ),
        const Divider(height: 1),
        // Content — swipeable
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildLabaRugi(),
              _buildNeracaSaldo(),
              _buildArusKas(),
              _buildBiayaPerIkan(),
            ],
          ),
        ),
      ],
    );
  }

  // ==================== LABA RUGI ====================
  Widget _buildLabaRugi() {
    final items = _data!.labaRugi;
    if (items.isEmpty) return const Center(child: Text('Belum ada data'));

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: _buildLabaRugiItems(items),
      ),
    );
  }

  List<Widget> _buildLabaRugiItems(List<LabaRugiItem> items) {
    final list = <Widget>[];
    int? bebanIndex;

    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      if (item.label.isEmpty) {
        list.add(const SizedBox(height: 8));
        continue;
      }
      if (item.label == 'BEBAN') bebanIndex = i;

      // Warna khusus untuk PENDAPATAN, BEBAN, LABA/RUGI
      Color? textColor;
      if (item.label == 'PENDAPATAN') textColor = AppColors.primary;
      if (item.label == 'BEBAN') textColor = AppColors.accent;
      if (item.label == 'LABA/RUGI BERSIH') textColor = item.jumlah < 0 ? AppColors.negative : AppColors.positive;

      list.add(Padding(
        padding: EdgeInsets.symmetric(vertical: item.isTotal ? 8 : 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                item.label,
                style: TextStyle(
                  fontSize: item.isTotal ? 15 : 14,
                  fontWeight: item.isTotal ? FontWeight.bold : FontWeight.normal,
                  color: textColor ?? (item.isTotal ? AppColors.textPrimary : AppColors.textSecondary),
                ),
              ),
            ),
            Text(
              formatRp(item.jumlah),
              style: TextStyle(
                fontSize: item.isTotal ? 15 : 14,
                fontWeight: item.isTotal ? FontWeight.bold : FontWeight.w600,
                color: textColor ?? (item.jumlah < 0 ? AppColors.negative : null),
              ),
            ),
          ],
        ),
      ));

      if (item.isTotal) {
        list.add(const Divider(thickness: 1.5));
      }
    }
    return list;
  }

  // ==================== NERACA SALDO ====================
  Widget _buildNeracaSaldo() {
    final items = _data!.neracaSaldo;
    if (items.isEmpty) return const Center(child: Text('Belum ada data'));

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Expanded(flex: 2, child: Text('Akun', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(flex: 1, child: Text('Debit', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(flex: 1, child: Text('Kredit', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // Items
          ...items.map((item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.kode, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                      Text(item.namaAkun, style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(formatRp(item.debit), textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 12, color: item.debit > 0 ? AppColors.negative : AppColors.textSecondary)),
                ),
                Expanded(
                  flex: 1,
                  child: Text(formatRp(item.kredit), textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 12, color: item.kredit > 0 ? AppColors.positive : AppColors.textSecondary)),
                ),
              ],
            ),
          )),
          // Total
          const Divider(thickness: 1.5),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                const Expanded(flex: 2, child: Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                Expanded(flex: 1, child: Text(formatRp(items.fold(0, (s, i) => s + i.debit)),
                    textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                Expanded(flex: 1, child: Text(formatRp(items.fold(0, (s, i) => s + i.kredit)),
                    textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== ARUS KAS ====================
  Widget _buildArusKas() {
    final items = _data!.arusKas;
    if (items.isEmpty) return const Center(child: Text('Belum ada data'));

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: _buildArusKasItems(items),
      ),
    );
  }

  List<Widget> _buildArusKasItems(List<ArusKasItem> items) {
    final list = <Widget>[];
    for (final item in items) {
      if (item.label.isEmpty) {
        list.add(const SizedBox(height: 12));
        continue;
      }

      // Warna section header
      Color? textColor;
      if (item.label == 'Aktivitas Operasi') textColor = AppColors.primary;
      if (item.label == 'Aktivitas Investasi') textColor = AppColors.accent;
      if (item.label == 'Aktivitas Pendanaan') textColor = Colors.blue[700];

      list.add(Padding(
        padding: EdgeInsets.symmetric(vertical: item.isTotal ? 6 : 3),
        child: Row(
          children: [
            Expanded(
              child: Text(
                item.label,
                style: TextStyle(
                  fontSize: item.isTotal ? 15 : 13,
                  fontWeight: item.isTotal ? FontWeight.bold : FontWeight.normal,
                  color: textColor ?? (item.isTotal ? AppColors.textPrimary : null),
                ),
              ),
            ),
            Text(
              formatRp(item.jumlah.abs()),
              style: TextStyle(
                fontSize: item.isTotal ? 15 : 13,
                fontWeight: item.isTotal ? FontWeight.bold : FontWeight.w600,
                color: item.jumlah < 0 ? AppColors.negative : (item.jumlah > 0 ? AppColors.positive : AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ));
      if (item.isTotal) list.add(const Divider());
    }
    return list;
  }

  // ==================== BIAYA PER IKAN ====================
  Widget _buildBiayaPerIkan() {
    final items = _data!.biayaPerIkan;
    if (items.isEmpty) return const Center(child: Text('Belum ada data'));

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Expanded(flex: 2, child: Text('Kategori', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(child: Text('Nila', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.primary))),
                Expanded(child: Text('Gurame', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.accent))),
                Expanded(child: Text('Bawal', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.blue))),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // Items
          ...items.map((item) {
            final isTotal = item.kategori == 'TOTAL';
            return Padding(
              padding: EdgeInsets.symmetric(vertical: isTotal ? 6 : 3),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      item.kategori,
                      style: TextStyle(
                        fontSize: isTotal ? 13 : 12,
                        fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                  Expanded(child: Text(formatRp(item.nila),
                      textAlign: TextAlign.right,
                      style: TextStyle(fontSize: isTotal ? 13 : 11,
                          fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                          color: isTotal ? AppColors.primary : null))),
                  Expanded(child: Text(formatRp(item.gurame),
                      textAlign: TextAlign.right,
                      style: TextStyle(fontSize: isTotal ? 13 : 11,
                          fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                          color: isTotal ? AppColors.accent : null))),
                  Expanded(child: Text(formatRp(item.bawal),
                      textAlign: TextAlign.right,
                      style: TextStyle(fontSize: isTotal ? 13 : 11,
                          fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                          color: isTotal ? Colors.blue : null))),
                ],
              ),
            );
          }),
          // Total footer
          if (items.isNotEmpty) ...[
            const Divider(thickness: 1.5),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  const Expanded(flex: 2, child: Text('GRAND TOTAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                  Expanded(child: Text(formatRp(items.last.nila), textAlign: TextAlign.right,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                  Expanded(child: Text(formatRp(items.last.gurame), textAlign: TextAlign.right,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                  Expanded(child: Text(formatRp(items.last.bawal), textAlign: TextAlign.right,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
