class Ringkasan {
  final int totalModal;
  final int totalPengeluaran;
  final int saldoKas;
  final int jumlahIkan;

  Ringkasan({
    required this.totalModal,
    required this.totalPengeluaran,
    required this.saldoKas,
    required this.jumlahIkan,
  });

  factory Ringkasan.fromJson(Map<String, dynamic> json) {
    return Ringkasan(
      totalModal: (json['total_modal'] as num?)?.toInt() ?? 0,
      totalPengeluaran: (json['total_pengeluaran'] as num?)?.toInt() ?? 0,
      saldoKas: (json['saldo_kas'] as num?)?.toInt() ?? 0,
      jumlahIkan: (json['jumlah_ikan'] as num?)?.toInt() ?? 0,
    );
  }
}

class RingkasanBiaya {
  final String kategori;
  final int jumlah;
  final String proporsi;

  RingkasanBiaya({
    required this.kategori,
    required this.jumlah,
    required this.proporsi,
  });

  factory RingkasanBiaya.fromJson(Map<String, dynamic> json) {
    return RingkasanBiaya(
      kategori: json['kategori'] as String? ?? '',
      jumlah: (json['jumlah'] as num?)?.toInt() ?? 0,
      proporsi: json['proporsi'] as String? ?? '',
    );
  }
}

class TransaksiItem {
  final String tanggal;
  final String keterangan;
  final String akunDebit;
  final String akunKredit;
  final int nominal;
  final String kategoriBarang;
  final String qty;
  final String hargaSatuan;
  final String toko;

  TransaksiItem({
    required this.tanggal,
    required this.keterangan,
    required this.akunDebit,
    required this.akunKredit,
    required this.nominal,
    required this.kategoriBarang,
    required this.qty,
    required this.hargaSatuan,
    required this.toko,
  });

  factory TransaksiItem.fromJson(Map<String, dynamic> json) {
    return TransaksiItem(
      tanggal: json['tanggal'] as String? ?? '',
      keterangan: json['keterangan'] as String? ?? '',
      akunDebit: json['akun_debit'] as String? ?? '',
      akunKredit: json['akun_kredit'] as String? ?? '',
      nominal: (json['nominal'] as num?)?.toInt() ?? 0,
      kategoriBarang: json['kategori_barang'] as String? ?? '',
      qty: json['qty'] as String? ?? '',
      hargaSatuan: json['harga_satuan'] as String? ?? '',
      toko: json['toko'] as String? ?? '',
    );
  }
}

class AkunItem {
  final String kode;
  final String nama;
  final String kategori;
  final String kodeNama;
  final String saldoNormal;

  AkunItem({
    required this.kode,
    required this.nama,
    required this.kategori,
    required this.kodeNama,
    required this.saldoNormal,
  });

  factory AkunItem.fromJson(Map<String, dynamic> json) {
    return AkunItem(
      kode: json['kode'] as String? ?? '',
      nama: json['nama'] as String? ?? '',
      kategori: json['kategori'] as String? ?? '',
      kodeNama: json['kode_nama'] as String? ?? '',
      saldoNormal: json['saldo_normal'] as String? ?? '',
    );
  }
}

class NeracaSaldoItem {
  final String kode;
  final String namaAkun;
  final int debit;
  final int kredit;
  final String kategori;

  NeracaSaldoItem({
    required this.kode,
    required this.namaAkun,
    required this.debit,
    required this.kredit,
    required this.kategori,
  });

  factory NeracaSaldoItem.fromJson(Map<String, dynamic> json) {
    return NeracaSaldoItem(
      kode: json['kode'] as String? ?? '',
      namaAkun: json['nama_akun'] as String? ?? '',
      debit: (json['debit'] as num?)?.toInt() ?? 0,
      kredit: (json['kredit'] as num?)?.toInt() ?? 0,
      kategori: json['kategori'] as String? ?? '',
    );
  }
}

class LabaRugiItem {
  final String label;
  final int jumlah;
  final bool isTotal;

  LabaRugiItem({
    required this.label,
    required this.jumlah,
    this.isTotal = false,
  });

  factory LabaRugiItem.fromJson(Map<String, dynamic> json) {
    return LabaRugiItem(
      label: json['label'] as String? ?? '',
      jumlah: (json['jumlah'] as num?)?.toInt() ?? 0,
      isTotal: json['is_total'] as bool? ?? false,
    );
  }
}

class BiayaPerIkanItem {
  final String kategori;
  final int nila;
  final int gurame;
  final int bawal;
  final int total;

  BiayaPerIkanItem({
    required this.kategori,
    required this.nila,
    required this.gurame,
    required this.bawal,
    required this.total,
  });

  factory BiayaPerIkanItem.fromJson(Map<String, dynamic> json) {
    return BiayaPerIkanItem(
      kategori: json['kategori'] as String? ?? '',
      nila: (json['nila'] as num?)?.toInt() ?? 0,
      gurame: (json['gurame'] as num?)?.toInt() ?? 0,
      bawal: (json['bawal'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? 0,
    );
  }
}

class ArusKasItem {
  final String label;
  final int jumlah;
  final bool isTotal;

  ArusKasItem({
    required this.label,
    required this.jumlah,
    this.isTotal = false,
  });

  factory ArusKasItem.fromJson(Map<String, dynamic> json) {
    return ArusKasItem(
      label: json['label'] as String? ?? '',
      jumlah: (json['jumlah'] as num?)?.toInt() ?? 0,
      isTotal: json['is_total'] as bool? ?? false,
    );
  }
}

class LaporanKeuangan {
  final List<LabaRugiItem> labaRugi;
  final List<NeracaSaldoItem> neracaSaldo;
  final List<BiayaPerIkanItem> biayaPerIkan;
  final List<ArusKasItem> arusKas;

  LaporanKeuangan({
    required this.labaRugi,
    required this.neracaSaldo,
    required this.biayaPerIkan,
    required this.arusKas,
  });

  factory LaporanKeuangan.fromJson(Map<String, dynamic> json) {
    return LaporanKeuangan(
      labaRugi: (json['laba_rugi'] as List?)
              ?.map((e) => LabaRugiItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      neracaSaldo: (json['neraca_saldo'] as List?)
              ?.map((e) => NeracaSaldoItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      biayaPerIkan: (json['biaya_per_ikan'] as List?)
              ?.map((e) => BiayaPerIkanItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      arusKas: (json['arus_kas'] as List?)
              ?.map((e) => ArusKasItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
