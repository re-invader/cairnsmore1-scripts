#!/bin/bash

scripts_path="/home/cairnsmore1-scripts";
cgminer_path="${scripts_path}/cgminer";

${cgminer_path}/cgminer_check.sh stop;
${scripts_path}/screen_fpga.sh kill;
sleep 1;
modprobe -vr ftdi_sio;
sleep 2;
${scripts_path}/cairnsmore/driver_init.sh;
${scripts_path}/screen_fpga.sh;
sleep 1;
(${cgminer_path}/cgminer_check.sh > /dev/null &)