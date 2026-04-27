# soc-wsl
WLS ubuntu for SOC tasks

## 1. Basic installation tasks
In windows, install WSL Ubuntu
```cmd
wsl --install -d Ubuntu
```

Inside WSL Ubuntu, update & upgrade system
```bash
sudo apt update && sudo apt upgrade -y
```
NOTE: VPN in windows may need to be shutdown during installation. VPN configuration may prevent WSL network connections.

Create user account for investigations
```bash
useradd -m soc
passwd soc
usermod -aG sudo soc
chsh -s /bin/bash soc
```

Edit /etc/wsl.conf file. Specify default login for soc user instead of root.
```
[user]
default=soc
```
In windows, restar WSL Ubuntu
```cmd
wsl --shutdown
wsl -d Ubuntu --cd ~
```

## 2. Install tools
Log in as soc and install following packages from repository
```bash
sudo apt install -y \
  nftables python3 python3-pip \
  git curl unzip p7zip-full \
  file binutils exiftool jq \
  ripgrep xxd less wget \
  ripmime mpack \
  yara poppler-utils qpdf
```
Install Didier Stevens Suite from Github
```bash
sudo git clone https://github.com/DidierStevens/DidierStevensSuite.git /opt/tools/didier
```
Create links for /opt/tools/ for soc 
```bash
ln -s /opt/tools /home/$u/tools
```
Install MS Office and Macro investigation tools via PIP (do this for soc user too, no admin rights required)
```bash
pip install --break-system-packages oletools
pip install --break-system-packages yara-python
```

## 3. Make folder for investigations
Make /home/shared folder per investigations, where 
samples/ → input files 
output/ → extracted content 
tmp/ → scratch work

Example for "case-000"
```bash
sudo mkdir -p /home/shared/case-000/{samples,output,tmp}
sudo chmod -R 777 /home/shared
```

## 4. Git clone ./wsl-net-isolate.sh
During analysis, internet connectivity for WSL should be limited as a precaution. 
To make this possibler, clone this git repository and make wsl-net-isolate.sh executable.
```bash
git clone https://github.com/luparpe/soc-wsl/
chmod a+x soc-wsl/wsl-net-isolate.sh
```
This script can be run during investigation.

## 5. Backup WSL
Backup WSL with previous configuration. Run as administrator on windows:
```cmd
"wsl --export Ubuntu soc-ubuntu-clean.tar"
```
Copy tar file into external location. This is the clean WSL to revert after each investigation.

## 6. Investigations
Log in as soc user for investigations. 
Copy files for analysis from windows workstation to WSL Ubuntu /home/shared/case-nnn/samples (TIP: make easily accessible link for it to windows desktop).
During analysis, internet connectivity for WSL should be limited as a precaution. To do this, run script "./wsl-net-isolate.sh start" (and "stop" when done)
sudo shouldn't be needed for basic static analysis. Use it with causion!
