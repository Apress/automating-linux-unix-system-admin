#!/usr/bin/perl -w
use strict;

# First, ask user for a directory
print "Please enter a directory name: ";

# Use 'my' to declare variables 
# Use the <> operators to read a line from STDIN
my $dir = <STDIN>;

# Now, use the 'chomp' function to remove the carriage return 
chomp($dir);

# First, do a dir listing by executing the 'ls' command directly
print "\nCalling system ls function:\n";
# The 'system' function will execute any shell command
system("ls $dir");

# Next, do a dir listing using internal Perl commands
# The 'die' function will cause the script to abort if the 
# 'opendir' function call fails
print "\nListing directory internally:\n";
opendir(DIR, $dir) or die "Could not find directory: $dir\n";
my $entry;
# Now, read each entry, one at a time, into the $entry variable
while ($entry = readdir(DIR)) {
   print "$entry\n";
}
closedir(DIR);
