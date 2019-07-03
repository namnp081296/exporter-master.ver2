#!/bin/bash
########################################################################################################################################################
# Text Reset
RCol='\e[0m'    
Gre='\e[0;32m'
Red='\e[0;31m'
success="[$Gre OK $RCol]"
fail="[$Red Fail $RCol]"
########################################################################################################################################################
# Declare Variables
DTIME=$(date +"%Y%m%d")
SDIR=`pwd`
HOMEPATH="/etc/prometheus"
USER='prometheus'
BINARYPATH=${HOMEPATH}/sbin
LOGPATH=${HOMEPATH}/logs
CNFPATH=${HOMEPATH}/var
SVPATH=${HOMEPATH}/services
DLog="${LOGPATH}/deploy_$IP_$DTIME.log"
merge_port="11011"
node_port="11020"
########################################################################################################################################################
# Check WorkDIR
function check_homepath() {
	arr_path=(${HOMEPATH} ${BINARYPATH} ${LOGPATH} ${CNFPATH} ${SVPATH})
	for hpath in "${arr_path[@]}"
	do 
		[ ! -d "${hpath}" ] && sudo mkdir -p "${hpath}"
	done
}
# Check User
function check_user() {
	sudo getent passwd $USER > /dev/null 2&>1
    	if [ $? -eq 0 ]; then
	   	sudo chown -R $USER:$USER $HOMEPATH
    	else
       		sudo useradd --no-create-home --shell /sbin/nologin ${USER}
	   		sudo chown -R $USER:$USER $HOMEPATH
    	fi
}
# Log File
function check_log() {
	[ ! -f "$LOGPATH/exporter_merge_${DTIME}.log" ] && touch $LOGPATH/exporter_merge_${DTIME}.log
	[ ! -f "$LOGPATH/exporter_node_${DTIME}.log" ] && touch $LOGPATH/exporter_node_${DTIME}.log
	sudo chown -R $USER $LOGPATH
}
# Update 
function update_source() {
	sudo cp -R $SDIR/sbin $HOMEPATH
	sudo cp -R $SDIR/services $HOMEPATH
	sudo cp $SDIR/var/exporter_merge.yaml $CNFPATH
	sudo chmod +x $BINARYPATH -R
}
# Funtion Start/Stop/Restart
function stop_exporter() {
	ps=`ps aux | grep -v grep | grep -v rsync | grep "${prog}"`
	c=`ps aux | grep -v grep | grep -v rsync | grep "${prog}" | wc -l`

	echo -n $"Stopping $prog: "
	if [ $c -gt 0 ]; then
		pids=`echo "$ps" | sed 's/  \+/ /g' | cut -d' ' -f2`
		kill -9 $pids 
		echo -e $success.
	fi
}
function start_exporter() {
	#ps=`ps aux | grep -v grep | grep -v rsync | grep "${prog}" | awk 'BEGIN{FS="/exporter_"}{print $2}' | awk '{print $1}'`
    ps="${prog}"
	   if [[ $ps == exporter_merge ]]; then
		bash -c "${BINARYPATH}/${prog} -c ${CNFPATH}/${prog}.yaml --listen-port $merge_port >> $LOGPATH/exporter_merge_$DTIME.log 2>&1 &"
		echo -e $success.
	   elif [[ $ps == exporter_node ]]; then
		bash -c "${BINARYPATH}/${prog} --web.listen-address=:${node_port} >> $LOGPATH/exporter_node_$DTIME.log 2>&1 &"
		echo -e $success.
	fi
}
function init_file() {
        os=`cat /etc/redhat-release | grep -oP '(?<= )[0-9]+(?=\.)'`
	if [[ $os == 6 ]]; then
		[ ! -f "/etc/init.d/exporter_merge" ] && sudo cp $SVPATH/exporter_merge/init.d/exporter_merge /etc/init.d/
		[ ! -f "/etc/init.d/exporter_node" ] && sudo cp $SVPATH/exporter_node/init.d/exporter_node /etc/init.d/
		sudo chmod +x /etc/init.d/exporter_*
		chkconfig --add exporter_merge >/dev/null 2>&1 
		chkconfig on exporter_merge >/dev/null 2>&1 
		chkconfig --add exporter_node >/dev/null 2>&1
		chkconfig on exporter_node >/dev/null 2>&1
	elif [[ $os == 7 ]]; then
		[ ! -f "/etc/systemd/system/exporter_merge.service" ] && sudo cp $SVPATH/exporter_merge/systemd/exporter_merge.service /etc/systemd/system/
		[ ! -f "/etc/systemd/system/exporter_node.service" ] && sudo cp $SVPATH/exporter_node/systemd/exporter_node.service /etc/systemd/system/
		sudo chmod +x /etc/systemd/system/exporter_*.service
		sudo systemctl daemon-reload
		sudo systemctl enable exporter_merge.service
		sudo systemctl enable exporter_node.service
    else
       echo "Can not detect OS"
    fi
}
# Step 1: Stop service
arr_path_1=("exporter_merge" "exporter_node")
for prog in "${arr_path_1[@]}"
    do
         stop_exporter
    done
echo -n ""
# Step 2: Base Check
check_homepath
check_user
check_log
update_source
init_file
# Step 2: Start Exporter_Merge & Node
arr_path_2=("exporter_merge" "exporter_node")
for prog in "${arr_path_2[@]}"
	do 
		start_exporter
	done
echo -n ""
#END
echo "Install successful."
