#!/bin/bash
# shellcheck disable=SC2001
# shellcheck disable=SC2016

# Common script functions for RocketPool Node

# Set global variables, if they are not already set
if [[ $verbose != true && $verbose != false ]]; then verbose=false; fi
if [[ -z $LOG_FILE ]]; then LOG_FILE=$HOME/rp-install.log; fi
if [[ -z $CONFIG_FILE ]]; then CONFIG_FILE=$HOME/new-install.yml; fi

if [[ -z $USER_PREFIX ]]; then USER_PREFIX='rpuser'; fi
if [[ -z $TIMEZONE ]]; then TIMEZONE='America/Chicago'; fi
if [[ -z $SSH_PORT ]]; then SSH_PORT=22; fi
if [[ -z $RP_INSTALL_FILE ]]; then RP_INSTALL_FILE=$HOME/bin/rocketpool; fi
if [[ -z $RP_DIR ]]; then RP_DIR=$HOME/.rocketpool; fi
if [[ -z $DROPBOX_DEST_DIR ]]; then DROPBOX_DEST_DIR=$HOME/Dropbox; fi

if [[ -z $RSYNC_LOG_FILE ]]; then RSYNC_LOG_FILE=$HOME/rp-install-rsync.log; fi

if [[ -z $WAIT_EPOCH_SECONDS || $WAIT_EPOCH_SECONDS -lt 0 ]]; then 
  if [[ $verbose == true ]]; then
    echo "Set default value for WAIT_EPOCH_SECONDS";
  fi 
  WAIT_EPOCH_SECONDS=5;
fi
if [[ -z $WAIT_EPOCH_MAX_RETRIES || $WAIT_EPOCH_MAX_RETRIES -lt 0 ]]; then 
  if [[ $verbose == true ]]; then
    echo "Set default value for WAIT_EPOCH_MAX_RETRIES";
  fi
  WAIT_EPOCH_MAX_RETRIES=15
fi
if [[ -z $WAIT_EPOCH_SECONDS || $WAIT_EPOCH_SECONDS -lt 0 ]]; then
  (( WAIT_EPOCH_MAX_RETRIES=(WAIT_EPOCH_MAX_RETRIES*60)/5 )) # wait a max of 15 minutes
else
  (( WAIT_EPOCH_MAX_RETRIES=(WAIT_EPOCH_MAX_RETRIES*60)/WAIT_EPOCH_SECONDS )) # wait a max of 15 minutes
fi

if [[ $CHANGE_ROOTPASSWORD != true && $CHANGE_ROOTPASSWORD != false ]]; then CHANGE_ROOTPASSWORD=true; fi
if [[ $CREATE_NONROOTUSER != true && $CREATE_NONROOTUSER != false ]]; then CREATE_NONROOTUSER=true; fi
if [[ $ENABLE_FIREWALL != true && $ENABLE_FIREWALL != false ]]; then ENABLE_FIREWALL=true; fi
if [[ $ENABLE_FALLBACK != true && $ENABLE_FALLBACK != false ]]; then ENABLE_FALLBACK=false; fi
if [[ $PREVENT_DOSATTACK != true && $PREVENT_DOSATTACK != false ]]; then PREVENT_DOSATTACK=true; fi
if [[ $MODIFY_AUTOUPGRADE != true && $MODIFY_AUTOUPGRADE != false ]]; then MODIFY_AUTOUPGRADE=true; fi
if [[ $CREATE_SWAPFILE != true && $CREATE_SWAPFILE != false ]]; then CREATE_SWAPFILE=true; fi

if [[ $RESTORE_ETH1_BACKUP != true && $RESTORE_ETH1_BACKUP != false ]]; then RESTORE_ETH1_BACKUP=true; fi
if [[ $ENABLE_AUTHENTICATION != true && $ENABLE_AUTHENTICATION != false ]]; then ENABLE_AUTHENTICATION=true; fi
if [[ $ADD_ALIASES != true && $ADD_ALIASES != false ]]; then ADD_ALIASES=true; fi
if [[ $INSTALL_ROCKETPOOL != true && $INSTALL_ROCKETPOOL != false ]]; then INSTALL_ROCKETPOOL=true; fi
if [[ $INSTALL_JQ != true && $INSTALL_JQ != false ]]; then INSTALL_JQ=true; fi
if [[ $INSTALL_DROPBOX != true && $INSTALL_DROPBOX != false ]]; then INSTALL_DROPBOX=false; fi

if [[ $REBOOT_DURING_RPL_INSTALL != true && $REBOOT_DURING_RPL_INSTALL != false ]]; then REBOOT_DURING_RPL_INSTALL=true; fi
if [[ $INSTALL_GRAFANA != true && $INSTALL_GRAFANA != false ]]; then INSTALL_GRAFANA=true; fi
if [[ $INSTALL_TAILSCALE != true && $INSTALL_TAILSCALE != false ]]; then INSTALL_TAILSCALE=true; fi

if [[ -z $EXECUTION_CLIENT_PORT ]]; then EXECUTION_CLIENT_PORT=30303; fi
if [[ -z $CONSENSUS_CLIENT_PORT ]]; then CONSENSUS_CLIENT_PORT=9001; fi
if [[ -z $ETH_API_PORT ]]; then ETH_API_PORT=5052; fi
if [[ -z $PRYSM_ETH_API_PORT ]]; then PRYSM_ETH_API_PORT=5053; fi
if [[ -z $PROMETHEUS_IP_ADDRESS ]]; then PROMETHEUS_IP_ADDRESS=172.23.0.0; fi
if [[ -z $GRAFANA_PORT ]]; then GRAFANA_PORT=3100; fi
if [[ -z $FALLBACK_ETH_API_PORT ]]; then FALLBACK_ETH_API_PORT=8545; fi

if [[ $DEBUG != true && $DEBUG != false ]]; then DEBUG=false; fi
if [[ $prompt != true && $prompt != false ]]; then prompt=false; fi

# variables for this script
RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[33m"
NOCOLOR="\033[0m"

log() {
  # $1 is message to log
  # $2 is override of the script name
  scriptName=$(basename "${BASH_SOURCE[1]}")
  if [[ "$2" == '-o' ]]; then
    scriptName=$(basename "${BASH_SOURCE[2]}")
  fi

  if [[ -z "$LOG_FILE" ]]; then
    echo -e "${YELLOW}Log filename not defined so cannot log message. Message to log: $1${NOCOLOR}"
    return
  fi
  if [[ $verbose == true ]]; then
    echo "$scriptName $1"
  fi
  echo "$(date) $scriptName $1" >> "$LOG_FILE"
}

log_fail() {
  # $1 is message to log
  # $2 is override of the script name
  scriptName=$(basename "${BASH_SOURCE[1]}")
  if [[ "$2" == '-o' ]]; then
    scriptName=$(basename "${BASH_SOURCE[2]}")
  fi

  if [[ -z "$LOG_FILE" ]]; then
    echo -e "${YELLOW}Log filename not defined so cannot log message. Message to log: $1${NOCOLOR}"
    return
  fi
  # echo -e "ERROR: ${RED}${1}${NOCOLOR}"
  echo "$(date) $scriptName ERROR: $1" >> "$LOG_FILE"
  # printf "%s\n" "$( tput setaf 1 )$error$( tput setaf 0 ): $errormessage" | tee -a t.log
}

log_step() {
  log "is at Step $1" '-o'
}

debug_enter_function() {
  functionStartTime=$(date +%s%N)
  if [[ $verbose == true ]]; then
    echo "Enter function: ${FUNCNAME[1]}"
  fi
  log "Enter function: ${FUNCNAME[1]}" '-o'
}

debug_leave_function() {
  functionEndTime=$(date +%s%N)
  duration=$((functionEndTime - functionStartTime))
  minutes=$(( duration / 60000000000 ))
  seconds=$(( (duration % 60000000000) / 1000000000 ))
  milliseconds=$(( ((duration % 60000000000) % 1000000000) / 1000000 ))

  message="Leave function: ${FUNCNAME[1]} Duration: ${minutes}m${seconds}s${milliseconds}ms"
  if [[ $verbose == true ]]; then
    echo "{$message}"
  fi
  log "${message}" '-o'
}

Initialize() {
  scriptStartTime=$(date +%s%N)
  log "Script initialized and starting." '-o'
}

Cleanup() {
  scriptEndTime=$(date +%s%N)
  duration=$((scriptEndTime - scriptStartTime))
  minutes=$(( duration / 60000000000 ))
  seconds=$(( (duration % 60000000000) / 1000000000 ))
  milliseconds=$(( ((duration % 60000000000) % 1000000000) / 1000000 ))

  message="Script Duration: ${minutes}m${seconds}s${milliseconds}ms"
  if [[ -n "$1" ]]; then
    message=${message}". Ending on step: $1"
  fi

  if [[ $verbose == true ]]; then
    echo "${message}"
  fi
  log "${message}" '-o'
}

getNetwork() {
  local __result=

  # Note: Your Smartnode is currently using the Ethereum Mainnet.
  # Note: Your Smartnode is currently using the Prater Test Network.
  prefix='Your Smart Node is currently using the'

  tmpMessage=$(rocketpool service version | grep "$prefix")
#  echo $tmpMessage
  len=$(( ${#tmpMessage} - ${#prefix} ))
  # removed colored output, blanks, and Test while getting the substring
  # __result=$(sed "s,\x1B\[[0-9;]*[a-zA-Z],,g" <<< $(sed "s/ //g" <<< $(sed "s/\.//g" <<< $(sed "s/Test//g" <<< $(sed "s/Ethereum//g" <<< $(sed "s/Network//g" <<< ${tmpMessage:${#prefix}:$len}))))))
  __result="$(sed "s,\x1B\[[0-9;]*[a-zA-Z],,g" <<< "$(sed "s/ //g" <<< "$(sed "s/\.//g" <<< "$(sed "s/Test//g" <<< "$(sed "s/Ethereum//g" <<< "$(sed "s/Network//g" <<< "${tmpMessage:${#prefix}:$len}")")")")")")"
  if ! [[ ${__result,,} =~ "mainnet" || ${__result,,} =~ "prater" ]]; then
    log "Could not parse network ($tmpMessage)."
    answer=
    read -r -p "Could not parse network ($tmpMessage). Enter Network: " answer
    __result=$answer
  fi

  echo "$__result"
}

getDomain() {
  # local __network=$1
  local __result=

  if [[ -z "$__network" ]]; then 
    # network was not passed so get it
    __network=$(getNetwork)
  fi

  if [[ ! ${__network,,} =~ "mainnet" ]]; then
    __result="${__network,,}."
  fi

  echo "$__result"
}

getValidator() {
  local __result=

  __result=$(rocketpool minipool status | grep 'Validator index' | awk '{print $3}' | head -n 1)

  if [[ ${#__result} -lt 1 ]]; then
    # Validator ID is missing
    log "Could get Validator ID ($__result)."

    if [[ "$verbose" == true ]]; then
      answer=
      read -r -p 'Validator ID is missing. Press ENTER to continue.' answer
      answer=
    fi
  fi

  echo "$__result"
}

getLastEpoch() {
  local __result=
  local __domain=
  local __validator=
  __domain=$(getDomain)
  __validator=$(getValidator)

  # Get last epoch attested
  local __urlAttestations="https://${__domain}beaconcha.in/api/v1/validator/$__validator/attestations"

  __result=$(curl -X 'GET' "$__urlAttestations" -H 'accept: application/json' -s | jq --raw-output '.data'[0].epoch)
  if [[ ${#__result} -lt 1 ]]; then
    log_fail "ERROR: could not determine last Epoch."

    if [[ "$verbose" == true ]]; then
      answer=
      read -r -p "Last Epoch is missing. Press ENTER to continue. Domain: $__domain" answer
      read -r -p "Last Epoch is missing. Press ENTER to continue. Validator: $__validator" answer
      read -r -p "Last Epoch is missing. Press ENTER to continue. Result: $__result" answer
      read -r -p "Last Epoch is missing. Press ENTER to continue. url: $__urlAttestations" answer
      answer=
    fi
    return
  fi

  echo "$__result"
}

waitForNextEpoch() {
  # $1 is override to silence the update messages
  debug_enter_function
#  local __network=$(getNetwork)
  local __domain=
  __domain=$(getDomain)
  if [[ "$verbose" == true ]]; then
    echo "Domain is: $__domain"
  fi

  local __validator=
  __validator=$(getValidator)
  if [[ ${#__validator} -lt 1 ]]; then
    log "Validator ID is missing so do not wait for next Epoch"
    echo 'Validator ID is missing so do not wait for next Epoch.'
    return
  fi
  if [[ "$verbose" == true ]]; then
    echo "Validator ID: $__validator"
  fi

  # Get last epoch attested
  local __urlAttestations=
  __urlAttestations="https://${__domain}beaconcha.in/api/v1/validator/$__validator/attestations"
  if [[ "$verbose" == true ]]; then
    echo "Attestation url: $__urlAttestations"
  fi

  local __lastEpoch=
  __lastEpoch=$(getLastEpoch)
  if [[ ${#__lastEpoch} -lt 1 ]]; then
    log "Last Epoch is missing so do not wait for next Epoch."
    echo 'Last Epoch is missing so do not wait for next Epoch.'
    return
  fi
  if [[ "$verbose" == true ]]; then
    echo "lastEpoch: $__lastEpoch"
  fi

  local let __nextEpoch=
  __nextEpoch=$(( __lastEpoch+1 ))
  if [[ "$verbose" == true ]]; then
    echo "nextEpoch: $__nextEpoch"
  fi
  if [[ "$1" != '-s' ]]; then
    echo "*** Wait for next epoch: $__nextEpoch"
  fi
  local i=0
  while [[ $__lastEpoch -ne $__nextEpoch && $i -lt $WAIT_EPOCH_MAX_RETRIES ]];
  do
    (( i++ ))
    __lastEpoch=$(getLastEpoch)
    if [[ $__lastEpoch -eq $__nextEpoch ]]; then
      if [[ "$verbose" == true ]]; then
        echo ""
        echo "next epoch arrived: $__lastEpoch"
      fi
      local __lastInclusionSlot=0
      local j=0
      while [[ $__lastInclusionSlot -le 0 ]];
      do
        (( j++ ))
        __lastInclusionSlot=$(curl -X 'GET' "$__urlAttestations" -H 'accept: application/json' -s | jq --raw-output '.data'[0].inclusionslot)
        # if [[ "$verbose" == true ]]; then
        #   echo ""
        #   echo "last inclusion slot: $__lastInclusionSlot"
        # fi
        if [[ $__lastInclusionSlot -gt 0 ]]; then
          if [[ "$verbose" == true ]]; then
            echo ""
            echo "node has processed the next epoch"
          fi
          break
        else
          if [[ "$verbose" == true ]]; then
            echo -ne "wait while still processing the next epoch ($j)"\\r
          fi
          sleep "$WAIT_EPOCH_SECONDS"
        fi
      done
    else
     if [[ "$1" != '-s' ]]; then
        echo -ne "check every $WAIT_EPOCH_SECONDS seconds ($i of $WAIT_EPOCH_MAX_RETRIES)"\\r
        sleep "$WAIT_EPOCH_SECONDS"
      fi
    fi
  done

  if [[ $__lastEpoch -ne $__nextEpoch ]]; then
    log_fail 'It seems the next Epoch was not processed.'
    echo 'ERROR: it seems the next Epoch was not processed.'
    return
  fi
  debug_leave_function
}

getVariableFromConfigFile() {
  # $1 is key
  # $2 is override of the config filename
  local __key=$1
  local __configFilename=
  local __result=

  __configFilename=$CONFIG_FILE
  if [[ -n $2 ]]; then 
    __configFilename=$2;
  fi

  if [[ ! -f "$__configFilename" ]]; then 
    log "Config file $__configFilename does not exist so cannot look up $__key variable."
    # echo "Config file $__configFilename does not exist so cannot look up $__key variable."
    return
  else
    __result=$(grep "^$__key" "$__configFilename" | cut -d'=' -f2-)
    # echo "$(date) $key = $__result"
  fi

  echo "$__result"
}

setVariablesFromConfigFile() {
  # $1 is the config filename
  debug_enter_function

  local __verbose=

  local __configFilename=
  __configFilename=$CONFIG_FILE
  if [[ -n $1 ]]; then 
    __configFilename=$1;
  fi

  # Verbose
  tmpKey=Verbose
  if [[ $verbose == true ]]; then echo "Looking for $tmpKey in config file"; fi 
  tmpValue=$(getVariableFromConfigFile "$tmpKey" "$__configFilename")
  if [[ $verbose == true ]]; then echo "$tmpKey = $tmpValue"; fi 
  if [[ -n $tmpValue ]]; then __verbose="$tmpValue"; fi

  # SecondsToWaitForEpoch
  tmpKey=SecondsToWaitForEpoch
  if [[ $verbose == true ]]; then echo "Looking for $tmpKey in config file"; fi 
  tmpValue=$(getVariableFromConfigFile "$tmpKey" "$__configFilename")
  if [[ $verbose == true ]]; then echo "$tmpKey = $tmpValue"; fi 
  if [[ -n $tmpValue ]]; then WAIT_EPOCH_SECONDS="$tmpValue"; fi

  # NumberOfTimesToRetryWaitingForEpoch
  tmpKey=NumberOfTimesToRetryWaitingForEpoch
  if [[ $verbose == true ]]; then echo "Looking for $tmpKey in config file"; fi 
  tmpValue=$(getVariableFromConfigFile "$tmpKey" "$__configFilename")
  if [[ $verbose == true ]]; then echo "$tmpKey = $tmpValue"; fi 
  if [[ -n $tmpValue ]]; then WAIT_EPOCH_MAX_RETRIES="$tmpValue"; fi

  # UsernamePrefix
  tmpKey=UsernamePrefix
  if [[ $verbose == true ]]; then echo "Looking for $tmpKey in config file"; fi 
  tmpValue=$(getVariableFromConfigFile "$tmpKey" "$__configFilename")
  if [[ $verbose == true ]]; then echo "$tmpKey = $tmpValue"; fi 
  if [[ -n $tmpValue ]]; then USER_PREFIX="$tmpValue"; fi

  # Timezone
  tmpKey=Timezone
  if [[ $verbose == true ]]; then echo "Looking for $tmpKey in config file"; fi 
  tmpValue=$(getVariableFromConfigFile "$tmpKey" "$__configFilename")
  if [[ $verbose == true ]]; then echo "$tmpKey = $tmpValue"; fi 
  if [[ -n $tmpValue ]]; then TIMEZONE="$tmpValue"; fi

  # SshPort
  tmpKey=SshPort
  if [[ $verbose == true ]]; then echo "Looking for $tmpKey in config file"; fi 
  tmpValue=$(getVariableFromConfigFile "$tmpKey" "$__configFilename")
  if [[ $verbose == true ]]; then echo "$tmpKey = $tmpValue"; fi 
  if [[ -n $tmpValue ]]; then SSH_PORT="$tmpValue"; fi

  # InstallDropbox
  tmpKey=InstallDropbox
  if [[ $verbose == true ]]; then echo "Looking for $tmpKey in config file"; fi 
  tmpValue=$(getVariableFromConfigFile "$tmpKey" "$__configFilename")
  if [[ $verbose == true ]]; then echo "$tmpKey = $tmpValue"; fi 
  if [[ -n $tmpValue ]]; then INSTALL_DROPBOX="$tmpValue"; fi

  # LogFilename
  tmpKey=LogFilename
  if [[ $verbose == true ]]; then echo "Looking for $tmpKey in config file"; fi 
  tmpValue=$(getVariableFromConfigFile "$tmpKey" "$__configFilename")
  if [[ $verbose == true ]]; then echo "$tmpKey = $tmpValue"; fi 
  tmpValue="${tmpValue/'$HOME'/$HOME}" # replace $HOME literal with folder
  if [[ -n $tmpValue ]]; then LOG_FILE="$tmpValue"; fi

  # RsyncLogFilename
  tmpKey=RsyncLogFilename
  if [[ $verbose == true ]]; then echo "Looking for $tmpKey in config file"; fi 
  tmpValue=$(getVariableFromConfigFile "$tmpKey" "$__configFilename")
  if [[ $verbose == true ]]; then echo "$tmpKey = $tmpValue"; fi 
  tmpValue="${tmpValue/'$HOME'/$HOME}" # replace $HOME literal with folder
  if [[ -n $tmpValue ]]; then RSYNC_LOG_FILE="$tmpValue"; fi

  # RocketPoolInstallFile
  tmpKey=RocketPoolInstallFile
  if [[ $verbose == true ]]; then echo "Looking for $tmpKey in config file"; fi 
  tmpValue=$(getVariableFromConfigFile "$tmpKey" "$__configFilename")
  if [[ $verbose == true ]]; then echo "$tmpKey = $tmpValue"; fi 
  tmpValue="${tmpValue/'$HOME'/$HOME}" # replace $HOME literal with folder
  if [[ -n $tmpValue ]]; then RP_INSTALL_FILE="$tmpValue"; fi

  # RocketPoolDirectory
  tmpKey=RocketPoolDirectory
  if [[ $verbose == true ]]; then echo "Looking for $tmpKey in config file"; fi 
  tmpValue=$(getVariableFromConfigFile "$tmpKey" "$__configFilename")
  if [[ $verbose == true ]]; then echo "$tmpKey = $tmpValue"; fi 
  tmpValue="${tmpValue/'$HOME'/$HOME}" # replace $HOME literal with folder
  if [[ -n $tmpValue ]]; then RP_DIR="$tmpValue"; fi

  # DropboxDirectory
  tmpKey=DropboxDirectory
  if [[ $verbose == true ]]; then echo "Looking for $tmpKey in config file"; fi 
  tmpValue=$(getVariableFromConfigFile "$tmpKey" "$__configFilename")
  if [[ $verbose == true ]]; then echo "$tmpKey = $tmpValue"; fi 
  tmpValue="${tmpValue/'$HOME'/$HOME}" # replace $HOME literal with folder
  if [[ -n $tmpValue ]]; then DROPBOX_DEST_DIR="$tmpValue"; fi

  # ChangeRootPassword
  tmpKey=ChangeRootPassword
  if [[ $verbose == true ]]; then echo "Looking for $tmpKey in config file"; fi 
  tmpValue=$(getVariableFromConfigFile "$tmpKey" "$__configFilename")
  if [[ $verbose == true ]]; then echo "$tmpKey = $tmpValue"; fi 
  if [[ -n $tmpValue ]]; then CHANGE_ROOTPASSWORD="$tmpValue"; fi

  # CreateNonRootUser
  tmpKey=CreateNonRootUser
  if [[ $verbose == true ]]; then echo "Looking for $tmpKey in config file"; fi 
  tmpValue=$(getVariableFromConfigFile "$tmpKey" "$__configFilename")
  if [[ $verbose == true ]]; then echo "$tmpKey = $tmpValue"; fi 
  if [[ -n $tmpValue ]]; then CREATE_NONROOTUSER="$tmpValue"; fi

  # EnableFirewall
  tmpKey=EnableFirewall
  if [[ $verbose == true ]]; then echo "Looking for $tmpKey in config file"; fi 
  tmpValue=$(getVariableFromConfigFile "$tmpKey" "$__configFilename")
  if [[ $verbose == true ]]; then echo "$tmpKey = $tmpValue"; fi 
  if [[ -n $tmpValue ]]; then ENABLE_FIREWALL="$tmpValue"; fi

  # EnableFallback
  tmpKey=EnableFallback
  if [[ $verbose == true ]]; then echo "Looking for $tmpKey in config file"; fi 
  tmpValue=$(getVariableFromConfigFile "$tmpKey" "$__configFilename")
  if [[ $verbose == true ]]; then echo "$tmpKey = $tmpValue"; fi 
  if [[ -n $tmpValue ]]; then ENABLE_FALLBACK="$tmpValue"; fi

  # PreventDOSAttack
  tmpKey=PreventDOSAttack
  if [[ $verbose == true ]]; then echo "Looking for $tmpKey in config file"; fi 
  tmpValue=$(getVariableFromConfigFile "$tmpKey" "$__configFilename")
  if [[ $verbose == true ]]; then echo "$tmpKey = $tmpValue"; fi 
  if [[ -n $tmpValue ]]; then PREVENT_DOSATTACK="$tmpValue"; fi

  # EnableAutoOSUpgrade
  tmpKey=EnableAutoOSUpgrade
  if [[ $verbose == true ]]; then echo "Looking for $tmpKey in config file"; fi 
  tmpValue=$(getVariableFromConfigFile "$tmpKey" "$__configFilename")
  if [[ $verbose == true ]]; then echo "$tmpKey = $tmpValue"; fi 
  if [[ -n $tmpValue ]]; then MODIFY_AUTOUPGRADE="$tmpValue"; fi

  # CreateSwapfile
  tmpKey=CreateSwapfile
  if [[ $verbose == true ]]; then echo "Looking for $tmpKey in config file"; fi 
  tmpValue=$(getVariableFromConfigFile "$tmpKey" "$__configFilename")
  if [[ $verbose == true ]]; then echo "$tmpKey = $tmpValue"; fi 
  if [[ -n $tmpValue ]]; then CREATE_SWAPFILE="$tmpValue"; fi

  # RestoreEth1FromBackup
  tmpKey=RestoreEth1FromBackup
  if [[ $verbose == true ]]; then echo "Looking for $tmpKey in config file"; fi 
  tmpValue=$(getVariableFromConfigFile "$tmpKey" "$__configFilename")
  if [[ $verbose == true ]]; then echo "$tmpKey = $tmpValue"; fi 
  if [[ -n $tmpValue ]]; then RESTORE_ETH1_BACKUP="$tmpValue"; fi

  # Enable2FactorAuthentication
  tmpKey=Enable2FactorAuthentication
  if [[ $verbose == true ]]; then echo "Looking for $tmpKey in config file"; fi 
  tmpValue=$(getVariableFromConfigFile "$tmpKey" "$__configFilename")
  if [[ $verbose == true ]]; then echo "$tmpKey = $tmpValue"; fi 
  if [[ -n $tmpValue ]]; then ENABLE_AUTHENTICATION="$tmpValue"; fi

  # AddRocketPoolAliases
  tmpKey=AddRocketPoolAliases
  if [[ $verbose == true ]]; then echo "Looking for $tmpKey in config file"; fi 
  tmpValue=$(getVariableFromConfigFile "$tmpKey" "$__configFilename")
  if [[ $verbose == true ]]; then echo "$tmpKey = $tmpValue"; fi 
  if [[ -n $tmpValue ]]; then ADD_ALIASES="$tmpValue"; fi

  # InstallRocketPool
  tmpKey=InstallRocketPool
  if [[ $verbose == true ]]; then echo "Looking for $tmpKey in config file"; fi 
  tmpValue=$(getVariableFromConfigFile "$tmpKey" "$__configFilename")
  if [[ $verbose == true ]]; then echo "$tmpKey = $tmpValue"; fi 
  if [[ -n $tmpValue ]]; then INSTALL_ROCKETPOOL="$tmpValue"; fi

  # InstallJQ
  tmpKey=InstallJQ
  if [[ $verbose == true ]]; then echo "Looking for $tmpKey in config file"; fi 
  tmpValue=$(getVariableFromConfigFile "$tmpKey" "$__configFilename")
  if [[ $verbose == true ]]; then echo "$tmpKey = $tmpValue"; fi 
  if [[ -n $tmpValue ]]; then INSTALL_JQ="$tmpValue"; fi

  # RebootDuringRocketPoolInstallation
  tmpKey=RebootDuringRocketPoolInstallation
  if [[ $verbose == true ]]; then echo "Looking for $tmpKey in config file"; fi 
  tmpValue=$(getVariableFromConfigFile "$tmpKey" "$__configFilename")
  if [[ $verbose == true ]]; then echo "$tmpKey = $tmpValue"; fi 
  if [[ -n $tmpValue ]]; then REBOOT_DURING_RPL_INSTALL="$tmpValue"; fi

  # InstallGrafana
  tmpKey=InstallGrafana
  if [[ $verbose == true ]]; then echo "Looking for $tmpKey in config file"; fi 
  tmpValue=$(getVariableFromConfigFile "$tmpKey" "$__configFilename")
  if [[ $verbose == true ]]; then echo "$tmpKey = $tmpValue"; fi 
  if [[ -n $tmpValue ]]; then INSTALL_GRAFANA="$tmpValue"; fi

  # InstallTailscale
  tmpKey=InstallTailscale
  if [[ $verbose == true ]]; then echo "Looking for $tmpKey in config file"; fi 
  tmpValue=$(getVariableFromConfigFile "$tmpKey" "$__configFilename")
  if [[ $verbose == true ]]; then echo "$tmpKey = $tmpValue"; fi 
  if [[ -n $tmpValue ]]; then INSTALL_TAILSCALE="$tmpValue"; fi

  # Execution Client Port
  tmpKey=ExecutionClientPort
  if [[ $verbose == true ]]; then echo "Looking for $tmpKey in config file"; fi 
  tmpValue=$(getVariableFromConfigFile "$tmpKey" "$__configFilename")
  if [[ $verbose == true ]]; then echo "$tmpKey = $tmpValue"; fi 
  if [[ -n $tmpValue ]]; then EXECUTION_CLIENT_PORT="$tmpValue"; fi

  # Consensus Client Port
  tmpKey=ConsensusClientPort
  if [[ $verbose == true ]]; then echo "Looking for $tmpKey in config file"; fi 
  tmpValue=$(getVariableFromConfigFile "$tmpKey" "$__configFilename")
  if [[ $verbose == true ]]; then echo "$tmpKey = $tmpValue"; fi 
  if [[ -n $tmpValue ]]; then CONSENSUS_CLIENT_PORT="$tmpValue"; fi

  # Ethereum API Port
  tmpKey=EthApiPort
  if [[ $verbose == true ]]; then echo "Looking for $tmpKey in config file"; fi 
  tmpValue=$(getVariableFromConfigFile "$tmpKey" "$__configFilename")
  if [[ $verbose == true ]]; then echo "$tmpKey = $tmpValue"; fi 
  if [[ -n $tmpValue ]]; then ETH_API_PORT="$tmpValue"; fi

  # Prysm Ethereum API Port
  tmpKey=PrysmEthApiPort
  if [[ $verbose == true ]]; then echo "Looking for $tmpKey in config file"; fi 
  tmpValue=$(getVariableFromConfigFile "$tmpKey" "$__configFilename")
  if [[ $verbose == true ]]; then echo "$tmpKey = $tmpValue"; fi 
  if [[ -n $tmpValue ]]; then PRYSM_ETH_API_PORT="$tmpValue"; fi

  # Prometheus IP
  tmpKey=PrometheusIp
  if [[ $verbose == true ]]; then echo "Looking for $tmpKey in config file"; fi 
  tmpValue=$(getVariableFromConfigFile "$tmpKey" "$__configFilename")
  if [[ $verbose == true ]]; then echo "$tmpKey = $tmpValue"; fi 
  if [[ -n $tmpValue ]]; then PROMETHEUS_IP_ADDRESS="$tmpValue"; fi

  # Grafana Port
  tmpKey=GrafanaPort
  if [[ $verbose == true ]]; then echo "Looking for $tmpKey in config file"; fi 
  tmpValue=$(getVariableFromConfigFile "$tmpKey" "$__configFilename")
  if [[ $verbose == true ]]; then echo "$tmpKey = $tmpValue"; fi 
  if [[ -n $tmpValue ]]; then GRAFANA_PORT="$tmpValue"; fi

  # Fallback Ethereum API Port
  tmpKey=FallbackEthApiPort
  if [[ $verbose == true ]]; then echo "Looking for $tmpKey in config file"; fi 
  tmpValue=$(getVariableFromConfigFile "$tmpKey" "$__configFilename")
  if [[ $verbose == true ]]; then echo "$tmpKey = $tmpValue"; fi 
  if [[ -n $tmpValue ]]; then FALLBACK_ETH_API_PORT="$tmpValue"; fi


  debug_leave_function
  # Update the global variable after calling debug_leave_function to avoid unexpected messages
  if [[ -n $__verbose ]]; then verbose="$__verbose"; fi
}

echoVariables() {
  debug_enter_function

  echo "verbose: $verbose"
  echo "WAIT_EPOCH_SECONDS: $WAIT_EPOCH_SECONDS"
  echo "WAIT_EPOCH_MAX_RETRIES: $WAIT_EPOCH_MAX_RETRIES"
  echo "USER_PREFIX: $USER_PREFIX"
  echo "TIMEZONE: $TIMEZONE"
  echo "SSH_PORT: $SSH_PORT"
  echo "INSTALL_DROPBOX: $INSTALL_DROPBOX"
  echo "LOG_FILE: $LOG_FILE"
  echo "RSYNC_LOG_FILE: $RSYNC_LOG_FILE"
  echo "RP_INSTALL_FILE: $RP_INSTALL_FILE"
  echo "RP_DIR: $RP_DIR"
  echo "DROPBOX_DEST_DIR: $DROPBOX_DEST_DIR"
  echo "CHANGE_ROOTPASSWORD: $CHANGE_ROOTPASSWORD"
  echo "CREATE_NONROOTUSER: $CREATE_NONROOTUSER"
  echo "ENABLE_FIREWALL: $ENABLE_FIREWALL"
  echo "ENABLE_FALLBACK: $ENABLE_FALLBACK"
  echo "PREVENT_DOSATTACK: $PREVENT_DOSATTACK"
  echo "MODIFY_AUTOUPGRADE: $MODIFY_AUTOUPGRADE"
  echo "CREATE_SWAPFILE: $CREATE_SWAPFILE"
  echo "RESTORE_ETH1_BACKUP: $RESTORE_ETH1_BACKUP"
  echo "ENABLE_AUTHENTICATION: $ENABLE_AUTHENTICATION"
  echo "ADD_ALIASES: $ADD_ALIASES"
  echo "INSTALL_ROCKETPOOL: $INSTALL_ROCKETPOOL"
  echo "INSTALL_JQ: $INSTALL_JQ"
  echo "REBOOT_DURING_RPL_INSTALL: $REBOOT_DURING_RPL_INSTALL"
  echo "INSTALL_GRAFANA: $INSTALL_GRAFANA"
  echo "EXECUTION_CLIENT_PORT: $EXECUTION_CLIENT_PORT"
  echo "CONSENSUS_CLIENT_PORT: $CONSENSUS_CLIENT_PORT"
  echo "ETH_API_PORT: $ETH_API_PORT"
  echo "PRYSM_ETH_API_PORT: $PRYSM_ETH_API_PORT"
  echo "PROMETHEUS_IP_ADDRESS: $PROMETHEUS_IP_ADDRESS"
  echo "GRAFANA_PORT: $GRAFANA_PORT"
  echo "FALLBACK_ETH_API_PORT: $FALLBACK_ETH_API_PORT"

  debug_leave_function
}

# template() {
#     debug_enter_function
#     debug_leave_function
# }
