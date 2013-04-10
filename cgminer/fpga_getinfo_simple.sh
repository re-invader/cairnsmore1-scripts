#!/bin/bash

#
# simple getinfo script
#

script_cmd=$1;

fpga_count="2";
fpga_host="127.0.0.1";
fpga_port_prefix="100";
interval="5";

cgminer_path="/home/cairnsmore1-scripts/cgminer";
cgminer_api_my="${cgminer_path}/cgminer-api-my";


# ------------------- #

while [ inf ]
do

clear

megahash_all="0";
accepted_all="0";
rejected_all="0";
errors_all="0";
utility_all="0";

for (( c=1; c<=$fpga_count; c++ ))
do
    
    dev_num=`expr $c - 1`;
    info_string=`$cgminer_api_my $fpga_host ${fpga_port_prefix}${c}`;
    error_check=`echo $info_string | grep "Socket"`;
    
    if [ -z "$error_check" ]
    then
	megahash=`echo $info_string | cut -f1 -d- | cut -f1 -d.`;
	accepted=`echo $info_string | cut -f2 -d-`;
	rejected=`echo $info_string | cut -f3 -d-`;
	errors=`echo $info_string | cut -f4 -d-`;
	utility=`echo $info_string | cut -f5 -d-`;
	
	if [ $(echo " $accepted + $rejected + $errors > 0" | bc) -eq 1 ]
	then
	    errors_prc=`printf "%.1f" $(echo "scale = 1; ( $errors * 100 ) / ($accepted + $rejected + $errors)" | bc)`;
	    rejected_prc=`printf "%.1f" $(echo "scale = 1; ( $rejected * 100 ) / ($accepted + $rejected + $errors)" | bc)`;
	else
	    errors_prc="0";
	    rejected_prc="0";
	fi
	
	let "megahash_all += $megahash";
	let "accepted_all += $accepted";
	let "rejected_all += $rejected";
	let "errors_all += $errors";
	utility_all=`echo "$utility + $utility_all" | bc`;

	echo `date +"%T"` "FPGA${c} hashrate=$megahash, accepted=$accepted, rejected=$rejected ($rejected_prc%), hw_err=$errors ($errors_prc%), utility=$utility";
	eval "fpga${c}_str='hashrate=$megahash, accepted=$accepted, rejected=$rejected ($rejected_prc%), hw_err=$errors ($errors_prc%), utility=$utility'";

    else
	echo `date +"%T"` "FPGA${c} error";
	let "error_count += 1";
    fi


done

echo "";

if [ $(echo " $accepted + $rejected + $errors > 0" | bc) -eq 1 ]
then
    errors_prc_all=`printf "%.1f" $(echo "scale = 1; ( $errors_all * 100 ) / ($accepted_all + $rejected_all + $errors_all)" | bc)`;
    rejected_prc_all=`printf "%.1f" $(echo "scale = 1; ( $rejected_all * 100 ) / ($accepted_all + $rejected_all + $errors_all)" | bc)`;
else
    errors_prc_all="0";
    rejected_prc_all="0";
fi
echo "TOTAL hashrate=$megahash_all, accepted=$accepted_all, rejected=$rejected_all ($rejected_prc_all%), hw_err=$errors_all ($errors_prc_all%), utility=$utility_all";

echo "";

sleep $interval;

done
