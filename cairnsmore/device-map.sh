device_config="device-map.conf";

for i in `cat $device_config`;
do
    device_num=`echo $i | cut -f1 -d":"`;
    port_num=`echo $i | cut -f2 -d":"`;
    timing_num=`echo $i | cut -f3 -d":"`;

    device_str=`ls -l /dev/serial/by-id | grep -v total | cut -f9-12 -d" " | grep $device_num | grep if0$port_num | cut -f3 -d/`;

    if [ -z "$device_str" ]
    then
	device_str="null";
    fi

    echo "/dev/$device_str;::;$timing_num";
done