#!/bin/bash

# Script to restart OS
# perform restart right after processing Epoch to minimize missed attestations
# jq package is required

if [[ -f "common-rpl.sh" ]]; then source common-rpl.sh; elif [[ -f "../Common/common-rpl.sh" ]]; then source ../Common/common-rpl.sh; elif [[ -f "../common-rpl.sh" ]]; then source ../common-rpl.sh; else echo "Failed to load common-rpl.sh"; return 0; fi
if [[ -f "common-rpl-maintenance.sh" ]]; then source common-rpl-maintenance.sh; elif [[ -f "../Common/common-rpl-maintenance.sh" ]]; then source ../Common/common-rpl-maintenance.sh; elif [[ -f "../common-rpl-maintenance.sh" ]]; then source ../common-rpl-maintenance.sh; else echo "Failed to load common-rpl-maintenance.sh"; return 0; fi

#Define the string value
_waitForNextEpoch=true
defaults=true

# handle command line options
if [[ $1 == "-n" || $1 == "--no_wait" ||
    $2 == "-n" || $2 == "--no_wait" ||
    $3 == "-n" || $3 == "--no_wait" ||
    $4 == "-n" || $4 == "--no_wait" ]]; then
    echo "Do no wait for next epoch"
    _waitForNextEpoch=false
fi
if [[ $1 == "-p" || $1 == "--prompt" || 
    $2 == "-p" || $2 == "--prompt" || 
    $3 == "-p" || $3 == "--prompt" || 
    $4 == "-p" || $4 == "--prompt" ]]; then
    echo "Prompt for values and options"
    defaults=false
fi
if [[ $1 == "-v" || $1 == "--verbose" ||
    $2 == "-v" || $2 == "--verbose" ||
    $3 == "-v" || $3 == "--verbose" ||
    $4 == "-v" || $4 == "--verbose" ]]; then
    echo "Verbose on"
    verbose=true
fi
if [[ $1 == "-h" || $1 == "--help" || 
    $2 == "-h" || $2 == "--help" || 
    $3 == "-h" || $3 == "--help" || 
    $4 == "-h" || $4 == "--help" ]]; then
    cat << EOF
Usage: restart-os [OPTIONS]...
Restart the Operating System after optionally waiting for the next Epoch to minimize missed attestations.

    Option                     Meaning
    -h|--help                  Displays this help and exit
    -n|--no_wait               Do not wait for next Epoch before interrupting node and potentially missing attestations
    -p|--prompt                Prompt for each option instead of using defaults
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
        _waitForNextEpoch=false
    fi
fi

# use sudo command to prompt for password if necessary so we don't prompt after waiting for epoch
sudo ls >/dev/null

#wait for next epoch?
if [[ $_waitForNextEpoch == true ]]; then
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
echo '...sleep 90 seconds to allow for reboot'
sleep 90 # need this to allow the reboot command to complete.
