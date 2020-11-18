#!/bin/bash

# create CSV log file with column header
cat header.txt > /dev/shm/log5.csv
#cat log5.csv > /dev/shm/log5.csv

# start well water depth logging process
nohup ./doRange.sh 100000 >> /dev/shm/log5.csv &
