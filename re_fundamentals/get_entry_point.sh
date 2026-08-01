#!/bin/bash

# Check if file argument is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <ELF file>"
    exit 1
fi

file_name="$1"

# Check if file exists
if [ ! -f "$file_name" ]; then
    echo "Error: File '$file_name' does not exist."
    exit 1
fi

# Check if file is an ELF file
if ! file "$file_name" | grep -q "ELF"; then
    echo "Error: '$file_name' is not a valid ELF file."
    exit 1
fi

# Extract ELF header information
magic_number=$(readelf -h "$file_name" | grep "Magic:" | awk '{for(i=2; i<=NF; i++) printf "%s ", $i; print ""}' | sed 's/ $//')
class=$(readelf -h "$file_name" | grep "Class:" | awk '{print $2, $3}' | sed 's/ $//')
byte_order=$(readelf -h "$file_name" | grep "Data:" | awk '{print $4, $5}')
entry_point_address=$(readelf -h "$file_name" | grep "Entry point address:" | awk '{print $4}')

# Source the messages.sh script (ensure it's in the same directory)
source ./messages.sh

display_elf_header_info
