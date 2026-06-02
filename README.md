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

## Git

**Debian/Ubuntu**
~~~
sudo apt install git
~~~
**Arch Linux / Manjaro**
~~~
sudo pacman -S git
~~~

## Dnsutils (dig, nslookup)

**Debian/Ubuntu**
~~~
sudo apt install dnsutils
~~~
**Arch Linux / Manjaro**
~~~
sudo pacman -S bind-tools
~~~

## Google Cloud CLI
Provides the `gcloud` command with CREATE, DELETE, and DESCRIBE API functions.

**Debian/Ubuntu** — follow the official instructions:
https://cloud.google.com/sdk/docs/install#deb

**Arch Linux / Manjaro** — install via AUR (requires yay or paru):
~~~
yay -S google-cloud-cli
~~~
or
~~~
paru -S google-cloud-cli
~~~

## Go

**Recommended for all distros:** Download directly from https://go.dev/dl/ and follow the install instructions. Do NOT install Go via apt or pacman — package manager versions are often outdated and can cause tool compatibility issues.

To remove an older Go install and reinstall from a downloaded tarball:
~~~
rm -rf /usr/local/go && tar -C /usr/local -xzf go1.22.2.linux-amd64.tar.gz
~~~

## curl

**Debian/Ubuntu**
~~~
sudo apt install curl
~~~
**Arch Linux / Manjaro**
~~~
sudo pacman -S curl
~~~

## Python 3

Used to match candidate IPs against GCP's published IP ranges to auto-detect the correct region.

**Debian/Ubuntu**
~~~
sudo apt install python3
~~~
**Arch Linux / Manjaro**
~~~
sudo pacman -S python
~~~

## Go-based Tools
The following tools are installed automatically by `setup.sh` via `go install`:

- Subfinder - https://github.com/projectdiscovery/subfinder?tab=readme-ov-file#installation
- HTTPX - https://github.com/projectdiscovery/httpx?tab=readme-ov-file#installation-instructions
- anew - https://github.com/tomnomnom/anew

# Optional Tools
- Notify - Send messages via WebHooks to Discord, Slack, or Telegram.

# WARNING

Please make sure that the go command and all other tools that were installed via the setup.sh script can be run in your $HOME directory without needing to use the full relative path of the go binary, or the tool binaries.

Go Install Documentation (If you need help):

https://go.dev/doc/install

I recommend adding the paths of the installed tools and Golang system-wide to /etc/profile

Add these two lines to the file (Requires sudo):
~~~
export PATH=$PATH:/usr/local/go/bin
export PATH=$PATH:$HOME/go/bin
~~~

## Before you run the following commands...

### Configure the environment that will utilize the GCP functions with the proper Project ID

~~~
gcloud config set project <PROJECT-ID>
~~~

# Setup Instructions

1.) 
~~~
git clone https://github.com/yeti-code/GCP-Genie.git
~~~
2.) 
~~~
cd GCP-Genie
~~~
3.)
~~~
chmod +x setup.sh target_setup.sh gcp-genie.sh
~~~
4.) 
~~~
./setup.sh
~~~
5.) Run Subfinder at least once to generate your provider-config.yaml file. This is where API keys are stored for tool use. You can find the config at...
~~~
$HOME/.config/subfinder
~~~

6.) 
~~~
./target_setup.sh -t <foo.com> -p <your-gcp-project-id> -z <fallback-zone> (Ex: us-south1-a)
~~~
7.) 
CTRL + c to enter back into the shell. The script has become a background process so that you may safely exit the SSH session, or close the terminal.

You can use
~~~
ps aux
~~~
to check the Process or kill it later if needed.
