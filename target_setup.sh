#!/bin/bash
# Make sure required tools are up-to-date before runtime
~/go/bin/subfinder -update

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
    echo "Usage: $0 -t <foo.com> -p <your-project-id> [-z <fallback-zone>]" 1>&2
    echo "  -z is optional. The script auto-detects the GCP region from the candidate IP." 1>&2
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

# -t and -p are required; -z is optional (used as fallback if region auto-detection fails)
if [ -z "${TARGET_TLD}" ] || [ -z "${PROJECT}" ]; then
    display_help
fi

mkdir -p "$DIR/output"
mkdir -p "$DIR/output/$TARGET_TLD"

~/go/bin/subfinder -provider-config "$HOME/.config/subfinder/provider-config.yaml" -d "$TARGET_TLD" -o "$DIR/output/$TARGET_TLD/$TARGET_TLD.txt"

ZONE_ARG=""
[[ -n "$ZONE" ]] && ZONE_ARG="-z $ZONE"

nohup /bin/bash "$DIR/gcp-genie.sh" -t "$TARGET_TLD" -p "$PROJECT" $ZONE_ARG &
