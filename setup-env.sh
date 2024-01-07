#!/bin/bash

# Clone the GitHub repository
git clone https://github.com/sincemilkyway/pixelstreaming-utils.git

# Change directory
cd pixelstreaming-utils

# Install Python (latest version compatible with 3.10)
sudo apt update
sudo apt install -y software-properties-common
sudo add-apt-repository -y ppa:deadsnakes/ppa
sudo apt update
sudo apt install -y python3.10 python3.10-venv

# Install pip for Python 3.10
sudo apt install -y python3.10-distutils
curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
python3.10 get-pip.py

# Install requirements
python3.10 -m pip install -r requirements.txt

# Fetch the public IP address of the instance
current_public_ip=$(curl http://checkip.amazonaws.com)

# Run the create-record.py script and capture the new URL
new_url=$(python3.10 create-record.py $current_public_ip)

# Replace the setup.sh file
sudo cp setup.sh /home/ubuntu/Linux/PC_Build_Export/Samples/PixelStreaming/WebServers/SignallingWebServer/platform_scripts/bash/setup.sh

# Create the directory for the JSON file if it doesn't exist
mkdir -p /home/ubuntu/setup-variables

# Write the new IP and URL to a JSON file in the specified directory
echo "{\"new_ip\": \"$current_public_ip\", \"new_url\": \"$new_url\"}" > /home/ubuntu/setup-variables/const.json
