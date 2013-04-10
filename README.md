CAIRNSMORE1 SCRIPTS by invader

this scripts was made for better utilizing, less downtime for some of my devices,
more free time and happiness for me :) i still using them, and with some minor
adjustments ( deleted unused and weird lines of code, fixed paths and info )
i decided to release them mostly "as is" to public.
and i hope it would be useful to someone.

what you need to run them:

0. on a system, where you run cairnsmore1 at first time you need to run
   ./cairnsmore/99-cairnsmore.install.sh
   which adds udev rules. also you should install nmap and screen
   (as nmap used to check if pool port is open in fpga-utilize.sh script,
   and screen is used to run cgminer and other monitoring scripts in background)

1. (a) download & compile the latest cgminer from source (recommended).
       put binary to ./cgminer
       then compile ./cgminer/cgminer-api-my-build/cgminer-api-my.c
       by putting it in the root directory of cgminer source and
       issuing a command:
       gcc cgminer-api-my.c -I compat/jansson -o cgminer-api-my
       and then put it again to /cgminer
       OR you can just run ./cgminer/cgminer-api-my-build/cgminer-api-build.sh
   (b) if you already have cgminer binary, then just put it to /cgminer,
       also run ./cgminer/cgminer-api-my-build/cgminer-api-build.sh

2. (a) check the necessary path in ALL the scripts, and replace appropriately.
   (b) you can put all this scripts to /home/cairnsmore1-scripts

3. edit fpga_count in ALL the scripts to represent number of your "icarus" ports (*)

4. edit ./cairnsmore/device-map.conf to represent your devices.
   you can run ./cairnsmore/device-tty.sh for checking the FTDI chips serial number.

    device-map.conf format looks like

    <device FTDI chip serial number>:<port number (usually ports 2 and 3 used)>:<icarus timing>

    you can skip <icarus timing> parameter, then cgminer would try to find it automatically,
    "--icarus-timing short" used in all cases.

5. edit ./cgminer/fpga-utilize.address
   thats where you must put lines with your pool credentials and addresses
   <user>:<pass>@<host>:<port>
   or
   <host>:<post>
   if you connect workers to your pool and it would name it like $device_prefix$number

HOW IT WORKS:

./cairnsmore/driver_init.sh calls ./cairnsmore/device-map.sh which generates ./cgminer/fpga-utilize.map
files ./cgminer/fpga-utilize.map and ./cgminer/fpga-utilize.address is used by ./cgminer/fpga-utilize.sh
to start cgminer with needed usbserial port & pool parameters
./cgminer/fpga_getinfo.sh checks the utility/accepted/rejected/hashrate via cgminer api, monitors
for low device utility, and soft restarts cgminer via api in case something is wrong.
./cgminer/cgminer_check.sh restart screen cgminer & reinits the driver in cases of network failure,
unability to soft restart via api & etc.

HOW TO USE:

- first, you need to initialize driver
./cairnsmore/driver_init.sh

you will see a list of your devices with serial numbers

- try to run
./cgminer/fpga-utilize.sh 1

and look what is going on. if its connected to starts hashing and

- then try to run
./screen_fpga.sh

and check the screens via `screen -ls` command. try to connect to every screen `screen -r fpga<number>`
then to detach press ctrl+a+d.
then check open api ports (using nmap nmap 127.0.0.1 -p 1001-10xx ) or just using
/cgminer/fpga_getinfo_simple.sh

if all is ok at this stage, then try

./cgminer/fpga_getinfo.sh

- next try to run cgminer monitor

./cgminer/cgminer_check.sh

you can check and kill some screens to see what is happens - script should restart them
if "cgminer_check.sh" and "fpga_getinfo.sh" is working, then next

- add to your system autorun

./all_system_start.sh

NOTE:

(*) current scripts is made for using cairnsmore1 with makomk bitstreams which represent it as 2 icarus devices,
but if you want to use other fpga configuration, then you need to edit /cairnsmore/device-map.sh script.

as a bonus i also put some scripts that i used by myself to flash boards (./flash_all.sh) , do a usb reset ( usbreset.c )
and some example on power reset of a failing board.

there maybe some bugs, as i havent tested yet this edited scripts in new environment, but they based on working prototype.
