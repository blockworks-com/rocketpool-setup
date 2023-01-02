#!/bin/bash

if [[ -f "common-rpl.sh" ]]; then source common-rpl.sh; else source ../Common/common-rpl.sh; fi

#Define the string value
RSYNC_DETAIL_LOG_FILE=$HOME/rp-install-rsync-details.log
RSYNC_WIP_FILE=$HOME/rp-install-rsync-wip.log

host=
username=

# handle command line options
if [[ $1 == "-u" || $1 == "--user" || 
    $2 == "-u" || $2 == "--user" || 
    $3 == "-u" || $3 == "--user" || 
    $4 == "-u" || $4 == "--user" ]]; then
    if [[ $1 == "-u" || $1 == "--user" ]]; then
        username="$2"
    elif [[ $2 == "-u" || $2 == "--user" ]]; then
        username="$3"
    elif [[ $3 == "-u" || $3 == "--user" ]]; then
        username="$4"
    elif [[ $4 == "-u" || $4 == "--user" ]]; then
        username="$5"
    fi
    echo "Username set to: $username"
fi
if [[ $1 == "-s" || $1 == "--server" || 
    $2 == "-s" || $2 == "--server" || 
    $3 == "-s" || $3 == "--server" || 
    $4 == "-s" || $4 == "--server" ]]; then
    if [[ $1 == "-s" || $1 == "--server" ]]; then
        host="$2"
    elif [[ $2 == "-s" || $2 == "--server" ]]; then
        host="$3"
    elif [[ $3 == "-s" || $3 == "--server" ]]; then
        host="$4"
    elif [[ $4 == "-s" || $4 == "--server" ]]; then
        host="$5"
    fi
    echo "Server name of host set to: $host"
fi
if [[ $1 == "-v" || $1 == "--verbose" ||
    $2 == "-v" || $2 == "--verbose" || 
    $3 == "-v" || $3 == "--verbose" || 
    $4 == "-v" || $4 == "--verbose" ]]; then
    echo "verbose on"
    verbose=true
fi
if [[ $1 == "-h" || $1 == "--help" || 
    $2 == "-h" || $2 == "--help" || 
    $3 == "-h" || $3 == "--help" || 
    $4 == "-h" || $4 == "--help" ]]; then
    cat << EOF
Usage: do-rsync [OPTIONS]...
Call rsync to sync Execution Client date to host server.

    Option                     Meaning
    -h|--help                  Displays this help and exit
    -u|--user                  Username on host for connection
    -s|--server                Server name of host
    -v|--verbose               Displays verbose output
EOF
    return
fi

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
sudo find "$HOME/backup" -printf "%f\n" | tee "$RSYNC_WIP_FILE" > /dev/null

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