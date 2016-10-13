#!/bin/bash

# Ask the user for a directory
echo "Please enter a directory name:"
read input

# Now, show the contents of that directory
echo
echo "Contents of directory $input:"
ls $input
