#!/bin/bash

# Common script maintenance functions for RocketPool Node

# Set global variables, if they are not already set
if [[ $defaults != true && $defaults != false ]]; then defaults=true; fi
if [[ $forceUpdate != true && $forceUpdate != false ]]; then forceUpdate=false; fi
if [[ $_waitForNextEpoch != true && $_waitForNextEpoch != false ]]; then _waitForNextEpoch=true; fi
if [[ $distUpgrade != true && $distUpgrade != false ]]; then distUpgrade=true; fi
if [[ -z $LATEST_VERSION_URL ]]; then LATEST_VERSION_URL="github.com/rocket-pool/smartnode-install/releases/latest/download"; fi
if [[ -z $DOWNLOAD_BASE_URL ]]; then DOWNLOAD_BASE_URL="https://github.com/rocket-pool/smartnode-install/releases/download/v"; fi 

getLatestRPVersion() {
    # return version number
    # debug_enter_function
    local __resolvedUrl
    __resolvedUrl=$(curl "$LATEST_VERSION_URL" -s -L -I -w "%{url_effective}" -o /dev/null)

    # Set delimiter
    IFS='/'

    # Read the split words into an array
    read -r -a strarr <<< "$__resolvedUrl"

    # Count the total words
    local __count
    __count="${#strarr[*]}"
    # echo "There are $__count words in the resolved url."

    local __version
    __version="${strarr[$__count-1]}"
    if  [[ $__version == "v"* ]]; then
        # remove "v" prefix so it's only a number
    #    echo "starts with v"
        __version=${__version#?};
    fi
    # echo "Latest Version: $__version"

    echo "$__version"

    # debug_leave_function
}

getNodeVersion() {
    # return version number
    # debug_enter_function

    # Set delimiter
    IFS=': '

    nodeVersionText=$(rocketpool service version | grep service)
    #echo "Text is: $nodeVersionText"

    #Read the split words into an array
    read -r -a strarr <<< "$nodeVersionText"

    # Count the total words
    local __count
    __count="${#strarr[*]}"
    # echo "There are $__count words in the node version text"

    local __version
    __version="${strarr[$__count-1]}"
    # echo "Node Version  : $__version"

    echo "$__version"

    # debug_leave_function
}

verifyMatchingNodeVersion() {
    # return true they match or false
    # debug_enter_function

    # Set delimiter
    IFS=': '

    # Service
    serviceVersionText=$(rocketpool service version | grep service)
    #echo "Service version text is: $serviceVersionText"

    #Read the split words into an array
    read -r -a strarr <<< "$serviceVersionText"

    # Count the total words
    local __count
    __count="${#strarr[*]}"
    # echo "There are $__count words in the node service version text"

    local __serviceVersion
    __serviceVersion="${strarr[$__count-1]}"
    echo "Node service version: $__serviceVersion"


    # Client
    clientVersionText=$(rocketpool service version | grep client)
    #echo "Client version text is: $clientVersionText"

    #Read the split words into an array
    read -r -a strarr2 <<< "$clientVersionText"

    # Count the total words
    local __count
    __count="${#strarr2[*]}"
    # echo "There are $__count words in the node client version text"

    local __clientVersion
    __clientVersion="${strarr[$__count-1]}"
    echo "Node client version: $__clientVersion"

    if [[ $__serviceVersion == "$__clientVersion" ]]; then
        echo true
    else
        echo false
    fi

    # debug_leave_function
}

verifyNodeIsActive() {
    # return true if active or false
    # debug_enter_function

    nodeStatus=$(rocketpool node status)
    if [[ $nodeStatus == *"The node has a total of "*" active minipool(s)"* ]]; then
        echo true
    else
        echo false
    fi                                    

    # debug_leave_function
}

# template() {
#     debug_enter_function
#     debug_leave_function
# }
