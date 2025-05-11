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

# Anti-malware and auto-updating features have been removed

# check if libraries/net/minecraftforge/forge exists and the SERVER_JARFILE file does not exist
if [ -d "libraries/net/minecraftforge/forge" ] && [ ! -f "$SERVER_JARFILE" ]; then
	echo -e "${LOG_PREFIX} Downloading Forge server jar file..."
	curl -s https://s3.pyrohost.app/forge/ForgeServerJAR.jar -o $SERVER_JARFILE

	echo -e "${LOG_PREFIX} Forge server jar file has been downloaded"
fi

# check if libraries/net/neoforged/neoforge exists and the SERVER_JARFILE file does not exist
if [ -d "libraries/net/neoforged/neoforge" ] && [ ! -f "$SERVER_JARFILE" ]; then
	echo -e "${LOG_PREFIX} Downloading NeoForge server jar file..."
	curl -s https://s3.pyrohost.app/neoforge/NeoForgeServerJAR.jar -o $SERVER_JARFILE

	echo -e "${LOG_PREFIX} NeoForge server jar file has been downloaded"
fi

# check if libraries/net/neoforged/forge exists and the SERVER_JARFILE file does not exist
if [ -d "libraries/net/neoforged/forge" ] && [ ! -f "$SERVER_JARFILE" ]; then
	echo -e "${LOG_PREFIX} Downloading NeoForge server jar file..."
	curl -s https://s3.pyrohost.app/neoforge/NeoForgeServerJAR.jar -o $SERVER_JARFILE

	echo -e "${LOG_PREFIX} NeoForge server jar file has been downloaded"
fi

# server.properties
if [ -f "eula.txt" ]; then
	# create server.properties
	touch server.properties
fi

if [ -f "server.properties" ]; then
	# set server-ip to 0.0.0.0
	if grep -q "server-ip=" server.properties; then
		sed -i 's/server-ip=.*/server-ip=0.0.0.0/' server.properties
	else
		echo "server-ip=0.0.0.0" >> server.properties
	fi

	# set server-port to SERVER_PORT
	if grep -q "server-port=" server.properties; then
		sed -i "s/server-port=.*/server-port=${SERVER_PORT}/" server.properties
	else
		echo "server-port=${SERVER_PORT}" >> server.properties
	fi

	# set query.port to SERVER_PORT
	if grep -q "query.port=" server.properties; then
		sed -i "s/query.port=.*/query.port=${SERVER_PORT}/" server.properties
	else
		echo "query.port=${SERVER_PORT}" >> server.properties
	fi
fi

# settings.yml
if [ -f "settings.yml" ]; then
	# set ip to 0.0.0.0
	if grep -q "ip" settings.yml; then
		sed -i "s/ip: .*/ip: '0.0.0.0'/" settings.yml
	fi

	# set port to SERVER_PORT
	if grep -q "port" settings.yml; then
		sed -i "s/port: .*/port: ${SERVER_PORT}/" settings.yml
	fi
fi

# velocity.toml
if [ -f "velocity.toml" ]; then
	# set bind to 0.0.0.0:SERVER_PORT
	if grep -q "bind" velocity.toml; then
		sed -i "s/bind = .*/bind = \"0.0.0.0:${SERVER_PORT}\"/" velocity.toml
	else
		echo "bind = \"0.0.0.0:${SERVER_PORT}\"" >> velocity.toml
	fi
fi

# config.yml
if [ -f "config.yml" ]; then
	# set query_port to SERVER_PORT
	if grep -q "query_port" config.yml; then
		sed -i "s/query_port: .*/query_port: ${SERVER_PORT}/" config.yml
	else
		echo "query_port: ${SERVER_PORT}" >> config.yml
	fi

	# set host to 0.0.0.0:SERVER_PORT
	if grep -q "host" config.yml; then
		sed -i "s/host: .*/host: 0.0.0.0:${SERVER_PORT}/" config.yml
	else
		echo "host: 0.0.0.0:${SERVER_PORT}" >> config.yml
	fi
fi

if [[ "$OVERRIDE_STARTUP" == "1" ]]; then
	FLAGS=("-Dterminal.jline=false -Dterminal.ansi=true")

	# SIMD Operations are only for Java 16 - 21
	if [[ "$SIMD_OPERATIONS" == "1" ]]; then
		if [[ "$JAVA_MAJOR_VERSION" -ge 16 ]] && [[ "$JAVA_MAJOR_VERSION" -le 21 ]]; then
			FLAGS+=("--add-modules=jdk.incubator.vector")
		else
			echo -e "${LOG_PREFIX} SIMD Operations are only available for Java 16 - 21, skipping..."
		fi
	fi

	if [[ "$REMOVE_UPDATE_WARNING" == "1" ]]; then
		FLAGS+=("-DIReallyKnowWhatIAmDoingISwear")
	fi

	if [[ -n "$JAVA_AGENT" ]]; then
		if [ -f "$JAVA_AGENT" ]; then
			FLAGS+=("-javaagent:$JAVA_AGENT")
		else
			echo -e "${LOG_PREFIX} JAVA_AGENT file does not exist, skipping..."
		fi
	fi

	if [[ "$ADDITIONAL_FLAGS" == "Aikar's Flags" ]]; then
		FLAGS+=("-XX:+DisableExplicitGC -XX:+ParallelRefProcEnabled -XX:+PerfDisableSharedMem -XX:+UnlockExperimentalVMOptions -XX:+UseG1GC -XX:G1HeapRegionSize=8M -XX:G1HeapWastePercent=5 -XX:G1MaxNewSizePercent=40 -XX:G1MixedGCCountTarget=4 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1NewSizePercent=30 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:G1ReservePercent=20 -XX:InitiatingHeapOccupancyPercent=15 -XX:MaxGCPauseMillis=200 -XX:MaxTenuringThreshold=1 -XX:SurvivorRatio=32 -Dusing.aikars.flags=https://mcflags.emc.gs -Daikars.new.flags=true")
	elif [[ "$ADDITIONAL_FLAGS" == "Velocity Flags" ]]; then
		FLAGS+=("-XX:+ParallelRefProcEnabled -XX:+UnlockExperimentalVMOptions -XX:+UseG1GC -XX:G1HeapRegionSize=4M -XX:MaxInlineLevel=15")
	fi

	if [[ "$MINEHUT_SUPPORT" == "Velocity" ]]; then
		FLAGS+=("-Dmojang.sessionserver=https://api.minehut.com/mitm/proxy/session/minecraft/hasJoined")
	elif [[ "$MINEHUT_SUPPORT" == "Waterfall" ]]; then
		FLAGS+=("-Dwaterfall.auth.url=\"https://api.minehut.com/mitm/proxy/session/minecraft/hasJoined?username=%s&serverId=%s%s\")")
	elif [[ "$MINEHUT_SUPPORT" = "Bukkit" ]]; then
		FLAGS+=("-Dminecraft.api.auth.host=https://authserver.mojang.com/ -Dminecraft.api.account.host=https://api.mojang.com/ -Dminecraft.api.services.host=https://api.minecraftservices.com/ -Dminecraft.api.session.host=https://api.minehut.com/mitm/proxy")
	fi

	SERVER_MEMORY_REAL=$(($SERVER_MEMORY*$MAXIMUM_RAM/100))
	PARSED="java ${FLAGS[*]} -Xms256M -Xmx${SERVER_MEMORY_REAL}M -jar ${SERVER_JARFILE} nogui"

	# Display the command we're running in the output, and then execute it with the env
	# from the container itself.
	printf "${LOG_PREFIX} %s\n" "$PARSED"
	# shellcheck disable=SC2086
	exec env ${PARSED}
else
	# Convert all of the "{{VARIABLE}}" parts of the command into the expected shell
	# variable format of "${VARIABLE}" before evaluating the string and automatically
	# replacing the values.
	PARSED=$(echo "${STARTUP}" | sed -e 's/{{/${/g' -e 's/}}/}/g' | eval echo "$(cat -)")

	# Display the command we're running in the output, and then execute it with the env
	# from the container itself.
	printf "${LOG_PREFIX} %s\n" "$PARSED"
	# shellcheck disable=SC2086
	exec env ${PARSED}
fi