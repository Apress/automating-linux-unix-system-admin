#!/bin/sh

PATH=$PATH:/usr/sbin

mkdir -m 700 /a/.ssh

echo "ssh-dss AAAAB3NzaC1kc3MAAACBAIMgBhsQ6neSMbop+koRc6VL/vSc4qmDGkmMUkFvtPneNB33KIlFahpIRW5Z0E5CB3WsM0iZWTNd3JGyecdeMNmC5xfXYgInuCFjj1cdZWtx0BZ7J/oUa14l6veqt+8GNc0x8cl590Yx4FTMn4eZOGAe8sVHW2wGKaxPTFoe7nspAAAAFQCg88KahQq1RtV7BmUZIYNfUQV2ywAAAIAh+R0dJzLm7tWemS0CH52hjuGugUF51daGFsu0pZomORp2Xltt6VvGtcdbZp+Fxot79eMPE2GymhF15Nw6F7J8kK4wbI3MxmE6p0drp9elAmFot74dPXciuhPMUkVUG5VPjl2QsTp4R3si0RXUOdb9E5J55UKvd7HsH4LgFr2PIQAAAIBY7GmT8fdta598Oh0ObDP2ooTqmJL3KttQAJVG5iEPDhrjOnCvuvRrAiY6wTjlOwDLfSL5S7c/8qdRhCA6yN55WUGVYgzGrFoZv07zPikpugFn+pire43ZEGjqetmCsfjJOs6eYVdGOb3dOjr6Arc/qjRQxW/MNNAr/J3RpomqpZ== nate@hostname" > /a/.ssh/authorized_keys

OS_TYPE=`uname -rs`
case "$OS_TYPE" in
	"SunOS 5.10")
cat > /a/etc/rc2.d/S99runonce <<ENDSCRIPT
#!/bin/sh
# used at first boot after being jumpstarted
PATH=$PATH:/usr/sbin:/opt/csw/bin:/opt/csw/sbin

LOGFILE=/var/tmp/runonce.out
LOGFILE_ERR=/var/tmp/runonce.err
exec 1>\$LOGFILE
exec 2>\$LOGFILE_ERR

# get blastwave up and running:
# - answer "all", then "y" then "y"
pkgadd -d http://www.blastwave.org/pkg_get.pkg all <<EOM
yes
yes
EOM

cp -p /var/pkg-get/admin-fullauto /var/pkg-get/admin

pkg-get install wget gnupg textutils openssl_rt openssl_utils \
 berkeleydb4 daemontools_core daemontools daemontools_core sudo cfengine

# setup cfengine key
cfkey

# bootstrap cfengine with a basic update.conf and cfagent.conf (for
# some reason we seem to need both) that will get the current configs
# from the cfengine master.
[ -d /var/cfengine/inputs ] || mkdir -p /var/cfengine/inputs

cat <<ENDCFCONFIG | tee /var/cfengine/inputs/update.conf /var/cfengine/inputs/cfagent.conf
# created by jumpstart installation, meant to bootstrap the real
# configs from the cfengine master. If you can see this, then for some
# reason we were never able to talk to the cfengine master. :(
control:
	any::

		AllowRedefinitionOf = ( cf_base_path workdir client_cfinput )

		# all we care about right now is the first copy
		actionsequence	= ( copy.IfElapsed0 )

		domain		= ( campin.net )
		policyhost	= ( goldmaster.campin.net )

		# we host it on a Debian box
		master_cfinput	= ( /var/lib/cfengine2/masterfiles/inputs )
		workdir		= ( /var/cfengine )

		#
		# Splay goes here
		#
		SplayTime	= ( 0 )
		
	solaris|solarisx86::
		cf_base_path	= ( /opt/csw/sbin )
		workdir		= ( /var/cfengine )

	debian::
		cf_base_path	= ( /usr/sbin )
		workdir		= ( /var/lib/cfengine2 )

	!debian.!(solaris|solarisx86)::
		# take a best guess on the path for other hosts
		cf_base_path	= ( /var/cfengine/bin )
	any::
		client_cfinput	= ( \$(workdir)/inputs )

copy:
	# Everything in $(master_cfinput) on the master
	# _and_ everything in its subdirectories is copied to every host.
	\$(master_cfinput)/	dest=\$(workdir)/inputs/
				r=inf
				mode=700
				type=binary
				exclude=*.lst
				exclude=*~
				exclude=#*
				exclude=RCS
				exclude=*,v
				purge=true
				server=\$(policyhost)
				trustkey=true
				encrypt=true

ENDCFCONFIG

/opt/csw/sbin/cfagent -qv

# move myself out of the way
mv /etc/rc2.d/S99runonce /etc/rc2.d/.s99runonce
ENDSCRIPT

	chmod 755 /a/etc/rc2.d/S99runonce
		;;
esac

# configure power management
sed s/unconfigured/noshutdown/ /a/etc/power.conf > /a/etc/power.conf.sed
mv /a/etc/power.conf.sed /a/etc/power.conf

# permit root login over ssh
sed 's/^PermitRootLogin no/PermitRootLogin yes/' /a/etc/ssh/sshd_config > \
 /a/etc/ssh/sshd_config.sed
mv /a/etc/ssh/sshd_config.sed /a/etc/ssh/sshd_config

# prevent prompts on first boot about power management
sed 's/^CONSOLE/\#CONSOLE/' /a/etc/default/login > /a/etc/default/login.sed
mv /a/etc/default/login.sed /a/etc/default/login

# prevent prompts on first boot about the NFS domain
touch /a/etc/.NFS4inst_state.domain
cat > /a/etc/.sysidconfig.apps <<EOSYS
/usr/sbin/sysidnfs4
/usr/sbin/sysidpm
/lib/svc/method/sshd
/usr/lib/cc-ccr/bin/eraseCCRRepository
EOSYS

cat > /a/etc/.sysIDtool.state <<EOIDT
1 # System previously configured?
1 # Bootparams succeeded?
1 # System is on a network?
1 # Extended network information gathered?
1 # Autobinder succeeded?
1 # Network has subnets?
1 # root password prompted for?
1 # locale and term prompted for?
1 # security policy in place
vt100
EOIDT
