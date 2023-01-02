#!/bin/bash

if [[ -f "common-rpl.sh" ]]; then source common-rpl.sh; else source ../Common/common-rpl.sh; fi

#Define the string value
RSYNC_DETAIL_LOG_FILE=$HOME/rp-install-rsync-details.log
RSYNC_WIP_FILE=$HOME/rp-install-rsync-wip.log

host=
username=

if [[ $1 == "-h" || $1 == "--help" ]]; then
    echo 'help info'
    return
    elif [[ -n "$2" ]]; then
    if [[ $1 == "--user" ]]; then
        username=$2
        elif [[ $1 == "--host" ]]; then
        host=$2
    fi
    if [[ -n "$4" ]]; then
        if [[ $3 == "--user" ]]; then
            username=$4
            elif [[ $3 == "--host" ]]; then
            host=$4
        fi
    fi
fi

function script_usage() {
    cat << EOF
Usage:
    -h|--help                  Displays this help and exit
    -u|--user                  User on host for connection
    -h|--host                  Host IP address for connection
EOF
}


#####################################################################################################################
# Main
#####################################################################################################################
Initialize

if [[ -z "$host" ]]; then
    answer=
    echo 'Enter destination server IP address:'
    read -r answer
    if [[ $answer != '' ]]; then
        host=$answer
    fi
fi

if [[ -z "$username" ]]; then
    answer=
    echo 'Enter username on destination server:'
    read -r answer
    if [[ $answer != '' ]]; then
        username=$answer
    fi
fi

# use sudo command to prompt for password if necessary so we don't prompt after staring the Rocketpool installation.
sudo ls >/dev/null

echo "latest in chaindata: $(sudo ls "$HOME"/backup/geth/geth/chaindata -Art | tail -n 1)"
echo "latest in chaindata: $(sudo ls "$HOME"/backup/geth/geth/chaindata -Art | tail -n 1)" >> "$RSYNC_LOG_FILE"
echo "latest in ancient: $(sudo ls "$HOME"/backup/geth/geth/chaindata/ancient -Art | tail -n 1)"
echo "latest in ancient: $(sudo ls "$HOME"/backup/geth/geth/chaindata/ancient -Art | tail -n 1)" >> "$RSYNC_LOG_FILE"

# capture list of filenames to be used by rsync-progress.sh script
sudo find "$HOME/backup" -printf "%f\n" > "$RSYNC_WIP_FILE"

echo "" && echo "Destination IP: $host; username: $username. Press ENTER to continue or Ctrl-C to cancel."
read -r junk
junk=

echo -e "$(date) Start rsync to $host." >> "$RSYNC_LOG_FILE"
sudo rsync -P -av "$HOME/backup" "$username@$host:$HOME/" | tee "$RSYNC_DETAIL_LOG_FILE"
result=$?
if [[ $result == 255 ]]; then
    echo "" && echo '*** Trying to automatically fix: Removing from known_hosts.' && echo ""
    sudo ssh-keygen -f "/root/.ssh/known_hosts" -R "$host"
    sudo rsync -P -av "$HOME/backup" "$username@$host:$HOME/" | tee "$RSYNC_DETAIL_LOG_FILE"
    result=$?
fi
if [[ $result != 0 ]]; then
    echo "" && echo "*** Trying to automatically fix: Add the public key to $HOME/.ssh/authorized_keys the other server. Append the following:"
    cat "$HOME/.ssh/id_ed25519.pub"
    echo "" && echo "Press ENTER to continue."
    read -r junk
    junk=
    
    sudo rsync -P -av "$HOME/backup" "$username@$host:$HOME/" | tee "$RSYNC_DETAIL_LOG_FILE"
    result=$?
fi

if [[ $result != 0 ]]; then
    echo "" && echo '*** Trying to automatically fix: Run pause-2fa.sh on the other server. Press ENTER to continue.'
    read -r junk
    junk=
    
    sudo rsync -P -av "$HOME/backup" "$username@$host:$HOME/" | tee "$RSYNC_DETAIL_LOG_FILE"
    result=$?
fi

if [[ $result != 0 ]]; then
    echo 'ERROR: Rsync failed. TRY AGAIN LATER. EXIT'
    return
else
    echo -e "$(date) rsync to $host finished." >> "$RSYNC_LOG_FILE"
    
    echo "" && echo 'Upload rsync log to host. You will be prompted to log into the host again.'
    scp "$RSYNC_LOG_FILE" "$username@$host:$HOME/"
    echo 'FINISHED.'
fi

Cleanup