#!/bin/bash
#
# backup raspberry-pi

enable_output() {
	exec 1>&3 2>&4
}

disable_output() {
	exec 3>&1 4>&2 >/dev/null 2>&1
}

return_msg() {
	enable_output

	printf "$msg\n"

	disable_output

	exit $rc
}

exit_if_error() {
	(($#)) || return

	local rc=$1
	local message="${3:-No message specified}"

	((rc)) && {
		msg=$3
		stderr=$4

		return_msg
	}

	return 0
}

check_requirement() {
	if ! which $1 &>/dev/null; then
		enable_output
		
		printf "module require '$1' installed. exiting\n"
		exit 1
	fi
}

# create the file descriptors and disable output
disable_output

# enable output
enable_output

# set default values for returning in the JSON object
changed="false"
rc=0
stdout=""
stderr=""
msg=""

#####################################################################################
# check required dependencies
#####################################################################################
check_requirement image-backup

#####################################################################################
# vaildate input arguments
####################################################################################

# if [ -z "$" ]; then
# 	msg="service account id is not provided. Exiting"
# 	rc=2

# 	return_json
# fi

#####################################################################################
# business logic
#####################################################################################

# generate backup file name
backup_file_name="/mnt/remote-backup/$(hostname -s).img"
echo "generated backup file name $backup_file_name"

# create initial backup if not exist
if [ ! -f $backup_file_name ]; then
	echo "creating initial image backup for $(hostname)"
	
	result=$(sudo image-backup --initial $backup_file_name,,5000)
	exit_if_error $? $LINENO "failed to generate intial backup $backup_file_name" "$result"

	return 0
fi

# create backup
echo "creating image for $(hostname)"

result=$(image-backup $backup_file_name)
exit_if_error $? $LINENO "failed to generate backup $backup_file_name" "$result"

msg="successfully created backup $backup_file_name"

# exit with the set values
return_msg