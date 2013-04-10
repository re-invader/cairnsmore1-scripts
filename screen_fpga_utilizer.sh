#!/bin/bash

#
# screen utilizer run script
#

script_cmd=$1
cgminer_path="/home/cairnsmore1-scripts/cgminer";
processes='NOTNULL';

echo `date +"%T %y/%m/%d"` "[screen_cgminer_utilizer] Checking active cgminer utilize checker processes... "

while [ -n "$processes" ]
do
    processes=`ps -ef | grep "fpga_getinfo.sh" | grep -v grep`

    if [ -z "$processes" ]
    then
	echo `date +"%T %y/%m/%d"` "[screen_cgminer_utilizer] No active processes found."
	
	# remove error file
	rm screen_fpga_utilizer.errors &> /dev/null;
    else
	echo `date +"%T %y/%m/%d"` "[screen_cgminer_utilizer] Stopping active processes."

	screen -x utilizer -X "quit" &>> screen_fpga_utilizer.errors
	
	# check for errors
	check_instance=`cat screen_fpga_utilizer.errors | grep "There are several suitable screens on"`;
	
	# check for multiple instances
	if [ -n "$check_instance" ]
	then
	    echo `date +"%T %y/%m/%d"` "[screen_cgminer_utilizer] Seems that multiple instances running...";
	    for i in `cat screen_fpga_utilizer.errors | grep "fpga" | cut -f2`
	    do
		echo `date +"%T %y/%m/%d"` "[screen_cgminer_utilizer] Stopping instance $i...";
		screen -x $i -X "quit" &>> screen_fpga_utilizer.errors;
	    done
	fi
    fi
    
    sleep 1;
done

if [ "$script_cmd" == "stop" ] || [ "$script_cmd" == "kill" ]
then
    exit;
fi

# status
echo `date +"%T %y/%m/%d"` "[screen_cgminer_utilizer] Running screen with cgminer utilize checker process ..."

# starting cgminer utilize checker script 
screen -d -m -S utilizer ${cgminer_path}/fpga_getinfo.sh screen

# set screen height
screen -x utilizer -p 0 -X height 40 2> /dev/null
screen -x utilizer -p 0 -X width 120 2> /dev/null

echo `date +"%T %y/%m/%d"` "[screen_cgminer_utilizer] Finished."
