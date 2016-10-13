#!/usr/bin/perl -w
use strict;

# The logfile to analyze by default on a RedHat-based system
my $log = "/var/log/secure";

# Where the key fingerprints are stored
my $prints = "/usr/local/etc/ssh/prints";

# First, read and store the fingerprints in a hash table
# Duplicate lines will not hurt anything
open (PRINTS, "$prints") or die "Can't open $prints: $!\n";
my (%Prints, $line);
while ($line = <PRINTS>) {
	chomp($line);
	my ($account, $print) = split / /, $line;
	$Prints{$print} = $account;
}
close (PRINTS);

# Open the logfile and process each line
# Store results in a two-tier hash table
open (LOG, "$log") or die "Can't open $log: $!\n";
my (%Results, $user);
while ($line = <LOG>) {
	chomp ($line);
	if ($line =~ /Found matching \S+ key: ([0-9a-f:]+)/) {
		# Determine user from print-lookup hash (if possible)
		if ($Prints{$1}) {
			$user = $Prints{$1};
		} else {
			$user = 'Unknown';
		}
	} elsif ($line =~ /Accepted publickey for (\S+)/) {
		$Results{$1}{$user}++;
	}
}
close (LOG);

# Display the results
my $account;
foreach $account (keys %Results) {
	print "$account:\n";
	foreach $user (keys %{$Results{$account}}) {
		print " $user: $Results{$account}{$user} connection(s)\n";
	}
}
exit 0;
