#!/bin/sh
PATH=/sbin:/usr/sbin:/bin:/usr/bin
REQUIRED_HOST=adminhost1

usage() {
	echo "Usage: $0 account_name"
	echo "Make sure this is run on the host: $REQUIRED_HOST"
	exit 1
}

MYHOSTNAME=`hostname`

[ -n "$1" -a $MYHOSTNAME == $REQUIRED_HOST ] || usage

USERNAME=$1

useradd -m $USERNAME || exit 1
cp /opt/admin/etc/skel/.bash* /home/$USERNAME/ || exit 1

/usr/bin/mailx -s "Welcome to our site" ${1}@example.net <<EOF
The SA team has created an account for you on the UNIX systems.
You have a default password that's unique to your account,
which will need to be changed upon initial login.
The system will force this password change.

Please call the SA help desk at 555-1212 in order to receive your
password, and to ask any questions that you may have.
EOF
