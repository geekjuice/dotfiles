#!/bin/bash

# Multiple SSH Port Forwarder

# Colors
R='\e[0;31m'
G='\e[0;32m'
Y='\e[0;33m'
B='\e[0;34m'
O='\e[0m'

# Functions
showhelp() {
    echo "usage: sshp [-l host] [ports] REMOTEHOST"
}

# Process options
while getopts :hl: opt; do
    case $opt in
        l)  # Host
            host=$OPTARG ;;
        h)  # Help
            showhelp
            exit 1 ;;
        :)  # Catch all
            printf "Option -$OPTARG requires an argument.\n" >&2
            showhelp
            exit 1 ;;
    esac
done
shift $(($OPTIND - 1))

# Check for enough arguments
if [[ $# -eq 0 ]];then
    printf "not enough arguments\n"
    showhelp
    exit 1
fi

# Process arguments
arr=( $@ )
len=${#arr[@]}
remote=${arr[$len-1]}
ports=${arr[@]:0:$len-1}
forwards=""
[[ -z $host ]] && host="localhost"

# Loop through ports to open
for port in $ports; do
    if [[ $port != *[!0-9]* ]]; then
        forwards="$forwards -L $port:$host:$port"
    fi
done

# Join ports by comma for output
ports=$(echo $ports | sed 's/ /, /g')
printf "${B}Forwarding ports: ${Y}$ports\n"

# SSH
printf "${G}Now connecting...${O}\n"
ssh $forwards $remote
