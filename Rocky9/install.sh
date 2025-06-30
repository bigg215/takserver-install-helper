#!/bin/bash
YELLOW=$(tput setaf 3)
GREEN=$(tput setaf 2)
RED=$(tput setaf 1)
NC=$(tput sgr0)
SO=$(tput smso)
SR=$(tput rmso)

if [[ $# = 0 ]]
then
	echo 'Exiting: missing filename arguement'
	echo 'Usage: ./install.sh <takserver.rpm>'
    exit 1 
fi

FILE=$1

echo '>> Increase MAX connections <<'
echo -e '* soft nofile 32768\n* hard nofile 32768' | sudo tee --append /etc/security/limits.conf
echo '>> DONE <<'
echo '++++++++++++++++++++++++++++++++++++++++++'

echo '>> Install extra packages for enterprise linux (EPEL) <<'
sudo /usr/bin/crb enable
sudo dnf install epel-release -y
echo '>> DONE <<'
echo '++++++++++++++++++++++++++++++++++++++++++'

echo '>> Install postgres <<'
sudo rpm --import https://download.postgresql.org/pub/repos/yum/keys/PGDG-RPM-GPG-KEY-RHEL
sudo dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-x86_64/pgdg-redhat-repo-latest.noarch.rpm
sudo dnf -qy module disable postgresql && sudo dnf update -y

sudo dnf install java-17-openjdk-devel -y
echo '>> DONE << '
echo '++++++++++++++++++++++++++++++++++++++++++'

echo '>> Install Takserver v5.X <<'
echo "Installing $FILE"
sudo dnf install $1 -y
echo '>> DONE <<'
echo '++++++++++++++++++++++++++++++++++++++++++'

dnf install checkpolicy -y 

cd /opt/tak && sudo ./apply-selinux.sh && sudo semodule -l | grep takserver
cd - 

echo '>> Configure TAK Server <<'

sudo systemctl daemon-reload
sudo systemctl start takserver
sudo systemctl enable takserver

echo '>> DONE <<'
echo '++++++++++++++++++++++++++++++++++++++++++'

echo 'INSTALL COMPLETE'
sleep 10s

echo '>> CERT GENERATION <<'
OLDDIR=$(pwd)

cd /opt/tak/certs/

echo 'Clearing out old certifications' 
sudo rm -vRf /opt/tak/cert/files

echo "The following will edit cert-metadata.sh to create the correct certificates"
echo "Please enter the following in CAPS, WITH NO SPACES!"

read -p 'STATE: ' STATEVAR
read -p 'CITY: ' CITYVAR
read -p 'ORGANIZATION: ' ORGVAR
read -p 'ORGANIZATIONAL_UNIT: ' OUVAR

#replace STATE
sed -i 's/STATE=${STATE}/STATE='"$STATEVAR"'/g' cert-metadata.sh

#replace CITY
sed -i 's/CITY=${CITY}/CITY='"$CITYVAR"'/g' cert-metadata.sh

#replace ORG
sed -i 's/ORGANIZATION=${ORGANIZATION:-TAK}/ORGANIZATION='"$ORGVAR"'/g' cert-metadata.sh

#replace OU
sed -i 's/ORGANIZATIONAL_UNIT=${ORGANIZATIONAL_UNIT}/ORGANIZATIONAL_UNIT='"$OUVAR"'/g' cert-metadata.sh

echo "Default CA password used"

echo "cert-metadata.sh updated"
echo "creating certificates" 

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
TIMER=90
while [[ -d / ]]                                                  
do
	printf "Sleeping for $TIMER seconds ... \033[K\r"
	TIMER=$(($TIMER-10))
	sleep 10s
  [[ $TIMER = 0 ]] && break
  continue
done

echo "configuring Client X509 certificate authentication on port 8089"

sudo sed -i 's|<input auth="anonymous" _name="stdtcp" protocol="tcp" port="8087"/>|<input auth="x509" _name="stdssl" protocol="tls" port="8089"/>|g' /opt/tak/CoreConfig.xml
echo "complete"

echo "configuring intermediate ca for use"

sudo sed -i 's|truststoreFile="certs/files/truststore-root.jks|truststoreFile="certs/files/truststore-intermediate-ca.jks|g' /opt/tak/CoreConfig.xml
echo "complete"

echo "enabling TAKserver signing, enrolled user certificates will be valid for 3650 days"

sudo sed -i 's|<vbm enabled="false"/>|<certificateSigning CA="TAKServer"><certificateConfig>\n<nameEntries>\n<nameEntry name="O" value="TAK"/>\n<nameEntry name="OU" value="TAK"/>\n</nameEntries>\n</certificateConfig>\n<TAKServerCAConfig keystore="JKS" keystoreFile="certs/files/intermediate-ca-signing.jks"  keystorePass="atakatak" validityDays="3650" signatureAlg="SHA256WithRSA" />\n</certificateSigning>\n <vbm enabled="false"/>|g' /opt/tak/CoreConfig.xml

sudo sed -i 's|<auth>|<auth x509groups="true" x509addAnonymous="false" x509checkRevocation=“true”>|g' /opt/tak/CoreConfig.xml

echo "restarting tak server"
sudo systemctl restart takserver

echo "sleeping for 270 seconds..."
TIMER=270
printf "$TIMER \033[K\r"
while [[ -d / ]]                                                  
do
	sleep 10s
	TIMER=$(($TIMER-10))
	printf "$TIMER \033[K\r"
  [[ $TIMER = 0 ]] && break
  continue
done

echo "--==TAK SERVER CERTIFICATE CREATION SUCCESSFUL==--"

cd $OLDDIR

echo "promoting certs to admin"
echo "promoting admin.pem to administrator"
sudo java -jar /opt/tak/utils/UserManager.jar certmod -A /opt/tak/certs/files/admin.pem

echo "restarting tak server"
sudo systemctl restart takserver

echo "copying admin.p12 to /home/atak/"
sudo cp /opt/tak/certs/files/admin.p12 /home/atak/

echo "changing owner of /home/atak/admin.p12 to tak user"
sudo chown atak:atak /home/atak/admin.p12

echo "copying truststore-intermediate-ca.p12 to /home/atak/"
sudo cp /opt/tak/certs/files/truststore-intermediate-ca.p12 /home/atak/

echo "changing owner of /home/atak/truststore-intermediate-ca.p12 to atak user"
sudo chown atak:atak /home/atak/truststore-intermediate-ca.p12

echo "+++++++++++++++++++++++++++++++++++++++++++++++"
echo "+++++++++++++ COMPLETE ++++++++++++++++++++++++"
echo "+++++++++++++++++++++++++++++++++++++++++++++++"

echo "+++++++++++++++ ALL DONE! ++++++++++++++++"
