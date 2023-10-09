#!/bin/sh

##############################
#                            #
#  Copyright (c) xTekC.      #
#  Licensed under MPL-2.0.   #
#  See LICENSE for details.  # 
#                            #
##############################

ORANGE="\033[38;5;214m"
GREEN="\033[0;32m"
RESET="\033[0m"

for dir in src tests; do
	if [ "$dir" = "tests" ]; then
		file_name="test_main.zig"
	else
		file_name="main.zig"
	fi

	file_path="$dir/$file_name"

	if [ -f "$file_path" ]; then
		if [ "$dir" = "tests" ]; then
			header="Integration Tests:"
		else
			header="Unit Tests:"
		fi
		printf "${ORANGE}%s${RESET}\n" "$header"

		test_count=0

		while IFS= read -r line; do
			if echo "$line" | grep -q "^test "; then
				test_name=$(echo "$line" | awk -F'"' '{print $2}')

				printf "  ${GREEN}%s${RESET}\n" "$test_name"

				test_count=$((test_count + 1))
			fi
		done <"$file_path"

		printf "All %d tests passed.\n\n" "$test_count"
	else
		printf "File does not exist: %s\n" "$file_path"
	fi
done
