#!/bin/bash

#
# restart one device script
#

c=$1;
cgminer_path="/home/cairnsmore1-scripts/cgminer";

if [ -z "$c" ]
then
    echo "usage: ./screen_fpga_one.sh < screen number >"
    exit;
fi

# stop previous cgminer
echo `date +"%T %y/%m/%d"` "[screen_cgminer] Stopping FPGA${c} cgminer screen process...";
screen -x fpga${c} -X "quit" &> /dev/null

# workdir
cd $cgminer_path

# starting cgminer screen
echo `date +"%T %y/%m/%d"` "[screen_cgminer] Running screen with cgminer for FPGA${c}..."
screen -d -m -S fpga${c} ${cgminer_path}/fpga-utilize.sh ${c}

# set screen height
screen -x fpga${c} -p 0 -X height 40 2> /dev/null
screen -x fpga${c} -p 0 -X width 120 2> /dev/null

echo `date +"%T %y/%m/%d"` "[screen_cgminer] Finished."
