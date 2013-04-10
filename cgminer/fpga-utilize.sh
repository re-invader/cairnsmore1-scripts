#!/bin/bash

# tab field separator
IFS=$'\12';

# ============ OPTIONS =============
api_allow_list="W:127.0.0.1";
port_prefix="100";
cgminer_dir="/home/cairnsmore1-scripts/cgminer";
device_num=$1;
device_prefix="fpga_test";
address_file="fpga-utilize.address";
fpga_portmap_file="fpga-utilize.map";
host_user_string="";
dev_port=`cat $fpga_portmap_file | head -$device_num | tail -1 | cut -f1 -d";"`;
dev_options1=`cat $fpga_portmap_file | head -$device_num | tail -1 | cut -f2 -d";"`;
dev_options2=`cat $fpga_portmap_file | head -$device_num | tail -1 | cut -f3 -d";"`;
# ==================================

if [ -z "$device_num" ]
then
    echo "usage: fpga-utilize.sh <DEVICE NUMBER>";
    exit;
fi

echo `date +"%T %y/%m/%d"` "Starting CGminer on FPGA$device_num.";
echo "Prefix = $device_prefix";

for i in `cat $address_file`;
do
#    echo "line: $i";
    
    if [ `echo "$i" | grep "@"` ]
    then
	user_info=`echo "$i" | cut -f1 -d@`;
	host_data=`echo "$i" | cut -f2 -d@`;
    else
	user_info="$device_prefix$device_num";
	host_data=$i;
    fi

    host_addr=`echo "$host_data" | cut -f1 -d:`
    host_port=`echo "$host_data" | cut -f2 -d:`

    PING_TEST=`nmap $host_addr -p $host_port -n | grep open`;

    if [ -n "$PING_TEST" ]
    then
	echo `date +"%T %y/%m/%d"` "Host ($host_addr) looks good."
	if [ -z "$host_user_string" ]
	then
	    host_user_string="$user_info@$host_data";
	    host_string=$host_data;
	    user_string=$user_info;
	fi
    else
	echo `date +"%T %y/%m/%d"` "Host ($host_addr) is unavailible."
    fi

done

# cgminer

# space field separator
IFS=' ';

echo `date +"%T %y/%m/%d"` "Using Host $host_string"
echo `date +"%T %y/%m/%d"` "Using Port $dev_port"
echo `date +"%T %y/%m/%d"` "Port Options $dev_options1"

if [ -n "$dev_options2" ]
then
    echo `date +"%T %y/%m/%d"` "Port Timing $dev_options2"

    CGMINER_OPTIONS="-S $dev_port -o http://$host_string/ -O $user_string --icarus-timing short --icarus-options $dev_options1 --icarus-timing $dev_options2 --verbose --api-listen --api-port $port_prefix$device_num --api-allow $api_allow_list";
else
    CGMINER_OPTIONS="-S $dev_port -o http://$host_string/ -O $user_string --icarus-timing short --icarus-options $dev_options1 --verbose --api-listen --api-port $port_prefix$device_num --api-allow $api_allow_list";
fi
echo "CGminer options '$CGMINER_OPTIONS'";

# run
${cgminer_dir}/cgminer ${CGMINER_OPTIONS};