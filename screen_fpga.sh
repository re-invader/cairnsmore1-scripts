#!/bin/bash

#
# screen fpga run script
#

# adjust this
fpga_count="2"

script_cmd=$1
cgminer_path="/home/cairnsmore1-scripts/cgminer";
run_delay="0";
processes='NOTNULL';

echo `date +"%T %y/%m/%d"` "[screen_cgminer] Checking active cgminer processes... "

while [ -n "$processes" ]
do
    processes=`ps -ef | grep "SCREEN" | grep "cgminer/fpga-utilize"`

    if [ -z "$processes" ]
    then
	echo `date +"%T %y/%m/%d"` "[screen_cgminer] No active processes found."

	# remove error file
	rm screen_fpga.errors &> /dev/null;
    else
	echo `date +"%T %y/%m/%d"` "[screen_cgminer] Stopping active processes."

	# repeat for all fpga's
	for (( c=1; c<=$fpga_count; c++ ))
	do
	    # killing previous tasks
	    screen -x fpga${c} -X "quit" &>> screen_fpga.errors
	done
	
	# check for errors
	check_instance=`cat screen_fpga.errors | grep "There are several suitable screens on"`;
	
	# check for multiple instances
	if [ -n "$check_instance" ]
	then
	    echo `date +"%T %y/%m/%d"` "[screen_cgminer] Seems that multiple instances running...";
	    for i in `cat screen_fpga.errors | grep "fpga" | cut -f2`
	    do
		echo `date +"%T %y/%m/%d"` "[screen_cgminer] Stopping instance $i...";
		screen -x $i -X "quit" &>> screen_fpga.errors;
	    done
	fi
    fi
    
    sleep 1;
done

if [ "$script_cmd" == "stop" ] || [ "$script_cmd" == "kill" ]
then
    exit;
fi

# workdir
cd ${cgminer_path}

# repeat for all fpga's
for (( c=1; c<=$fpga_count; c++ ))
do
    # status
    echo `date +"%T %y/%m/%d"` "[screen_cgminer] Running screen with cgminer for FPGA${c}..."

    # starting cgminer
    screen -d -m -S fpga${c} ${cgminer_path}/fpga-utilize.sh ${c}

    # set screen height
    screen -x fpga${c} -p 0 -X height 40 2> /dev/null
    screen -x fpga${c} -p 0 -X width 120 2> /dev/null
    
    sleep $run_delay;
done

echo `date +"%T %y/%m/%d"` "[screen_cgminer] Finished."
