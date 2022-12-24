#!/bin/bash

if [[ -f "common-rpl.sh" ]]; then source common-rpl.sh; else source ../Common/common-rpl.sh; fi

#Define the string value
RSYNC_DETAIL_LOG_FILE=$HOME/rp-install-rsync-details.log
RSYNC_WIP_FILE=$HOME/rp-install-rsync-wip.log

# TODO: fix shellcheck warning 2217
echo wc -l <"$RSYNC_WIP_FILE"
while read -r line; do
    # reading each line
    line=$(basename -- "$line")
    sed -i "/$line/d" "$RSYNC_WIP_FILE"
done < "$RSYNC_DETAIL_LOG_FILE"

echo wc -l <"$RSYNC_WIP_FILE"
