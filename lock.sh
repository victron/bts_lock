#!/bin/bash
# bts_lock.sh
# v.0.3.3
# get ASR site name from $1
# get BTS site name from $2

####### TO-DO ######
# - quick help
# - ping check at the end
# + aps check and exit if protect
# ? aps check and start to work on router+1 if protect
# + date and time  on start
# - logging 
# ? shadow work, output in logs
# ? security (hide key password)
# ? replace file functions on array
# + wait indicator
# + rewrite  check_exit_status function and implement
# + delete files
# - Piping Grep to Awk
####### history ########



#**************************************************
#    constants block
#**************************************************
# declare -i waite_time
  waite_time=300

# file for commands
# 
# tmp files declare in next template
# <program_name>.process_number.<file_memplate  (bts_lock.sh.26051.commands.tmp)

 command_list_file="./$(basename $0).$$.commands.tmp"
 send_command_output_file="./$(basename $0).$$.output.tmp"
 command_list_shut_file="./$(basename $0).$$.commands_shut.tmp"
 aps_output="./$(basename $0).$$.aps_check_output.tmp"

#**************************************************
#    variables block
#**************************************************
  #**************************************************
  #    variables for functions
  #**************************************************

  generate_command_list_check_2=$2
  send_command_2=$1
  
#**************************************************
#    functions block
#**************************************************
search_host_name ()
# search server hostname in .db files
# currently return hostnams in stdout
# $1 - <bts_name>
  {
    for i in `grep -l $1 ./*.db | sort`; do
      echo "`basename $i .db`"
  }
  
delete_tmp_files ()
  {
  echo " start delete tmp files"
    rm $command_list_file && echo "deleted.. $command_list_file"
    rm $send_command_output_file && echo "deleted.. $send_command_output_file"
    rm $command_list_shut_file && echo "deleted.. $command_list_shut_file"
    rm $aps_output && echo "deleted.. $aps_output"
    return 0
  }
  
send_command ()
# send commands to server via ssh
# function with parameters
  {
    cat  $1 | ssh -T $send_command_2
    #( cat commands ; sleep 100 ) | ssh -T test@bsns-asr1002-1.cisco.com
  }
  
check_exit_status ()
# check exit status code
# $1 info message if exit notOk
  {
  
    RETVAL=$?
      if [ $RETVAL -eq 0 ] ; then
#debug	echo "If=ok start exit_status"
	return 0
	  else
#debug	    echo "If=Nok start exit_status"
#debug	    echo "error=$RETVAL ----> exit"
	    delete_tmp_files
	    echo "$1 exit..$RETVAL"
	    exit $RETVAL
      fi
   }
   
   
generate_command_list_check ()
# generates commands file list $command_list_file
  {
    #echo $2  >  $command_list_file
    echo "sh int desc | i $generate_command_list_check_2" >  $command_list_file 
    
  }
  
check_exist_bts ()
# checking on exist bts on router
  {
    ( grep Mu $send_command_output_file || ( RETVAL=$?; echo "check list generation error... $RETVAL ";exit $RETVAL) || exit $RETVAL ) || exit $RETVAL
   }
   
generate_command_list_shut_noShut ()
# generates commands file list $command_list_shut_file
# parameter $1 shut or noshut
  {
#takes file in format 
#----------------------
#
#KIE-PRI-TVK_BSSA1#sh int desc | i KIECHNOZR345
#Se0/4/0.1/2/2/2:0              down           down     KIECHNOZR345C1
#Se0/4/0.1/2/2/3:0              down           down     KIECHNOZR345C2
#Mu18                           down           down     L3 link to KIECHNOZR345
#Se0/4/0.1/2/x2/2:0              down           down     KIECHNOZR345C1
#Se0/4/0.1/2/x2/3:0              down           down     KIECHNOZR345C2
#Mu1                           down           down     L3 link to KIECHNOZR345
#----------------------
#prepare for shutdown on cisco in format ($1=shut)
#----------------------
#conf t
#int multil1
#shut
#int multil18
#shut
#int Se0/4/0.1/2/2/2:0
#shut
#int Se0/4/0.1/2/2/3:0
#shut
#int Se0/4/0.1/2/x2/2:0
#shut
#int Se0/4/0.1/2/x2/3:0
#shut
#----------------------

  
  case "$1" in 
      "shut" )
      echo "conf t" > $command_list_shut_file
      grep -e Se -e Mu $send_command_output_file | awk '{print $1}'| sort | awk '{ gsub(/Mu/,"multil"); print "int "$1"\nshut" }' >> $command_list_shut_file
      ;;
      "noshut" )
# generate conmmands for 'no shutdown' in $command_list_shut_file

      echo "conf t" > $command_list_shut_file
      grep -e Se -e Mu $send_command_output_file | awk '{print $1}'| sort -r | awk '{ gsub(/Mu/,"multil"); print "int "$1"\nno shut" }' >> $command_list_shut_file
# 'show interface des | i <BTS_Name>' at the end of 'no shutdown' 
      echo "do sh int desc | i $generate_command_list_check_2" >> $command_list_shut_file
      ;;
    esac  
  }
  
generate_command_list_check_active_aps ()
# check for active APS on router
# $2 = <sh int desc | i <BTS>_file> output_file, 
# $2 = <APS_output>, if $1 ="analyze_resp  
# $3 = file in format:
# ------------------
# show aps controller sonET 0/3/1
# show aps controller sonET 0/3/1
# ==================
# $1 = "request_list" or "analyze_resp" (generate list for APS state request or analyze response  )

  {
  case "$1" in
    "request_list" )
      grep -e Se $2 | awk '{print $1}'| awk -F. '{print $1}' | awk '{ gsub(/Se/,""); print "show aps controller sonET "$1 }' > $3
      return 0
    ;;
    "analyze_resp" )
      # check $aps_output file exist or not
#      [ -e $2 ] ||  (RETVAL=$?; echo "file $2 not present exit.. $RETVAL "; exit $RETVAL) || exit $?
      [ -e $2 ]; check_exit_status "file $2 not present"
      # check "APS Group" keyword in file $aps_output
#debug      echo "APS ????"
        grep "APS Group" $2 > /dev/null || ( RETVAL=$?; echo "APS not configured on router exit.. $RETVAL "; rm $2;exit $RETVAL) || exit $RETVAL
      # check on "protect channel"keword in $aps_output
#debug      echo "protect ????"
      grep "protect channel" $2 | awk '{print $1" " $2" "$6" " $7" on router, exit... 102"}'
      grep "protect channel" $2 > /dev/null; ( RETVAL=$?; echo "delete $2"; rm $2;exit $RETVAL) && exit 102
      echo "APS... OK"
      return 0
    ;;
   esac
  }
  
waite_function ()
# waite function and indication
  {
#    for i in `seq 1 $1` ; do
    for ((i = 0 ; i < $1 ; i++ )); do
#    for i in `eval echo {1..$1}` ; do
     echo -ne "$i \r"
#    echo -ne "$i \r"| dialog --gauge "Please wait" 10 70 0
    sleep 1
    done
  }
#**************************************************
#    exe block
#**************************************************
# ----------- phase 1 ------ checking ----------------
# generate command list for check exist BTS sites  

generate_command_list_check; check_exit_status "check list generation error" 
# 1-st connection
echo "`date +%Y-%m-%d_%H:%M:%S`"
# send 'sh int desc | i <BTS_Name> and  save output in $send_command_output_file
#off 
send_command $command_list_file  > $send_command_output_file || check_exit_status "ssh error" 
# check for exist requested BTS_name in $send_command_output_file
echo " check BTS on router"
#debug echo "debug-> $2"
#debug echo "debug-> $send_command_output_file"
grep "Mu" $send_command_output_file > /dev/null || check_exit_status "BTS not present on router"

# ----------- phase 1.2 ------ checking APS ----------------
# generate command list for check APS state
# !!! currently without exit analyze
#debug read
echo " check APS on router"
#debug echo " prep APS list"
generate_command_list_check_active_aps request_list $send_command_output_file $command_list_file
# 2-d connection
#off 
send_command $command_list_file  > $aps_output || check_exit_status "ssh error" 
#debug echo " Analyze APS list"
generate_command_list_check_active_aps analyze_resp $aps_output


# ----------- phase 2 ------ shutdown ----------------
# generates command list 'shutdown' in $command_list_shut_file
echo " shutdown phase"
generate_command_list_shut_noShut shut || check_exit_status "list_shutown error"
# 3-d connection
# send commands from $command_list_shut_file
#off
send_command $command_list_shut_file || check_exit_status "ssh error"

# ----------- phase 3 ------ waiting ----------------
# waiting 300 sec. before next actions
echo "`date +%Y-%m-%d_%H:%M:%S` waiting $waite_time sec. "
#sleep $waite_time
waite_function $waite_time

# ----------- phase 4 ------ no shutdown ----------------
# generate conmmands for 'no shutdown' in $command_list_shut_file
generate_command_list_shut_noShut noshut || check_exit_status "list_shutown error"
# 4-th connection 
# send commands from $command_list_shut_file
#off
send_command $command_list_shut_file || check_exit_status "ssh error"

# normal exit
delete_tmp_files
echo "`date +%Y-%m-%d_%H:%M:%S` exit.. 0 "
exit 0

  
  
  
  