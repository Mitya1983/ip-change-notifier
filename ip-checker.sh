#!/bin/bash

trap 'log "Service stopped"; exit 0' SIGINT SIGTERM

command -v jq >/dev/null || { echo "jq is required but not installed"; exit 1; }

check_ip() {
    local response
    tmp_ip_file=$(mktemp)
    response=$(curl -s -w "%{http_code}" -o "$tmp_ip_file" https://api.ipify.org?format=json)

    if [[ "$response" != "200" ]]; then
        echo "Failed to fetch IP"
        return 1
    fi

    jq -r '.ip' "$tmp_ip_file"
    rm -f "$tmp_ip_file"
}

working_directory="$HOME/.ip-change-notifier"

log() {
    local message="$1"
    local timestamp
    timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo "[$timestamp] $message" >> "$working_directory/log.log"
}

if [[ ! -d "$working_directory" ]]; then
    mkdir -p "$working_directory" || exit 1
fi
cd "$working_directory" || exit 2
current_ip_file="$working_directory/current_ip"
g_ip=""
log "Service start"
if [[ -f "$current_ip_file" ]]; then
    log "$current_ip_file exists. Thus retrieving IP from file"
    g_ip=$(<"$current_ip_file")
fi

if [[ -n "$g_ip" ]]; then
    log "Successfully retrieved IP from file - $g_ip"
fi
log "Starting main loop"
while true; do
    new_ip=$(check_ip)
    if [[ $? -ne 0 || -z "$new_ip" ]]; then
        log "Failed to retrieve new IP"
        sleep 60
        continue
    fi
    if [[ "$g_ip" != "$new_ip" ]]; then
        echo "IP has changed from $g_ip to $new_ip"
        g_ip="$new_ip"
        echo "$g_ip" > "$current_ip_file"
        if echo "$g_ip" | mail -s "New IP" mitia.tristan@pm.me; then
            log "Sent IP change notification"
        else
            log "Failed to send email"
        fi
    else
        log "IP had not changed"
    fi
    sleep 60
done
