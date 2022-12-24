#!/bin/bash

if [[ -f "common-rpl.sh" ]]; then source common-rpl.sh; else source ../Common/common-rpl.sh; fi
if [[ -f "common-rpl-maintenance.sh" ]]; then source common-rpl-maintenance.sh; else source ../Common/common-rpl-maintenance.sh; fi

#Define the string value
prune='n'
disk='sda3'

# handle command line options
if [[ $1 == "-n" || $1 == "--no_wait" || 
    $2 == "-n" || $2 == "--no_wait" || 
    $3 == "-n" || $3 == "--no_wait" || 
    $4 == "-n" || $4 == "--no_wait" || 
    $5 == "-n" || $5 == "--no_wait" || 
    $6 == "-n" || $6 == "--no_wait" ]]; then
    echo "Do no wait for next epoch"
    waitForNextEpoch=false
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
Usage:
    -f|--force                 Force an upgrade to latest version even if the node is down
    -h|--help                  Displays this help
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

echo ''
echo "Running Monthly tasks: update OS, update RPL, prune GETH, ..."
echo ''

echo '*** Check disk space'
df -h

#ask if we should perform prune
answer=
echo ''
echo 'Perform prune-eth1 to free disk space (y/n)?'
read -r answer
if [[ $answer == 'y' ]]; then
  prune=$answer
fi

# set parameters for other scripts
param=""
if [[ $waitForNextEpoch == false ]]; then
  param="$param -n"
fi
if [[ $forceUpdate == true ]]; then
  param="$param -f"
fi
if [[ $verbose == true ]]; then
  param="$param -v"
fi

echo ''
echo '*** Call Update OS'
. ./update-os.sh "$param"

echo ''
echo '*** Call Update RPL'
. ./update-rpl.sh "$param"

if [[ $prune == 'y' ]]; then
  echo ''
  echo '*** Call Prune Geth'
  . ./prune-geth.sh "$param"
else
  echo 'not pruning'
fi

if [ -f /var/run/reboot-required ]; then
  echo '*** reboot required'
  echo 'Check timing to minimize missing Attestations and run sudo reboot'
else
  echo 'reboot NOT required'
fi

duration=$seconds
echo "$((duration / 60)) minutes and $((duration % 60)) seconds elapsed."

Cleanup