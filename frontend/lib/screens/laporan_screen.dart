import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../widgets/common.dart';

class LaporanScreen extends StatefulWidget {
  const LaporanScreen({super.key});

  @override
  State<LaporanScreen> createState() => _LaporanScreenState();
}

class _LaporanScreenState extends State<LaporanScreen> {
  LaporanKeuangan? _data;
  bool _loading = true;
  String? _error;
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _load();
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
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!),
                      FilledButton(onPressed: _load, child: const Text('Coba Lagi')),
                    ],
                  ),
                )
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        // Tab bar
        Container(
          color: Colors.white,
          child: Row(
            children: [
              _tabButton('Laba Rugi', 0),
              _tabButton('Neraca Saldo', 1),
              _tabButton('Arus Kas', 2),
              _tabButton('Biaya/Ikan', 3),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: _buildTabContent(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _tabButton(String label, int index) {
    final active = _tabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tabIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: active ? AppColors.primary : Colors.transparent,
                width: 2.5,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
              color: active ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildTabContent() {
    if (_data == null) return [];

    switch (_tabIndex) {
      case 0:
        return _buildLabaRugi();
      case 1:
        return _buildNeracaSaldo();
      case 2:
        return _buildArusKas();
      case 3:
        return _buildBiayaPerIkan();
      default:
        return [];
    }
  }

  List<Widget> _buildLabaRugi() {
    final items = _data!.labaRugi;
    if (items.isEmpty) return [const Text('Belum ada data')];

    final list = <Widget>[];
    for (final item in items) {
      if (item.label.isEmpty) {
        list.add(const SizedBox(height: 8));
        continue;
      }
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
                  color: item.isTotal ? AppColors.textPrimary : AppColors.textSecondary,
                ),
              ),
            ),
            Text(
              formatRp(item.jumlah),
              style: TextStyle(
                fontSize: item.isTotal ? 15 : 14,
                fontWeight: item.isTotal ? FontWeight.bold : FontWeight.w600,
                color: item.label.contains('Rugi') && item.jumlah > 0 ? AppColors.negative : null,
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

  List<Widget> _buildNeracaSaldo() {
    final items = _data!.neracaSaldo;
    if (items.isEmpty) return [const Text('Belum ada data')];

    final list = <Widget>[
      Row(
        children: [
          const Expanded(flex: 2, child: Text('Akun', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          const Expanded(flex: 1, child: Text('Debit', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          const Expanded(flex: 1, child: Text('Kredit', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
        ],
      ),
      const Divider(),
    ];

    for (final item in items) {
      list.add(Padding(
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
              child: Text(formatRp(item.debit), textAlign: TextAlign.right, style: TextStyle(fontSize: 12, color: item.debit > 0 ? AppColors.negative : AppColors.textSecondary)),
            ),
            Expanded(
              flex: 1,
              child: Text(formatRp(item.kredit), textAlign: TextAlign.right, style: TextStyle(fontSize: 12, color: item.kredit > 0 ? AppColors.positive : AppColors.textSecondary)),
            ),
          ],
        ),
      ));
    }

    // Total row
    final totalDebit = items.fold(0, (sum, i) => sum + i.debit);
    final totalKredit = items.fold(0, (sum, i) => sum + i.kredit);
    list.add(const Divider());
    list.add(Row(
      children: [
        const Expanded(flex: 2, child: Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
        Expanded(flex: 1, child: Text(formatRp(totalDebit), textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
        Expanded(flex: 1, child: Text(formatRp(totalKredit), textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
      ],
    ));

    return list;
  }

  List<Widget> _buildArusKas() {
    final items = _data!.arusKas;
    if (items.isEmpty) return [const Text('Belum ada data')];

    final list = <Widget>[];
    for (final item in items) {
      if (item.label.isEmpty) {
        list.add(const SizedBox(height: 12));
        continue;
      }
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
      if (item.isTotal) {
        list.add(const Divider());
      }
    }
    return list;
  }

  List<Widget> _buildBiayaPerIkan() {
    final items = _data!.biayaPerIkan;
    if (items.isEmpty) return [const Text('Belum ada data')];

    final list = <Widget>[
      Row(
        children: [
          Expanded(flex: 2, child: Text('Kategori', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          Expanded(child: Text('Nila', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
          Expanded(child: Text('Gurame', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
          Expanded(child: Text('Bawal', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
        ],
      ),
      const Divider(),
    ];

    for (final item in items) {
      final isTotal = item.kategori == 'TOTAL';
      list.add(Padding(
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
            Expanded(child: Text(formatRp(item.nila), textAlign: TextAlign.right, style: TextStyle(fontSize: isTotal ? 13 : 11, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal))),
            Expanded(child: Text(formatRp(item.gurame), textAlign: TextAlign.right, style: TextStyle(fontSize: isTotal ? 13 : 11, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal))),
            Expanded(child: Text(formatRp(item.bawal), textAlign: TextAlign.right, style: TextStyle(fontSize: isTotal ? 13 : 11, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal))),
          ],
        ),
      ));
      if (isTotal) list.add(const Divider());
    }
    return list;
  }
}
