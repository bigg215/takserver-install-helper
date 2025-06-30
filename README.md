# takserver-install-helper

Helper scripts, tools, and guides for setting up a civilian takserver

# ROCKY LINUX 9 

Tested on proxmox 8.4.1 using the rockylinux-9-default LXC template.

## Usage

```shell
sudo useradd atak 
sudo passwd atak
sudo usermod -aG wheel atak
su - atak 
```

```shell
sudo chmod u+x install.sh
sudo ./install.sh <takserver.rpm>
```
Certs will generate and auto enrollment 