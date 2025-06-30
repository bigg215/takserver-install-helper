#!/bin/bash
#original script by Ryan Schilder March 2024

if [[ $# = 0 ]]
then
	echo 'Exiting: add file name'
    exit 1
else
    continue 
fi

echo '>> Increase MAX connections <<'
echo -e '* soft nofile 32768\n* hard nofile 32768' | sudo tee --append /etc/security/limits.conf
echo '>> DONE <<'
echo '++++++++++++++++++++++++++++++++++++++++++'

sudo dnf config-manager --set-enabled crb

echo '>> Install extra packages for enterprise linux (EPEL) <<'
sudo dnf install epel-release -y
echo '>> DONE <<'
echo '++++++++++++++++++++++++++++++++++++++++++'

echo '>> Install postgres <<'
sudo rpm --import https://download.postgresql.org/pub/repos/yum/keys/PGDG-RPM-GPG-KEY-RHEL
## disable updates / freeze
sudo dnf -qy module disable postgresql && sudo dnf update -y
## manual install of java 17
sudo dnf install java-17-openjdk-devel -y
echo '>> DONE << '
echo '++++++++++++++++++++++++++++++++++++++++++'

echo '>> Install Takserver v5.X <<'
echo 'Installing $1'
sudo dnf install $1 -y
echo '>> DONE <<'
echo '++++++++++++++++++++++++++++++++++++++++++'

dnf install checkpolicy -y 

sudo ./opt/tak/apply-selinux.sh && sudo semodule -l | grep takserver

echo '>> Check JAVA version, should be 17.x <<'
java -version

echo '>> Choose 17.x if multiple options (openjdk) <<'
sudo alternatives --config java
echo '++++++++++++++++++++++++++++++++++++++++++'

echo '>> Configure TAK Server <<'

sudo systemctl daemon-reload
sudo systemctl start takserver
sudo systemctl enable takserver

echo '>> DONE <<'
echo '++++++++++++++++++++++++++++++++++++++++++'

echo 'INSTALL COMPLETE'
sleep 10s

echo '>> CERT GENERATION <<'
olddir=$(pwd)

cd /opt/tak/certs/

echo 'Clearing out old certifications' 
sudo rm -vRf /opt/tak/cert/files

echo "The following will edit cert-metadata.sh to create the correct certificates"
echo "Please enter the following in CAPS, WITH NO SPACES!"

read -p 'STATE: ' statevar
read -p 'CITY: ' cityvar
read -p 'ORGANIZATION: ' orgvar
read -p 'ORGANIZATIONAL_UNIT: ' ouvar

#replace STATE
sed -i 's/STATE=${STATE}/STATE='"$statevar"'/g' cert-metadata.sh

#replace CITY
sed -i 's/CITY=${CITY}/CITY='"$cityvar"'/g' cert-metadata.sh

#replace ORG
sed -i 's/ORGANIZATION=${ORGANIZATION:-TAK}/ORGANIZATION='"$orgvar"'/g' cert-metadata.sh

#replace OU
sed -i 's/ORGANIZATIONAL_UNIT=${ORGANIZATIONAL_UNIT}/ORGANIZATIONAL_UNIT='"$ouvar"'/g' cert-metadata.sh

echo "Default CA password used"

echo "cert-metadata.sh updated"
echo "creating certificates"

su - atak 

echo "creating Root CA - USER MUST ENTER CA NAME"
sudo ./makeRootCa.sh

echo "creating Intermediate CA for signing"
echo "Answer Y when prompted"
sudo ./makeCert.sh ca intermediate-ca

echo "Make server ceftificate"
sudo ./makeCert.sh server takserver

echo "Make admin certificate"
sudo ./makeCert.sh client admin

echo "Make user certificate"
sudo ./makeCert.sh client user

echo "restarting tak server"
sudo systemctl restart takserver

echo "sleeping for 90 seconds..."
sleep 10s
echo "80"
sleep 10s
echo "70"
sleep 10s
echo "60"
sleep 10s
echo "50"
sleep 10s
echo "40"
sleep 10s
echo "30"
sleep 10s
echo "20"
sleep 10s
echo "10"
sleep 10s

echo "configuring Client X509 certificate authentication on port 8089"

sudo sed -i 's|<input auth="anonymous" _name="stdtcp" protocol="tcp" port="8087"/>|<input auth="x509" _name="stdssl" protocol="tls" port="8089"/>|g' /opt/tak/CoreConfig.xml
echo "complete"

echo "configuring intermediate ca for use"

sudo sed -i 's|truststoreFile="certs/files/truststore-root.jks|truststoreFile="certs/files/truststore-intermediate-ca.jks|g' /opt/tak/CoreConfig.xml
echo "complete"

echo "enabling TAKserver signing, enrolled user certificates will be valid for 3650 days"

sudo sed -i 's|<vbm enabled="false"/>|<certificateSigning CA="TAKServer"><certificateConfig>\n<nameEntries>\n<nameEntry name="O" value="TAK"/>\n<nameEntry name="OU" value="TAK"/>\n</nameEntries>\n</certificateConfig>\n<TAKServerCAConfig keystore="JKS" keystoreFile="certs/files/intermediate-ca-signing.jks"  keystorePass="atakatak" validityDays="3650" signatureAlg="SHA256WithRSA" />\n</certificateSigning>\n <vbm enabled="false"/>|g' /opt/tak/CoreConfig.xml

sudo sed -i 's|<auth>|<auth x509useGroupCache="true">|g' /opt/tak/CoreConfig.xml

echo "restarting tak server"
sudo systemctl restart takserver

echo "sleeping for 270 seconds, otherwise promoting admin cert will fail"
sleep 10s
echo "260"
sleep 10s
echo "250"
sleep 10s
echo "240"
sleep 10s
echo "230"
sleep 10s
echo "220"
sleep 10s 
echo "210"
sleep 10s
echo "200"
sleep 10s
echo "190"
sleep 10s
echo "180"
sleep 10s
echo "170"
sleep 10s
echo "160"
sleep 10s
echo "150"
sleep 10s
echo "140"
sleep 10s
echo "130"
sleep 10s
echo "120"
sleep 10s 
echo "110"
sleep 10s
echo "100"
sleep 10s
echo "90"
sleep 10s
echo "80"
sleep 10s
echo "70"
sleep 10s
echo "60"
sleep 10s
echo "50"
sleep 10s
echo "40"
sleep 10s
echo "30"
sleep 10s
echo "20"
sleep 10s
echo "10"
sleep 10s

echo "--==TAK SERVER CERTIFICATE CREATION SUCCESSFUL==--"

cd $olddir

echo "promoting certs to admin"
echo "promoting admin.pem to administrator"
sudo java -jar /opt/tak/utils/UserManager.jar certmod -A /opt/tak/certs/files/admin.pem

echo "restarting tak server"
sudo systemctl restart takserver

echo "copying admin.p12 to /home/atak/"
sudo cp /opt/tak/certs/files/admin.p12 /home/atak/

echo "changing owner of /home/atak/admin.p12 to tak user"
sudo chown tak:tak /home/atak/admin.p12

echo "copying truststore-intermediate-ca.p12 to /home/atak/"
sudo cp /opt/tak/certs/files/truststore-intermediate-ca.p12 /home/atak/

echo "changing owner of /home/atak/truststore-intermediate-ca.p12 to atak user"
sudo chown atak:atak /home/atak/truststore-intermediate-ca.p12

echo "+++++++++++++++++++++++++++++++++++++++++++++++"
echo "+++++++++++++ COMPLETE ++++++++++++++++++++++++"
echo "+++++++++++++++++++++++++++++++++++++++++++++++"

echo "+++++++++++++++ ALL DONE! ++++++++++++++++"
