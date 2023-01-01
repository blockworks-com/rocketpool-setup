#!/bin/bash

# Script to update OS
# perform updates right after processing Epoch to minimize missed attestations

if [[ -f "common-rpl.sh" ]]; then source common-rpl.sh; else source ../Common/common-rpl.sh; fi
if [[ -f "common-rpl-maintenance.sh" ]]; then source common-rpl-maintenance.sh; else source ../Common/common-rpl-maintenance.sh; fi

#Define the string value

# handle command line options
if [[ $1 == "-n" || $1 == "--no_wait" ||
    $2 == "-n" || $2 == "--no_wait" ||
    $3 == "-n" || $3 == "--no_wait" ]]; then
    echo "Do no wait for next epoch"
    _waitForNextEpoch=false
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
# ask if we should wait for next epoch
if [[ $defaults == false ]]; then
    answer=
    echo ''
    echo 'Wait for next epoch [y/n]?'
    read -r answer
    if [[ ${answer,,} == 'y' ]]; then
        _waitForNextEpoch=false
    fi
fi

#ask if we should perform dist-upgrade
if [[ $defaults == false ]]; then
    answer=
    echo ''
    echo 'Also perform dist-upgrade [y/n]?'
    read -r answer
    if [[ ${answer,,} != 'y' ]]; then
        distUpgrade=false
    fi
fi

# use sudo command to prompt for password if necessary so we don't prompt after waiting for epoch
sudo ls >/dev/null

#no prompting during updates
# sudo DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" dist-upgrade

echo 'apt cli show warnings that can be ignored.'
#check if updates are available
if [[ $verbose == true ]]; then
    echo 'Check if there are updates available'
fi
updatesAvail=false
sudo apt update >/dev/null
listOfUpdates=$(sudo apt list --upgradable)
if [[ ${#listOfUpdates} -gt 10 ]]; then # TODO: Why this magic value of 10??
    updatesAvail=true
    if [[ $verbose == true ]]; then
        echo 'Updates available'
    fi
    
    if [[ $distUpgrade == true ]] ; then
        # if [[ $verbose == true ]]; then
            echo 'sudo apt dist-upgrade'
        # fi

        if [[ $_waitForNextEpoch == true ]]; then
            # Wait for next epoch before proceeding
            waitForNextEpoch
        fi
        log 'Start apt dist-upgrade.'
        sudo apt dist-upgrade -y >/dev/null
        # refresh what is available for updates after updating dist
        sudo apt update >/dev/null
        sudo apt list --upgradable >/dev/null
        log 'apt dist-upgrade finished'
    else
        if [[ $verbose == true ]]; then
            echo 'skipping dist-upgrade'
        fi
        log 'skipping dist-upgrade'
    fi
    
    # if [[ $verbose == true ]]; then
        echo 'sudo apt upgrade'
    # fi
    #wait for next epoch?
    if [[ $_waitForNextEpoch == true ]]; then
        # Wait for next epoch before proceeding
        waitForNextEpoch
    fi
    log 'Start apt upgrade.'
    sudo apt upgrade -y >/dev/null
    
    if [[ $verbose == true ]]; then
        echo 'sudo apt autoremove'
    fi
    sudo apt autoremove -y >/dev/null
    
    if [[ $verbose == true ]]; then
        echo 'sudo apt list --upgradable'
    fi
    sudo apt list --upgradable >/dev/null
    log 'apt upgrade finished.'
else
    if [[ $verbose == true ]]; then
        echo 'No updates available'
    fi
fi

if [[ $verbose == true ]]; then
    echo "Run apt update to refresh the dashboard"
fi
sudo apt update >/dev/null

#echo 'Is a reboot required?'
if [ -f /var/run/reboot-required ]; then
    if [[ $verbose == true ]]; then
        echo ''
        echo ''
        echo 'reboot required'
    fi
    log 'reboot required after OS updates.'
    if [[ $_waitForNextEpoch == true ]]; then
        echo 'Check timing to minimize missing Attestations and run sudo reboot'
        # Wait for next epoch before proceeding
        waitForNextEpoch
    fi
    echo 'Manually run sudo reboot'
    echo ''
    # sudo reboot
    # Cleanup
    # sleep 90 # need this to allow the reboot command to complete.
    return
else
    if [[ $verbose == true ]]; then
        echo 'Reboot NOT required'
    fi
fi

Cleanup