#!/bin/bash

#
# cgminer_check script
#

script_cmd=$1
self_pid=$$

# --------------------------------------------
# ADJUST THIS VALUES
# --------------------------------------------

# configuration values
fpga_count="2";
cgminer_host="127.0.0.1";
cgminer_port_prefix="100"
scripts_path="/home/cairnsmore1-scripts";
cgminer_path="${scripts_path}/cgminer";
cgminer_api_my="${cgminer_path}/cgminer-api-my";
indicate_file="/home/www/fpga-status";
log_file="/var/log/fpga_mess.log";

# check timings values
threshold="5";
interval="30";
interval_long="20";
interval_short="10";

# --------------------------------------------

script_cmd=$1
self_pid=$$
processes=`pgrep cgminer_check`;
processes_num=`echo $processes | wc -w`;
event_log_file="cgminer_check.stats";
count="1";

while [ "$processes_num" -ge "2" ]
do
    for i in $processes
    do
	if [ "$i" != "$self_pid" ]
	then
	    echo `date +"%T %y/%m/%d"` "[cgminer_check] Found another running process with PID=$i. Terminating." | tee -a $err_log_file
	    kill -TERM $i;
	fi
    done

    processes=`pgrep cgminer_check`;
    processes_num=`echo $processes | wc -w`;
done

if [ "$script_cmd" == "stop" ] || [ "$script_cmd" == "kill" ]
then
    exit;
fi

if [ "$script_cmd" == "fast" ]
then
    interval="10";
    interval_short="1";
    interval_long="30";
fi

echo `date +"%T %y/%m/%d"` "[cgminer_check] Started. fpga count = $fpga_count, Threshold = $threshold, Interval = $interval." | tee -a $err_log_file

while [ inf ]
do
    # query fpga
    for (( c=1; c<=$fpga_count; c++ ))
    do
	eval fpga${c}_rate=`$cgminer_api_my $cgminer_host $cgminer_port_prefix$c | cut -f1 -d- | cut -f1 -d" "`;
	eval fpga${c}_stat=`cat $event_log_file | head -$c | tail -1 | cut -f4 -d" "`;

	eval fpga${c}_work_prev=`eval "echo \\$fpga${c}_work_curr"`;
	eval fpga${c}_work_curr=`$cgminer_api_my $cgminer_host $cgminer_port_prefix$c | cut -f2 -d- | cut -f1 -d" "`;
    done

    fpga_error="";
    fpga_idle="";

    # log errors 
    for (( c=1; c<=$fpga_count; c++ ))
    do
	fpga_value=`eval "echo \\$fpga${c}_rate"`;
	fpga_socket_err=`echo $fpga_value | grep Socket`;
	fpga_work_curr=`eval "echo \\$fpga${c}_work_curr"`;
	fpga_work_prev=`eval "echo \\$fpga${c}_work_prev"`;
	
	if [ -n "$fpga_socket_err" ]
	then
	    fpga_error="${fpga_error} FPGA${c}";
	fi
	if [ "$fpga_value" == "0" ] || [ "$fpga_work_curr" == "$fpga_work_prev" ]
	then
	    fpga_idle="${fpga_idle} FPGA${c}";
	fi
    done

    # if cgminer errors
    if [ -n "$fpga_error" ]
    then
	echo "FAIL" > $indicate_file;
	echo `date +"%T %y/%m/%d"` "[cgminer_check]${fpga_error} failed $count of $threshold!" | tee -a $log_file;
	count=`expr 1 + $count`;
	interval_in=$interval_short;
    elif [ -n "$fpga_idle" ]
    then
	echo "FAIL" > $indicate_file;
	echo `date +"%T %y/%m/%d"` "[cgminer_check]${fpga_idle} inactive $count of $threshold!" | tee -a $log_file;
	count=`expr 1 + $count`;
	interval_in=$interval_short;
    else
	echo "OK" > $indicate_file;
	interval_in=$interval;
	count=1;
    fi

    # count greater or equal threshold
    if [ "$count" -gt "$threshold" ]
    then
    
	#
	# reinit cgminer & log events
	#
	echo `date +"%T %y/%m/%d"` "[cgminer_check] Restarting cgminer ..." | tee -a $log_file
	rm -f $event_log_file;

	for (( c=1; c<=$fpga_count; c++ ))
	do
	    fpga_value=`eval "echo \\$fpga${c}_rate"`;
	    fpga_stat_value=`eval "echo \\$fpga${c}_stat"`;
	    fpga_socket_err=`echo $fpga_value | grep Socket`;
	    fpga_stat_count=`echo $fpga_stat_value | cut -f2 -d"-" | grep -v "OK"`;
	    fpga_work_curr=`eval "echo \\$fpga${c}_work_curr"`;
	    fpga_work_prev=`eval "echo \\$fpga${c}_work_prev"`;
	    
	    if [ -n "$fpga_socket_err" ] || [ "$fpga_value" == "0" ] || [ "$fpga_work_curr" == "$fpga_work_prev" ]
	    then
		# restart cgminer
		${scripts_path}/screen_fpga_one.sh $c | tee -a $log_file
		
		# increment restart counter
		if [ -n "$fpga_stat_count" ]
		then
		    fpga_stat_count=`expr 1 + $fpga_stat_count`;
		else
		    fpga_stat_count="1";
		fi
		echo `date +"%T %y/%m/%d"` "FPGA$c RESET-$fpga_stat_count" >> $event_log_file;
	    fi
	    
	    if [ -z "$fpga_socket_err" ] && [ "$fpga_value" != "0" ] && [ "$fpga_work_curr" != "$fpga_work_prev" ]
	    then
		echo `date +"%T %y/%m/%d"` "FPGA$c OK" >> $event_log_file;
	    fi
	done
	
	#
	# analyze events log & restart system
	#
	
	check_restart=`cat $event_log_file | grep -e RESET-[123] | wc -l`;

#	EDIT: i use this part of script to 'replug' the power of damn lagging cairnsmore1
#	device if even driver restart didn't helps. so the script called 'poweroff.sh'
#	calls utility that use bitbang mode of FT245R chip which connected directly to relay, 
#	that is in the end doing a power reset of the device.
#	i commented it out, but in case if you want to build something alike...
#	also, check poweroff.sh for such script example.
#
#	check_halt=`cat $event_log_file | grep "RESET-[345]" | wc -l`;
#    
#	if [ "$check_halt" -ge "1" ]
#	then
#	    rm -f $event_log_file;
#	    touch $event_log_file;
#	    echo `date +"%T %y/%m/%d"` "[cgminer_check] Trying Poweroff - Reset ..." | tee -a $log_file;
#	    ${scripts_path}/cairnsmore/poweroff.sh | tee -a $log_file;
#	    exit;
#	fi

	if [ "$check_restart" != "0" ]
	then
	    echo `date +"%T %y/%m/%d"` "[cgminer_check] Restarting driver ..." | tee -a $log_file;
	    echo `date +"%T %y/%m/%d"` "$check_restart devices failed, restarting driver." >> /root/cairnsmore/driver_reinit.log;
	    ${scripts_path}/cairnsmore/driver_reinit.sh | tee -a $log_file;
	    exit;
	fi

	interval_in=$interval_long;
	count=1;
    fi

    # wait
    sleep $interval_in;
done