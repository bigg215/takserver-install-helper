#!/bin/bash
echo "sleeping for 90 seconds..."
timer=90
printf "$timer \033[K\r"
while [[ -d / ]]                                                  
do
	sleep 10s
	timer=$(($timer-10))
	printf "$timer \033[K\r"
  [[ $timer = 0 ]] && break
  continue
done