#!/usr/bin/env bash

# Script to track sync progress

if [[ -f "common-rpl.sh" ]]; then source common-rpl.sh; else source ../Common/common-rpl.sh; fi

#Define the string value
WAIT_MAX_RETRIES=6
WAIT_SECONDS=600

# init variables

# handle command line options
if [[ $1 == "-v" || $1 == "--verbose" ||
    $2 == "-v" || $2 == "--verbose" ]]; then
    echo "verbose on"
    verbose=true
fi
if [[ $1 == "-h" || $1 == "--help" || 
    $2 == "-h" || $2 == "--help" ]]; then
    cat << EOF
Usage: sync-progress [OPTIONS]...
Show the sync progress.

    Option                     Meaning
    -h|--help                  Displays this help and exit
    -v|--verbose               Displays verbose output
EOF
    return
fi

getStartingPoint() {
    filename='./sync-progress.txt'
    if [[ -f $filename ]]; then
        readarray -t array < $filename
        startingDate=${array[0]}
        startingSeconds=${array[1]}
        startingProgress=${array[2]}
    else
        if [[ $verbose == true ]]; then
            echo "$filename does not exist"
        fi
        getCurrentPoint
        startingProgress=$currentProgress
        startingDate=$currentDate
        startingSeconds=$currentSeconds

        echo "$startingDate" > $filename
        echo "$startingSeconds" >> $filename
        echo "$startingProgress" >> $filename
    fi

    if [[ $verbose == true ]]; then
        echo "startingDate: $startingDate"
        echo "startingSeconds: $startingSeconds"
        echo "startingProgress: $startingProgress"
    fi
}


getCurrentPoint() {
    currentProgress=$(rocketpool node sync | grep 'Your consensus client')
    if  [[ $(echo "$currentProgress" | grep 'Your consensus client') == *'fully synced'* ]] ;
    then
        currentProgress=100
    else
        currentProgress=$(echo $currentProgress | grep 'Your consensus client' | awk -F'(' '{print $2}' | awk -F'%)' '{print $1}')
    fi

    currentDate=$(date)
    currentSeconds=$(date +%s)

    if [[ $verbose ]]; then
        echo "currentDate: $currentDate"
        echo "currentSeconds: $currentSeconds"
        echo "currentProgress: $currentProgress"
    fi

    if [[ $previousProgress == '' ]]; then
        previousProgress=$currentProgress
        previousDate=$currentDate
        previousSeconds=$currentSeconds
        if [[ $verbose ]]; then
            echo "previousDate: $previousDate"
            echo "previousSeconds: $previousSeconds"
            echo "previousProgress: $previousProgress"
        fi
    fi
}

calcProgress() {
    spanProgress=$(awk '{print $1-$2}' <<<"${currentProgress} ${startingProgress}")
    spanSeconds=$(awk '{print $1-$2}' <<<"${currentSeconds} ${startingSeconds}")

    secondsPer1Percent=$(awk '{print $1/$2*$3}' <<<"1 ${spanProgress} ${spanSeconds}")
    remainingProgress=$(awk '{print $1-$2}' <<<"100 ${currentProgress}")
    remainingSeconds=$(awk '{print $1*$2}' <<<"${remainingProgress} ${secondsPer1Percent}")
    estimatedCompletion=$(date --date "now + $remainingSeconds seconds")

    if [[ $verbose ]]; then
        #echo "spanDate: $spanDate"
        echo "spanSeconds: $spanSeconds"
        echo "spanProgress: $spanProgress"

        echo "It has taken $spanSeconds seconds to make $spanProgress progress."
        echo ""

        echo "secondsPer1Percent: $secondsPer1Percent"
        echo "remainingProgress: $remainingProgress"
        echo "remainingSeconds: $remainingSeconds"
        echo "Estimated Completion: $estimatedCompletion"
    fi

    spanPreviousProgress=$(awk '{print $1-$2}' <<<"${currentProgress} ${previousProgress}")
    spanPreviousSeconds=$(awk '{print $1-$2}' <<<"${currentSeconds} ${previousSeconds}")
    secondsPreviousPer1Percent=$(awk '{print $1/$2*$3}' <<<"1 ${spanPreviousProgress} ${spanPreviousSeconds}")
    remainingPreviousSeconds=$(awk '{print $1*$2}' <<<"${remainingProgress} ${secondsPreviousPer1Percent}")
    estimatedPreviousCompletion=$(date --date "now + $remainingPreviousSeconds seconds")
    if [[ $verbose ]]; then
        echo "... previous:"
        echo "spanProgress: $spanPreviousProgress"
        echo "spanSeconds: $spanPreviousSeconds"
        echo "per1percent: $secondsPreviousPer1Percent"
        echo "remainingSeconds: $remainingPreviousSeconds"
        echo "estimatedCommpletion: $estimatedPreviousCompletion"
        echo "Estimated Completion (Previous): $estimatedPreviousCompletion"
    fi
}

#####################################################################################################################
# Main
#####################################################################################################################
Initialize

getStartingPoint
if  [[ $startingProgress == *'100'* ]]; then
    echo 'Already synced so exit.'
    return
fi

i=0
while [[ $i -lt $WAIT_MAX_RETRIES ]];
do
    (( i++ ))
    getCurrentPoint
    if [[ $currentProgress == *'100'* ]]; then
        echo 'Syncing is complete'
        break
    else
        calcProgress
        echo -ne "Progress: $currentProgress; Estimated Completion: $estimatedCompletion; Estimated Completion (Previous): $estimatedPreviousCompletion; check every $WAIT_SECONDS seconds ($i of $WAIT_MAX_RETRIES)"\\r
        sleep $WAIT_SECONDS
    fi
done
echo ''

Cleanup