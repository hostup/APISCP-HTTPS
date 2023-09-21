#!/bin/bash

# Convert IP to its long form
ip_to_long() {
    local ip=$1
    local a b c d
    IFS=. read -r a b c d <<< "$ip"
    echo "$((a * 256 ** 3 + b * 256 ** 2 + c * 256 + d))"
}

# Declare an associative array for Cloudflare IP ranges in long form
declare -A cloudflare_ranges_long

# Populate the associative array
for range in \
    "173.245.48.0/20" "103.21.244.0/22" "103.22.200.0/22" \
    "103.31.4.0/22" "141.101.64.0/18" "108.162.192.0/18" \
    "190.93.240.0/20" "188.114.96.0/20" "197.234.240.0/22" \
    "198.41.128.0/17" "162.158.0.0/15" "104.16.0.0/13" \
    "104.24.0.0/14" "172.64.0.0/13" "131.0.72.0/22"
do
    declare network=$(echo "$range" | cut -d/ -f1)
    declare prefix=$(echo "$range" | cut -d/ -f2)
    declare net_long=$(ip_to_long "$network")
    declare broadcast_long=$(( net_long + (2 ** (32 - prefix)) - 1 ))
    cloudflare_ranges_long["$net_long"]="$broadcast_long"
done

is_cloudflare_ip() {
    local ip_long=$(ip_to_long "$1")
    for net_long in "${!cloudflare_ranges_long[@]}"; do
        if [ "$ip_long" -ge "$net_long" ] && [ "$ip_long" -le "${cloudflare_ranges_long["$net_long"]}" ]; then
            return 0
        fi
    done
    return 1
}

output_file="/etc/httpd/conf.d/ssl_domains.txt"
> "$output_file"
declare -a domains_array

for crt in /home/virtual/*/fst/etc/httpd/conf/ssl.crt/server.crt; do
    if [[ -f "$crt" ]]; then
        alt_names=$(openssl x509 -in "$crt" -noout -text | grep -A1 'Subject Alternative Name:' | tail -n1 | sed s/DNS://g | sed s/,//g)
        for domain in $alt_names; do
            # Convert wildcard domains (*.domain.tld) to www.domain.tld
            if [[ "$domain" == "*."* ]]; then
                domain="www.${domain:2}"
            fi

            if [[ "$domain" =~ ^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*\.[a-zA-Z]{2,}$ ]]; then
                ip_addr=$(dig +short "$domain" | head -n1)
                if [[ "$ip_addr" =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}$ ]] && ! is_cloudflare_ip "$ip_addr"; then
                    domains_array+=("$domain 1")
                fi
            fi
        done
    fi
done

printf "%s\n" "${domains_array[@]}" > "$output_file"
sort -u "$output_file" -o "$output_file"
