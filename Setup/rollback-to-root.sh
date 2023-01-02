#!/bin/bash

if [[ -f "common-rpl.sh" ]]; then source common-rpl.sh; else source ../Common/common-rpl.sh; fi

#Define the string value

# handle command line options
if [[ $1 == "-v" || $1 == "--verbose" ||
    $2 == "-v" || $2 == "--verbose" ]]; then
    echo "verbose on"
    verbose=true
fi
if [[ $1 == "-h" || $1 == "--help" || 
    $2 == "-h" || $2 == "--help" ]]; then
    cat << EOF
Usage: rollback-to-root [OPTIONS]...
Used to uninstall RocketPool and remove RocketPool user.

    Option                     Meaning
    -h|--help                  Displays this help and exit
    -v|--verbose               Displays verbose output
EOF
    return
fi

#####################################################################################################################
# Main
#####################################################################################################################
Initialize

answer=
echo 'WARNING: This cannot be undone. Are you sure you want to rollback to root (y/n)?'
read -r answer
if [[ $answer   == 'y' ]]; then
    # echo 'Prompt for sudo since it will be used in this script.'
    # sudo ls >/dev/null

    if [[ $USER != *"$USER_PREFIX"* ]]; then
        echo "Enter Rocketpool user to remove (e.g. ${USER_PREFIX}123)"
        read -r answer
        if [[ -n $answer ]]; then
            TMP_USER=$(getent passwd | grep "$answer" | cut -d: -f1)
            if [[ -z $TMP_USER ]]; then
                echo "User $answer not found. EXIT"
                return
            else
                log "Rolling back by removing $TMP_USER"
                passwd --lock "$TMP_USER"
                sudo killall -9 -u "$TMP_USER"
                sudo deluser --remove-home -r "$TMP_USER"
                log "Rollback complete"
            fi
        fi
    else
        echo 'uninstall Dropbox'
        dropbox stop
        dropbox status  # Should report "not running"
        rm -rf "$HOME/.dropbox-dist"
        rm -rf /var/lib/dropbox
        rm -rf "$HOME/.dropbox*"
        sudo apt-get remove nautilus-dropbox
        sudo apt-get remove dropbox
        rm /etc/apt/source.d/dropbox
        rm -rv "$HOME/Dropbox"
        
        echo 'Roll back changes to sshd_config'
        sudo cp /etc/ssh/sshd_config.orig /etc/ssh/sshd_config
        echo 'Roll back changes to sshd_config'
        sudo cp /etc/pam.d/sshd.orig /etc/pam.d/sshd
        echo 'Restart ssh'
        sudo systemctl restart ssh

        echo '*** Logoff and rerun as root user.'
    fi
else
    return
fi

Cleanup