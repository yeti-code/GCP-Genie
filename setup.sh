#!/bin/bash

# List of Golang tools to check and install
tools=(
    "github.com/projectdiscovery/subfinder/v2/cmd/subfinder"
    "github.com/projectdiscovery/httpx/cmd/httpx"
    "github.com/projectdiscovery/nuclei/v3/cmd/nuclei"
    "github.com/projectdiscovery/notify/cmd/notify"
    "github.com/tomnomnom/anew"
)

for tool in "${tools[@]}"; do
    # Extract the tool name from the path
    tool_name=$(basename "$tool")

    # Check if the tool is installed
    if ! command -v "$tool_name" &> /dev/null; then
        echo "$tool_name is not installed. Installing..."
        go install -v "$tool@latest"
    else
        echo "$tool_name is already installed."
    fi
done
