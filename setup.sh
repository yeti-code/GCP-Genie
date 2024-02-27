#!/bin/bash
# Please double check for the latest Go version on their site... and update the below commands with the latest version, or whichever version you need for compatability.
# https://go.dev/dl/

apt update && apt upgrade

apt install dnsutils

curl -OL https://go.dev/dl/go1.22.0.linux-amd64.tar.gz

rm -rf /usr/local/go && tar -C /usr/local -xzf go1.22.0.linux-amd64.tar.gz

echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.profile

source ~/.profile

go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest
go install -v github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest
go install -v github.com/projectdiscovery/notify/cmd/notify@latest
