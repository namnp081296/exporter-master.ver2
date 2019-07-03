#!/bin/bash
# Declare Variables
### Change here
exp_name="exporter_mysqld"
### Not need change
DTIME=$(date +"%Y%m%d")
HOMEPATH="/etc/prometheus"
USER='prometheus'
BINARYPATH=${HOMEPATH}/sbin
LOGPATH=${HOMEPATH}/logs
CNFPATH=${HOMEPATH}/var
SVPATH=${HOMEPATH}/services
DLog="${LOGPATH}/deploy_$IP_$DTIME.log"

### FUNTION 
function check_log() {
	[ ! -f "$LOGPATH/${exp_name}_${DTIME}.log" ] && touch $LOGPATH/${exp_name}_${DTIME}.log	
	sudo chown -R $USER: $LOGPATH
}
function stop_exporter() {
	ps=`ps aux | grep -v grep | grep -v rsync | grep "${prog}"`
	c=`ps aux | grep -v grep | grep -v rsync | grep "${prog}" | wc -l`

	echo -n $"Stopping $prog: "
	if [ $c -gt 0 ]; then
		pids=`echo "$ps" | sed 's/  \+/ /g' | cut -d' ' -f2`
		kill -9 $pids 
		echo -e $success
	fi
}
function start_exporter() {
	ps=`ps aux | grep -v grep | grep -v rsync | grep "${prog}"`
    c=`ps aux | grep -v grep | grep -v rsync | grep "${prog}" | wc -l`
	if [ $c -gt 0 ]; then
        $BINARYPATH/$exp_name --config.file=$CNFPATH/${exp_name}.yml >> $LOGPATH/${exp_name}_${DTIME}.log &
        echo -e $success
	fi
}
function init_file() {
        os=`cat /etc/redhat-release | grep -oP '(?<= )[0-9]+(?=\.)'`
	if [[ $os == 6 ]]; then
		[ ! -f "/etc/init.d/${exp_name}" ] && sudo cp $SVPATH/${exp_name}/init.d/${exp_name} /etc/init.d/

		sudo chmod +x /etc/init.d/exporter_*
		chkconfig --add ${exp_name} >/dev/null 2>&1 
		chkconfig on ${exp_name} >/dev/null 2>&1 

	elif [[ $os == 7 ]]; then
		[ ! -f "/etc/systemd/system/${exp_name}.service" ] && sudo cp $SVPATH/${exp_name}/systemd/${exp_name}.service /etc/systemd/system/
		sudo chmod +x /etc/systemd/system/exporter_*.service
		sudo systemctl daemon-reload
		sudo systemctl enable ${exp_name}.service

    else
       echo "Can not detect OS"
    fi
}

# Step 1
stop_exporter
# Step 2
check_log
init_file
# Step 3
start_exporter
# END
