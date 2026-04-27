# soc-wsl
WLS ubuntu for SOC tasks

## 1. Basic installation tasks
In windowns, install WSL Ubuntu
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
chsh -s /bin/bash soc
```
Create local admin account and ad it for sudoers
```bash
useradd -m ladm
passwd ladm
usermod -aG sudo ladm
chsh -s /bin/bash ladm
```

## 2. Install tools
Log in as ladm ("wsl -d Ubuntu -u ladm --cd ~") and install following packages from repository
```bash
sudo apt install -y \
  python3 python3-pip git curl unzip p7zip-full \
  file binutils exiftool jq \
  ripgrep xxd less wget \
  ripmime mpack \
  yara poppler-utils qpdf
```
Install Didier Stevens Suite from Github
```bash
sudo git clone https://github.com/DidierStevens/DidierStevensSuite.git /opt/tools/didier
```
Create links for /opt/tools/ for soc and ladm users (optional)
```bash
for u in soc ladm; do
  sudo -u "$u" ln -s /opt/tools /home/$u/tools
done
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

## 4. Backup WSL
Backup WSL with previous configuration. Run as administrator on windows:
```cmd
"wsl --export Ubuntu soc-ubuntu-init.tar"
```
Copy tar file into external location. This is the clean WSL to revert after each investigation.

## 5. Investigations
Log in as soc user for investigations. Static analysis shouldn't require higher privileges, but if needed, use ladm account for sudo activities.
Copy files for analysis from windows workstation to WSL Ubuntu /home/shared/case-nnn/samples (TIP: make easily accessible link for it to windows desktop)
During analysis, internet connectivity for WSL should be limited as a precaution. To do this, run script "wsl-net-isolate.sh".
