#!/bin/bash
IP="192.168.1.10"
PORT="8089"
SERVERNAME="takserver"
UUID=$(uuidgen)
CAPASSWORD=atakatak
FILENAME=$SERVERNAME".zip"

echo "Moving templates"
mkdir -p autoenrollment/MANIFEST
cp data-packages/config.pref.template autoenrollment/config.pref
cp data-packages/MANIFEST/manifest.xml.template autoenrollment/MANIFEST/manifest.xml  

echo "Editing config.pref"
sed -i 's|<entry key="description0" class="class java.lang.String">|<entry key="description0" class="class java.lang.String">'$SERVERNAME'|g' ./autoenrollment/config.pref
sed -i 's|<entry key="connectString0" class="class java.lang.String">|<entry key="connectString0" class="class java.lang.String">'$IP':'$PORT':ssl|g' ./autoenrollment/config.pref
sed -i 's|<entry key="caPassword0" class="class java.lang.String">|<entry key="caPassword0" class="class java.lang.String">'$CAPASSWORD'|g' ./autoenrollment/config.pref

echo "Editing manifest.xml"
sed -i 's|<Parameter name=“uid” value=“|<Parameter name=“uid” value=“'$UUID'|g' ./autoenrollment/MANIFEST/manifest.xml
sed -i 's|<Parameter name="name" value="|<Parameter name="name" value="'$FILENAME'|g' ./autoenrollment/MANIFEST/manifest.xml

echo "DONE"

cd autoenrollment
zip enroll.zip truststore-intermediate-ca.p12 config.pref MANIFEST/manifest.xml
cd - 

echo "DONE"