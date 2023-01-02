#!/bin/bash

# DR recovery script

#echo $(date)': rocketpool node sync'

if [[ -f "common-rpl.sh" ]]; then source common-rpl.sh; else source ../Common/common-rpl.sh; fi

#Define the string value
WAIT_MAX_RETRIES=6
WAIT_SECONDS=600
verbose=false

# handle command line options
if [[ $1 == "-v" || $1 == "--verbose" ||
    $2 == "-v" || $2 == "--verbose" ]]; then
    echo "verbose on"
    verbose=true
fi
if [[ $1 == "-h" || $1 == "--help" || 
    $2 == "-h" || $2 == "--help" ]]; then
    cat << EOF
Usage:
    -h|--help                  Displays this help and exit
    -v|--verbose               Displays verbose output
EOF
    return
fi

recoverEth1() {
    # rsync -z $HOME/backup rpuser1234@1.1.1.1:$HOME/backup/
    # tar -xvf backup.tar -C $HOME/backup
    rocketpool service import-eth1-data "$HOME/backup"
}

getCurrentPoint() {
    currentProgress=$(rocketpool node sync | grep 'Your primary consensus client')
    if  [[ $(echo "$currentProgress" | grep 'Your primary consensus client') == *'fully synced'* ]] ;
    then
        currentProgress=100
    else
        currentProgress=$(echo "$currentProgress" | grep 'Your primary consensus client' | awk -F'(' '{print $2}' | awk -F'%)' '{print $1}')
    fi

    if [[ $verbose == true ]]; then
        echo "currentProgress: $currentProgress"
    fi
}

recoverWallet() {
    # $HOME/.rocketpool/data/wallet
    rocketpool wallet recover

    answer=
    echo 'Was the wallet recovery successful (y/n)?'
    read -r answer
    if [[ $answer == 'y' ]]; then
        docker restart rocketpool_validator
        echo ''
        echo 'Confirm node is now attesting. Done.'
    else
        echo 'AFTER you resolve the issues, run: docker restart rocketpool_validator'
    fi
}

#####################################################################################################################
# Main
#####################################################################################################################
Initialize

i=0
while [[ $i -lt $WAIT_MAX_RETRIES ]];
do
    (( i++ ))
    getCurrentPoint
    if [[ $currentProgress == *'100'* ]]; then
        echo 'Syncing is complete'
        break
    else
        echo -ne "Progress: $currentProgress; check every $WAIT_SECONDS seconds ($i of $WAIT_MAX_RETRIES)"\\r
        sleep $WAIT_SECONDS
    fi
done

if [[ $currentProgress == *'100'* ]]; then
    echo ''
    recoverWallet
fi

Cleanup