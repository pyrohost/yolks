#!/bin/bash

# Default the TZ environment variable to UTC.
TZ=${TZ:-UTC}
export TZ

# Set environment variable that holds the Internal Docker IP
INTERNAL_IP=$(ip route get 1 | awk '{print $(NF-2);exit}')
export INTERNAL_IP

# check if LOG_PREFIX is set
if [ -z "$LOG_PREFIX" ]; then
	LOG_PREFIX="\033[1m\033[33mcontainer@pterodactyl~\033[0m"
fi

# Switch to the container's working directory
cd /home/container || exit 1

# Print Java version
printf "${LOG_PREFIX} java -version\n"
java -version

JAVA_MAJOR_VERSION=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}' | awk -F '.' '{print $1}')

if [[ "$OVERRIDE_STARTUP" == "1" ]]; then
	FLAGS=("-Dterminal.jline=false" "-Dterminal.ansi=true")

	# SIMD Operations (Java 16–21)
	if [[ "$SIMD_OPERATIONS" == "1" ]]; then
		if [[ "$JAVA_MAJOR_VERSION" -ge 16 && "$JAVA_MAJOR_VERSION" -le 21 ]]; then
			FLAGS+=("--add-modules=jdk.incubator.vector")
		else
			echo -e "${LOG_PREFIX} SIMD Operations require Java 16–21, skipping..."
		fi
	fi

	# Java agent support, if provided
	if [[ -n "$JAVA_AGENT" ]]; then
		if [ -f "$JAVA_AGENT" ]; then
			FLAGS+=("-javaagent:$JAVA_AGENT")
		else
			echo -e "${LOG_PREFIX} JAVA_AGENT file not found, skipping..."
		fi
	fi

	# Calculate heap size
	SERVER_MEMORY_REAL=$(( SERVER_MEMORY * MAXIMUM_RAM / 100 ))

	# Build and run the command
	PARSED="java ${FLAGS[*]} -Xms256M -Xmx${SERVER_MEMORY_REAL}M -jar ${SERVER_JARFILE}"
	printf "${LOG_PREFIX} %s\n" "$PARSED"
	# shellcheck disable=SC2086
	exec env ${PARSED}
else
	# Expand {{VARS}} in STARTUP and run
	PARSED=$(echo "${STARTUP}" | sed -e 's/{{/${/g' -e 's/}}/}/g' | eval echo "$(cat -)")
	printf "${LOG_PREFIX} %s\n" "$PARSED"
	# shellcheck disable=SC2086
	exec env ${PARSED}
fi
