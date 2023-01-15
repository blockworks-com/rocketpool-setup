#!/bin/bash

# tweaking the prune geth script shared on Discord. 

if [[ -f "common-rpl.sh" ]]; then source common-rpl.sh; elif [[ -f "../Common/common-rpl.sh" ]]; then source ../Common/common-rpl.sh; elif [[ -f "../common-rpl.sh" ]]; then source ../common-rpl.sh; else echo "Failed to load common-rpl.sh"; return 0; fi
if [[ -f "common-rpl-maintenance.sh" ]]; then source common-rpl-maintenance.sh; elif [[ -f "../Common/common-rpl-maintenance.sh" ]]; then source ../Common/common-rpl-maintenance.sh; elif [[ -f "../common-rpl-maintenance.sh" ]]; then source ../common-rpl-maintenance.sh; else echo "Failed to load common-rpl-maintenance.sh"; return 0; fi

#Define the string value
PATH_CONSTRAINING_DISK_SPACE='/' # Depends on your device
ETH1_CONTAINER='rocketpool_eth1' # See docker ps
GETH_VERSION=$( docker exec -i rocketpool_eth1 geth version | grep -Po "(?<=^Version: )[0-9\.]+" ) # See docker exec -i rocketpool_eth1 geth version
ETH1_DATA_VOLUME="rocketpool_eth1clientdata" # See docker volumes ls
ETH1_MOUNT_POINT="/ethclient"

# handle command line options
if [[ $1 == "-v" || $1 == "--verbose" ||
    $2 == "-v" || $2 == "--verbose" ]]; then
    echo "Verbose on"
    verbose=true
fi
if [[ $1 == "-h" || $1 == "--help" || 
    $2 == "-h" || $2 == "--help" ]]; then
    cat << EOF
Usage: prune-geth [OPTIONS]...
Check diskspace and then prune geth.

    Option                     Meaning
    -h|--help                  Displays this help and exit
    -v|--verbose               Displays verbose output
EOF
    return
fi

#####################################################################################################################
# Main
#####################################################################################################################
Initialize

###################
# Hardware constraints
###################
minimumDiskSpaceinGB=50
freeDiskSpaceInGB=$( df -BG $PATH_CONSTRAINING_DISK_SPACE | grep -Po "(\d+)(?=G \ *\s+\d+%)" )

###################
# Sanity checks
###################
echo "Path constraining disk space: $PATH_CONSTRAINING_DISK_SPACE"
echo "Is this correct? [y/n]"
read -r DISKPATHCORRECT

# Check if disk constraint is correct
if [ "$DISKPATHCORRECT" = "n" ]; then
    echo "You may change the disk path at the top of this script by editing PATH_CONSTRAINING_DISK_SPACE"
    log "Disk path is not correct so exit."
    return 0
else
    echo "✅ Disk location confirmed"
fi

# Check if volume exists
if docker volume ls | grep -q "$ETH1_DATA_VOLUME"; then
    echo "✅ Volume $ETH1_DATA_VOLUME exists"
else
    echo "🛑 Volume $ETH1_DATA_VOLUME does not exist"
    log "Volume $ETH1_DATA_VOLUME does not exist."
    return 1
fi

# Check for free disk space
if [ "$freeDiskSpaceInGB" -lt $minimumDiskSpaceinGB ]; then
    echo "🛑 Free disk space is $freeDiskSpaceInGB, which is under the minimum $minimumDiskSpaceinGB GB"
    log "Free disk space is $freeDiskSpaceInGB, which is under the minimum $minimumDiskSpaceinGB GB."
    return 1
else
    echo "✅ Free disk space is $freeDiskSpaceInGB GB"
    log "Free disk space is $freeDiskSpaceInGB GB"
fi

#####################
# Pruning actions
#####################

echo ''
preDiskspace=$( df -BG $PATH_CONSTRAINING_DISK_SPACE | grep -Po "(\d+)(?=G \ *\s+\d+%)" )
echo "diskspace before prune: $preDiskspace"
log "Diskspace before prune: $preDiskspace"

echo "Start rocketpool Geth pruning"
log "Start RocketPool Geth pruning."
rocketpool service prune-eth1

echo "Viewing log. When 'State pruning successful', hit Ctrl-Z to exit viewing the log or Ctrl-C to quit script."
echo "Prune stages: Iterating state snapshot, Pruning state data, and Compacting database"
rocketpool service logs eth1 | grep "Iterated snapshot\|Pruned state data\|Database compaction finished\|State pruning successful\|snapshot\|Prun\|Compact"
# now kill the log-viewer job so we can continue
#rocketpool service logs eth1 | grep "Iterated snapshot\|Pruned state data\|Database compaction finished\|State pruning successful"
jobId=$(jobs | grep 'rocketpool service logs eth1' | awk '{print $1}' | awk -F'[^0-9]*' '$0=$2')
# echo 'Job to kill is '$jobId
echo ''
read -r -p 'Enter Job to Kill: ' -e -i "$jobId" jobId
reNumber='^[0-9]+$'
if ! [[ $jobId =~ $reNumber ]] ; then
    echo "ERROR: Job Id must be a number" >&2; 
    return 1
fi
if [[ $jobId -gt 0 ]]; then
    kill "%$jobId"
fi

echo "Prune complete"
postDiskspace=$( df -BG $PATH_CONSTRAINING_DISK_SPACE | grep -Po "(\d+)(?=G \ *\s+\d+%)" )
echo "diskspace after prune: $postDiskspace"
log "Diskspace after prune: $postDiskspace"

# echo 'diskspace after prune'
# df -h | grep sda3

# echo "Stopping rocketpool ETH1 container"
# docker stop rocketpool_eth1

# echo "Starting GETH offline prune"
# docker run --rm \
#     -v $ETH1_DATA_VOLUME:$ETH1_MOUNT_POINT \
#     -ti ethereum/client-go:v$GETH_VERSION \
#     snapshot prune-state --datadir $ETH1_MOUNT_POINT/geth

# echo "Prune complete, restarting rocketpool ETH1 container"
# docker start rocketpool_eth1

Cleanup
