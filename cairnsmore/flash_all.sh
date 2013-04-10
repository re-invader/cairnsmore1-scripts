#!/bin/bash

board_id=$1
bitstream=$2
fpga_load=$3
fpga_erase=$4
fpga_count=4

if [ -z "$bitstream" ] || [ -z $board_id ]
then
    echo "usage: flash_all.sh <board id string> <bitstream filename> [0123] [erase]";
    exit;
fi

if [ -z "$fpga_load" ]
then
    echo "usage: flash_all.sh <board id string> <bitstream filename> [0123] [erase]";
    exit;
fi

for (( c=1; c<=$fpga_count; c++ ))
do
    number=`echo "$fpga_load" | cut -b${c}`;
    if [ -n "$number" ]
    then
	if [ -n "$fpga_erase" ]
	then
	    echo `date +"%T %y/%m/%d"` "[$c] erasing FPGA$number on board #$board_id" | tee -a flash.log
	    xc3sprog -c cm1 -p${number} -e 2>&1 | tee -a flash.log
	    echo `date +"%T %y/%m/%d"` "[$c] finished." | tee -a flash.log
	    echo "" | tee -a flash.log
	fi
	echo `date +"%T %y/%m/%d"` "[$c] flashing bitstream '$bitstream' to FPGA$number on board #$board_id" | tee -a flash.log
	xc3sprog -c cm1 -p${number} -Ixc6lx150.bit $bitstream 2>&1 | tee -a flash.log
	echo `date +"%T %y/%m/%d"` "[$c] finished." | tee -a flash.log
	echo "" | tee -a flash.log
    fi
done

