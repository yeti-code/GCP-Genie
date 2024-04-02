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

- Git 
~~~
sudo apt install git
~~~
- Dnsutils
~~~
sudo apt install dnsutils
~~~
- Google Cloud CLI Installer API Functions (CREATE, DELETE, and DESCRIBE)
- Go - https://go.dev/dl/ (DO NOT INSTALL via APT package manager. Go to the go.dev site and follow the install instructions)
- Subfinder - https://github.com/projectdiscovery/subfinder?tab=readme-ov-file#installation
- HTTPX - https://github.com/projectdiscovery/httpx?tab=readme-ov-file#installation-instructions
- anew - https://github.com/tomnomnom/anew

# Optional Tools
- Notify - Send messages via WebHooks to Discord, Slack, or Telegram.

# WARNING

Please make sure that the go command and all other tools that were installed via the setup.sh script can be run in your #HOME directory without needing to use the full relative path of the go binary, or the tool binaries.

I recommend adding the paths of the installed tools to

~~~
#HOME/.profile
~~~

You can run these commands in your terminal to add the $PATH variables for the go install and the go tools.

For Go install:
~~~
 echo 'export PATH=$PATH:/usr/local/go/bin' >> $HOME/.profile
~~~

Installed tools: Run this AFTER you have run the setup.sh script, and before executing the target or gcp-shenie script files which utilize the installed go tools. Assuming you have never installed any go tools before.
~~~
 echo 'export PATH=$PATH:$HOME/go/bin' >> $HOME/.profile
~~~

# Setup Instructions

1.) 
~~~
git clone https://github.com/yeti-code/GCP-Genie.git
~~~
2.) 
~~~
chmod +x setup.sh target_setup.sh gcp-genie.sh
~~~
3.) 
~~~
./setup.sh
~~~
4.) 
~~~
./target_setup.sh --target-tld <target here>
~~~
5.) 
CTRL + c to enter back into the shell. The script has become a background process so that you may safely exit the SSH session, or close the terminal.

You can use
~~~
ps aux
~~~
to check the Process or kill it later if needed.
