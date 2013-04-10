#!/bin/bash

fpga_log="/var/log/fpga_mess.log";
scripts_path="/home/cairnsmore1-scripts";
cgminer_path="${scripts_path}/cgminer";

echo `date +"%T %y/%m/%d"` "running on user" `whoami` ", current dir" `pwd`;

# starting ftdi kernel module
echo `date +"%T %y/%m/%d"` "Initializing FPGA kernel module..."
${scripts_path}/cairnsmore/driver_init.sh

sleep 1;

# starting cgminer
echo `date +"%T %y/%m/%d"` "Running CGMINER..."
${scripts_path}/screen_fpga.sh 2>&1 $fpga_log

# starting cgminer monitor
echo `date +"%T %y/%m/%d"` "Running CGMINER monitor..."
${cgminer_path}/cgminer_check.sh 2>&1 $fpga_log &)

# starting cgminer utility monitor
echo `date +"%T %y/%m/%d"` "Running CGMINER utility monitor..."
${scripts_path}/screen_fpga_utilizer.sh 2>&1 $fpga_log

