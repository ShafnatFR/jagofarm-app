"""JagoFarm API — Vercel serverless entry point"""
import json, os, re
from fastapi import FastAPI, Response
from starlette.middleware.base import BaseHTTPMiddleware
from google.oauth2.credentials import Credentials
from google.auth.transport.requests import Request
from googleapiclient.discovery import build

app = FastAPI(title="JagoFarm API", version="1.0.3")

class CORSHeaders(BaseHTTPMiddleware):
    async def dispatch(self, request, call_next):
        response = await call_next(request)
        response.headers["Access-Control-Allow-Origin"] = "*"
        response.headers["Access-Control-Allow-Methods"] = "GET, POST, PUT, DELETE, OPTIONS"
        response.headers["Access-Control-Allow-Headers"] = "*"
        return response

app.add_middleware(CORSHeaders)

SPREADSHEET_ID = "1HwKPfiKPR7iZDQJU_8VtI1KIYOgk--JedW4vTPC4ASg"
_sheets = None

def get_google_credentials():
    env_token = os.environ.get("GOOGLE_TOKEN_JSON")
    if env_token:
        token_data = json.loads(env_token)
        creds = Credentials.from_authorized_user_info(token_data)
        return creds
    raise RuntimeError("GOOGLE_TOKEN_JSON not set in env")

def get_sheets():
    global _sheets
    if _sheets is None:
        creds = get_google_credentials()
        _sheets = build("sheets", "v4", credentials=creds, cache_discovery=False)
    return _sheets

def read_range(range_name):
    sheet = get_sheets()
    result = sheet.spreadsheets().values().get(
        spreadsheetId=SPREADSHEET_ID, range=range_name,
    ).execute()
    return result.get("values", [])

def write_range(range_name, values, mode="USER_ENTERED"):
    sheet = get_sheets()
    body = {"values": values, "majorDimension": "ROWS"}
    result = sheet.spreadsheets().values().update(
        spreadsheetId=SPREADSHEET_ID, range=range_name,
        valueInputOption=mode, body=body
    ).execute()
    return result.get("updatedCells", 0)

def parse_rp(val):
    if val is None: return 0
    if isinstance(val, (int, float)):
        return int(val)
    s = str(val).strip()
    if not s: return 0
    s = s.replace("Rp","").replace("rp","").strip()
    s = s.split(",")[0]
    s = s.replace(".","")
    s = re.sub(r"[^\d\-]", "", s)
    try: return int(s)
    except: return 0

@app.get("/api/health")
def health():
    return {"status":"ok","spreadsheet":"JagoFarmV2"}

@app.get("/api/ringkasan")
def ringkasan():
    rows = read_range("'Dashboard'!A2:B5")
    r = {"total_modal":0,"total_pengeluaran":0,"saldo_kas":0,"jumlah_ikan":0}
    for row in rows:
        if len(row)<2: continue
        label = str(row[0]).strip().lower()
        val = parse_rp(row[1])
        if "modal" in label: r["total_modal"]=val
        elif "pengeluaran" in label or "biaya" in label: r["total_pengeluaran"]=val
        elif "kas" in label or "bank" in label: r["saldo_kas"]=val
        elif "ikan" in label: r["jumlah_ikan"]=val
    return r

@app.get("/api/ringkasan-biaya")
def ringkasan_biaya():
    rows = read_range("'Dashboard'!A10:C18")
    items = []
    for r in rows:
        if len(r)>=2 and str(r[0]).strip() and str(r[0]).strip() not in ("Jumlah", "Kategori", "TOTAL", ""):
            items.append({"kategori":str(r[0]).strip(),"jumlah":parse_rp(r[1]) if len(r)>1 else 0,"proporsi":str(r[2]).strip() if len(r)>2 else ""})
    return items

@app.get("/api/biaya-per-ekor")
def biaya_per_ekor():
    rows = read_range("'Dashboard'!A48:E52")
    items = []
    for r in rows:
        if len(r) >= 2 and str(r[0]).strip() and str(r[0]).strip() not in ("Ikan", ""):
            items.append({"ikan": str(r[0]).strip(), "total": parse_rp(r[1]) if len(r)>1 else 0, "ekor": parse_rp(r[2]) if len(r)>2 else 0, "per_ekor": parse_rp(r[3]) if len(r)>3 else 0, "label": str(r[0]).strip()})
    return items

@app.get("/api/waterfall-kas")
def waterfall_kas():
    rows = read_range("'Dashboard'!A40:B47")
    items = []
    for r in rows:
        if len(r) >= 1 and str(r[0]).strip() and str(r[0]).strip() not in ("Tahap", ""):
            val = str(r[1]).strip() if len(r)>1 else "0"
            items.append({"tahap": str(r[0]).strip(), "nominal": parse_rp(val)})
    return items

@app.get("/api/neraca")
def neraca():
    rows = read_range("'Neraca'!A2:D20")
    items = []
    for r in rows:
        if len(r) >= 1 and str(r[0]).strip():
            val2 = parse_rp(r[1]) if len(r)>1 else 0
            items.append({"label": str(r[0]).strip(), "jumlah": val2, "is_total": "total" in str(r[0]).strip().lower(), "side": "aset"})
    return items

@app.get("/api/transaksi")
def get_transaksi(limit:int=50, offset:int=0):
    rows = read_range("'Input Transaksi'!A2:I500")
    items = []
    for r in rows:
        if len(r)>=1 and str(r[0]).strip():
            items.append({"tanggal":str(r[0]).strip(),"keterangan":str(r[1]).strip() if len(r)>1 else "","akun_debit":str(r[2]).strip() if len(r)>2 else "","akun_kredit":str(r[3]).strip() if len(r)>3 else "","nominal":parse_rp(r[4]) if len(r)>4 else 0,"kategori_barang":str(r[5]).strip() if len(r)>5 else "","qty":str(r[6]).strip() if len(r)>6 else "","harga_satuan":str(r[7]).strip() if len(r)>7 else "","toko":str(r[8]).strip() if len(r)>8 else ""})
    return items

@app.get("/api/daftar-akun")
def daftar_akun():
    rows = read_range("'Daftar Akun'!A2:E30")
    return [{"kode":str(r[0]).strip(),"nama":str(r[1]).strip() if len(r)>1 else "","kategori":str(r[2]).strip() if len(r)>2 else "","kode_nama":str(r[3]).strip() if len(r)>3 else f"{str(r[0]).strip()} - {str(r[1]).strip()}","saldo_normal":str(r[4]).strip() if len(r)>4 else ""} for r in rows if len(r)>=2 and str(r[0]).strip()]

@app.get("/api/neraca-saldo")
def neraca_saldo():
    rows = read_range("'Neraca Saldo'!A2:E20")
    return [{"kode":str(r[0]).strip(),"nama_akun":str(r[1]).strip() if len(r)>1 else "","debit":parse_rp(r[2]) if len(r)>2 else 0,"kredit":parse_rp(r[3]) if len(r)>3 else 0,"kategori":str(r[4]).strip() if len(r)>4 else ""} for r in rows if len(r)>=2 and str(r[0]).strip()]

@app.get("/api/laporan-keuangan")
def laporan_keuangan():
    lr = [{"label":str(r[0]).strip(),"jumlah":parse_rp(r[1]) if len(r)>1 else 0,"is_total":str(r[2]).strip().lower()=="total" if len(r)>2 else False} for r in read_range("'Laba Rugi'!A2:C20") if len(r)>=1 and str(r[0]).strip()]
    ns = [{"kode":str(r[0]).strip(),"nama_akun":str(r[1]).strip() if len(r)>1 else "","debit":parse_rp(r[2]) if len(r)>2 else 0,"kredit":parse_rp(r[3]) if len(r)>3 else 0,"kategori":str(r[4]).strip() if len(r)>4 else ""} for r in read_range("'Neraca Saldo'!A2:E20") if len(r)>=2 and str(r[0]).strip()]
    ak = [{"label":str(r[0]).strip(),"jumlah":parse_rp(r[1]) if len(r)>1 else 0,"is_total":str(r[2]).strip().lower()=="total" if len(r)>2 else False} for r in read_range("'Arus Kas'!A2:C20") if len(r)>=1 and str(r[0]).strip()]
    bp = [{"kategori":str(r[0]).strip(),"nila":parse_rp(r[1]) if len(r)>1 else 0,"gurame":parse_rp(r[2]) if len(r)>2 else 0,"bawal":parse_rp(r[3]) if len(r)>3 else 0,"total":parse_rp(r[4]) if len(r)>4 else 0} for r in read_range("'Biaya Per Ikan'!A2:E10") if len(r)>=2 and str(r[0]).strip()]
    nc = [{"label":str(r[0]).strip(),"jumlah":parse_rp(r[1]) if len(r)>1 else 0,"is_total":str(r[2]).strip().lower()=="total" if len(r)>2 else False,"side":str(r[3]).strip() if len(r)>3 else ""} for r in read_range("'Neraca'!A2:C20") if len(r)>=1 and str(r[0]).strip()]
    return {"laba_rugi":lr,"neraca":nc,"arus_kas":ak,"biaya_per_ikan":bp,"neraca_saldo":ns}

@app.post("/api/auto-journal")
def auto_journal():
    """
    Read Input Transaksi -> Jurnal Umum
    Auto-generate double-entry journal entries for un-posted transactions
    """
    # 1) Read all transactions from Input Transaksi (header row 1, data from row 2)
    tx_rows = read_range("'Input Transaksi'!A2:I1005")
    transaksi = []
    for r in tx_rows:
        if len(r) >= 1 and str(r[0]).strip():
            transaksi.append({
                "tanggal": str(r[0]).strip(),
                "keterangan": str(r[1]).strip() if len(r) > 1 else "",
                "akun_debit": str(r[2]).strip() if len(r) > 2 else "",
                "akun_kredit": str(r[3]).strip() if len(r) > 3 else "",
                "nominal": str(r[4]).strip() if len(r) > 4 else "0",
            })

    # 2) Read existing journal entries
    jurnal_rows = read_range("'Jurnal Umum'!A2:F1000")
    existing_count = len(jurnal_rows)

    # 3) Each transaction = 2 journal rows (Debit + Credit)
    # So if we have N transactions, we need 2*N journal rows
    # existing_count // 2 = number of already-journaled transactions
    already_journalled = existing_count // 2

    if already_journalled >= len(transaksi):
        return {"status": "ok", "message": "Semua transaksi sudah tercatat di Jurnal Umum", "new_entries": 0}

    # 4) Find highest existing journal number
    last_no = 0
    for r in jurnal_rows:
        if len(r) >= 1 and str(r[0]).strip().isdigit():
            last_no = max(last_no, int(str(r[0]).strip()))

    # 5) Generate new journal entries
    new_entries = []
    for i in range(already_journalled, len(transaksi)):
        t = transaksi[i]
        last_no += 1
        # Row 1: Debit side
        new_entries.append([
            str(last_no),
            t["tanggal"],
            t["akun_debit"],
            t["akun_kredit"],
            t["nominal"],
            ""
        ])
        last_no += 1
        # Row 2: Credit side
        new_entries.append([
            str(last_no),
            t["tanggal"],
            t["akun_kredit"],
            t["akun_debit"],
            "",
            t["nominal"]
        ])

    # 6) Write to Jurnal Umum
    start_row = existing_count + 2  # +2 because: A2 is first data row, header is A1
    end_row = start_row + len(new_entries) - 1
    range_name = f"'Jurnal Umum'!A{start_row}:F{end_row}"

    cells = write_range(range_name, new_entries)

    details = []
    for i, t in enumerate(transaksi[already_journalled:]):
        details.append({
            "no": (already_journalled + i + 1),
            "tanggal": t["tanggal"],
            "keterangan": t["keterangan"],
            "debit": t["akun_debit"],
            "kredit": t["akun_kredit"],
            "nominal": t["nominal"]
        })

    return {
        "status": "ok",
        "message": f"Berhasil menjurnal {len(new_entries) // 2} transaksi baru ({len(new_entries)} baris)",
        "new_entries": len(new_entries) // 2,
        "start_row": start_row,
        "end_row": end_row,
        "updated_cells": cells,
        "details": details
    }
