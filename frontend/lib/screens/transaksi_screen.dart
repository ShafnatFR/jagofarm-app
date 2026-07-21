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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items = await ApiService.getTransaksi(limit: 200);
      setState(() {
        _items = items;
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
        title: const Text('Transaksi', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!),
            const SizedBox(height: 16),
            FilledButton(onPressed: _load, child: const Text('Coba Lagi')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: _items.isEmpty
          ? const Center(child: Text('Belum ada transaksi'))
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _items.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text('${_items.length} transaksi', style: TextStyle(color: AppColors.textSecondary)),
                  );
                }
                return _buildTransaksiCard(_items[index - 1]);
              },
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
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('Hari ke-${item.tanggal}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: debitColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(debitLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: debitColor)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(item.keterangan, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${item.akunDebit} → ${item.akunKredit}',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ),
                Text(formatRp(item.nominal), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: debitColor)),
              ],
            ),
            if (item.kategoriBarang.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('${item.kategoriBarang}${item.qty.isNotEmpty ? " × $item.qty" : ""}',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
            if (item.toko.isNotEmpty) ...[
              const SizedBox(height: 2),
              Icon(Icons.store, size: 12, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(item.toko, style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ],
        ),
      ),
    );
  }
}
