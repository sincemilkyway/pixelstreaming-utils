#!/bin/bash
# Copyright SEO CONTENT.AI V1, Inc. All Rights Reserved.
BASH_LOCATION=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

pushd "${BASH_LOCATION}" > /dev/null

source common_utils.sh

use_args $@
# Azure specific fix to allow installing NodeJS from NodeSource
if test -f "/etc/apt/sources.list.d/azure-cli.list"; then
	sudo touch /etc/apt/sources.list.d/nodesource.list
	sudo touch /usr/share/keyrings/nodesource.gpg
	sudo chmod 644 /etc/apt/sources.list.d/nodesource.list
	sudo chmod 644 /usr/share/keyrings/nodesource.gpg
	sudo chmod 644 /etc/apt/sources.list.d/azure-cli.list
fi

function check_version() { #current_version #min_version
	#check if same string
	if [ -z "$2" ] || [ "$1" = "$2" ]; then
		return 0
	fi

	local i current minimum

	IFS="." read -r -a current <<< $1
	IFS="." read -r -a minimum <<< $2

	# fill empty fields in current with zeros
	for ((i=${#current[@]}; i<${#minimum[@]}; i++))
	do
		current[i]=0
	done

	for ((i=0; i<${#current[@]}; i++))
	do
		if [[ -z ${minimum[i]} ]]; then
			# fill empty fields in minimum with zeros
			minimum[i]=0
	fi

		if ((10#${current[i]} > 10#${minimum[i]})); then
			return 1
	fi

		if ((10#${current[i]} < 10#${minimum[i]})); then
			return 2
	fi
	done

	# if got this far string is the same once we added missing 0
	return 0
}

function check_and_install() { #dep_name #get_version_string #version_min #install_command
	local is_installed=0

	log_msg "Checking for required $1 install"

	local current=$(echo $2 | sed -E 's/[^0-9.]//g')
	local minimum=$(echo $3 | sed -E 's/[^0-9.]//g')

	if [ $# -ne 4 ]; then
		log_msg "check_and_install expects 4 args (dep_name get_version_string version_min install_command) got $#"
		return -1
	fi

	if [ ! -z $current ]; then
		log_msg "Current version: $current checking >= $minimum"
		check_version "$current" "$minimum"
		if [ "$?" -lt 2 ]; then
			log_msg "$1 is installed."
			return 0
		else
			log_msg "Required install of $1 not found installing"
		fi
	fi

	if [ $is_installed -ne 1 ]; then
		echo "$1 installation not found installing..."

		start_process $4

		if [ $? -ge 1 ]; then
			echo "Installation of $1 failed try running `export VERBOSE=1` then run this script again for more details"
		fi
	fi
}
function setup_frontend() {
    # Navigate to root
    pushd ${BASH_LOCATION}/../../.. > /dev/null

    # Update Node to the latest version and install TypeScript
    npm install -g typescript
	if [ ! -f SignallingWebServer/Public/index.html ] || [ ! -z "$FORCE_BUILD" ] ; then
        echo "Building from test-sourav-build repository."
		# Clone the repository if it doesn't exist
		if [ ! -d "test-sourav-build" ]; then
			git clone https://github.com/uba2000/test-sourav-build.git
		fi

		# Read values from ~/values.json
		if [ ! -f ~/values.json ]; then
			echo "values.json not found."
			exit 1
		fi

		NEW_IP=$(jq -r '.new_ip' ~/values.json)
		NEW_URL=$(jq -r '.new_url' ~/values.json)

		# Ensure values are not empty
		if [ -z "$NEW_IP" ] || [ -z "$NEW_URL" ]; then
			echo "Missing values in ~/values.json"
			exit 1
		fi

		# File path for the constants file
		FILE_PATH="test-sourav-build/src/lib/utils/util-constants.ts"

		# Determine OS type for sed command compatibility
		case "$(uname)" in
			"Linux" ) SED_CMD="sed -i";;
			"Darwin" ) SED_CMD="sed -i ''";;
			* ) echo "Unsupported OS"; exit 1;;
		esac

		# Using sed to replace lines in the file
		$SED_CMD "s|export const PIXEL_STREAM_PUBLIC_IP = .*;|export const PIXEL_STREAM_PUBLIC_IP = \"ws://$NEW_IP:80\";|" "$FILE_PATH"
		$SED_CMD "s|export const CONSTANT_BASE_URL = .*;|export const CONSTANT_BASE_URL = \"$NEW_URL\";|" "$FILE_PATH"

		echo "Values have been updated in $FILE_PATH."

		# Build the project
		pushd test-sourav-build > /dev/null
		npm install
		npm run build
		popd

		# Clear the destination directory
		rm -rf ~/Linux/PC_Build_Export/Samples/PixelStreaming/WebServers/SignallingWebServer/Public/*

		# Copy new build to the destination
		cp -r test-sourav-build/dist/* ~/Linux/PC_Build_Export/Samples/PixelStreaming/WebServers/SignallingWebServer/Public/

		echo "Frontend build complete and files copied."
	else
        echo 'Skipping build. Index.html exists. Use "--build" to force rebuild.'
    fi

    popd > /dev/null # return to root
}

echo "Checking Pixel Streaming Server dependencies."

# navigate to SignallingWebServer root
pushd ${BASH_LOCATION}/../.. > /dev/null

node_version=""
if [[ -f "${BASH_LOCATION}/node/bin/node" ]]; then
	node_version=$("${BASH_LOCATION}/node/bin/node" --version)
fi
check_and_install "node" "$node_version" "v16.4.2" "curl https://nodejs.org/dist/v16.14.2/node-v16.14.2-linux-x64.tar.gz --output node.tar.xz
													&& tar -xf node.tar.xz
													&& rm node.tar.xz
													&& mv node-v*-linux-x64 \"${BASH_LOCATION}/node\""

PATH="${BASH_LOCATION}/node/bin:$PATH"
"${BASH_LOCATION}/node/lib/node_modules/npm/bin/npm-cli.js" install

popd > /dev/null # SignallingWebServer

# Trigger Frontend Build if needed or requested
# This has to be done after check_and_install "node"
setup_frontend

popd > /dev/null # BASH_SOURCE

#command #dep_name #get_version_string #version_min #install command
coturn_version=$(if command -v turnserver &> /dev/null; then echo 1; else echo 0; fi)
if [ $coturn_version -eq 0 ]; then
	if ! command -v apt-get &> /dev/null; then
		echo "Setup for the scripts is designed for use with distros that use the apt-get package manager" \
			 "if you are seeing this message you will have to update \"${BASH_LOCATION}/setup.sh\" with\n" \
			 "a package manger and the equivalent packages for your distribution. Please follow the\n" \
			 "instructions found at https://pkgs.org/search/?q=coturn to install Coturn for your specific distribution"
		exit 1
	else
		if [ `id -u` -eq 0 ]; then
			check_and_install "coturn" "$coturn_version" "1" "apt-get install -y coturn"
		else
			check_and_install "coturn" "$coturn_version" "1" "sudo apt-get install -y coturn"
		fi
	fi
fi
