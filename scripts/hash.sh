#!/bin/sh

##############################
#                            #
#  Copyright (c) xTekC.      #
#  Licensed under MPL-2.0.   #
#  See LICENSE for details.  # 
#                            #
##############################

RED="\033[0;31m"
ORANGE="\033[0;33m"
GREEN="\033[0;32m"
RESET="\033[0m"

zig_hash=$(zig build 2>&1 | grep -oP 'expected \.hash = "\K[^"]+')

if [ -z "$zig_hash" ]; then
	printf "${RED}Failed to capture library hash from zig build.${RESET}\n"
	exit 1
fi

printf "${ORANGE}Captured library hash:${RESET} \n$zig_hash\n"

awk -v hash="$zig_hash" 'BEGIN { replaced=0 }
{
    if ($0 ~ /\/\/\.hash = "hash_here"/)
    {
        if (!replaced)
        {
            print "            .hash = \"" hash "\",";
            replaced=1;
        }
        else { print $0; }
        next;
    }
    print $0;
}' ./build.zig.zon >temp.zon

mv temp.zon ./build.zig.zon
printf "${GREEN}Updated hash in build.zig.zon${RESET}\n"
