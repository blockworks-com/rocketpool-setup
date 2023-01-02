#!/bin/bash

if [[ -f "common-rpl.sh" ]]; then source common-rpl.sh; else source ../Common/common-rpl.sh; fi

#Define the string value
RSYNC_DETAIL_LOG_FILE=$HOME/rp-install-rsync-details.log
RSYNC_WIP_FILE=$HOME/rp-install-rsync-wip.log

# handle command line options
if [[ $1 == "-v" || $1 == "--verbose" ||
    $2 == "-v" || $2 == "--verbose" ]]; then
    echo "verbose on"
    verbose=true
fi
if [[ $1 == "-h" || $1 == "--help" || 
    $2 == "-h" || $2 == "--help" ]]; then
    cat << EOF
Usage: rsync-progress [OPTIONS]...
Show the rsync progress.

    Option                     Meaning
    -h|--help                  Displays this help and exit
    -v|--verbose               Displays verbose output
EOF
    return
fi

# TODO: fix shellcheck warning 2217
echo wc -l <"$RSYNC_WIP_FILE"
while read -r line; do
    # reading each line
    line=$(basename -- "$line")
    sed -i "/$line/d" "$RSYNC_WIP_FILE"
done < "$RSYNC_DETAIL_LOG_FILE"

echo wc -l <"$RSYNC_WIP_FILE"
