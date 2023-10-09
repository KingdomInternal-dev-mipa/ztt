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

get_github_url() {
	printf "${ORANGE}Enter GitHub library URL: ${RESET}\n" >/dev/tty
	read -r url </dev/tty
	case "$url" in
	"https://github.com/"*)
		echo "$url"
		;;
	*)
		printf "${RED}Invalid GitHub library URL${RESET}\n" >/dev/tty
		exit 1
		;;
	esac
}

get_commit_hash() {
	printf "${ORANGE}Enter library commit hash or release version: ${RESET}\n" >/dev/tty
	read -r hash </dev/tty
	if [ -z "$hash" ]; then
		printf "${RED}No library commit hash or release version was provided.${RESET}\n" >/dev/tty
		exit 1
	fi
	echo "$hash"
}

extract_library() {
	url=$1
	library="${url##https://github.com/}"
	library="${library#*/}"
	library="${library%%/*}"
	library=$(echo "$library" | tr '-' '_')
	echo "$library"
}

main() {
	github_url=$(get_github_url)

	commit_hash=$(get_commit_hash)

	library=$(extract_library "$github_url")

	if grep -q ".${library}" ./build.zig.zon; then
		existing_entry=$(grep ".${library} = ." ./build.zig.zon)
		if [ "$existing_entry" = "$content" ]; then
			printf "${RED}This library already exists with the same content in build.zig.zon.${RESET}\n"
			exit 1
		fi

		printf "${RED}This library already exists in build.zig.zon.${RESET}\n"

		printf "${RED}Do you want to replace it? (y/N):${RESET} "
		read -r response
		case "$response" in
		[yY])
			awk -v repo=".${library}" -v content="$content" '
            BEGIN { inside_repo = 0; skip_repo = 0 }
            /^[\t ]*\.'$library'[ \t]*=[ \t]*\./ {
                inside_repo = 1;
                skip_repo = 1;
                next;
            }
            /^[\t ]*\.url[ \t]*=[^\n]*$/ {
                if (inside_repo && skip_repo) {
                    next;
                }
            }
            /^[\t ]*\.hash[ \t]*=[^\n]*$/ {
                if (inside_repo && skip_repo) {
                    next;
                }
            }
            /^[\t ]*\},?/ {
                if (inside_repo && skip_repo) {
                    inside_repo = 0;
                    skip_repo = 0;
                    next;
                }
            }
            { print; }
            ' ./build.zig.zon >temp.zon

			mv temp.zon ./build.zig.zon
			printf "${GREEN}Replaced dependency in build.zig.zon${RESET}\n"
			;;
		*)
			echo "Exiting..."
			exit 1
			;;
		esac
	fi

	content="        .${library} = .{
            .url = \"$github_url/archive/$commit_hash.tar.gz\",
            //.hash = \"hash_here\"
        },"

	awk -v content="$content" 'BEGIN { added=0 }
    {
        if ($0 ~ /\.dependencies = \.\{.*\}/) { print; added=0; next }
        if ($0 ~ /\.dependencies = \.\{/)
        {
            if (!added)
            {
                print $0;
                print content;
                added=1;
            }
            else { print $0; }
            next;
        }
        print $0;
    }' ./build.zig.zon >temp.zon

	mv temp.zon ./build.zig.zon
	printf "${GREEN}Added dependency to build.zig.zon${RESET}\n"
}

main
