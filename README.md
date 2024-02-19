# GCP-Genie
A bash tool that looks for vulnerable subdomains for takeover, via unmanaged A records pointing to ephemeral Google owned IP addresses.

~~~
 _____  _____ ______       _____            _      
|  __ \/  __ \| ___ \     |  __ \          (_)     
| |  \/| /  \/| |_/ /_____| |  \/ ___ _ __  _  ___ 
| | __ | |    |  __/______| | __ / _ \ '_ \| |/ _ \
| |_\ \| \__/\| |         | |_\ \  __/ | | | |  __/
 \____/ \____/\_|          \____/\___|_| |_|_|\___|                                                                                   
~~~

# Required Tools

- Subfinder - https://github.com/projectdiscovery/subfinder?tab=readme-ov-file#installation
- HTTPX - https://github.com/projectdiscovery/httpx?tab=readme-ov-file#installation-instructions
- anew - https://github.com/tomnomnom/anew
- dnsutils - sudo apt install dnsutils
- Go - https://go.dev/dl/ (DO NOT INSTALL via APT package manager. Go to the go.dev site and follow the install instructions)

# Optional Tools

- Google Cloud CLI Installer (Depends on your setup.)
