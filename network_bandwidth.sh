#!/bin/bash
#############################################################################
# Author : Gurupad Bhat
# Version : v1.0
# Description : This will parse the bandwidth utilisation of each interface 
# and send the metrics to the data pipeline
##############################################################################
#set -x
##############################################################################
# checks if 2 args passed, checks config files exists and also checks network_bandwidth_config having valid json or not
##############################################################################
check_arguments (){
	if [ "$#" -lt 2 ];then
		usage
	fi
	check_config_files_exists $1 $2
	check_if_file_contains_valid_json $1
}

##############################################################################
# checks if config files exists
##############################################################################

check_config_files_exists (){
	json_conf_file=$1
	sip_conf_file=$2
	if [ ! -f "$json_conf_file" ]; then
		echo -e "$json_conf_file file does not exists"
		exit 1
	fi
	if [ -f "$sip_conf_file" ]; then
		sipinterface="$("$(which cat)" $sipconfFile | "$(which awk)" '{print $3}' | tr -d '\"'\")"
	else
		sipinterface=""
	fi
}
##############################################################################
# checks if json file(config) is well formed with jq
##############################################################################

check_if_file_contains_valid_json () {
	json_string="$("$(which cat)" $1)"
	if ! "$(which jq-linux64)" -e . >/dev/null 2>&1 <<<"$json_string"; then
		echo -e "Failed to parse JSON"
		exit 1
	fi
}
#############################################################################
# Checks for ifstat and jq package
#############################################################################

check_dependencies () {

	declare -a DEPNDENCY_ARR=("ifstat" "jq-linux64")
    for package in "${DEPNDENCY_ARR[@]}"
    do
    result=$(which $package > /dev/null 2>&1)
    if [[ $? -ne 0 ]]; then
    	echo -e "$package is not installed. Cannot proceed further"
	   	exit 1
    fi
    done
}

get_interfaces() {
	interfacelist="$("$(sudo which ip)" r | "$(which grep)" -w proto | "$(which awk)" '{print $3}')"
	eval "INTERFACE_ARRAY=($interfacelist)"
}

############################################################################
# pulls the download and upload speed for each interface
############################################################################

get_bandwidth_for_interfaces () {
	outputStr=""
	for interface in "${INTERFACE_ARRAY[@]}"; do
		if [ "$interface" != "$sipinterface" ]; then
			host="$(hostname)"
			circuitid="$(echo $json_string | "$(which jq-linux64)" -r .\"$host\" | "$(which jq-linux64)" -r .$interface | "$(which jq-linux64)" -r .'CIRCUIT_ID')"
			operator="$(echo $json_string | "$(which jq-linux64)" -r .\"$host\" | "$(which jq-linux64)" -r .$interface | "$(which jq-linux64)" -r .'OPERATOR')"
			stat="$(ifstat -b -i $interface 1 1 | sed -n 3p)"
			download_speed=$(echo $stat | "$(which awk)" '{print $1/1000}') #converting data Kb to Mb
			upload_speed=$(echo $stat | "$(which awk)" '{print $2/1000}') #converting data KB to MB
			outputStr="{\"name\":\"ill_bandwidth\",\"timestamp\":`date +%s`,\"tags\":{\"interface\":\"$interface\",\"host\":\"$host\",\"circuit_id\":\"$circuitid\",\"operator\":\"$operator\"},\"fields\":{\"download\":\"$download_speed\",\"upload\":\"$upload_speed\"}}"
			set_bandwidth_stats_to_odfe $outputStr
		fi
		done
}

###########################################################################
# sends bandwidth data to data pipeline 
###########################################################################
set_bandwidth_stats_to_odfe () {
	echo $1 >/dev/udp/localhost/6700
	echo $1
}

usage() {
	echo -e "No arguments supplied..!! please pass the arguments like this USAGE :- <network_bandwidth.sh> <config_path> <sipconfFile>"
	exit 1
}

###########################################################################
# main function
###########################################################################

main () {
	check_dependencies
	check_arguments $1 $2
	get_interfaces
	get_bandwidth_for_interfaces
}
main $@