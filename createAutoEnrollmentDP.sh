#!/bin/bash
IP="192.168.1.10"
PORT="8089"
SERVERNAME="takserver"

sed -i 's|<entry key="description0" class="class java.lang.String">|<entry key="description0" class="class java.lang.String">'$SERVERNAME'|g' ./data-packages/config.pref
sed -i 's|<entry key="connectString0" class="class java.lang.String">|<entry key="connectString0" class="class java.lang.String">'$IP':'$PORT':ssl|g' ./data-packages/config.pref

