#!/bin/bash

scripts_path="/home/cairnsmore1-scripts";
log_file="/var/log/fpga_init.log";

# init ftdi driver
modprobe ftdi_sio vendor=0x0403 product=0x8350;

# wait a little
sleep 5;

# what we have now
echo `date +"%T %y/%m/%d"` "driver initialized" | tee -a $log_file;
echo "-- ./device-tty.sh --" | tee -a $log_file;
${scripts_path}/cairnsmore/device-tty.sh | tee -a $log_file;
${scripts_path}/cairnsmore/device-map.sh > ${scripts_path}/cgminer/fpga-utilize.map;
echo `date +"%T %y/%m/%d"` "device-map generated" `cat ${scripts_path}/cgminer/fpga-utilize.map 2> /dev/null | wc -l` "positions" | tee -a $log_file;
echo "-- ./device-map.sh --" | tee -a $log_file;
${scripts_path}/cairnsmore/device-map.sh | tee -a $log_file;