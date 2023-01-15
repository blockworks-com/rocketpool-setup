#!/bin/bash
# shellcheck disable=SC2016

if [[ -f "common-rpl.sh" ]]; then source common-rpl.sh; elif [[ -f "../Common/common-rpl.sh" ]]; then source ../Common/common-rpl.sh; elif [[ -f "../common-rpl.sh" ]]; then source ../common-rpl.sh; else echo "Failed to load common-rpl.sh"; return 0; fi

errors=0
success=0

clearValues() {
    # echo "Clear All Values"

    unset -v verbose
    unset -v LOG_FILE
    unset -v WAIT_EPOCH_SECONDS
    unset -v WAIT_EPOCH_MAX_RETRIES
    unset -v RSYNC_LOG_FILE
    unset -v USER_PREFIX
    unset -v TIMEZONE
    unset -v SSH_PORT
    unset -v RP_INSTALL_FILE
    unset -v RP_DIR
    unset -v CHANGE_ROOTPASSWORD
    unset -v CREATE_NONROOTUSER
    unset -v ENABLE_FIREWALL
    unset -v ENABLE_FALLBACK
    unset -v PREVENT_DOSATTACK
    unset -v MODIFY_AUTOUPGRADE
    unset -v RESTORE_ETH1_BACKUP
    unset -v ENABLE_AUTHENTICATION
    unset -v ADD_ALIASES
    unset -v INSTALL_ROCKETPOOL
    unset -v INSTALL_JQ
    unset -v REBOOT_DURING_RPL_INSTALL
    unset -v INSTALL_GRAFANA
    unset -v DROPBOX_DEST_DIR
    unset -v INSTALL_DROPBOX
}

test0001() {
    clearValues
    setVariablesFromConfigFile "test0001.yml"
    echo "Test Suite 0001"

    local __verbose=$verbose
    if [[ ! $verbose == false ]]; then (( errors++ )); echo "Error: verbose was not loaded from the config file with the correct value."; else (( success++ )); fi
    verbose=$__verbose

    if [[ ! $LOG_FILE == "$HOME/test0001.log" ]]; then (( errors++ )); echo "Error: LOG_FILE was not loaded from the config file with the correct value."; else (( success++ )); fi
    if [[ ! $WAIT_EPOCH_SECONDS == 235 ]]; then (( errors++ )); echo "Error: WAIT_EPOCH_SECONDS was not loaded from the config file with the correct value."; else (( success++ )); fi
    if [[ ! $WAIT_EPOCH_MAX_RETRIES == 985 ]]; then (( errors++ )); echo "Error: WAIT_EPOCH_MAX_RETRIES was not loaded from the config file with the correct value."; else (( success++ )); fi

    if [[ ! $RSYNC_LOG_FILE == "$HOME/test0001-rsync.log" ]]; then (( errors++ )); echo "Error: RSYNC_LOG_FILE was not loaded from the config file with the correct value."; else (( success++ )); fi
    if [[ ! $USER_PREFIX == "ddd" ]]; then (( errors++ )); echo "Error: USER_PREFIX was not loaded from the config file with the correct value."; else (( success++ )); fi
    if [[ ! $TIMEZONE == "Europe/London" ]]; then (( errors++ )); echo "Error: TIMEZONE was not loaded from the config file with the correct value."; else (( success++ )); fi
    if [[ ! $SSH_PORT == 110 ]]; then (( errors++ )); echo "Error: SSH_PORT was not loaded from the config file with the correct value."; else (( success++ )); fi
    if [[ ! $RP_INSTALL_FILE == "$HOME/bin/rocketpool0001" ]]; then (( errors++ )); echo "Error: RP_INSTALL_FILE was not loaded from the config file with the correct value."; else (( success++ )); fi
    if [[ ! $RP_DIR == "$HOME/.rocketpool0001" ]]; then (( errors++ )); echo "Error: RP_DIR was not loaded from the config file with the correct value."; else (( success++ )); fi
    if [[ ! $DROPBOX_DEST_DIR == "$HOME/Dropbox0001" ]]; then (( errors++ )); echo "Error: DROPBOX_DEST_DIR was not loaded from the config file with the correct value."; else (( success++ )); fi

    if [[ ! $CHANGE_ROOTPASSWORD == false ]]; then (( errors++ )); echo "Error: CHANGE_ROOTPASSWORD was not loaded from the config file with the correct value."; else (( success++ )); fi
    if [[ ! $CREATE_NONROOTUSER == false ]]; then (( errors++ )); echo "Error: CREATE_NONROOTUSER was not loaded from the config file with the correct value."; else (( success++ )); fi
    if [[ ! $ENABLE_FIREWALL == false ]]; then (( errors++ )); echo "Error: ENABLE_FIREWALL was not loaded from the config file with the correct value."; else (( success++ )); fi
    if [[ ! $ENABLE_FALLBACK == true ]]; then (( errors++ )); echo "Error: ENABLE_FALLBACK was not loaded from the config file with the correct value."; else (( success++ )); fi
    if [[ ! $PREVENT_DOSATTACK == false ]]; then (( errors++ )); echo "Error: PREVENT_DOSATTACK was not loaded from the config file with the correct value."; else (( success++ )); fi
    if [[ ! $MODIFY_AUTOUPGRADE == false ]]; then (( errors++ )); echo "Error: MODIFY_AUTOUPGRADE was not loaded from the config file with the correct value."; else (( success++ )); fi
    if [[ ! $RESTORE_ETH1_BACKUP == false ]]; then (( errors++ )); echo "Error: RESTORE_ETH1_BACKUP was not loaded from the config file with the correct value."; else (( success++ )); fi
    if [[ ! $ENABLE_AUTHENTICATION == false ]]; then (( errors++ )); echo "Error: ENABLE_AUTHENTICATION was not loaded from the config file with the correct value."; else (( success++ )); fi
    if [[ ! $ADD_ALIASES == false ]]; then (( errors++ )); echo "Error: ADD_ALIASES was not loaded from the config file with the correct value."; else (( success++ )); fi
    if [[ ! $INSTALL_ROCKETPOOL == false ]]; then (( errors++ )); echo "Error: INSTALL_ROCKETPOOL was not loaded from the config file with the correct value."; else (( success++ )); fi
    if [[ ! $INSTALL_JQ == false ]]; then (( errors++ )); echo "Error: INSTALL_JQ was not loaded from the config file with the correct value."; else (( success++ )); fi
    if [[ ! $REBOOT_DURING_RPL_INSTALL == false ]]; then (( errors++ )); echo "Error: REBOOT_DURING_RPL_INSTALL was not loaded from the config file with the correct value."; else (( success++ )); fi
    if [[ ! $INSTALL_GRAFANA == false ]]; then (( errors++ )); echo "Error: INSTALL_GRAFANA was not loaded from the config file with the correct value."; else (( success++ )); fi
    if [[ ! $INSTALL_DROPBOX == false ]]; then (( errors++ )); echo "Error: INSTALL_DROPBOX was not loaded from the config file with the correct value."; else (( success++ )); fi
}

test0002() {
    clearValues
    setVariablesFromConfigFile "test0002.yml"
    echo "Test Suite 0002"

    # not set in the config
    TIMEZONE="somedefaultvalue"
    if [[ ! $TIMEZONE == "somedefaultvalue" ]]; then (( errors++ )); echo "Error: TIMEZONE was not loaded from the config file with the correct value."; else (( success++ )); fi
}

test0002a() {
    clearValues
    setVariablesFromConfigFile "test0002.yml"
    echo "Test Suite 0002a"

    # not set in config 
    LOG_FILE="somedefaultvalue"
    if [[ ! $LOG_FILE == "somedefaultvalue" ]]; then (( errors++ )); echo "Error: LOG_FILE was not loaded from the config file with the correct value."; else (( success++ )); fi
}

test0003() {
    clearValues
    setVariablesFromConfigFile "test0003.yml"
    echo "Test Suite 0003"

    local __verbose=$verbose
    if [[ ! $verbose == false ]]; then (( errors++ )); echo "Error: verbose was not loaded from the config file with the correct value."; else (( success++ )); fi
    verbose=$__verbose

    if [[ ! $LOG_FILE == "$HOME/test0001.log" ]]; then (( errors++ )); echo "Error: LOG_FILE was not loaded from the config file with the correct value."; else (( success++ )); fi
    if [[ ! $WAIT_EPOCH_SECONDS == 235 ]]; then (( errors++ )); echo "Error: WAIT_EPOCH_SECONDS was not loaded from the config file with the correct value."; else (( success++ )); fi
    if [[ ! $WAIT_EPOCH_MAX_RETRIES == 985 ]]; then (( errors++ )); echo "Error: WAIT_EPOCH_MAX_RETRIES was not loaded from the config file with the correct value."; else (( success++ )); fi

    if [[ ! $RSYNC_LOG_FILE == "$HOME/test0001-rsync.log" ]]; then (( errors++ )); echo "Error: RSYNC_LOG_FILE was not loaded from the config file with the correct value."; else (( success++ )); fi
    if [[ ! $USER_PREFIX == "iuf" ]]; then (( errors++ )); echo "Error: USER_PREFIX was not loaded from the config file with the correct value."; else (( success++ )); fi
    if [[ ! $TIMEZONE == "Europe/London" ]]; then (( errors++ )); echo "Error: TIMEZONE was not loaded from the config file with the correct value."; else (( success++ )); fi
    if [[ ! $SSH_PORT == 110 ]]; then (( errors++ )); echo "Error: SSH_PORT was not loaded from the config file with the correct value."; else (( success++ )); fi
    if [[ ! $RP_INSTALL_FILE == "$HOME/bin/rocketpool0001" ]]; then (( errors++ )); echo "Error: RP_INSTALL_FILE was not loaded from the config file with the correct value."; else (( success++ )); fi
    if [[ ! $RP_DIR == "$HOME/.rocketpool0001" ]]; then (( errors++ )); echo "Error: RP_DIR was not loaded from the config file with the correct value."; else (( success++ )); fi
    if [[ ! $DROPBOX_DEST_DIR == "$HOME/Dropbox0001" ]]; then (( errors++ )); echo "Error: DROPBOX_DEST_DIR was not loaded from the config file with the correct value."; else (( success++ )); fi

    if [[ ! $INSTALL_DROPBOX == false ]]; then (( errors++ )); echo "Error: INSTALL_DROPBOX was not loaded from the config file with the correct value."; else (( success++ )); fi
}

# Do not load from config file to use hardcoded defaults
test0004() {
    clearValues
    echo "Test Suite 0004"

    # reload common-rpl since it sets the hardcoded defaults
    source ../common-rpl.sh

    if [[ ! $verbose == false ]]; then (( errors++ )); echo "Error: verbose was not set with the correct hardcoded default value."; else (( success++ )); fi

    if [[ ! $CONFIG_FILE == "$HOME/new-install.yml" ]]; then (( errors++ )); echo "Error: CONFIG_FILE was not set with the correct hardcoded default value."; else (( success++ )); fi

    if [[ ! $LOG_FILE == "$HOME/rp-install.log" ]]; then (( errors++ )); echo "Error: LOG_FILE was not set with the correct hardcoded default value."; else (( success++ )); fi
    if [[ ! $WAIT_EPOCH_SECONDS == 5 ]]; then (( errors++ )); echo "Error: WAIT_EPOCH_SECONDS was not set with the correct hardcoded default value."; else (( success++ )); fi
    if [[ ! $WAIT_EPOCH_MAX_RETRIES == 180 ]]; then (( errors++ )); echo "Error: WAIT_EPOCH_MAX_RETRIES was not set with the correct hardcoded default value."; else (( success++ )); fi

    if [[ ! $RSYNC_LOG_FILE == *"rp-install-rsync.log" ]]; then (( errors++ )); echo "Error: RSYNC_LOG_FILE was not set with the correct hardcoded default value."; else (( success++ )); fi
    if [[ ! $USER_PREFIX == "rpuser" ]]; then (( errors++ )); echo "Error: USER_PREFIX was not set with the correct hardcoded default value."; else (( success++ )); fi
    if [[ ! $TIMEZONE == "America/Chicago" ]]; then (( errors++ )); echo "Error: TIMEZONE was not set with the correct hardcoded default value."; else (( success++ )); fi
    if [[ ! $SSH_PORT == 22 ]]; then (( errors++ )); echo "Error: SSH_PORT was not set with the correct hardcoded default value."; else (( success++ )); fi
    if [[ ! $RP_INSTALL_FILE == *"/bin/rocketpool" ]]; then (( errors++ )); echo "Error: RP_INSTALL_FILE was not set with the correct hardcoded default value."; else (( success++ )); fi
    if [[ ! $RP_DIR == *".rocketpool" ]]; then (( errors++ )); echo "Error: RP_DIR was not set with the correct hardcoded default value."; else (( success++ )); fi
    if [[ ! $DROPBOX_DEST_DIR == *"/Dropbox" ]]; then (( errors++ )); echo "Error: DROPBOX_DEST_DIR was not set with the correct hardcoded default value."; else (( success++ )); fi

    if [[ ! $CHANGE_ROOTPASSWORD == true ]]; then (( errors++ )); echo "Error: CHANGE_ROOTPASSWORD was not set with the correct hardcoded default value."; else (( success++ )); fi
    if [[ ! $CREATE_NONROOTUSER == true ]]; then (( errors++ )); echo "Error: CREATE_NONROOTUSER was not set with the correct hardcoded default value."; else (( success++ )); fi
    if [[ ! $ENABLE_FIREWALL == true ]]; then (( errors++ )); echo "Error: ENABLE_FIREWALL was not set with the correct hardcoded default value."; else (( success++ )); fi
    if [[ ! $ENABLE_FALLBACK == false ]]; then (( errors++ )); echo "Error: ENABLE_FALLBACK was not set with the correct hardcoded default value."; else (( success++ )); fi
    if [[ ! $PREVENT_DOSATTACK == true ]]; then (( errors++ )); echo "Error: PREVENT_DOSATTACK was not set with the correct hardcoded default value."; else (( success++ )); fi
    if [[ ! $MODIFY_AUTOUPGRADE == true ]]; then (( errors++ )); echo "Error: MODIFY_AUTOUPGRADE was not set with the correct hardcoded default value."; else (( success++ )); fi
    if [[ ! $RESTORE_ETH1_BACKUP == true ]]; then (( errors++ )); echo "Error: RESTORE_ETH1_BACKUP was not set with the correct hardcoded default value."; else (( success++ )); fi
    if [[ ! $ENABLE_AUTHENTICATION == true ]]; then (( errors++ )); echo "Error: ENABLE_AUTHENTICATION was not set with the correct hardcoded default value."; else (( success++ )); fi
    if [[ ! $ADD_ALIASES == true ]]; then (( errors++ )); echo "Error: ADD_ALIASES was not set with the correct hardcoded default value."; else (( success++ )); fi
    if [[ ! $INSTALL_ROCKETPOOL == true ]]; then (( errors++ )); echo "Error: INSTALL_ROCKETPOOL was not set with the correct hardcoded default value."; else (( success++ )); fi
    if [[ ! $INSTALL_JQ == true ]]; then (( errors++ )); echo "Error: INSTALL_JQ was not set with the correct hardcoded default value."; else (( success++ )); fi
    if [[ ! $REBOOT_DURING_RPL_INSTALL == true ]]; then (( errors++ )); echo "Error: REBOOT_DURING_RPL_INSTALL was not set with the correct hardcoded default value."; else (( success++ )); fi
    if [[ ! $INSTALL_GRAFANA == true ]]; then (( errors++ )); echo "Error: INSTALL_GRAFANA was not set with the correct hardcoded default value."; else (( success++ )); fi
    if [[ ! $INSTALL_DROPBOX == true ]]; then (( errors++ )); echo "Error: INSTALL_DROPBOX was not set with the correct hardcoded default value."; else (( success++ )); fi
}

__verbose=$verbose
verbose=false

test0001
test0002
test0002a
test0003
test0004
echo "successful: $success; errors: $errors"

# Cleanup
verbose=$__verbose
