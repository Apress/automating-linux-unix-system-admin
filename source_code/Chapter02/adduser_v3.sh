#!/bin/sh
# Written by ncampi 05/26/08 for new UNIX user account creation
# WARNING!!!! If you attempt to run this for an existing username,
# it will probably delete that user and all their files!
# Think about adding logic to prevent this.

# set the path for safety and security
PATH=/usr/sbin:/bin:/usr/bin

# update me if we fail over or rebuild/rename the admin host
REQUIRED_HOST=adminhost1

usage() {
	echo "Usage: $0 account_name"
	echo "Make sure this is run on the host: $REQUIRED_HOST"
	exit 1
}

die() {
	echo ""
	echo "$*"
	echo ""
	echo "Attempting removal of user account and exiting now."
	userdel -rf $USERNAME
	exit 1
}

MYHOSTNAME=`hostname`

[ -n "$1" -a $MYHOSTNAME == $REQUIRED_HOST ] || usage

USERNAME=$1

useradd -m $USERNAME || die "useradd command failed."
cp /opt/admin/etc/skel/.bash* /home/$USERNAME/ || \
die "Copy of skeleton files failed."

/usr/bin/mailx -s "Welcome to our site" ${1}@example.net <<EOF

The SA team has created an account for you on the UNIX systems.
You have a default password that's unique to your account,
which will need to be changed upon initial login. The system will
force this password change upon your first login.

Please visit the SA help desk in order to receive your password,
and to ask any questions that you may have.
EOF
