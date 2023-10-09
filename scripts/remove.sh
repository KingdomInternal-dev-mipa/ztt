#!/bin/sh

##############################
#                            #
#  Copyright (c) xTekC.      #
#  Licensed under MPL-2.0.   #
#  See LICENSE for details.  # 
#                            #
##############################

RED="\033[0;31m"
RESET="\033[0m"

remove_library() {
	lib_name=$1

	awk -v lib="${lib_name}" '
    BEGIN { inside_dependencies = 0; inside_lib = 0; remove_lib = 0; }
    /^[\t ]*\.dependencies[ \t]*=[ \t]*\.\{/ { inside_dependencies = 1; print; next }
inside_dependencies && /^[ \t]*\}[ \t]*,/ {
    if (inside_lib && remove_lib) {
        inside_lib = 0;
        remove_lib = 0;
        next;
    }
    if (last_line) {
        print last_line;
    }
    last_line = $0; 
    next;
}
inside_dependencies && /^[ \t][ \t]*$/ {
    if (inside_lib && remove_lib) {
        inside_lib = 0;
        remove_lib = 0;
        next;
    }
    if (last_line) {
        print last_line;
        last_line = "";
    }
    print;
}
inside_dependencies && /^[ \t ]*\.'${lib_name}'[ \t]*=[ \t]*\./ {
    inside_lib = 1;
    remove_lib = 1;
    next;
}
!inside_lib {
    if (last_line) {
        print last_line;
        last_line = "";
    }
    print;
}

    ' ./build.zig.zon >temp.zon

	mv temp.zon ./build.zig.zon
	printf "${RED}Removed library ${RESET}${lib_name}${RED} from build.zig.zon${RESET}\n"
}

printf "${RED}Enter the name of the library to remove:${RESET} \n" >/dev/tty
read -r lib_name </dev/tty

if [ -z "$lib_name" ]; then
	printf "${RED}Invalid library name${RESET}\n"
elif grep -q "^[\t ]*\.${lib_name}[ \t]*=[ \t]*\." ./build.zig.zon; then
	remove_library "$lib_name"
else
	printf "${RED}Library not found${RESET}\n"
fi
