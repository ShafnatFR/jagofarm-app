"""JagoFarm API"""
import json, os, re
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from google.oauth2.credentials import Credentials
from google.auth.transport.requests import Request
from googleapiclient.discovery import build

app = FastAPI(title="JagoFarm API", version="1.0.2")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Constants ──
SPREADSHEET_ID = "1HwKPfiKPR7iZDQJU_8VtI1KIYOgk--JedW4vTPC4ASg"

# ── Google Sheets Client ──
_sheets = None

def get_google_credentials():
    env_token = os.environ.get("GOOGLE_TOKEN_JSON")
    if env_token:
        token_data = json.loads(env_token)
        creds = Credentials.from_authorized_user_info(token_data)
        return creds
    raise RuntimeError("GOOGLE_TOKEN_JSON not set")

def get_sheets():
    global _sheets
    if _sheets is None:
        creds = get_google_credentials()
        _sheets = build("sheets", "v4", credentials=creds, cache_discovery=False)
    return _sheets

def read_range(range_name):
    sheet = get_sheets()
    result = sheet.spreadsheets().values().get(
        spreadsheetId=SPREADSHEET_ID,
        range=range_name,
    ).execute()
    return result.get("values", [])

def parse_rp(val):
    if val is None:
        return 0
    s = str(val).strip()
    if not s:
        return 0
    s = s.replace("Rp", "").replace("rp", "").replace(" ", "").replace(",", "").replace(".", "")
    s = re.sub(r"[^\d\-]", "", s)
    try:
        return int(s)
    except ValueError:
        return 0

# ── Endpoints ──

@app.get("/api/health")
def health_check():
    return {"status": "ok", "spreadsheet": "JagoFarmV2"}

@app.get("/api/ringkasan")
def ringkasan():
    rows = read_range("'Dashboard'!B2:E5")
    result = {"total_modal": 0, "total_pengeluaran": 0, "saldo_kas": 0, "jumlah_ikan": 0}
    for r in rows:
        if len(r) < 2:
            continue
        label = str(r[0]).strip().lower()
        val = parse_rp(r[1]) if len(r) > 1 else 0
        if "modal" in label:
            result["total_modal"] = val
        elif "pengeluaran" in label or "biaya" in label:
            result["total_pengeluaran"] = val
        elif "kas" in label or "bank" in label:
            result["saldo_kas"] = val
        elif "ikan" in label:
            result["jumlah_ikan"] = val
    return result

@app.get("/api/ringkasan-biaya")
def ringkasan_biaya():
    rows = read_range("'Dashboard'!B7:C12")
    items = []
    for r in rows:
        if len(r) >= 1 and str(r[0]).strip():
            items.append({
                "kategori": str(r[0]).strip(),
                "jumlah": parse_rp(r[1]) if len(r) > 1 else 0,
                "proporsi": str(r[2]).strip() if len(r) > 2 else "",
            })
    return items

@app.get("/api/transaksi")
def get_transaksi(limit: int = 50, offset: int = 0):
    rows = read_range("'Input Transaksi'!A2:I500")
    items = []
    for r in rows:
        if len(r) >= 1 and str(r[0]).strip():
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

@app.get("/api/daftar-akun")
def get_daftar_akun():
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

@app.get("/api/neraca-saldo")
def get_neraca_saldo():
    rows = read_range("'Neraca Saldo'!A2:E20")
    items = []
    for r in rows:
        if len(r) >= 2 and str(r[0]).strip():
            items.append({
                "kode": str(r[0]).strip(),
                "nama_akun": str(r[1]).strip() if len(r) > 1 else "",
                "debit": parse_rp(r[2]) if len(r) > 2 else 0,
                "kredit": parse_rp(r[3]) if len(r) > 3 else 0,
                "kategori": str(r[4]).strip() if len(r) > 4 else "",
            })
    return items

@app.get("/api/laporan-keuangan")
def get_laporan_keuangan():
    # Laba Rugi
    lr_rows = read_range("'Laba Rugi'!A2:C20")
    laba_rugi = []
    for r in lr_rows:
        if len(r) >= 1 and str(r[0]).strip():
            laba_rugi.append({
                "label": str(r[0]).strip(),
                "jumlah": parse_rp(r[1]) if len(r) > 1 else 0,
                "is_total": str(r[2]).strip().lower() == "total" if len(r) > 2 else False,
            })

    # Neraca Saldo (reuse)
    ns_rows = read_range("'Neraca Saldo'!A2:E20")
    neraca_saldo = []
    for r in ns_rows:
        if len(r) >= 2 and str(r[0]).strip():
            neraca_saldo.append({
                "kode": str(r[0]).strip(),
                "nama_akun": str(r[1]).strip() if len(r) > 1 else "",
                "debit": parse_rp(r[2]) if len(r) > 2 else 0,
                "kredit": parse_rp(r[3]) if len(r) > 3 else 0,
                "kategori": str(r[4]).strip() if len(r) > 4 else "",
            })

    # Arus Kas
    ak_rows = read_range("'Arus Kas'!A2:C20")
    arus_kas = []
    for r in ak_rows:
        if len(r) >= 1 and str(r[0]).strip():
            arus_kas.append({
                "label": str(r[0]).strip(),
                "jumlah": parse_rp(r[1]) if len(r) > 1 else 0,
                "is_total": str(r[2]).strip().lower() == "total" if len(r) > 2 else False,
            })

    # Biaya Per Ikan
    bp_rows = read_range("'Biaya Per Ikan'!A2:E10")
    biaya_per_ikan = []
    for r in bp_rows:
        if len(r) >= 2 and str(r[0]).strip():
            biaya_per_ikan.append({
                "kategori": str(r[0]).strip(),
                "nila": parse_rp(r[1]) if len(r) > 1 else 0,
                "gurame": parse_rp(r[2]) if len(r) > 2 else 0,
                "bawal": parse_rp(r[3]) if len(r) > 3 else 0,
                "total": parse_rp(r[4]) if len(r) > 4 else 0,
            })

    # Neraca
    n_rows = read_range("'Neraca'!A2:C20")
    neraca = []
    for r in n_rows:
        if len(r) >= 1 and str(r[0]).strip():
            neraca.append({
                "label": str(r[0]).strip(),
                "jumlah": parse_rp(r[1]) if len(r) > 1 else 0,
                "is_total": str(r[2]).strip().lower() == "total" if len(r) > 2 else False,
                "side": str(r[3]).strip() if len(r) > 3 else "",
            })

    return {
        "laba_rugi": laba_rugi,
        "neraca": neraca,
        "arus_kas": arus_kas,
        "biaya_per_ikan": biaya_per_ikan,
        "neraca_saldo": neraca_saldo,
    }
