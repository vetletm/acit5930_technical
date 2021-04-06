#!/usr/bin/env bash


csv_filename="$(date +"%Y%m%d-%H%M")-metrics.csv"
touch $csv_filename
echo "timestamp,pid1,cpu1,mem1,pid2,cpu2,mem2" >> $csv_filename

while true
do
  timestamp=$(date +"%Y%m%d-%H%M%S")
  cpu_mem_usage=$(pgrep simple_switch | xargs -I % top -b -n 1 -p % | grep simple_switch | awk '{print $1 "," $9 "," $10 ","}' | tr -d '\n')
  echo "$timestamp,$cpu_mem_usage" >> $csv_filename
  sleep 5
done
