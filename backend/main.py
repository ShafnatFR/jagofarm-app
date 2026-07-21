"""
JagoFarm API — Read-only bridge from Google Sheets to Flutter app.
Supports local file & production (env var) deployment.
"""
import json, os, re
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional

from google.oauth2.credentials import Credentials
from google.auth.transport.requests import Request
from googleapiclient.discovery import build

app = FastAPI(title="JagoFarm API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Constants ───────────────────────────────────────────────
SPREADSHEET_ID = "1HwKPfiKPR7iZDQJU_8VtI1KIYOgk--JedW4vTPC4ASg"
LOCAL_TOKEN_PATH = r"C:\Users\shafnats\AppData\Local\hermes\google_token.json"

# ── Google Sheets Client ────────────────────────────────────
_sheets = None

def get_google_credentials():
    """Get credentials from env var (production) or local file (development)."""
    env_token = os.environ.get("GOOGLE_TOKEN_JSON")
    if env_token:
        # Production: from environment variable (set in Railway)
        token_data = json.loads(env_token)
        creds = Credentials.from_authorized_user_info(token_data)
        return creds

    # Development: from local file
    if os.path.exists(LOCAL_TOKEN_PATH):
        with open(LOCAL_TOKEN_PATH) as f:
            token_data = json.load(f)
        creds = Credentials.from_authorized_user_info(token_data)
        creds.refresh(Request())
        # save refreshed token back
        token_data["token"] = creds.token
        token_data["expiry"] = creds.expiry.isoformat() if creds.expiry else None
        with open(LOCAL_TOKEN_PATH, "w") as f:
            json.dump(token_data, f)
        return creds

    raise RuntimeError(
        "No Google credentials found. "
        "Set GOOGLE_TOKEN_JSON env var or ensure google_token.json exists."
    )

def get_sheets():
    global _sheets
    if _sheets:
        return _sheets
    creds = get_google_credentials()
    _sheets = build("sheets", "v4", credentials=creds)
    return _sheets


# ── Helpers ─────────────────────────────────────────────────
def parse_rp(text: str) -> int:
    """Parse 'Rp 871.109,00' → 871109 (int)."""
    if not text:
        return 0
    text = str(text).strip()
    text = text.replace("Rp ", "").replace("Rp", "")
    text = text.replace(".", "").replace(",00", "").replace(",", "")
    text = text.replace("−", "-").replace("(", "-").replace(")", "")
    try:
        return int(float(text))
    except ValueError:
        return 0


def read_range(range_str: str, fmt: str = "FORMATTED_VALUE") -> list[list]:
    """Read a range from the spreadsheet."""
    s = get_sheets()
    r = s.spreadsheets().values().get(
        spreadsheetId=SPREADSHEET_ID, range=range_str, valueRenderOption=fmt
    ).execute()
    return r.get("values", [])


# ── Response Models ──────────────────────────────────────────
class Ringkasan(BaseModel):
    total_modal: int
    total_pengeluaran: int
    saldo_kas: int
    jumlah_ikan: int

class TransaksiItem(BaseModel):
    tanggal: str
    keterangan: str
    akun_debit: str
    akun_kredit: str
    nominal: int
    kategori_barang: str = ""
    qty: str = ""
    harga_satuan: str = ""
    toko: str = ""

class AkunItem(BaseModel):
    kode: str
    nama: str
    kategori: str
    kode_nama: str
    saldo_normal: str

class NeracaSaldoItem(BaseModel):
    kode: str
    nama_akun: str
    debit: int
    kredit: int
    kategori: str
    kode_nama: str = ""

class LabaRugiItem(BaseModel):
    label: str
    jumlah: int
    is_total: bool = False

class NeracaItem(BaseModel):
    label: str
    jumlah: int
    is_total: bool = False
    side: str = "aset"  # aset | kewajiban

class ArusKasItem(BaseModel):
    label: str
    jumlah: int
    is_total: bool = False

class BiayaPerIkanItem(BaseModel):
    kategori: str
    nila: int
    gurame: int
    bawal: int
    total: int

class LaporanKeuangan(BaseModel):
    laba_rugi: list[LabaRugiItem]
    neraca: list[NeracaItem]
    arus_kas: list[ArusKasItem]
    biaya_per_ikan: list[BiayaPerIkanItem]
    neraca_saldo: list[NeracaSaldoItem]


# ── Endpoints ────────────────────────────────────────────────

@app.get("/api/ringkasan")
def get_ringkasan():
    """Ringkasan dari Dashboard."""
    rows = read_range("'Dashboard'!A1:E6")
    ringkasan = {}
    for r in rows:
        if len(r) >= 1:
            label = str(r[0]).strip()
            val = str(r[1]).strip() if len(r) > 1 else "0"
            if "Total Modal" in label:
                ringkasan["total_modal"] = parse_rp(val)
            elif "Total Pengeluaran" in label:
                ringkasan["total_pengeluaran"] = parse_rp(val)
            elif "Saldo Kas" in label:
                ringkasan["saldo_kas"] = parse_rp(val)
            elif "Jumlah Ikan" in label:
                ringkasan["jumlah_ikan"] = int(parse_rp(val) or 0)
    return ringkasan


@app.get("/api/ringkasan-biaya")
def get_ringkasan_biaya():
    """Kategori biaya dari Dashboard (rows 11-15)."""
    rows = read_range("'Dashboard'!A11:C16")
    items = []
    for r in rows:
        if len(r) >= 3 and str(r[0]).strip() and "Total" not in str(r[0]):
            items.append({
                "kategori": str(r[0]).strip(),
                "jumlah": parse_rp(r[1]),
                "proporsi": str(r[2]).strip(),
            })
    return items


@app.get("/api/transaksi")
def get_transaksi(limit: int = 50, offset: int = 0):
    """Daftar transaksi dari Input Transaksi (baris 2+)."""
    rows = read_range("'Input Transaksi'!A2:I1005")
    items = []
    for r in rows[offset:offset+limit]:
        if len(r) >= 5 and str(r[0]).strip():
            items.append({
                "tanggal": str(r[0]).strip(),
                "keterangan": str(r[1]).strip() if len(r) > 1 else "",
                "akun_debit": str(r[2]).strip() if len(r) > 2 else "",
                "akun_kredit": str(r[3]).strip() if len(r) > 3 else "",
                "nominal": parse_rp(r[4]) if len(r) > 4 else 0,
                "kategori_barang": str(r[5]).strip() if len(r) > 5 else "",
                "qty": str(r[6]).strip() if len(r) > 6 else "",
                "harga_satuan": str(r[7]).strip() if len(r) > 7 else "",
                "toko": str(r[8]).strip() if len(r) > 8 else "",
            })
    return items


@app.get("/api/transaksi/filter")
def filter_transaksi(kategori: str = "", ikan: str = ""):
    """Filter transaksi by kategori barang or ikan keyword."""
    items = get_transaksi(limit=1000, offset=0)
    if kategori:
        items = [i for i in items if kategori.lower() in i["akun_debit"].lower() or kategori.lower() in i["kategori_barang"].lower()]
    if ikan:
        items = [i for i in items if ikan.lower() in i["keterangan"].lower()]
    return items


@app.get("/api/daftar-akun")
def get_daftar_akun():
    """Daftar akun."""
    rows = read_range("'Daftar Akun'!A2:E30")
    items = []
    for r in rows:
        if len(r) >= 2 and str(r[0]).strip():
            items.append({
                "kode": str(r[0]).strip(),
                "nama": str(r[1]).strip() if len(r) > 1 else "",
                "kategori": str(r[2]).strip() if len(r) > 2 else "",
                "kode_nama": str(r[3]).strip() if len(r) > 3 else str(r[0]).strip() + " - " + str(r[1]).strip(),
                "saldo_normal": str(r[4]).strip() if len(r) > 4 else "",
            })
    return items


@app.get("/api/jurnal-umum")
def get_jurnal_umum(limit: int = 50, offset: int = 0):
    """Jurnal Umum."""
    rows = read_range("'Jurnal Umum'!A2:F500")
    items = []
    for r in rows:
        if len(r) >= 6 and str(r[0]).strip():
            items.append({
                "no": str(r[0]).strip(),
                "tanggal": str(r[1]).strip(),
                "akun": str(r[2]).strip() if len(r) > 2 else "",
                "ref": str(r[3]).strip() if len(r) > 3 else "",
                "debit": parse_rp(r[4]) if len(r) > 4 else 0,
                "kredit": parse_rp(r[5]) if len(r) > 5 else 0,
            })
    return items


@app.get("/api/neraca-saldo")
def get_neraca_saldo():
    """Neraca Saldo."""
    rows = read_range("'Neraca Saldo'!A2:E30")
    items = []
    for r in rows:
        if len(r) >= 2 and str(r[0]).strip():
            items.append({
                "kode": str(r[0]).strip(),
                "nama_akun": str(r[1]).strip() if len(r) > 1 else "",
                "debit": parse_rp(r[2]) if len(r) > 2 else 0,
                "kredit": parse_rp(r[3]) if len(r) > 3 else 0,
                "kategori": str(r[4]).strip() if len(r) > 4 else "",
                "kode_nama": str(r[5]).strip() if len(r) > 5 else "",
            })
    return items


@app.get("/api/laporan-keuangan")
def get_laporan_keuangan():
    """All laporan keuangan in one call."""
    # Laba Rugi
    lr_rows = read_range("'Laba Rugi'!A1:B15")
    laba_rugi = []
    for r in lr_rows:
        if len(r) >= 1:
            label = str(r[0]).strip()
            val = str(r[1]).strip() if len(r) > 1 else ""
            if label and "LAPORAN" not in label:
                is_total = "Total" in label
                laba_rugi.append({
                    "label": label.strip(),
                    "jumlah": parse_rp(val),
                    "is_total": is_total,
                })

    # Neraca
    nr_rows = read_range("'Neraca'!A1:E16")
    neraca = []
    for r in nr_rows:
        if len(r) >= 1:
            label_a = str(r[0]).strip()
            val_b = parse_rp(r[1]) if len(r) > 1 and str(r[1]).strip() else 0
            label_c = str(r[2]).strip() if len(r) > 2 else ""
            val_d = parse_rp(r[3]) if len(r) > 3 and str(r[3]).strip() else 0
            if label_a and "LAPORAN" not in label_a and "ASET" not in label_a and "KEWAJIBAN" not in label_a:
                is_total = "Total" in label_a
                neraca.append({
                    "label": label_a.strip(),
                    "jumlah": val_b,
                    "is_total": is_total,
                    "side": "aset",
                })
            if label_c and "EKUITAS" not in label_c and "Kewajiban" not in label_c:
                is_total = "Total" in label_c
                neraca.append({
                    "label": label_c.strip(),
                    "jumlah": val_d,
                    "is_total": is_total,
                    "side": "kewajiban",
                })

    # Arus Kas
    ak_rows = read_range("'Arus Kas'!A1:B16")
    arus_kas = []
    for r in ak_rows:
        if len(r) >= 1:
            label = str(r[0]).strip()
            val = str(r[1]).strip() if len(r) > 1 else ""
            if label and "LAPORAN" not in label:
                is_total = "Bersih" in label or "Kas Akhir" in label
                arus_kas.append({
                    "label": label.strip(),
                    "jumlah": parse_rp(val),
                    "is_total": is_total,
                })

    # Biaya Per Ikan
    bp_rows = read_range("'Biaya Per Ikan'!A1:E6")
    biaya_per_ikan = []
    for r in bp_rows:
        if len(r) >= 5 and str(r[0]).strip():
            biaya_per_ikan.append({
                "kategori": str(r[0]).strip(),
                "nila": parse_rp(r[1]) if len(r) > 1 else 0,
                "gurame": parse_rp(r[2]) if len(r) > 2 else 0,
                "bawal": parse_rp(r[3]) if len(r) > 3 else 0,
                "total": parse_rp(r[4]) if len(r) > 4 else 0,
            })

    # Neraca Saldo
    ns_items = get_neraca_saldo()

    return {
        "laba_rugi": laba_rugi,
        "neraca": neraca,
        "arus_kas": arus_kas,
        "biaya_per_ikan": biaya_per_ikan,
        "neraca_saldo": ns_items,
    }


@app.get("/api/health")
def health():
    return {"status": "ok", "spreadsheet": "JagoFarmV2"}


if __name__ == "__main__":
    import uvicorn
    port = int(os.environ.get("PORT", 8000))
    uvicorn.run(app, host="0.0.0.0", port=port)
