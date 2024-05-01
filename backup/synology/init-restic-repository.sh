#!/bin/sh 

set -u

###################################################################################
# import utility functions
###################################################################################

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

#####################################################################################
# business logic
#####################################################################################

disable_output
enable_output

# check if repository is initialized
result=$(source /etc/restic-env; restic cat config > /dev/null 2>&1)

if [ $? == 0 ]; then
	msg="repository is already initialized. $RESTIC_REPOSITORY"
	rc=0
	return_msg
fi

# initialized repository
result=$(source /etc/restic-env; restic init > 2>&1)

case $? in

	0)
	msg="successfully initialized repository at $RESTIC_REPOSITORY"
	rc=0
	;;

	*)
	msg="failed to initialize repository at $RESTIC_REPOSITORY. $result"
	rc=$?
	;;

esac

return_msg