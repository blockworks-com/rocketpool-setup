#!/bin/bash

# Script to update RocketPool Node
# perform updates right after processing Epoch to minimize missed attestations

if [[ -f "common-rpl.sh" ]]; then source common-rpl.sh; else source ../Common/common-rpl.sh; fi
if [[ -f "common-rpl-maintenance.sh" ]]; then source common-rpl-maintenance.sh; else source ../Common/common-rpl-maintenance.sh; fi

#TODO: support passing in EC version tag

#Define values or override default values
OUR_PLATFORM="rocketpool-cli-linux-amd64"
WAIT_AFTER_START=60
overrideVersion=

#https://github.com/rocket-pool/smartnode-install/releases/latest/download/rocketpool-cli-linux-amd64 # latest that needs to be resolved
#https://github.com/rocket-pool/smartnode-install/releases/download/v?.?.?/rocketpool-cli-linux-amd64 # actual download for specific version

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
if [[ $1 == "-o" || $1 == "--override" || 
    $2 == "-o" || $2 == "--override" || 
    $3 == "-o" || $3 == "--override" || 
    $4 == "-o" || $4 == "--override" || 
    $5 == "-o" || $5 == "--override" || 
    $6 == "-o" || $6 == "--override" ]]; then
    if [[ $1 == "-o" || $1 == "--override" ]]; then
        overrideVersion="$2"
    elif [[ $2 == "-o" || $2 == "--override" ]]; then
        overrideVersion="$3"
    elif [[ $3 == "-o" || $3 == "--override" ]]; then
        overrideVersion="$4"
    elif [[ $4 == "-o" || $4 == "--override" ]]; then
        overrideVersion="$5"
    elif [[ $5 == "-o" || $5 == "--override" ]]; then
        overrideVersion="$6"
    elif [[ $6 == "-o" || $6 == "--override" ]]; then
        overrideVersion="$7"
    fi
    echo "Override Rocket Pool version set to: $overrideVersion"
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

if [[ $forceUpdate == false && $(verifyNodeIsActive) == false ]]; then
    # node not running, sync'ed, and ready
    echo "ERROR: Node is not running, sync'ed, and ready. Try again later. EXIT"
    rocketpool node status
    return
fi                                    

installVersion=
if [[ -n $overrideVersion ]]; then
    installVersion=$overrideVersion
    if  [[ $installVersion == "v"* ]]; then
        # remove "v" prefix so it's only a number
        installVersion=${installVersion#?};
    fi
    if [[ $verbose == true ]]; then
        echo "Override version: $installVersion"
    fi
else
    installVersion=$(getLatestRPVersion)
    if [[ $verbose == true ]]; then
        echo "Latest version: $installVersion"
    fi
fi

nodeVersion=$(getNodeVersion)
if [[ $verbose == true ]]; then
    echo "Node version: $nodeVersion"
fi

# Do we need to upgrade?
if [[ $installVersion == "$nodeVersion" ]] ;
then
    echo "Already at the latest version."
else
    if [[ $verbose == true ]]; then
        echo "********************************************"
        echo "ACTION REQUIRED: UPGRADE TO VERSION $installVersion"
        echo "********************************************"
    else
        echo "Upgrading to $installVersion"
    fi
    # use sudo command to prompt for password if necessary so we don't prompt after waiting for epoch
    sudo ls >/dev/null

    if [[ "$defaults" == false ]]; then
        answer=
        echo ''
        echo "Upgrade to $installVersion (y/n)?"
        read -r answer
        if [[ $answer != 'y' ]]; then
            echo "Answer was $answer so exiting script."
            return
        fi
    fi

    # Remove old version so we can check if the download was successful
    if [[ $verbose == true ]]; then
        echo "Remove old Rocketpool version"
    fi
    rmdir -p "$RP_INSTALL_FILE" 2>/dev/null

    downloadUrl="${DOWNLOAD_BASE_URL}${installVersion}/$OUR_PLATFORM"
    if [[ $verbose == true ]]; then
        echo "Downloading Rocket Pool from: $downloadUrl"
    fi
    wget "$downloadUrl" -O "$HOME/bin/rocketpool" 2>/dev/null
    exit_code=$?
    if [[ $verbose == true ]]; then
        echo "Done downloading"
    fi
    if [[ $exit_code != 0 ]]; then
        echo "ERROR: download failed with exit code: $exit_code"
        echo "Enter Url to download and press ENTER to try again"
        read -r downloadUrl
        echo "Downloading from: $downloadUrl"
        wget "$downloadUrl" -O "$HOME/bin/rocketpool" 2>/dev/null
        exit_code=$?
        if [[ $exit_code != 0 ]] ;
        then
            echo "ERROR: download failed again with exit code: $exit_code. EXIT."
            return
        fi
    else
        # download was successful
        mkdir -p "$HOME/bin" 2>/dev/null
        chmod +x "$RP_INSTALL_FILE" 2>/dev/null

        # Make a backup of rocketpool with configs
        if [[ $verbose == true ]]; then
            echo "Making a backup of rocketpool"
        fi
        sudo cp -r "$HOME/.rocketpool" "$HOME/.rocketpool.bak" 2>/dev/null

        if [[ "$_waitForNextEpoch" == true ]]; then
          # Wait for next epoch before proceeding
          waitForNextEpoch
        fi

        #$(rocketpool service pause)
        if [[ $verbose == true ]]; then
            echo "Stopping Rocketpool Service"
            rocketpool service stop -y
        else
            rocketpool service stop -y 2>/dev/null
        fi

        if [[ $verbose == true ]]; then
            echo "Installing Rocketpool Service"
            rocketpool service install -d -y
        else
            rocketpool service install -d -y 2>/dev/null
        fi
        #rocketpool service install -d -n $rpNetwork

        if [[ $verbose == true ]]; then
            echo "Starting Rocketpool Service"
            rocketpool service start -y
        else
            rocketpool service start -y 2>/dev/null
        fi

        # Do this right after starting the service to give the service a few seconds to start
        if [[ $verbose == true ]]; then
            echo "Run apt update to refresh the dashboard"
        fi
        sudo apt update >/dev/null

        # It takes a few seconds to become active
        sleep "$WAIT_AFTER_START"
        nodeStatus=$(rocketpool node status)
        if [[ ! $nodeStatus == *"The node has a total of "*" active minipool(s)"* ]]; then
            echo ""
            echo "Node is not active yet. Retying in $WAIT_AFTER_START seconds."

            sleep "$WAIT_AFTER_START"
            nodeStatus=$(rocketpool node status)
            if [[ ! $nodeStatus == *"The node has a total of "*" active minipool(s)"* ]]; then
                echo ""
                echo "WARNING: Node is still not active. Manually resolve using: "
                rocketpool node status
                rocketpool node sync
            fi
        fi

        # Verify both client and service were upgrade and are the same.
        if [[ $verbose == true ]]; then
            echo "Verify Rocketpool client and service versions"
        fi
        matchingVersion=$(verifyMatchingNodeVersion)
        if [[ $matchingVersion == false ]]; then
            echo "ERROR: Node client and service versions do not match. Manually fix. EXIT"
            rocketpool service version
            return
        fi

        # Verify updated version is what we expect.
        nodeVersion=$(getNodeVersion)
        if [[ $installVersion != "$nodeVersion" ]]; then
            echo "ERROR: Node service is: $nodeVersion but was expected to be: $installVersion. EXIT"
            rocketpool service version
            return
        fi

        # Verify wallet is fine.
        walletStatus=$(rocketpool wallet status)
        if [[ ! $walletStatus == *"node wallet is initialized"* ]]; then
            if [[ $verbose == true ]]; then
                echo "Rebuild Rocketpool Wallet"
            fi
            rocketpool wallet rebuild
        fi

        echo "Done"
    fi
fi

Cleanup