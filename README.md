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
- Notify - Send messages via WebHooks to Discord, Slack, or Telegram.

# Setup script

I have included a "setup.sh" file in the GitHub repo. This can be run if you do not want to manually install the tools or Go. Beware though, depending on your setup, the script may not work perfectly. So please "RTFM", and just modify the script as you see fit.
