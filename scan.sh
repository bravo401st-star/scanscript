#!/bin/bash

###
###
###  Modified script for easier times and less maths (you're welcome) missing input safety but just don't misinput!
###
###

GREEN='\033[0;32m'
RED='\033[0;31m'
B_GREEN='\033[1;32m'
B_RED='\033[1;31m'
NC='\033[0m'

printf "${B_GREEN}Enter network address and CIDR(leave out CIDR to scan single IP) (e.g. 192.168.0.1/24):${NC} "
read net

printf "${B_GREEN}Enter the TCP ports space-delimited [Default: 21-23 80]:${NC} "
read ports

if [ -z $ports ]
then
  printf "${GREEN}No ports provided, assuming 21-23 80...${NC}\n"
  ports="21-23 80"
fi

# pull CIDR, and beginning of net and the range (if no CIDR we assume scan that SINGLE IP)
declare net_addr
declare last_oct
declare start_
declare end_
declare -i cidr

# pull octets
net_addr=$(awk -F. '{print $1"."$2"."$3}' <<< "$net")
last_oct=$(awk -F. '{print $4}' <<< "$net")
last_oct=$(awk -F/ '{print $1}' <<< "$last_oct")

# pull CIDR
if grep -q "/" <<< "$net"
then
  cidr=$(awk -F/ '{print $2}' <<< "$net")
fi

if [ -z $cidr ]
then
  # no cidr found, we will assume scan the single given ip
  printf "${GREEN}No CIDR given, assuming single host scan...${NC}\n"
  start_=$last_oct
  end_=$last_oct
else
  declare -i host_bits
  host_bits=$((32 - cidr))
  declare -i host_count
  host_count=$((2 ** host_bits))

  # now we use bad maths to find start and end range
  start_=$(($((last_oct / host_count)) * host_count + 1))
  end_=$((start_ + host_count - 2))
fi
printf "${GREEN}[Scanning from ${net_addr}.${start_} to ${net_addr}.${end}]${NC}\n\n"

for ((i=$start_; i<=$end_; i++))
do
  nc -nvzw1 $net_addr.$i $ports 2>&1 | grep -E 'succ|open' &
done
wait
printf "${B_GREEN}DONE!\n"
