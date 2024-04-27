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

if [ $(sudo synogroup --get "${group_name}" > /dev/null 2>&1; echo $?) -ne 0 ]; then
	echo "creating group ${group_name} as it doesn't exist"

	result=$(sudo synogroup --add ${group_name} ${managed_user_name} > /dev/null 2>&1)
	exit_if_error $? $LINENO "failed create group ${group_name}" "$result"

	exit 0
fi

echo "updating group ${group_name} with ${managed_user_name}"

# get list of current users in group admistrators
current_members=$(sudo synogroup --get ${group_name} | grep --perl-regexp --only-matching '(?<=^\d:\[).*(?=\]$)' 2>&1)

if [[ -z "${current_members[@]-}" ]]; then
	echo "adding ${managed_user_name} as the only member of ${group_name}"

	result=$(sudo synogroup --member ${group_name} ${managed_user_name} > /dev/null 2>&1)
	exit_if_error $? $LINENO "failed to add ${managed_user_name} to group ${group_name}" "$result"

	exit 0
fi

members=""
already_member=false

echo "fetched current members of group ${group_name}"

for member in ${current_members};do

	if [ ${member} == ${managed_user_name} ]; then
		already_member=true
		break
	fi

	members="${members} ${member}"
done

if $already_member; then
	echo "user is already a member of group=${group_name}, username=${managed_user_name}"
	exit 0
fi

echo "adding ${managed_user_name} as a member of ${group_name}"

result=$(sudo synogroup --member ${group_name} ${members} ${managed_user_name} > /dev/null 2>&1)
exit_if_error $? $LINENO "failed to add ${managed_user_name} to group ${group_name}" "$result"

exit 0