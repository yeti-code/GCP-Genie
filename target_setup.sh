#!/bin/bash
# Make sure required tools are up-to-date before runtime
~/go/bin/subfinder -update
~/go/bin/httpx -update

# Initialize Variables
TARGET_TLD=""
PROJECT=""
ZONE=""

DIR=$(pwd)

# Generic Error to stdout message
handle_exceptions() {
    echo "An error occurred while processing the options."
    exit 1
}

# Function to display usage instructions
display_help() {
    echo "Usage: $0 [-t <foo.com>] [-p <your-project-id>] [-z <us-south1-a>]" 1>&2
    exit 1
}

# Parse Command-Line Args
while getopts ":t:p:z:" opt; do
    case "${opt}" in
        t)
            TARGET_TLD=${OPTARG}
            ;;
        p)
            PROJECT=${OPTARG}
            ;;
        z)
            ZONE=${OPTARG}
            ;;
        *)
            handle_exceptions
            ;;
    esac
done

shift $((OPTIND-1))

# Check all flags are set
if [ -z "${TARGET_TLD}" ] || [ -z "${PROJECT}" ] || [ -z "${ZONE}" ]; then
    usage
fi

mkdir /"$DIR"/output
mkdir /"$DIR"/output/"$TARGET_TLD"

~/go/bin/subfinder -provider-config /"$HOME"/.config/subfinder/provider-config.yaml -d "$TARGET_TLD" -o /"$DIR"/output/"$TARGET_TLD"/"$TARGET_TLD".txt

nohup /bin/bash gcp-genie.sh &
