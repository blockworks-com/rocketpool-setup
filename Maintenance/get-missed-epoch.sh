#!/bin/bash
# shellcheck disable=SC1090

# Notes: 'last' includes when the server was rebooted
#        'sudo cat /var/log/auth.log' shows who logged on and what commands they ran
#        sed '/Accepted google_authenticator for rpuser1234/,/session closed for user rpuser1234/ !d' <<< $(sed '/May  8 /,/May  9/ !d' <<< $(sudo cat /var/log/auth.log)) will show activity for date and user

if [[ -f "common-rpl.sh" ]]; then source common-rpl.sh; else source ../Common/common-rpl.sh; fi
if [[ -f "common-rpl-maintenance.sh" ]]; then source common-rpl-maintenance.sh; else source ../Common/common-rpl-maintenance.sh; fi

# TODO: remove comma from values passed

#Define the string value
missedLogDir="./missed-epoch"
linesPerEpoch=71
bufferLines=500

missedEpoch=
missedSlot=
_waitForNextEpoch=true

if [[ $1 == "-n" || $1 == "--no_wait" || 
    $2 == "-n" || $2 == "--no_wait" || 
    $3 == "-n" || $3 == "--no_wait" || 
    $4 == "-n" || $4 == "--no_wait" || 
    $5 == "-n" || $5 == "--no_wait" || 
    $6 == "-n" || $6 == "--no_wait" ]]; then
    echo "Do no wait for next epoch"
    _waitForNextEpoch=false
fi
if [[ $1 == "-e" || $1 == "--epoch" ||
    $2 == "-e" || $2 == "--epoch" || 
    $3 == "-e" || $3 == "--epoch" || 
    $4 == "-e" || $4 == "--epoch" ]]; then
    if [[ $1 == "-s" || $1 == "--slot" ]]; then
        missedEpoch=${2//[,]/}
    elif [[ $2 == "-s" || $2 == "--slot" ]]; then
        missedEpoch=${3//[,]/}
    elif [[ $3 == "-s" || $2 == "--slot" ]]; then
        missedEpoch=${4//[,]/}
    elif [[ $4 == "-s" || $2 == "--slot" ]]; then
        missedEpoch=${5//[,]/}
    fi
    echo 'Missed Epoch: '$missedEpoch
fi
if [[ $1 == "-s" || $1 == "--slot" ||
    $2 == "-s" || $2 == "--slot" || 
    $3 == "-s" || $3 == "--slot" || 
    $4 == "-s" || $4 == "--slot" ]]; then
    if [[ $1 == "-s" || $1 == "--slot" ]]; then
        missedSlot=${2//[,]/}
    elif [[ $2 == "-s" || $1 == "--slot" ]]; then
        missedSlot=${3//[,]/}
    elif [[ $3 == "-s" || $1 == "--slot" ]]; then
        missedSlot=${4//[,]/}
    elif [[ $4 == "-s" || $1 == "--slot" ]]; then
        missedSlot=${5//[,]/}
    fi
    echo 'Missed Slot: '$missedSlot
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
Usage: get-missed-epoch [OPTIONS]...
Parses the log and saves the section for the missed epoch to missed-<123>.log for further analysis.

    Option                     Meaning
    -e|--epoch                 Epoch that was missed
    -h|--help                  Displays this help and exit
    -n|--no_wait               Do not wait for next Epoch before interrupting node and potentially missing attestations
    -s|--slot                  Slot that was missed
    -v|--verbose               Displays verbose output
EOF
    return
fi

getEpochForSlot() {
    # $1 is missedSlot
    debug_enter_function
    local __missedSlot=$1
    local __result=
    local __domain=
    __domain=$(getDomain)

    if [[ $__missedSlot -lt 1 ]]; then
        echo 'ERROR: invalid missedSlot passed.'
        return
    fi

    urlSlot="https://${__domain}beaconcha.in/api/v1/block/$__missedSlot"
    # echo $urlAttestations
    __result=$(curl -X 'GET' "$urlSlot" -H 'accept: application/json' -s | jq --raw-output '.data'.epoch)
    if [[ $__result -lt 1 ]]; then
        # echo "ERROR: could not determine missed Epoch from Slot. EXIT"
        return
    fi

    echo "$__result"
    debug_leave_function
}

#####################################################################################################################
# Main
#####################################################################################################################
Initialize

missedLogDir
# was a missed slot passed
if [[ $missedSlot ]]; then
    # use missed slot to find the missed epoch
    missedEpoch=$(getEpochForSlot "$missedSlot")
    echo "Missed Slot: $missedSlot was Epoch: $missedEpoch"
fi

# Prompt for answers
if [[ $missedEpoch && $missedEpoch -gt 0 ]]; then
    echo "Missed Epoch: $missedEpoch"
else
    answer=
    echo ""
    echo "Enter Missed Epoch?"
    read -r answer
    missedEpoch=${answer//[,]/}
fi

currentEpoch=$(getLastEpoch)
if [[ $currentEpoch && $missedEpoch -gt 0 ]]; then
    echo "Current Epoch: $currentEpoch"
else
    echo "Current Epoch: $currentEpoch"
    answer=
    echo ""
    echo "Enter Current Epoch?"
    read -r answer
    currentEpoch=${answer//[,]/}
fi

if [[ -f "$missedEpoch.log" ]]; then
    rm "$missedEpoch.log"
fi

if [[ -f "missed-$missedEpoch.log" ]]; then
    rm "missed-$missedEpoch.log"
fi

TMP_SCRIPT_FILE="./$missedEpoch.sh"
if [[ ! -f "missed-$missedEpoch.log" ]]; then
    lines=$(((( currentEpoch - missedEpoch) * 71) + bufferLines ))
    #echo $lines

    echo "sed '/ep och=$((missedEpoch - 1))/,/epoch=$((missedEpoch + 1))/ !d' $missedEpoch.log > missed-$missedEpoch.log" > "$TMP_SCRIPT_FILE"
    echo "rm $missedEpoch.log" >> "$TMP_SCRIPT_FILE"
    echo "rm $missedEpoch.sh" >> "$TMP_SCRIPT_FILE"

    echo "Wait $((( lines / 100000) + 3)) seconds and hit Ctrl-Z to continue."
    rpl service logs eth2 --tail $lines > "$missedEpoch.log"
    echo "Done capturing raw log."

    echo ''
    # jobs | grep "$missedEpoch.log"
    jobId=$(jobs | grep "$missedEpoch.log" | awk '{print $1}' | awk -F'[^0-9]*' '$0=$2')
    # echo 'Job to kill is '$jobId
    echo ""
    read -r -p "Enter Job to Kill: " -e -i "$jobId" jobId
    reNumber='^[0-9]+$'
    if ! [[ $jobId =~ $reNumber ]] ; then
        echo "ERROR: Job Id must be a number" >&2; 
        return 1
    fi
    if [[ $jobId -gt 0 ]]; then
        kill "%$jobId"
    fi

    echo "Use sed to filter raw log using sh."
#    sed '/epoch=$(($missedEpoch))/,/epoch=$(($missedEpoch + 1))/ !d' $missedEpoch.log > missed-$missedEpoch.log
#    rm $missedEpoch.log
#    rm $TMP_SCRIPT_FILE
    . ./"$TMP_SCRIPT_FILE"

    # add uptime to top of log as a reference - since top of file, these are in reverse order
    echo "" | cat - "missed-$missedEpoch.log" > temp && mv temp "missed-$missedEpoch.log"
    "$(who -b)" | cat - "missed-$missedEpoch.log" > temp && mv temp "missed-$missedEpoch.log"
    "$(uptime -p)" | cat - "missed-$missedEpoch.log" > temp && mv temp "missed-$missedEpoch.log"
    echo "Remember uptime is in local timezone and RocketPool logs are GMT" | cat - "missed-$missedEpoch.log" > temp && mv temp "missed-$missedEpoch.log"

    # check if there was a OS reboot
    # osRebooted=$(cat "missed-$missedEpoch.log" | grep -c 'shutting down')
    osRebooted=$(grep -c "shutting down" "missed-$missedEpoch.log")
    if [[ $osRebooted -gt 0 ]]; then
        echo 'OS rebooted. Press return to continue to view log.'
        read -r
    fi
else
    echo "Raw log file already exists."
    echo "Use sed to filter raw log using sh."
    . "$TMP_SCRIPT_FILE"
fi

# copy to missed epoch folder
if [[ -n $missedLogDir ]]; then
    if [ ! -d "$missedLogDir" ]; then
        mkdir -p "$missedLogDir";
    fi

    mv "missed-$missedEpoch.log" "$missedLogDir"
    cd "$missedLogDir"
    echo "view log in editor"
    nano "$missedLogDir/missed-$missedEpoch.log"
    cd ".."
else
    echo "view log in editor"
    nano "./missed-$missedEpoch.log
fi

echo 'listing Jobs one more time to make sure there are none hanging out there: '
jobs
#. $TMP_SCRIPT_FILE

Cleanup