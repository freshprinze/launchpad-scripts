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
managed_user_password=$2

if [ -z "$managed_user_name" ]; then
	msg="User Name is required. Exiting"
	return_msg
fi

if [ $(sudo synouser --get "${managed_user_name}" > /dev/null 2>&1; echo $?) -eq 0 ]; then
	echo "user already exists. username=${managed_user_name}"
	exit 0
fi

result=$(sudo synouser --add "${managed_user_name}" "${managed_user_password}" "" 0 "" 0 > /dev/null 2>&1)
exit_if_error $? $LINENO "failed create ${managed_user_name}" "$result"

user_dir=$(sudo synouser --get "${managed_user_name}" | grep -oP '(?<=User.Dir(.){4}: \[).*(?=\])' 2>&1)
until [ -d ${user_dir} ]; do sleep 1;done

# if [ ! -d ${user_dir} ]; then
# 	echo "user directory doesn't exist for user ${managed_user_name}"
# 	exit 0
# fi

echo "user directory ${user_dir} exists for user ${managed_user_name}"

sudo chmod 777 "${user_dir}"
sudo chown "${managed_user_name}:users" -R "${user_dir}"

if [ $(grep -E '/var/services/homes/${managed_user_name}:/sbin/nologin' /etc/passwd > /dev/null 2>&1; echo $?) -eq 0 ];then
    sudo sed -ie 's#/var/services/homes/${managed_user_name}:/sbin/nologin#/var/services/homes/${ansible_user}:/bin/sh#g' /etc/passwd
fi

exit 0