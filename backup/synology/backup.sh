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

include_from=include.txt
exclude_from=exclude.txt

if [ ! -f "$include_from" ]; then
	msg="include from file $include_from is missing. exiting"
	rc=5
	return_msg
fi

if [ ! -f "$exclude_from" ]; then
	msg="exclude from file $exclude_from is missing. exiting"
	rc=6
	return_msg
fi

# check if repository is initialized
result=$(source /etc/restic-env; restic cat config > /dev/null 2>&1)
exit_if_error $? $LINENO "repository is not initialized. $RESTIC_REPOSITORY" "$result"

# perform backup
result=$(source /etc/restic-env; restic backup --files-from $include_from --exclude-file $exclude_from > /dev/null 2>&1)

case $? in

	0)
	msg="successfully backed up files to $RESTIC_REPOSITORY"
	rc=0
	;;

	3)
	msg="incomplete backup created at $RESTIC_REPOSITORY. some source files could not be read"
	rc=3
	;;

	*)
	msg="failed create backup at $RESTIC_REPOSITORY"
	rc=$?
	;;

esac

return_msg