#!/bin/bash

echo ">> Creating user: atak <<"
sudo useradd -m atak

echo ">> Enter password for user <<"
sudo passwd atak

echo ">> Adding atak to sudo <<"
sudo usermod -aG wheel atak

echo ">> DONE << "
echo "++++++++++++++++++++++++++++++++++++++++++"

echo ">> Switch user with: su - atak" 
su - atak

