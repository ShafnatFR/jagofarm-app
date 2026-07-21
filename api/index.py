"""JagoFarm API — Vercel serverless entry point"""
import json, os, re
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from google.oauth2.credentials import Credentials
from google.auth.transport.requests import Request
from googleapiclient.discovery import build

app = FastAPI(title="JagoFarm API", version="1.0.2")

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
    expose_headers=["*"],
)

@app.middleware("http")
async def cors_header(request, call_next):
    response = await call_next(request)
    response.headers["Access-Control-Allow-Origin"] = "*"
    response.headers["Access-Control-Allow-Methods"] = "*"
    response.headers["Access-Control-Allow-Headers"] = "*"
    return response

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

def parse_rp(val):
    if val is None: return 0
    # If already a number, return directly
    if isinstance(val, (int, float)):
        return int(val)
    s = str(val).strip()
    if not s: return 0
    # Remove "Rp" prefix
    s = s.replace("Rp","").replace("rp","").strip()
    # Indonesia format uses comma as decimal: "1.234.567,89"
    # Split by comma, take integer part only
    s = s.split(",")[0]
    # Remove dots (thousand separator)
    s = s.replace(".","")
    # Keep only digits
    s = re.sub(r"[^\d\-]", "", s)
    try: return int(s)
    except: return 0

@app.get("/api/health")
def health():
    return {"status":"ok","spreadsheet":"JagoFarmV2"}

@app.get("/api/ringkasan")
def ringkasan():
    # Label di kolom A (A2:A5), value di kolom B (B2:B5)
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
    # Kategori di kolom A, jumlah di B, proporsi di C
    rows = read_range("'Dashboard'!A7:C12")
    items = []
    for r in rows:
        if len(r)>=2 and str(r[0]).strip() and str(r[0]).strip() not in ("Jumlah", "Kategori", ""):
            items.append({"kategori":str(r[0]).strip(),"jumlah":parse_rp(r[1]) if len(r)>1 else 0,"proporsi":str(r[2]).strip() if len(r)>2 else ""})
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
