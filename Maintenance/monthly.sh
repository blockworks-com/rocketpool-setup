#!/bin/bash

if [[ -f "common-rpl.sh" ]]; then source common-rpl.sh; elif [[ -f "../Common/common-rpl.sh" ]]; then source ../Common/common-rpl.sh; elif [[ -f "../common-rpl.sh" ]]; then source ../common-rpl.sh; else echo "Failed to load common-rpl.sh"; return 0; fi
if [[ -f "common-rpl-maintenance.sh" ]]; then source common-rpl-maintenance.sh; elif [[ -f "../Common/common-rpl-maintenance.sh" ]]; then source ../Common/common-rpl-maintenance.sh; elif [[ -f "../common-rpl-maintenance.sh" ]]; then source ../common-rpl-maintenance.sh; else echo "Failed to load common-rpl-maintenance.sh"; return 0; fi

#Define the string value
prune='n'
disk='sda3'
PATH_CONSTRAINING_DISK_SPACE='/' # Depends on your device
_waitForNextEpoch=true
forceUpdate=false
defaults=true

# handle command line options
if [[ $1 == "-n" || $1 == "--no_wait" || 
    $2 == "-n" || $2 == "--no_wait" || 
    $3 == "-n" || $3 == "--no_wait" || 
    $4 == "-n" || $4 == "--no_wait" || 
    $5 == "-n" || $5 == "--no_wait" || 
    $6 == "-n" || $6 == "--no_wait" ]]; then
    echo "Do no wait for next epoch"
    _waitForNextEpoch=false
fi
if [[ $1 == "-f" || $1 == "--force" || 
    $2 == "-f" || $2 == "--force" || 
    $3 == "-f" || $3 == "--force" || 
    $4 == "-f" || $4 == "--force" || 
    $5 == "-f" || $5 == "--force" || 
    $6 == "-f" || $6 == "--force" ]]; then
    echo "Force an upgrade to latest version even if the node is down"
    forceUpdate=true
fi
if [[ $1 == "-p" || $1 == "--prompt" || 
    $2 == "-p" || $2 == "--prompt" || 
    $3 == "-p" || $3 == "--prompt" || 
    $4 == "-p" || $4 == "--prompt" || 
    $5 == "-p" || $5 == "--prompt" || 
    $6 == "-p" || $6 == "--prompt" ]]; then
    echo "Prompt for values and options"
    defaults=false
fi
if [[ $1 == "-v" || $1 == "--verbose" || 
    $2 == "-v" || $2 == "--verbose" || 
    $3 == "-v" || $3 == "--verbose" || 
    $4 == "-v" || $4 == "--verbose" || 
    $5 == "-v" || $5 == "--verbose" || 
    $6 == "-v" || $6 == "--verbose" ]]; then
    echo "Verbose on"
    verbose=true
fi
if [[ $1 == "-h" || $1 == "--help" || 
    $2 == "-h" || $2 == "--help" || 
    $3 == "-h" || $3 == "--help" || 
    $4 == "-h" || $4 == "--help" || 
    $5 == "-h" || $5 == "--help" || 
    $6 == "-h" || $6 == "--help" ]]; then
    cat << EOF
Usage: monthly [OPTIONS]...
Wrapper script for monthly maintenance work. Calls update-os.sh, update-rpl.sh, optionally restart-os.sh, and optionally prune-geth.sh.

    Option                     Meaning
    -f|--force                 Force an upgrade to latest version even if the node is down
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

seconds=0

echo 'Running Monthly tasks: update OS, update RPL, prune GETH, ...'
echo ''

# use sudo command to prompt for password if necessary so we don't prompt after waiting for epoch
sudo ls >/dev/null

#ask if we should perform prune
answer=
echo ''
echo 'Dive is' $(df -BG '/' | grep -Po "(\d+%)") 'full. Perform prune-eth1 to free disk space (y/n)?'
read -r answer
if [[ $answer == 'y' ]]; then
  prune=$answer
fi

# set parameters for other scripts
param=""
if [[ $forceUpdate == true ]]; then
  param="$param -f"
fi
if [[ $_waitForNextEpoch == false ]]; then
  param="$param -n"
fi
if [[ $defaults == false ]]; then
  param="$param -p"
fi
if [[ $verbose == true ]]; then
  param="$param -v"
fi

echo '**************'
echo '* Call Update OS'
echo '**************'
. ./update-os.sh "$param"

echo '*****************'
echo '* Call Update RPL'
echo '*****************'
. ./update-rpl.sh "$param"

if [[ $prune == 'y' ]]; then
  echo '*****************'
  echo '* Call Prune Geth'
  echo '*****************'
  . ./prune-geth.sh "$param"
else
  echo 'not pruning'
fi

if [ -f /var/run/reboot-required ]; then
  echo '*****************'
  echo '* reboot required'
  echo '*****************'
  . ./restart-os.sh "$param"
else
  echo 'reboot NOT required'
fi

duration=$seconds
echo "$((duration / 60)) minutes and $((duration % 60)) seconds elapsed."

Cleanup