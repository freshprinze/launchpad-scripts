#!/bin/sh 

set -eu

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

managed_user_name=$1
group_name=$2

if [ -z "$managed_user_name" ]; then
	msg="User Name is required. Exiting"
	return_msg
fi

if [ -z "$group_name" ]; then
	msg="Group Name is required. Exiting"
	return_msg
fi

# get list of current users in group admistrators
current_members=$(sudo synogroup --get ${group_name} | grep --perl-regexp --only-matching '(?<=^\d:\[).*(?=\]$)' > /dev/null 2>&1)
exit_if_error $? $LINENO "failed get current members for ${group_name}" "$current_members"

members=""

for member in ${current_members};do
	members="${members} ${member}"
done

result=$(sudo synogroup --member ${group_name} ${members} ${managed_user_name} > /dev/null 2>&1)
exit_if_error $? $LINENO "failed to add ${managed_user_name} to group ${group_name}" "$result"

exit 0