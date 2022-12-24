#!/bin/bash

# Script to restart OS
# perform restart right after processing Epoch to minimize missed attestations
# jq package is required

if [[ -f "common-rpl.sh" ]]; then source common-rpl.sh; else source ../Common/common-rpl.sh; fi
if [[ -f "common-rpl-maintenance.sh" ]]; then source common-rpl-maintenance.sh; else source ../Common/common-rpl-maintenance.sh; fi

#Define the string value

# handle command line options
if [[ $1 == "-n" || $1 == "--no_wait" ||
    $2 == "-n" || $2 == "--no_wait" ||
    $3 == "-n" || $3 == "--no_wait" ]]; then
    echo "Do no wait for next epoch"
    waitForNextEpoch=false
fi
if [[ $1 == "-v" || $1 == "--verbose" ||
    $2 == "-v" || $2 == "--verbose" ||
    $3 == "-v" || $3 == "--verbose" ]]; then
    echo "Verbose on"
    verbose=true
fi
if [[ $1 == "-h" || $1 == "--help" || 
    $2 == "-h" || $2 == "--help" || 
    $3 == "-h" || $3 == "--help" ]]; then
    cat << EOF
Usage:
    -h|--help                  Displays this help
    -n|--no_wait               Do not wait for next Epoch before interrupting node and potentially missing attestations
    -v|--verbose               Displays verbose output
EOF
    return
fi

#####################################################################################################################
# Main
#####################################################################################################################
Initialize

# Prompt for answers
#ask if we should wait for next epoch
if [[ $defaults == false ]]; then
    answer=
    echo ''
    echo 'Wait for next epoch [y/n]?'
    read -r answer
    if [[ ${answer,,} == 'y' ]]; then
        waitForNextEpoch=false
    fi
fi

# use sudo command to prompt for password if necessary so we don't prompt after waiting for epoch
sudo ls >/dev/null

#wait for next epoch?
if [[ $waitForNextEpoch == true ]]; then
    if [[ $verbose == true ]]; then
        echo 'Check timing to minimize missing Attestations and run sudo reboot'
    fi
    # Wait for next epoch before proceeding
    waitForNextEpoch
fi

if [[ $verbose == true ]]; then
    echo 'Now run sudo reboot'
fi
sudo reboot
Cleanup
sleep 90 # need this to allow the reboot command to complete.
