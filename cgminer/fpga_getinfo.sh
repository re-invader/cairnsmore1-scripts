#!/bin/bash

#
# getinfo & utilizer script
#

script_cmd=$1;

# --------------------------------------------
# ADJUST THIS VALUES
# --------------------------------------------

fpga_count="2";
fpga_host="127.0.0.1";
fpga_port_prefix="100";

cgminer_path="/home/cairnsmore1-scripts/cgminer";

cgminer_api_my="${cgminer_path}/cgminer-api-my";
cgminer_api="${cgminer_path}/cgminer-api";
my_logfile="${cgminer_path}/fpga_getinfo.log";

# "refresh_interval" (sec)
# 	- says for itself

# "utility_reset" (U)
# 	- if device utility is less than this value, increment utility reset counter.

# "utility_count_increment" (num)
#	- increment in utility reset counter IF U < utility_reset

# "utility_count_increment_err" (num)
#	- increment in utility reset counter IF accepted = 0 AND hw errors present 

# "utility_count_threshold" (num)
#	- utility reset counter threshold, restarts the device when reached.

if [ "$script_cmd" == "screen" ]
then
    # "screen" mode
    refresh_interval="10";
    utility_reset="4.5";
    utility_count_increment="1";
    utility_count_increment_err="5";
    utility_count_threshold="30";
else
    # "live" mode 
    refresh_interval="1";
    utility_reset="5";
    utility_count_increment="1";
    utility_count_increment_err="5";
    utility_count_threshold="25";
fi

# --------------------------------------------

while [ inf ]
do

clear
error_count="0";

for (( c=1; c<=$fpga_count; c++ ))
do

    # api get info
    info_string=`${cgminer_api_my} ${fpga_host} ${fpga_port_prefix}${c}`;
    
    error_check=`echo $info_string | grep "Socket"`;

    if [ -z "$error_check" ]
    then
	megahash=`echo $info_string | cut -f1 -d-`;
	accepted=`echo $info_string | cut -f2 -d-`;
	rejected=`echo $info_string | cut -f3 -d-`;
	errors=`echo $info_string | cut -f4 -d-`;
	utility=`echo $info_string | cut -f5 -d-`;
	
	if [ $(echo " $accepted + $rejected + $errors > 0" | bc) -eq 1 ]
	then
	    errors_prc=`printf "%.1f" $(echo "scale = 1; ( $errors * 100 ) / ($accepted + $rejected + $errors)" | bc)`;
	else
	    errors_prc="0";
	fi

	echo `date +"%T %y/%m/%d"` "FPGA${c} hashrate=$megahash, accepted=$accepted, rejected=$rejected, hw_err=$errors ($errors_prc%), utility=$utility";
	eval "fpga${c}_str='hashrate=$megahash, accepted=$accepted, rejected=$rejected, hw_err=$errors ($errors_prc%), utility=$utility'";

	if [ $(echo "$utility < $utility_reset" | bc) -eq 1 ]
	then
	    fpga_error="${fpga_error} FPGA${c}";
	    let "fpga${c}_utility_count += $utility_count_increment";
	else
	    let "fpga${c}_utility_count = 0";
	fi
	
	if [ "$accepted" == "0" ] && [ "$errors" -gt "0" ] || [ "$errors" -gt "$accepted" ]
	then
	    let "fpga${c}_utility_count += $utility_count_increment_err";
	fi
    else
	echo `date +"%T %y/%m/%d"` "FPGA${c} error";
	let "error_count += 1";
    fi
    
    
done

echo "";

if [ -n "$fpga_error" ]
then
    echo "detected$fpga_error utility is low!";
    echo "";
    fpga_error="";
    for (( c=1; c<=$fpga_count; c++ ))
    do
	local_result=`eval "echo \\$fpga${c}_utility_count"`;
	if [ -n "$local_result" ] && [ "$local_result" != "0" ]
	then
	    if [ "$local_result" -ge "$utility_count_threshold" ]
	    then
		last_data=`eval "echo \\$fpga${c}_str"`;
		let "fpga${c}_utility_count = 0";
		echo "FPGA${c} resetting now ... ";
		${cgminer_api} restart ${fpga_host} ${fpga_port_prefix}${c} > /dev/null;
		echo `date +"%T %y/%m/%d"` "restarting FPGA${c} $last_data" >> $my_logfile
	    else
		echo "FPGA${c} reset counter = $local_result";
	    fi
	fi
    done
else
    if [ "$error_count" -ge "1" ]
    then
	echo "NOT OK";
    else
	echo "OK";
    fi
fi

if [ "$script_cmd" == "screen" ]
then
    echo "";
    tail -15 $my_logfile;
fi

echo "";

for (( c=1; c<=$fpga_count; c++ ))
do
    echo "FPGA${c} reset count = "`cat $my_logfile | grep "FPGA${c}" | wc -l`;
done

sleep $refresh_interval;

done
