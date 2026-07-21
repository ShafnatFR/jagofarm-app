import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../widgets/common.dart';

class TransaksiScreen extends StatefulWidget {
  const TransaksiScreen({super.key});

  @override
  State<TransaksiScreen> createState() => _TransaksiScreenState();
}

class _TransaksiScreenState extends State<TransaksiScreen> {
  List<TransaksiItem> _items = [];
  bool _loading = true;
  String? _error;
  String? _filterKategori;
  List<String> _kategoriList = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items = await ApiService.getTransaksi(limit: 200);
      final kategori = <String>{};
      for (final item in items) {
        if (item.kategoriBarang.isNotEmpty) {
          kategori.add(item.kategoriBarang);
        }
      }
      setState(() {
        _items = items;
        _kategoriList = kategori.toList()..sort();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<TransaksiItem> get _filteredItems {
    if (_filterKategori == null || _filterKategori!.isEmpty) return _items;
    return _items.where((i) => i.kategoriBarang == _filterKategori).toList();
  }

  /// Kelompokkan item per tanggal
  Map<int, List<TransaksiItem>> get _groupedByTanggal {
    final map = <int, List<TransaksiItem>>{};
    for (final item in _filteredItems) {
      final tgl = int.tryParse(item.tanggal) ?? 0;
      map.putIfAbsent(tgl, () => []).add(item);
    }
    return map;
  }

  int get _totalNominal => _filteredItems.fold(0, (s, i) => s + i.nominal);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Transaksi', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const ShimmerTransaksi()
          : _error != null ? _buildError() : _buildBody(),
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

  Widget _buildBody() {
    return RefreshIndicator(
      onRefresh: _load,
      child: CustomScrollView(
        slivers: [
          // Header — total nominal + filter
          SliverToBoxAdapter(child: _buildHeader()),
          if (_kategoriList.isNotEmpty)
            SliverToBoxAdapter(child: _buildFilterChips()),
          // Grouped by tanggal
          for (final entry in _groupedByTanggal.entries.toList()
            ..sort((a, b) => b.key.compareTo(a.key)))
            SliverToBoxAdapter(
              child: _buildTanggalGroup(entry.key, entry.value),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: InfoCard(
        child: Row(
          children: [
            const Icon(Icons.receipt, size: 20, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              '${_filteredItems.length} transaksi',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Text(
              formatRp(_totalNominal),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _filterChip('Semua', null),
            ..._kategoriList.map((k) => _filterChip(k, k)),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, String? value) {
    final active = _filterKategori == value;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label, style: TextStyle(fontSize: 11, color: active ? Colors.white : null)),
        selected: active,
        selectedColor: AppColors.primary,
        checkmarkColor: Colors.white,
        backgroundColor: Colors.white,
        onSelected: (_) => setState(() => _filterKategori = value),
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _buildTanggalGroup(int tgl, List<TransaksiItem> items) {
    // Hari dalam bahasa Indonesia
    final hariList = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    final hari = hariList[(tgl + 5) % 7]; // offset approximation

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label tanggal
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Hari ke-$tgl',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  hari,
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          // Cards
          ...items.map((item) => _buildTransaksiCard(item)),
        ],
      ),
    );
  }

  Widget _buildTransaksiCard(TransaksiItem item) {
    Color debitColor = AppColors.negative;
    String debitLabel = 'Keluar';
    if (item.akunDebit.startsWith('101') || item.akunDebit.startsWith('301') || item.akunDebit.startsWith('4')) {
      debitColor = AppColors.positive;
      debitLabel = 'Masuk';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(item.keterangan, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: debitColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(debitLabel == 'Masuk' ? Icons.arrow_downward : Icons.arrow_upward, size: 12, color: debitColor),
                      const SizedBox(width: 2),
                      Text(debitLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: debitColor)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${item.akunDebit} → ${item.akunKredit}',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ),
                Text(formatRp(item.nominal), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: debitColor)),
              ],
            ),
            if (item.kategoriBarang.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.category_outlined, size: 11, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${item.kategoriBarang}${item.qty.isNotEmpty ? " × $item.qty" : ""}',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ],
            if (item.toko.isNotEmpty) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(Icons.store, size: 11, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(item.toko, style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
