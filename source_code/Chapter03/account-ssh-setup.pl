#!/usr/bin/perl -w
use strict;

# Set the location of the configuration file here
my $config = "/usr/local/etc/ssh/accounts";

# Where the key fingerprints will be stored
# (for purposes of log analysis)
my $prints = "/usr/local/etc/ssh/prints";

# Set the path to a user's public key relative to
# their home directory
my $public_key = ".ssh/id_rsa.pub";

# This function takes one scalar parameter (hence the $
# within the parenthesis). The parameter is stored in
# the local variable $username. The home directory
# is returned, or undef is returned if the user does
# not exist.

sub GetHomeDir ($) {
	my ($username) = @_;
	my $homedir = (getpwnam($username))[7];
	unless ($homedir) {
		print STDERR "Account $username doesn't exist!\n";
	}
	return $homedir;
}

# This function takes in an account and the home directory and logs
# the key fingerprint (by running ssh-keygen -l), which has output:
# 2048 85:2c:6e:cb:f6:e1:39:66:99:15:b1:20:9e:4a:00:bc ...
sub StorePrint ($$) {
	my ($account, $homedir) = @_;
	my $print = `ssh-keygen-l -f $homedir/$public_key`;
	# Remove the carriage return
	chomp($print);
	# Keep the fingerprint only
	$print =~ s/^\d+ ([0-9a-f:]+).*$/$1/;
	print PRINTS "$account $print\n";
}

# This function takes one line from the config file and
# sets up that specific account.
	sub ProcessLine ($) {
	my ($line) = @_;
	# A colon separates the account name and the users with access
	my ($account, $users) = split (/:/, $line);
	my $homedir = GetHomeDir($account);
	return unless ($homedir);

	print "Account $account: ";

	# First, make sure the directory exists, is owned
	# by root, and is only accessible by root
	my $group = 0;

	if (-d "$homedir/.ssh") {
		$group = (stat("$homedir/.ssh"))[5];
		system("chown root:root $homedir/.ssh");
		system("chmod 0700 $homedir/.ssh");
	} else {
		mkdir("$homedir/.ssh", 0700);
	}

	# Remove the existing file
	unlink ("$homedir/.ssh/authorized_keys");

	# Create the new file by appending other users' public keys
	my ($user, $homedir2);
	foreach $user (split /,/, $users) {
		# Get this other user's home directory too
		$homedir2 = GetHomeDir($user);
		next unless ($homedir2);

		if ((not -f "$homedir2/$public_key") or
			( -l "$homedir2/$public_key") ) {
			print "\nUser $user public key not found or not a file!\n";
			next;
		}
		print "$user ";
		my $outfile = "$homedir/.ssh/authorized_keys";
		system("cat $homedir2/$public_key >> $outfile");
		StorePrint($user, $homedir2);
	}
	print "\n";

	# Now, fix the permissions to their proper values
	system("chmod 0600 $homedir/.ssh/authorized_keys");
	system("chown $account $homedir/.ssh/authorized_keys");
	system("chown $account $homedir/.ssh");
	if ($group) {
		# We saved its previous group ownership... restore it.
		system("chgrp $group $homedir/.ssh");
	}
}

# Open the fingerprint file
open (PRINTS, ">$prints") or die "Can't create $prints: $!\n";

# Open the config file and process each non-empty line
open (CONF, "$config") or die "Can't open $config: $!\n";
my $line;
# The angle operators (<>) read one line at a time
while ($line = <CONF>) {
	chomp($line);
	# Remove any comments
	$line =~ s/\#.*$//;
	# Remove leading and trailing whitespace
	$line =~ s/^\s+//;
	$line =~ s/\s+$//;
	# Process the line (if anything is left)
	$line and ProcessLine($line);
}
close (CONF);
close (PRINTS);
exit 0;
