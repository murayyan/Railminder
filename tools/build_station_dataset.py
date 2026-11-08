import json
import urllib.parse
import urllib.request
import sys

# Official lines
LINES = [
    {
        "id": "BOGOR_LINE",
        "name": "Lin Bogor",
        "colorHex": "#E31837",
        "stations": [
            ("JAKK", "Jakarta Kota"), ("JAY", "Jayakarta"), ("MGB", "Mangga Besar"),
            ("SW", "Sawah Besar"), ("JUA", "Juanda"), ("GDD", "Gondangdia"),
            ("CKI", "Cikini"), ("MRI", "Manggarai"), ("TEB", "Tebet"),
            ("CWG", "Cawang"), ("DRN", "Duren Kalibata"), ("PSMB", "Pasar Minggu Baru"),
            ("PSM", "Pasar Minggu"), ("TGB", "Tanjung Barat"), ("LNA", "Lenteng Agung"),
            ("UP", "Universitas Pancasila"), ("UI", "Universitas Indonesia"),
            ("POC", "Pondok Cina"), ("DPB", "Depok Baru"), ("DP", "Depok"),
            ("CTA", "Citayam"), ("CLT", "Cilebut"), ("BOO", "Bogor")
        ]
    },
    {
        "id": "NAMBO_BRANCH",
        "name": "Lin Nambo",
        "colorHex": "#E31837",
        "stations": [
            ("CTA", "Citayam"), ("PDRG", "Pondok Rajeg"), ("CBN", "Cibinong"), ("NBO", "Nambo")
        ]
    },
    {
        "id": "CIKARANG_LINE",
        "name": "Lin Cikarang",
        "colorHex": "#008080",
        "stations": [
            ("CKR", "Cikarang"), ("TLM", "Metland Telagamurni"), ("CBT", "Cibitung"),
            ("TBN", "Tambun"), ("BKST", "Bekasi Timur"), ("BKS", "Bekasi"),
            ("KRJ", "Kranji"), ("CKG", "Cakung"), ("BUA", "Buaran"),
            ("KLDB", "Klender Baru"), ("KLD", "Klender"), ("JNG", "Jatinegara"),
            ("MTR", "Matraman"), ("MRI", "Manggarai"), ("SUD", "Sudirman"),
            ("BNI", "BNI City"), ("KRT", "Karet"), ("THB", "Tanah Abang"),
            ("DU", "Duri"), ("AK", "Angke"), ("KPB", "Kampung Bandan"),
            ("RJW", "Rajawali"), ("KMO", "Kemayoran"), ("PSE", "Pasar Senen"),
            ("GST", "Gang Sentiong"), ("KMT", "Kramat"), ("POK", "Pondok Jati")
        ]
    },
    {
        "id": "RANGKASBITUNG_LINE",
        "name": "Lin Rangkasbitung",
        "colorHex": "#2E7D32",
        "stations": [
            ("THB", "Tanah Abang"), ("PLM", "Palmerah"), ("KBY", "Kebayoran"),
            ("PDR", "Pondok Ranji"), ("JMG", "Jurangmangu"), ("SDM", "Sudimara"),
            ("RW", "Rawa Buntu"), ("SRP", "Serpong"), ("CSK", "Cisauk"),
            ("CC", "Cicayur"), ("PRJ", "Parungpanjang"), ("CJT", "Cilejit"),
            ("DAR", "Daru"), ("TEJ", "Tenjo"), ("TGS", "Tigaraksa"),
            ("CKO", "Cikoya"), ("MJA", "Maja"), ("CTR", "Citeras"),
            ("RK", "Rangkasbitung")
        ]
    },
    {
        "id": "TANGERANG_LINE",
        "name": "Lin Tangerang",
        "colorHex": "#8D6E63",
        "stations": [
            ("DU", "Duri"), ("PSG", "Pesing"), ("TKO", "Taman Kota"),
            ("BDI", "Bojong Indah"), ("RBO", "Rawa Buaya"), ("KLDS", "Kalideres"),
            ("PIW", "Poris"), ("BPR", "Batu Ceper"), ("THT", "Tanah Tinggi"),
            ("TNG", "Tangerang")
        ]
    },
    {
        "id": "TANJUNG_PRIOK_LINE",
        "name": "Lin Tanjung Priuk",
        "colorHex": "#E91E63",
        "stations": [
            ("JAKK", "Jakarta Kota"), ("KPB", "Kampung Bandan"),
            ("AC", "Ancol"), ("TPK", "Tanjung Priuk")
        ]
    }
]

# Query overpass to get exact coordinates for all stations in Jabodetabek
query = """[out:json][timeout:60];
(
  node["railway"="station"](-7.0,106.1,-6.0,107.4);
  node["railway"="halt"](-7.0,106.1,-6.0,107.4);
);
out tags center;"""

req = urllib.request.Request(
    "https://overpass-api.de/api/interpreter?data=" + urllib.parse.quote(query),
    headers={"User-Agent": "RailminderDatasetBuilder/1.0"}
)

try:
    with urllib.request.urlopen(req) as resp:
        osm_data = json.loads(resp.read().decode("utf-8"))
except Exception as e:
    print(f"Failed to fetch OSM data: {e}", file=sys.stderr)
    sys.exit(1)

osm_lookup = {}
for el in osm_data.get("elements", []):
    name = el.get("tags", {}).get("name")
    if name:
        osm_lookup[name.strip().lower()] = (round(el["lat"], 6), round(el["lon"], 6))

# Fallback known official KRL coordinates in case name formatting differs
FALLBACK = {
    "karet": (-6.200833, 106.817500),
    "tanjung barat": (-6.307222, 106.838889),
    "metland telagamurni": (-6.268333, 107.098889),
    "pondok rajeg": (-6.460783, 106.824296),
    "bni city": (-6.201667, 106.820278),
    "matraman": (-6.211944, 106.858056),
    "citeras": (-6.335058, 106.332669),
    "rangkasbitung": (-6.360833, 106.249444),
}

# Resolve stations
stations_dict = {}
lines_output = []
order_counter = 0

for line in LINES:
    line_station_ids = []
    for code, name in line["stations"]:
        line_station_ids.append(code)
        if code not in stations_dict:
            order_counter += 1
            # Coordinate lookup
            k = name.strip().lower()
            coords = osm_lookup.get(k) or FALLBACK.get(k)
            if not coords:
                # try partial match
                for osm_k, c in osm_lookup.items():
                    if k in osm_k or osm_k in k:
                        coords = c
                        break
            if not coords:
                print(f"Missing coords for {name} ({code})", file=sys.stderr)
                sys.exit(1)

            stations_dict[code] = {
                "id": code,
                "name": name,
                "lineIds": [line["id"]],
                "latitude": coords[0],
                "longitude": coords[1],
                "orderIndex": order_counter
            }
        else:
            if line["id"] not in stations_dict[code]["lineIds"]:
                stations_dict[code]["lineIds"].append(line["id"])

    lines_output.append({
        "id": line["id"],
        "name": line["name"],
        "colorHex": line["colorHex"],
        "stationIds": line_station_ids
    })

dataset = {
    "version": "2026-11-08",
    "lines": lines_output,
    "stations": sorted(stations_dict.values(), key=lambda s: s["orderIndex"])
}

with open("assets/data/krl_stations.json", "w", encoding="utf-8") as f:
    json.dump(dataset, f, indent=2, ensure_ascii=False)

print(f"Built assets/data/krl_stations.json: {len(dataset['lines'])} lines, {len(dataset['stations'])} stations.")
