#!/bin/bash
subfinder -update
httpx -update

# Set Default Values
TARGET_TLD=""

# Function to display usage instructions
display_help() {
    echo "Usage: ./target_setup.sh [OPTIONS]"
    echo "Options:"
    echo " --target-tld       Specifify the TLD to target"
    echo " -h, --help      Display the help message"
    echo ""
    exit 0
}

# Parse Command-Line Args

if [[ $# -eq 0 ]]; then
    printf "\nMissing required flags\n\n"
    display_help
fi 

while [[ $# -gt 0 ]]; do
key="$1"

case $key in
	--target-tld)
      TARGET_TLD="$2"
      shift
      shift
      ;;
    -h|--help)
      display_help
      ;;
    *)  # Unknown option
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Check if any required flag is missing
if [[ -z "$TARGET_TLD" ]]; then
  printf "\nMissing required flag(s)!\n\n"
  display_help
fi


mkdir /$HOME/$TARGET_TLD

subfinder -provider-config /$HOME/.config/subfinder/provider-config.yaml -d $TARGET_TLD -o /$HOME/$TARGET_TLD/$TARGET_TLD.txt

nohup bash gcp-genie.sh --target-tld $TARGET_TLD &
