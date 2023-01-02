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
Usage: pause-2fa [OPTIONS]...
Pause Two Factor Authentication. This is typically used when calling rsync.

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

echo 'Press ENTER when ready to DISable 2FA.'
read -r junk
junk=
sudo cp /etc/ssh/sshd_config.orig /etc/ssh/sshd_config && sudo cp /etc/pam.d/sshd.orig /etc/pam.d/sshd && sudo systemctl restart ssh
echo '2FA is paused.'

# echo -e $(date) 'Start rsync to 1.1.1.1.'>>rp-install-rsync.log && sudo rsync --progress -av $HOME/backup rpuser1234@1.1.1.1:$HOME/ && echo -e $(date) 'rsync to 1.1.1.1 finished.'>>rp-install-rsync.log && scp rp-install-rsync.log rpuser1234@1.1.1.1:$HOME/ && echo 'FINISHED.'
echo 'Run do-rsync.sh on other server.'

echo ''
echo 'Press ENTER when ready to ENable 2FA.'
read -r junk
junk=
sudo cp /etc/ssh/sshd_config.updated /etc/ssh/sshd_config && sudo cp /etc/pam.d/sshd.updated /etc/pam.d/sshd && sudo systemctl restart ssh
echo '2FA is enabled.'


appendLog=false
answer=
echo "Append rsync log to log file (y/n)?"
read -r answer
if [[ $answer != 'n' ]]; then
    echo "Appending $RSYNC_LOG_FILE to $LOG_FILE"
    cat "$RSYNC_LOG_FILE" >> "$LOG_FILE"
fi

Cleanup