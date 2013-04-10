#!/bin/bash

scripts_path="/home/cairnsmore1-scripts";
cgminer_path="${scripts_path}/cgminer";

# stop
${cgminer_path}/cgminer_check.sh stop;
${scripts_path}/screen_fpga.sh kill;

# deinit driver
modprobe -vr ftdi_sio;
sleep 1;
lsmod | grep ftdi

# - power cycle -
echo "turning off..."
bitbang2 0
usleep 500000
echo "turning on..."
bitbang2 1
sleep 25

# init driver
${scripts_path}/cairnsmore/driver_init.sh;

# start
${scripts_path}/screen_fpga.sh;
(${cgminer_path}/cgminer_check.sh > /dev/null &)