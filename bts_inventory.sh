#!/bin/bash
# bts_inventory.sh
# v.0.2.0
#**************** History ***********************
# +improvement Avoid Piping Grep to Awk
#	grep error /var/log/messages | awk '{ print $4 }'
#	awk '/error/ { print $4 }' /var/log/messages
#v.0.1.6	changed search from 'Host ' keyword to 'BSSA'
# v.0.2.1	generate active BTS list
#************************************************
  bts_active_list="./bts_active_list.txt"
# grep 'Host '  ~/.ssh/config | awk '{ print $2}'| grep  [A-Z]
send_ssh_command ()
# send commands to server via ssh
# $1 - <server_host_name> or IP
# $2 - <command>

  {
     ssh -T $1 $2
    #( cat commands ; sleep 100 ) | ssh -T test@bsns-asr1002-1.cisco.com
  }

#  for i in `grep 'Host '  ~/.ssh/config | awk '{ print $2}'| grep  [A-Z]`; do 
   for i in `awk '/BSSA/ { print $2 }' ~/.ssh/config`; do
    echo "  processing.... $i"
#debug echo "debug--> pause"
#debug read    
    send_ssh_command $i 'sh int desc | i Mu' > "./$i.db" || echo "error to get list.. $i"
#debug echo "debug--> pause"
#debug read
   done
# generate list of active bts 
# matches done to keyword "up             up"
# tr deletes carriage return
echo "$bts_active_list preparing .... 5 sec."
sleep 5
 rm $bts_active_list
 awk '/up             up/ {print $7}' ./*.db | tr -d '\015' > $bts_active_list

 echo "################### found in UP_UP state `wc -l $bts_active_list` ############################"

echo "  normal exit"    
exit 0

