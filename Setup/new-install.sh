#!/bin/bash

# https://docs.rocketpool.net/guides/node/securing-your-node
# https://docs.rocketpool.net/guides/node/securing-your-node#creating-an-ssh-key-pair
# https://docs.rocketpool.net/guides/node/installing/overview

if [[ -f "common-rpl.sh" ]]; then source common-rpl.sh; elif [[ -f "../Common/common-rpl.sh" ]]; then source ../Common/common-rpl.sh; elif [[ -f "../common-rpl.sh" ]]; then source ../common-rpl.sh; else echo "Failed to load common-rpl.sh"; return 0; fi

# curl https://ipinfo.io/ip

#Define the string value
# DEBUG=true
defaults=true
prompt=true

# handle command line options
# check for verbose first so it is used with the other parameters
if [[ $1 == "-v" || $1 == "--verbose" ||
    $2 == "-v" || $2 == "--verbose" ||
    $3 == "-v" || $3 == "--verbose" ||
    $4 == "-v" || $4 == "--verbose" ]]; then
    echo "verbose on"
    verbose=true
fi
if [[ $1 == "-d" || $1 == "--defaults" ||
    $2 == "-d" || $2 == "--defaults" ||
    $3 == "-d" || $3 == "--defaults" ||
    $4 == "-d" || $4 == "--defaults" ]]; then
    echo "use defaults"
    prompt=false
else
    # Set variables from config file if defaults override was not passed
    echo "reading config file"
    setVariablesFromConfigFile "new-install.yml"
    prompt=false
fi
if [[ $1 == "-p" || $1 == "--prompt" ||
    $2 == "-p" || $2 == "--prompt" ||
    $3 == "-p" || $3 == "--prompt" ||
    $4 == "-p" || $4 == "--prompt" ]]; then
    # echo "prompt"
    prompt=true
fi
if [[ $1 == "-h" || $1 == "--help" || 
    $2 == "-h" || $2 == "--help" || 
    $3 == "-h" || $3 == "--help" || 
    $4 == "-h" || $4 == "--help" ]]; then
    cat << EOF
Usage: new-install [OPTIONS]...
Configures a new Ubuntu server and installs RocketPool. This script picks up where it left off, including during reboots.

    Option                     Meaning
    -d|--defaults              Install using defaults
    -h|--help                  Displays this help and exit
    -p|--prompt                Prompt for each option instead of using defaults
    -v|--verbose               Displays verbose output
EOF
    return
fi
if [[ $1 == "-t" || $1 == "--test" ||
    $2 == "-t" || $2 == "--test" ||
    $3 == "-t" || $3 == "--test" ||
    $4 == "-t" || $4 == "--test" ]]; then
    echoVariables
    return
fi

# 10. Prepare Ubuntu as root user
# 20. Finish preparting Ubuntu and download Rocketpool as non-root user
# 30. Install and config Rocketpool as non-root user
# 35. Start Rocketpool after first installation
# 37. Install and config Hyperdrive
# 40. Wait for eth1 to sync
# 44. Create Rocketpool Wallet
# 46. Wait for eth2 to sync
# 50. Finish Rocketpool installation as non-root user
# 60. Optional - Recover Rocketpool as non-root user
# 100. Node is active

# shout() { echo "$0: $*" >&2; }
# die() { shout "${@:2} ($1)"; return $1; } # return instead of exit so terminal is not closed
# try() { "$@" || die $? "cannot $*"; }

determine_step() {
    debug_enter_function
    step=0
    if [[ $USER != *"$USER_PREFIX"* ]]; then
        step=10
        # echo '  10. Prepare Ubuntu as root user'
    else
        if [[ ! -f $RP_INSTALL_FILE ]]; then
            step=20
            # echo '  20. Finish preparing Ubuntu and download Rocketpool as non-root user'
        else
            if [[ ! -d $RP_DIR ]]; then
                step=30
                # echo '  30. Install and config Rocketpool as non-root user'
            else
                serviceVersion=$(rocketpool service version)
                if [[ $serviceVersion == *"Could not get"* ]]; then 
                    step=35
                else
                    hyperdriveVersion=$(hyperdrive -v)
                    if [[ $hyperdriveVersion == *"command not found"* ]]; then 
                        step=37
                        log 'Hyperdrive not installed.'
                    else
                        syncStatus=$(rocketpool node sync)
                        if [[ ! $syncStatus == *"primary execution client is fully synced"* ]]; then 
                            step=40
                            log 'Primary execution client is fully synced.'
                            # 40. Wait for eth1 to sync
                        else
                            walletStatus=$(rocketpool wallet status)
                            if [[ ! $walletStatus == *"node wallet is initialized"* ]]; then
                                step=44
                                # 44. Create Rocketpool Wallet
                            else
                                #syncStatus=$(rocketpool node sync) # already run above
                                if [[ ! $syncStatus == *"consensus client is fully synced"* ]]; then
                                    step=46
                                    log 'Primary consensus client is fully synced.'
                                    # 46. Wait for eth2 to sync
                                else
                                    nodeStatus=$(rocketpool node status)
                                    if [[ $nodeStatus == *"The node is not registered with Rocket Pool"* ]]; then
                                        step=50
                                        # echo '  50. Finish Rocketpool installation as non-root user'
                                    elif [[ $nodeStatus == *"The node has a total of "*" active minipool(s)"* ]]; then
                                        step=100
                                        # 100. Node is active
                                    else
                                        step=0
                                        # minipoolStatus=$(rocketpool minipool status)
                                        # if [[ $minipoolStatus == *"! finalized minipool(s)"* ]]; then
                                        #     step=60
                                        #     # echo '  60. Optional - Recover Rocketpool as non-root user'
                                        # else
                                        #     step=UNKNOWN
                                        # fi
                                    fi
                                fi
                            fi
                        fi
                    fi
                fi
            fi
        fi
    fi

    log 'Step '$step
    debug_leave_function
    return $step
}

prepare_as_root_user() {
    debug_enter_function
    echo '******************'
    echo 'Root user - change password and create non-root user'
    echo '******************'

    # use sudo command to prompt for password if necessary so we don't prompt after starting the Rocketpool installation.
    echo 'Prompt for sudo since it will be used in this script.'
    sudo ls >/dev/null

    answer=
    echo "Enter new hostname (leave blank to skip)"
    read -r answer
    if [[ ! -z $answer ]]; then
        sudo hostnamectl set-hostname $answer
    fi

    if [[ $prompt == true ]]; then
        CHANGE_ROOTPASSWORD=false
        answer=
        echo 'Change Root Password (y/n)?'
        read -r answer
        if [[ $answer == 'y' ]]; then
            CHANGE_ROOTPASSWORD=true
        fi

        CREATE_NONROOTUSER=false
        answer=
        echo 'Create Non-root User (y/n)?'
        read -r answer
        if [[ $answer == 'y' ]]; then
            CREATE_NONROOTUSER=true
        fi

        ENABLE_FIREWALL=false
        answer=
        echo 'Enable firewall (y/n)?'
        read -r answer
        if [[ $answer == 'y' ]]; then
            ENABLE_FIREWALL=true
        fi

        ENABLE_FALLBACK=false
        answer=
        echo 'Is this a Fallback client and needs ports open (y/n)?'
        read -r answer
        if [[ $answer == 'y' ]]; then
            ENABLE_FALLBACK=true
        fi

        PREVENT_DOSATTACK=false
        answer=
        echo 'Prevent DOS  (y/n)?'
        read -r answer
        if [[ $answer == 'y' ]]; then
            PREVENT_DOSATTACK=true
        fi

        MODIFY_AUTOUPGRADE=false
        answer=
        echo 'Modify 20auto-upgrade (y/n)?'
        read -r answer
        if [[ $answer == 'y' ]]; then
            MODIFY_AUTOUPGRADE=true
        fi

        CREATE_SWAPFILE=false
        answer=
        echo 'Create Swap File  (y/n)?'
        read -r answer
        if [[ $answer == 'y' ]]; then
            CREATE_SWAPFILE=true
        fi

        INSTALL_TAILSCALE=false
        answer=
        echo 'Install Tailscale (y/n)?'
        read -r answer
        if [[ $answer == 'y' ]]; then
            INSTALL_TAILSCALE=true
        fi
    fi

    if [[ $CHANGE_ROOTPASSWORD == true ]]; then
        echo "   Changing $USER password. Consider disabling it: sudo passwd --delete --lock $USER"
        echo "   Suggested Generated Password: $(openssl rand -base64 25)"
        sudo passwd "$USER"
        log "$USER password changed."
    fi

    if [[ $CREATE_NONROOTUSER == true ]]; then
        echo '   Add user'
        TMP_USER=${USER_PREFIX}${RANDOM}
        # tmpPassword=$(openssl rand -base64 25)
        echo "   Generated Password for $TMP_USER: $(openssl rand -base64 25)"
        sudo useradd -d "/home/$TMP_USER" -m -s/bin/bash "$TMP_USER"
        sudo passwd "$TMP_USER"
        sudo adduser "$TMP_USER" sudo
        # sudo useradd -m $TMP_USER -p $tmpPassword
        #try $(sudo useradd $TMP_USER -p $(openssl rand -base64 25))
        #try $(sudo useradd -d /home/$TMP_USER $TMP_USER)
        # echo "   User $TMP_USER created with password: "$tmpPassword
        # tmpPassword=""
        #echo '   Suggested Generated Password: '$(openssl rand -base64 25)
        #try $(sudo passwd $TMP_USER)
        # sudo usermod -aG sudo $TMP_USER
        # echo '   Press ENTER when ready to continue.'
        # read -r junk
        # junk=
        log "non-root user created."
    fi

    if [[ $INSTALL_TAILSCALE == true ]]; then
        echo '   Install Tailscale'
        curl -fsSL https://tailscale.com/install.sh | sh
        sudo tailscale up --ssh
        echo '   '
        echo '' && echo '   Press ENTER you have registered the server and disable key expiry.'
        read -r junk
        log "Tailscale installed"
    fi

    # FIREWALL and DOS must be done as root
    if [[ $ENABLE_FIREWALL == true ]]; then
        # sudo ufw verbose
        echo '   Enable Firewall'
        # Disallow by default
        sudo ufw default deny incoming comment 'deny all incoming traffic'

        # Allow Rocketpool ports
        # configure_firewall

        # if [[ $ENABLE_FALLBACK == true ]]; then
        #     configure_firewall_for_fallback
        # fi

        if [[ $INSTALL_TAILSCALE == true ]]; then
            sudo ufw allow in on tailscale0
        else
            # If not using Tailscale then allow ssh traffic
            sudo ufw allow "$SSH_PORT/tcp" comment 'Allow ssh on custom port'
        fi

        sudo ufw --force enable
        sudo ufw status verbose
        log "Firewall rules enabled"
    fi

    if [[ $PREVENT_DOSATTACK == true ]]; then
        echo '   Prevent DOS Attack'
        ################################
        # Autoban failed attempts & DDOS
        # https://github.com/imthenachoman/How-To-Secure-A-Linux-Server#application-intrusion-detection-and-prevention-with-fail2ban
        ################################
        sudo apt install -y fail2ban
        echo -e "
        [sshd]
        enabled = true
        banaction = ufw
        port = $SSH_PORT
        filter = sshd
        logpath = %(sshd_log)s
        maxretry = 5
        " > ./ssh.local
        sudo mv ./ssh.local /etc/fail2ban/jail.d/ssh.local

        # Restart service
        sudo systemctl restart fail2ban
        log "Prevent DOS Attack added"
    fi

    if [[ $SSH_PORT -ne 22 && $INSTALL_TAILSCALE != true ]]; then
        # update SSH_PORT
        sudo sed -i "/Port/s/22/$SSH_PORT/g" /etc/ssh/sshd_config
        sudo sed -i '/Port/s/^#//g' /etc/ssh/sshd_config
        echo "SSH Port updated to $SSH_PORT"

        echo "restarting ssh"
        sudo systemctl restart ssh
        log "ssh restarted."
    fi

    if [[ $MODIFY_AUTOUPGRADE == true ]]; then
        echo '   Enable Auto Update'
        sudo apt update && sudo apt install -y unattended-upgrades update-notifier-common
        echo -e "
        APT::Periodic::Update-Package-Lists \"1\";
        APT::Periodic::Unattended-Upgrade \"1\";
        APT::Periodic::AutocleanInterval \"7\";
        Unattended-Upgrade::Remove-Unused-Dependencies \"true\";
        Unattended-Upgrade::Remove-New-Unused-Dependencies \"true\";
        # This is the most important choice: do you want to auto-reboot. This should be fine since Rocketpool auto-starts on reboot, but if you are using a custom setup you may not want this
        Unattended-Upgrade::Automatic-Reboot \"true\";
        Unattended-Upgrade::Automatic-Reboot-Time \"02:00\";
        " > ./20auto-upgrades
        sudo mv ./20auto-upgrades /etc/apt/apt.conf.d/20auto-upgrades

        # Load the new settings
        sudo systemctl restart unattended-upgrades
        log "Auto Upgrade enabled"
    fi

    if [[ $CREATE_SWAPFILE == true ]]; then
        # Create swapfile if it does not already exist
        if [ ! -f "/swapfile" ]; then
            echo '   Create Swap File'
            sudo dd if=/dev/zero of=/swapfile bs=1G count=16 status=progress
            sudo chmod 600 /swapfile
            sudo mkswap /swapfile
            sudo swapon /swapfile
            # Append line if it is not there
            if ! grep -q "swapfile" /etc/fstab; then 
                sudo sed -i -e '$a/swapfile                            none            swap    sw              0       0' /etc/fstab
            fi
            if ! grep -q "swapfile" /etc/fstab; then echo 'ERROR: Failed to append /swapfile to /etc/fstab'; fi

            # sudo apt install htop
            # htop

            sudo sysctl vm.swappiness=6
            sudo sysctl vm.vfs_cache_pressure=10
            # Append line if it is not there
            if ! grep -q "vm.swappiness" /etc/sysctl.conf; then 
                sudo sed -i -e '$avm.swappiness=6' /etc/sysctl.conf
            fi
            if ! grep -q "vm.swappiness" /etc/sysctl.conf; then 'echo ERROR: Failed to append vm.swappiness to /etc/sysctl.conf'; fi
            # Append line if it is not there
            if ! grep -q "vm.vfs_cache_pressure" /etc/sysctl.conf; then 
                sudo sed -i -e '$avm.vfs_cache_pressure=10' /etc/sysctl.conf
            fi
            if ! grep -q "vm.vfs_cache_pressure" /etc/sysctl.conf; then 'ERROR: Failed to append vm.vfs_cache_pressure to /etc/sysctl.conf'; fi

            # Load the new settings
            log "Swap File created"
        fi
    fi

    # copy log file from root if it doesn't exist so we have a complete log with timestamps
    TMP_USER_HOME=$(getent passwd "$TMP_USER" | cut -d: -f6)
    TMP_USER_LOG="$TMP_USER_HOME/$(basename $LOG_FILE)"
    if sudo [ ! -f "$TMP_USER_LOG" ]; then
        log "Copying log file to non-root user."
        sudo cp "$LOG_FILE" "$TMP_USER_HOME"
        sudo chown "$TMP_USER" "$TMP_USER_LOG"
        log "Log file copied from $USER."
        if sudo [ ! -f "$TMP_USER_LOG" ]; then
            echo "WARNING: Copy log failed."
        fi
    fi

    echo ''
    echo ''
    echo '   Logoff and log in as non-root user.'
    debug_leave_function
}

prepare_as_non-root_user() {
    debug_enter_function
    echo '******************'
    echo 'Non-root user'
    echo '******************'

    curl https://ipinfo.io/ip

    # use sudo command to prompt for password if necessary so we don't prompt after staring the Rocketpool installation.
    echo 'Prompt for sudo since it will be used in this script.'
    sudo ls >/dev/null

    if [[ $prompt == true ]]; then
        CONFIG_FIREWALL=false
        answer=
        echo 'Configure firewall for Rocketpool (y/n)?'
        read -r answer
        if [[ $answer == 'y' ]]; then
            CONFIG_FIREWALL=true
        fi

        ENABLE_FALLBACK=false
        answer=
        echo 'Is this a Fallback client and needs ports open (y/n)?'
        read -r answer
        if [[ $answer == 'y' ]]; then
            ENABLE_FALLBACK=true
        fi

        ENABLE_AUTHENTICATION=false
        answer=
        echo 'Enable Two Factor Authentication (y/n)?'
        read -r answer
        if [[ $answer == 'y' ]]; then
            ENABLE_AUTHENTICATION=true
        fi

        ADD_ALIASES=false
        answer=
        echo 'Add Aliases (y/n)?'
        read -r answer
        if [[ $answer == 'y' ]]; then
            ADD_ALIASES=true
        fi

        INSTALL_JQ=false
        answer=
        echo 'Install jq package (y/n)?'
        read -r answer
        if [[ $answer == 'y' ]]; then
            INSTALL_JQ=true
        fi

        INSTALL_ROCKETPOOL=false
        answer=
        echo 'Install Rocketpool (y/n)?'
        read -r answer
        if [[ $answer == 'y' ]]; then
            INSTALL_ROCKETPOOL=true
        fi

        INSTALL_DROPBOX=false
        answer=
        echo 'Install Dropbox (y/n)?'
        read -r answer
        if [[ $answer == 'y' ]]; then
            INSTALL_DROPBOX=true
        fi

        RESTORE_ETH1_BACKUP=false
        answer=
        echo 'Restore ETH1 from backup from other server (y/n)?'
        read -r answer
        if [[ $answer == 'y' ]]; then
            RESTORE_ETH1_BACKUP=true
        fi
    fi

    # # Always prompt early to start copying files from other server, even if we end up using Dropbox instead.
    # if [[ $RESTORE_ETH1_BACKUP == true ]]; then
    #     get_eth1_backup_from_other_server
    # fi

    if [[ $CONFIG_FIREWALL == true ]]; then
        # sudo ufw verbose
        echo '   Config Firewall'

        # Allow Rocketpool ports
        configure_firewall

        if [[ $ENABLE_FALLBACK == true ]]; then
            configure_firewall_for_fallback
        fi

        sudo ufw --force enable
        sudo ufw status verbose
        log "Firewall rules configured"
    fi

    if [[ $INSTALL_DROPBOX == true ]]; then
        install_dropbox
        if [[ $RESTORE_ETH1_BACKUP == true ]]; then
            get_eth1_backup_from_dropbox
        fi
    fi

    # generate rsa in case we need to rsync files from this server
    echo "Generate rsa in case we need to rsync files from this server."
    # ssh-keygen -t rsa -f $HOME/.ssh/id_rsa -q -N "" 
    ssh-keygen -t ed25519 -C "$(hostname -i | awk '{print $2}')" -f "$HOME/.ssh/id_ed25519" -q -N ""
    cat "$HOME/.ssh/id_ed25519.pub"

    if [[ $ADD_ALIASES == true ]]; then
        if ! grep -Fq "alias rpl=" .bashrc; then
            echo '   Adding Rocketpool Aliases.'
            cp "$HOME/.bashrc" "$HOME/.bashrc.bak"
            echo -e "
            # Rocketpool aliases
            alias rpl='rocketpool'
            alias rplrestart='date && rocketpool service stop && rocketpool service start && date'
            " >> "$HOME/.bashrc"
        fi
        log "Aliases added."
    fi

    if [[ $INSTALL_JQ == true ]]; then
        sudo apt install -y jq
        log "jq installed."
    fi

    if [[ $INSTALL_ROCKETPOOL == true ]]; then
        echo '   Download Rocketpool.'
        mkdir -p "$HOME/bin"
        wget https://github.com/rocket-pool/smartnode-install/releases/latest/download/rocketpool-cli-linux-amd64 -O "$HOME/bin/rocketpool"
        #wget https://github.com/rocket-pool/smartnode-install/releases/download/v1.0.0-rc8/rocketpool-cli-linux-amd64 -O $HOME/bin/rocketpool
        chmod +x "$HOME/bin/rocketpool"

        # MUST LOG OFF AND BACK ON TO INSTALL ROCKETPOOL
        # echo '' && echo '   You must open a new terminal to continue. Exiting script.'
        log "Rocketpool downloaded."
        # return
    fi

    if [[ $ENABLE_AUTHENTICATION == true ]]; then
        enable_authentication
    fi

    debug_leave_function
}

configure_firewall() {
    # Allow specific ports for Rocketpool client
    # Go Ethereum: https://geth.ethereum.org/docs/interface/private-network#setting-up-networking
    echo 'Allowing specific ports for Rocketpool and Ethereum...'
    
    sudo ufw allow "$EXECUTION_CLIENT_PORT/tcp" comment 'Execution client port, standardized by Rocket Pool'
    sudo ufw allow "$EXECUTION_CLIENT_PORT/udp" comment 'Execution client port, standardized by Rocket Pool'
    sudo ufw allow "$CONSENSUS_CLIENT_PORT/tcp" comment 'Consensus client port, standardized by Rocket Pool'
    sudo ufw allow "$CONSENSUS_CLIENT_PORT/udp" comment 'Consensus client port, standardized by Rocket Pool'
    sudo ufw allow "$ETH_API_PORT/tcp" comment 'Ethereum API port'
    sudo ufw allow "$PRYSM_ETH_API_PORT/tcp" comment 'Ethereum API port used by Prysm'
}

configure_firewall_for_fallback() {
    # Allow specific ports for Rocketpool fallback client
    echo 'Allowing specific ports for Rocketpool and Ethereum...'

    sudo ufw allow "$EXECUTION_CLIENT_PORT/tcp" comment 'Execution client port, standardized by Rocket Pool'
    sudo ufw allow "$EXECUTION_CLIENT_PORT/udp" comment 'Execution client port, standardized by Rocket Pool'
    sudo ufw allow "$CONSENSUS_CLIENT_PORT/tcp" comment 'Consensus client port, standardized by Rocket Pool'
    sudo ufw allow "$CONSENSUS_CLIENT_PORT/udp" comment 'Consensus client port, standardized by Rocket Pool'
    sudo ufw allow "$ETH_API_PORT/tcp" comment 'Ethereum API port'
    sudo ufw allow "$PRYSM_ETH_API_PORT/tcp" comment 'Ethereum API port used by Prysm'
}

enable_authentication() {
    debug_enter_function
    echo '' && echo '   Install Authentication'
    sudo apt-get -y install libpam-google-authenticator
    echo '' && echo '   Press ENTER when ready to run google-authenticator and add to your mobile. You many need to zoom out for QR.'
    read -r junk
    junk=
    google-authenticator --no-confirm --time-based --force --disallow-reuse --window-size=17 --rate-limit=3 --rate-time=30
    # google-authenticator
    if [ ! -f "$HOME/.google_authenticator.orig" ]; then
        sudo cp "$HOME/.google_authenticator" "$HOME/.google_authenticator.orig"
    fi
    log "google-authenticator installed and enabled."

    # https://docs.microsoft.com/en-us/windows-server/administration/openssh/openssh_keymanagement
    echo '   Update ssh Authorized Keys'
    mkdir -p "$HOME/.ssh" && touch "$HOME/.ssh/authorized_keys" && chmod -R go= "$HOME/.ssh"
    echo '' && echo "   From Windows, run: scp \"%USERPROFILE%/.ssh/\"id_rsa.pub $USER@$(hostname -i | awk '{print $2}'):$HOME/.ssh/authorized_keys" && echo ''
    echo '   Press ENTER when done (note: script will verify before proceeding).'
    read -r junk
    junk=
    # filesize=$(ls -lh $HOME/.ssh/authorized_keys | awk '{print  $5}')
    filesize=$(wc -c "$HOME/.ssh/authorized_keys" | awk '{print $1}')
    if [[ ! $filesize -gt 0 ]]; then
        echo "Authorized Keys must be populated to log in."
        echo "Press ENTER to modify manually. Copy from %USERPROFILE%/.ssh/id_rsa.pub"
        read -r junk
        junk=
        nano "$HOME/.ssh/authorized_keys"
    fi
    log "ssh Authorized Keys updated."

    echo '   Updating security settings in sshd_config.'
    if [ ! -f /etc/ssh/sshd_config.orig ]; then
        sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.orig
    fi
    # sudo awk '
    # $1=="PermitRootLogin" {$2="prohibit-password"}
    # $1=="PasswordAuthentication" {$2="yes"}
    # $1=="ChallengeResponseAuthentication" {$2="yes"}
    # $1=="UsePAM" {$2="yes"}
    # {print}
    # ' /etc/ssh/sshd_config.bak > /etc/ssh/sshd_config

    sudo sed -i '/PermitRootLogin/s/yes/prohibit-password/g' /etc/ssh/sshd_config
    sudo sed -i '/PermitRootLogin prohibit-password/s/^#//g' /etc/ssh/sshd_config

    sudo sed -i '/PasswordAuthentication/s/yes/no/g' /etc/ssh/sshd_config
    sudo sed -i '/PasswordAuthentication no/s/^#//g' /etc/ssh/sshd_config
 
    sudo sed -i '/ChallengeResponseAuthentication/s/no/yes/g' /etc/ssh/sshd_config
    sudo sed -i '/ChallengeResponseAuthentication yes/s/^#//g' /etc/ssh/sshd_config
    # Append line if it is not there
    if ! grep -q "ChallengeResponseAuthentication" /etc/ssh/sshd_config; then 
        sudo sed -i -e '$aChallengeResponseAuthentication yes' /etc/ssh/sshd_config
    fi

    sudo sed -i '/UsePAM/s/no/yes/g' /etc/ssh/sshd_config
    sudo sed -i '/UsePAM yes/s/^#//g' /etc/ssh/sshd_config

    sudo sed -i '/AuthorizedKeysFile/s/^#//g' /etc/ssh/sshd_config

    sudo sed -i '/KbdInteractiveAuthentication no/s/^Kbd/#Kbd/g' /etc/ssh/sshd_config

    # Append line if it is not there
    if ! grep -q "AuthenticationMethods publickey" /etc/ssh/sshd_config; then 
        sudo sed -i -e '$aAuthenticationMethods publickey,keyboard-interactive' /etc/ssh/sshd_config
    fi

    log "sshd_config security settings updated."

    # echo "Summary of changes that should have been made (using grep):"
    # cat /etc/ssh/sshd_config | grep "PermitRootLogin\|PasswordAuthentication\|ChallengeResponseAuthentication\|UsePAM\|AuthorizedKeysFile\|AuthenticationMethods"

    # echo '   Press ENTER when ready to modify sshd_config. MAKE THE FOLLOWING CHANGES:'
    # echo '      PermitRootLogin prohibit-password'
    # echo '      AuthorizedKeysFile .ssh/authorized_keys'
    # echo '      PasswordAuthentication no'
    # echo '      (Insert the following line) AuthenticationMethods publickey,keyboard-interactive'
    # echo '      ChallengeResponseAuthentication yes'
    # echo '      UsePAM yes'
    # read -r junk
    # junk=
    # sudo nano /etc/ssh/sshd_config

    sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.updated


    echo '   Updating security settings in sshd.'
    if [ ! -f /etc/pam.d/sshd.orig ]; then
        sudo cp /etc/pam.d/sshd /etc/pam.d/sshd.orig
    fi

    sudo sed -i '/@include common-auth/s/^/#/g' /etc/pam.d/sshd

    # Insert line if it is not there
    if ! grep -q "auth required pam_google_authenticator.so" /etc/pam.d/sshd; then 
        sudo sed -i '/#@include common-auth/a # Enable Google Authenticator' /etc/pam.d/sshd
        sudo sed -i '/# Enable Google Authenticator/a auth required pam_google_authenticator.so' /etc/pam.d/sshd
    fi

    # sudo sed -i -e '$a# Enable Google Authenticator\rauth required pam_google_authenticator.so' /etc/pam.d/sshd
    # sudo echo -e "
    # auth required pam_google_authenticator.so'
    # " >> /etc/pam.d/sshd

    log "sshd security settings updated."

    # echo "Summary of changes that should have been made (using grep):"
    # cat /etc/pam.d/sshd | grep "@include common-auth\|auth required pam_google_authenticator.so"

    # echo '   Press ENTER when ready to modify sshd. MAKE THE FOLLOWING CHANGES:'
    # echo '      comment out @include common-auth'
    # echo '      (Insert the following line) auth required pam_google_authenticator.so'
    # read -r junk
    # junk=
    # sudo nano /etc/pam.d/sshd

    sudo cp /etc/pam.d/sshd /etc/pam.d/sshd.updated

    # start ssh so changes are active
    # echo '   *********************'
    echo '   Restarting SSH will block rsync.'
    # echo '   *********************'
    # read -r junk
    # junk=
    sudo systemctl restart ssh
    log "ssh restarted."

    # https://tightvnc.org/
    echo ''
    echo '   VERIFY!!!! Log in another terminal to SSH does not prompt for password and 2FA is working. Exit this terminal and proceed on the new one.'
    # read -r junk
    # junk=

    log "ssh verified on another terminal."
    debug_leave_function
}

install_rocketpool() {
    debug_enter_function
    echo '   Start the Rocketpool Installation.'

    # use sudo command to prompt for password if necessary so we don't prompt after staring the Rocketpool installation.
    echo 'Prompt for sudo since it will be used in this script.'
    sudo ls >/dev/null

# Rocketpool installation now uses the UI, which prompts for network to use
    # INSTALL_ROCKETPOOL_MAINNET=false
    # answer=
    # echo 'Install Rocketpool MAINNET (y/n)?'
    # read -r answer
    # if [[ $answer == 'y' ]]; then
    #     INSTALL_ROCKETPOOL_MAINNET=true
    # fi

    # INSTALL_ROCKETPOOL_TESTNET=false
    # answer=
    # echo 'Install Rocketpool TESTNET (y/n)?'
    # read -r answer
    # if [[ $answer == 'y' ]]; then
    #     INSTALL_ROCKETPOOL_TESTNET=true
    # fi

    if [[ $prompt == true ]]; then
        REBOOT_DURING_RPL_INSTALL=false
        answer=
        echo 'Reboot During Rocketpool Install (y/n)?'
        read -r answer
        if [[ $answer == 'y' ]]; then
            REBOOT_DURING_RPL_INSTALL=true
        fi
    fi

    echo '' && echo '  Install Rocketpool.'

    rocketpool service install -y
    sudo usermod -aG docker "$USER"
    log "Rocketpool installed but not configured."

    echo '   Optional: Upload Rocketpool Config file. Press ENTER to continue.'
    read -r junk
    junk=

    echo ''
    echo '   Note: If you are using non-standard ports, make sure they are correct in Rocketpool config. Press ENTER to continue.'
    echo '   CheckPoint Sync Urls: MAINNET: https://beaconstate.info'
    echo '   CheckPoint Sync Urls: HOLESKY: https://holesky.beaconstate.info'
    echo ''
    
    echo '' && echo '  Configure Rocketpool. YOU MUST CLICK SAVE even if the config file was copied.' && echo ''
    rocketpool service config
    log "Rocketpool configured."

    if [[ $REBOOT_DURING_RPL_INSTALL == true ]]; then
        echo '   Press ENTER to reboot to finish Rocketpool installation. If rsync is running, it will need to be restarted.'
        read -r junk
        junk=
        log "Rebooting after Rocketpool installed and configured."
        sudo reboot
        echo '...sleep 90 seconds to allow for reboot'
        sleep 90
        return
    else
        echo '   You must open a new terminal to continue. Exiting script.'
        log "NO reboot after Rocketpool installed and configured."
    fi

    serviceVersion=$(rocketpool service version)
    if [[ $serviceVersion == *"Could not get"* ]]; then 
        echo '' && echo '*** You must start a new shell session by logging out and back in.'
    else
        start_rocketpool
        log "Rocketpool started."
    fi
    debug_leave_function
}

start_rocketpool() {
    debug_enter_function
    echo '' && echo '   Start Rocketpool Service.'
    rocketpool service start -y --ignore-slash-timer

    echo '   Verify Rocketpool versions.'
    rocketpool service version

    echo '' && echo '   Check docker STATUS column to ensure they do not say restarting.'
    docker ps

    echo '' && echo '   Verify rocketpool version and docker status. Then Wait for primary execution client to sync and run again.'

    log "Rocketpool running."
    debug_leave_function
}

stop_rocketpool() {
    debug_enter_function
    echo '' && echo '   Stop Rocketpool Service.'
    rocketpool service stop -y
    log "Rocketpool stopped."
    debug_leave_function
}

# wait_for_rocketpool_sync () {
#     echo '   Try again once both clients are synced.'
#     rocketpool node sync
# }

wait_for_eth1_sync() {
    debug_enter_function
    echo '   Try again once primary execution client is synced.'
    nodeStatus=$(rocketpool node sync)
    if [[ $nodeStatus == *"primary execution client is still syncing"* ]]; then
        date && rocketpool node sync
    fi
    debug_leave_function
}

wait_for_eth2_sync() {
    debug_enter_function
    echo '   Try again once consensus client is synced.'
    nodeStatus=$(rocketpool node sync)
    if [[ $nodeStatus == *"primary consensus client is still syncing"* ]]; then
        date && rocketpool node sync
    else
        nodeStatus=$(rocketpool node status)
        if [[ $nodeStatus == *"has a balance of 0.000000 ETH and 0.000000 RPL"* ]]; then
            echo '' && echo '   Load Wallet manually while waiting for consensus client to sync.'
        fi
    fi
    debug_leave_function
}

create_rocketpool_wallet() {
    debug_enter_function
    echo '   Initialize Wallet.'
    echo "   Suggested Generated Password: $(openssl rand -base64 25)"
    rocketpool wallet init
    log "Rocketpool Wallet created."

    echo '' && echo '   Load Wallet manually while waiting for consensus client to sync.'
    debug_leave_function
}

opt_in_to_smoothing_pool() {
    debug_enter_function
    # must be done after syncing
    echo '   Opt-in to Smoothing Pool.'
    rocketpool node join-smoothing-pool
    log "Rocketpool joined smoothing pool finished."

    debug_leave_function
}

finish_rocketpool_installation() {
    debug_enter_function
    echo '' && echo '   Final steps.'
    echo '   Register Node. Press ENTER to register Rocketpool node.'
    read -r junk
    junk=
    rocketpool node register -t "$TIMEZONE"
    log "Rocketpool node register started."

    nodeStatus=$(rocketpool node status)
    if [[ $nodeStatus == *"The node is not registered with Rocket Pool"* ]]; then
        echo '' && echo '***************' && echo 'ERROR: NODE WAS NOT REGISTERED' && echo '***************'
        answer=
        echo 'Continue (y/n)?'
        read -r answer
        if [[ ! $answer == 'y' ]]; then
            echo 'Exiting.'
            return
        fi
    fi
    log "Rocketpool node register finished."

    answer=
    echo "   Press ENTER after manually setting Withdrawal Address. Run 'rocketpool node set-withdrawal-address <your cold wallet address>'."
    read -r answer
    if [[ -z $answer ]]; then
        answer=
        echo 'Are you sure you want to continue WITHOUT changing the withdrawal address (y/n)?'
        read -r answer
        if [[ $answer == 'y' ]]; then
            echo 'okay, proceeding.'
        else
            echo "   Press ENTER after manually setting Withdrawal Address. Run 'rocketpool node set-withdrawal-address <your cold wallet address>'."
            read -r answer
            if [[ -z $answer ]]; then
                echo 'You are messed up now and will have to proceed on your own. You need to 1) swap rpl; 2) stake; 3) deposit; -- good luck!'
                read -r junk
                junk=
            else
                rocketpool node set-withdrawal-address "$answer"
                log "Rocketpool withdrawal address set."
                answer=
            fi
        fi
    else
        rocketpool node set-withdrawal-address "$answer"
        log "Rocketpool withdrawal address set."
        answer=
    fi
    answer= # clear wallet address
    
    
    echo '   Swap RPL v1 for v2.'
    rocketpool node swap-rpl
    log "Rocketpool swap-rpl finished."

    #echo '   Create minipool.'

    echo '   Stake rpl.'
    rocketpool node stake-rpl
    log "Rocketpool stake-rpl finished."

    echo '   Depositing ETH.'
    rocketpool node deposit
    log "Rocketpool node deposit finished."

    echo '   Confirm Successful Stake.'
    rocketpool minipool status
    log "Rocketpool minipool created."

    echo '   Join Smoothing.'
    opt_in_to_smoothing_pool
    
    echo '' && echo '' && echo '********************** IS THE INSTALLATION COMPLETE?????? *********' && echo '' && echo ''

    echo '   May need to reboot to ensure everything is clean???'
    debug_leave_function
}

recover_rocketpool() {
    debug_enter_function
    echo '   Recover Node.'

    # RECOVER_ROCKETPOOL=false
    # answer=
    # echo 'Recover Rocketpool (y/n)?'
    # read -r answer
    # if [[ $answer == 'y' ]]; then
        RECOVER_ROCKETPOOL=true
    # fi

    if [[ $RECOVER_ROCKETPOOL == true ]]; then
        echo '' && echo '   Press ENTER to Recover Wallet.'
        read -r junk
        junk=
        sudo rm -r .rocketpool/data/ && mkdir .rocketpool/data/
        rocketpool wallet recover
        log "Rocketpool Wallet recovered."

        echo ''
        rocketpool node status
        echo '   The status should show active minipools. If it does not then manually fix, otherwise you are done!!'
    fi
    debug_leave_function
}

active_node() {
    debug_enter_function
    echo '   Node is active. Done!!'
    debug_leave_function
}

terminate_node() {
    debug_enter_function
    echo '   TERMINATE NODE.'
    answer=
    echo 'Terminal Rocketpool node (y/n)?'
    read -r answer
    if [[ $answer == 'y' ]]; then
        echo '   NOT AUTOMATED: Manually do termination stuff.'
    fi
    debug_leave_function
}

install_dropbox() {
    debug_enter_function
    log "Download Dropbox installation."
    cd ~ && wget -O - "https://www.dropbox.com/download?plat=lnx.x86_64" | tar xzf -
    log "Finished downloading dropbox installation."

    echo '***************' && echo "Link account and then press Ctrl-Z to continue." && echo '***************' 
    echo ''
    "$HOME/.dropbox-dist/dropboxd"

    # now kill the dropbox job so we can continue
    jobId=$(jobs | grep 'dropboxd' | awk '{print $1}' | awk -F'[^0-9]*' '$0=$2')
    # echo 'Job to kill is '$jobId
    echo ''
    read -r -p 'Enter Job to Kill: ' -e -i "$jobId" jobId
    reNumber='^[0-9]+$'
    if ! [[ $jobId =~ $reNumber ]] ; then
        echo "ERROR: Job Id must be a number" >&2; 
        return 1
    fi
    if [[ $jobId -gt 0 ]]; then
        kill "%$jobId"
    fi

    echo "Dropbox files will be in $HOME/Dropbox."

    # use sudo command to prompt for password if necessary so we don't prompt after waiting for epoch
    sudo ls >/dev/null

    # create the file locally and then move to protected directory. Cannot echo to protected directory.
    echo -e "[Unit]
Description=Dropbox Daemon
After=network.target

[Service]
Type=forking
User=$USER
ExecStart=/bin/sh -c '/usr/local/bin/dropbox start'
ExecStop=/bin/sh -c '/usr/local/bin/dropbox stop'
Restart=always

[Install]
WantedBy=multi-user.target
    " > "$HOME/dropbox.service"
    sudo mv "$HOME/dropbox.service" /etc/systemd/system/dropbox.service

    # echo '   Press ENTER when ready to modify dropbox.service. MAKE THE FOLLOWING CHANGES:'
    # echo '[Unit]'
    # echo 'Description=Dropbox Daemon'
    # echo 'After=network.target'
    # echo ''
    # echo '[Service]'
    # echo 'Type=forking'
    # echo 'User='$USER
    # echo "ExecStart=/bin/sh -c '/usr/local/bin/dropbox start'"
    # echo "ExecStop=/bin/sh -c '/usr/local/bin/dropbox stop'"
    # echo 'Restart=always'
    # echo ''
    # echo '[Install]'
    # echo 'WantedBy=multi-user.target'
    # read -r junk
    # junk=
    # sudo nano /etc/systemd/system/dropbox.service

    sudo systemctl enable dropbox
    sudo systemctl start dropbox
    # systemctl status dropbox

    sudo wget -O /usr/local/bin/dropbox "https://www.dropbox.com/download?dl=packages/dropbox.py"
    if [[ ! -f /usr/local/bin/dropbox ]]; then
        echo '' && echo 'Downloading Dropbox Python script failed. Press ENTER to try again.'
        read -r junk
        junk=
        sudo wget -O /usr/local/bin/dropbox "https://www.dropbox.com/download?dl=packages/dropbox.py"

        if [[ ! -f /usr/local/bin/dropbox ]]; then
            echo '' && echo 'Downloading Dropbox Python script failed again so download it manually. Press ENTER to continue.'
            read -r junk
            junk=
        fi
    fi
    sudo chmod +x /usr/local/bin/dropbox

    # start dropbox
    echo "Start Dropbox. This takes several seconds to start and then it runs in the background."
    dropbox start

    dropboxStatus=$(dropbox status)
    if [[ $dropboxStatus == *"Dropbox isn't running"* ]]; then
        echo '' && echo 'Open another terminal and fix Dropbox so it is running. Press ENTER when it is running.'
        read -r junk
        junk=
    fi

    debug_leave_function
}

uninstall_dropbox() {
    debug_enter_function

    log 'Starting uninstalll Dropbox.'

    echo "Stop Dropbox."
    dropbox stop

    dropboxStatus=$(dropbox status)
    if [[ $dropboxStatus != *"Dropbox isn't running"* ]]; then
        echo 'For some reason Dropbox is still running. Open another terminal and stop Dropbox. Press ENTER to continue uninstalling Dropbox.'
        read -r junk
        junk=
    fi

    echo 'Delete Dropbox program files.'
    rm -rf "$HOME/.dropbox-dist"
    rm -rf /var/lib/dropbox
    rm -rf "$HOME/.dropbox*"

    echo 'Remove Dropbox packages.'
    sudo apt-get remove nautilus-dropbox
    sudo apt-get remove dropbox

    echo 'Delete Dropbox config files.'
    rm /etc/apt/source.d/dropbox

    echo 'Delete Dropbox folder.'
    rm -rv "$HOME/Dropbox"

    echo 'Dropbox has been uninstalled.'
    
    log 'Uninstalll Dropbox has finished.'

    debug_leave_function
}

disable_dropbox() {
    debug_enter_function

    dropbox exclude add "$DROPBOX_DEST_DIR"
    # dropbox exclude list
    # ls $HOME/Dropbox
    # df -h

    log 'Dropbox has been disabled.'
    debug_leave_function
}

enable_dropbox() {
    debug_enter_function

    dropbox exclude remove "$DROPBOX_DEST_DIR"
    # dropbox exclude list
    # ls $HOME/Dropbox
    # df -h

    log 'Dropbox has been enabled.'
    debug_leave_function
}

get_eth1_backup_from_other_server() {
    debug_enter_function
    # sudo rsync -av $HOME/backup rpuser1234@1.1.1.1:$HOME/
    ipAddr=$(hostname -I | awk '{print $1;}')
    # log "Run 'date && sudo rsync --progress -av $HOME/backup $USER@$ipAddr:$HOME/ && date' from other server."

# from other server
# sudo ssh-keygen -f "/root/.ssh/known_hosts" -R "1.1.1.1"
# sudo ssh-keyscan -H 1.1.1.1 >> $HOME/.ssh/known_hosts
# ssh-keygen -f "$HOME/.ssh/known_hosts" -R "1.1.1.1"
# 1. from other server: cat $HOME/.ssh/id_rsa.pub and copy the string
# 1a. this server: nano $HOME/.ssh/authorized_keys and append string
# Note: sudo grep sshd.\*Failed /var/log/auth.log | less to see failed ssh attempts
# date && sudo rsync -av $HOME/backup rpuser1234@1.1.1.1:$HOME/ && date
# echo -e $(date) 'Start rsync to '$ipAddr'.'>>rp-install-rsync.log && sudo rsync --progress -av $HOME/backup rpuser1234@1.1.1.1:$HOME/ && echo -e $(date) 'rsync to '$ipAddr' finished.'>>rp-install-rsync.log && scp rp-install-rsync.log $USER@ipAddr:$HOME/ && echo 'FINISHED.'

    echo '' && echo "   Run '. ./do-rsync.sh $USER@$ipAddr' from other server."
    echo "   Press ENTER to continue while files copy."
    read -r junk
    junk=

    # TODO: only check for backup directory if the user wants to copy from other server
    if [ ! -d "$HOME/backup" ]; then
        echo "$HOME/backup directory does not exist. Verify rsync is running from the other server. Press ENTER to continue."
        read -r junk
        junk=
    fi

    debug_leave_function
}

get_eth1_backup_from_dropbox() {
    debug_enter_function
    #make sure dropbox is sync'ing
    dropboxStatus=$(dropbox status)
    if [[ $dropboxStatus == *"Dropbox isn't running"* ]]; then
        echo '' && echo 'Open another terminal and fix Dropbox so it is running. Press ENTER when it is running.'
        read -r junk
        junk=
    fi

    dropboxFileStatus=$(dropbox filestatus Dropbox)
    if [[ $dropboxFileStatus == *"syncing"* ]]; then
        echo 'Dropbox is syncing so continue.'
    else
        if [[ $dropboxFileStatus == *"up to date"* ]]; then
            echo 'Dropbox is up to date to continue.'
        else
            echo "dropbox filestatus Dropbox: $dropboxFileStatus"
            echo 'Dropbox is NOT syncing. Verify this is okay and press ENTER to continue.'
            read -r junk
            junk=
        fi
    fi

    log "Dropbox is syncing."
    debug_leave_function
}

restore_eth1_backup_from_other_server() {
    debug_enter_function
    if [ ! -d "$HOME/backup" ]; then
        log_fail "WARNING: $HOME/backup directory does not exist."
        echo "WARNING: $HOME/backup directory does not exist. Once ALL files are in $HOME/backup, press ENTER to continue."
        read -r junk
        junk=
    fi

    echo '   Import eth1 data'
    log "Import eth1 data"
    rocketpool service import-eth1-data "$HOME/backup"
    log "Import eth1 data finished."
    debug_leave_function
}

restore_eth1_backup_from_dropbox() {
    debug_enter_function
    if [ ! -d "$DROPBOX_DEST_DIR" ]; then
        log_fail "WARNING: $DROPBOX_DEST_DIR directory does not exist."
        echo "WARNING: $DROPBOX_DEST_DIR directory does not exist. Once ALL files are in $DROPBOX_DEST_DIR, press ENTER to continue."
        read -r junk
        junk=
    fi

    echo '   Import eth1 data'
    log "Import eth1 data"
    rocketpool service import-eth1-data "$DROPBOX_DEST_DIR"
    log "Import eth1 data finished."
    debug_leave_function
}

pause2fa() {
    debug_enter_function

    log "Stop rocketpool"
    stop_rocketpool

    echo "Press ENTER to add the remote server to authorized_keys."
    read -r junk
    junk=
    nano "$HOME/.ssh/authorized_keys"

    sudo cp /etc/ssh/sshd_config.orig /etc/ssh/sshd_config
    sudo cp /etc/pam.d/sshd.orig /etc/pam.d/sshd
    sudo systemctl restart ssh
    log "2FA is paused"
    echo '2FA is paused.'

    # echo -e $(date) 'Start rsync to 1.1.1.1.'>>rp-install-rsync.log && sudo rsync --progress -av $HOME/backup rpuser1234@1.1.1.1:$HOME/ && echo -e $(date) 'rsync to 1.1.1.1 finished.'>>rp-install-rsync.log && scp rp-install-rsync.log rpuser1234@1.1.1.1:$HOME/ && echo 'FINISHED.'
    echo 'Run do-rsync.sh on other server.'

    echo ''
    echo 'Press ENTER when ready to ENable 2FA.'
    read -r junk
    junk=
    sudo cp /etc/ssh/sshd_config.updated /etc/ssh/sshd_config
    sudo cp /etc/pam.d/sshd.updated /etc/pam.d/sshd
    sudo systemctl restart ssh
    log "2FA is enabled"
    echo '2FA is enabled.'

    appendLog=false
    answer=
    echo 'Append rsync log to log file and delete it (y/n)?'
    read -r answer
    if [[ $answer != 'n' ]]; then
        echo "Appending $RSYNC_LOG_FILE to $LOG_FILE"
        cat "$RSYNC_LOG_FILE" >> "$LOG_FILE"
        rm "$RSYNC_LOG_FILE"
    fi

    echo '' && echo 'rsync finished.' && echo ''
    
    start_rocketpool
    log "RocketPool is started"
    
    debug_leave_function
}

install_grafana() {
    debug_enter_function

    if [[ $prompt == true ]]; then
        INSTALL_GRAFANA=false
        answer=
        echo 'Install Grafana Dashboard (y/n)?'
        read -r answer
        if [[ $answer == 'y' ]]; then
            INSTALL_GRAFANA=true
        fi
    fi

    if [[ $INSTALL_GRAFANA == true ]]; then
        log "Installing Grafana"
        echo '   Installing Grafana Dashboard.'
        # rocketpool service config
        # docker inspect rocketpool_monitor-net | grep -Po "(?<=\"Subnet\": \")[0-9./]+"
        sudo ufw allow from $PROMETHEUS_IP_ADDRESS/16 to any port 9103 comment "Allow prometheus access to node-exporter"
        # Allow any IP to connect to Grafana
        sudo ufw allow $GRAFANA_PORT/tcp comment 'Allow grafana from anywhere'
        rocketpool service stop -y
        rocketpool service start
        rocketpool service install-update-tracker -y
        docker restart rocketpool_exporter

        ipAddr=$(hostname -I | awk '{print $1;}')
        echo "Go to to the grafana dashboard: $ipAddr:$GRAFANA_PORT. Click Import under Dashboard menu. Import url: https://grafana.com/grafana/dashboards/14885"
        echo "Press ENTER when ready to continue."
        read -r
        log "Finished installing Grafana"
    fi

    debug_leave_function
}

install_nodeset() {
    debug_enter_function
    echo '   Start NodeSet Installation'

    # if [[ $prompt == true ]]; then
        INSTALL_NODESET=false
        answer=
        echo 'Install NodeSet (y/n)?'
        read -r answer
        if [[ $answer == 'y' ]]; then
            INSTALL_NODESET=true
        fi
    # fi

    if [[ $INSTALL_NODESET == true ]]; then
        install_hyperdrive
    fi

    echo '   Finished installing NodeSet'
    debug_leave_function
}

install_hyperdrive() {
    debug_enter_function
    echo '   Start the Hyperdrive Installation'

    # Update the system packages and install some prerequisites
    sudo apt update
    sudo apt install curl gnupg apt-transport-https ca-certificates

    # Save the Hyperdrive repository signing key
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://packagecloud.io/nodeset/hyperdrive/gpgkey -o /etc/apt/keyrings/hyperdrive.asc

    # Add the Hyperdrive repository to your apt list
    sudo tee -a /etc/apt/sources.list.d/hyperdrive.list << EOF
deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/hyperdrive.asc] https://packagecloud.io/nodeset/hyperdrive/any/ any main
deb-src [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/hyperdrive.asc] https://packagecloud.io/nodeset/hyperdrive/any/ any main
EOF

    # Install Hyperdrive via apt
    sudo apt update
    sudo apt install hyperdrive

    echo -e "
    # Hyperdrive aliases
    alias hd='hyperdrive'
    " >> "$HOME/.bashrc"

    echo '' && echo '  Configure Hyperdrive.' && echo ''
    echo '* Go to the HD and TX fees section'
    echo '* In Additional Docker Networks; put rocketpool_net in there so it can bridge into the smartnode network'
    echo '* Go to the EC settings and enter http://rocketpool_eth1:8545'
    echo '* Go to the BN settings and enter http://rocketpool_eth2:5052'
    echo '* Save, exit, and let it restart'
    echo '   '
    echo '' && echo '   Press ENTER to configure Hyperdrive.'
    read -r junk
    hyperdrive service config
    log "Hyperdrive configured."

    echo '   Finished installing Hyperdrive'
    debug_leave_function
}

# template() {
#     debug_enter_function
#     debug_leave_function
# }

#####################################################################################################################
# Main
#####################################################################################################################
Initialize

echo ''
echo ''
echo '******************'
echo 'New Install Script (note it may take several seconds to get status)'
if [[ -z $USER_PREFIX ]]; then echo 'ERROR: User Prefix is required. EXIT'; return; fi
STEP=0
determine_step
STEP=$?
echo 'Step is '$STEP
echo '******************'

case $STEP in
    10)
        # 10. Prepare Ubuntu as root user
        prepare_as_root_user
        ;;
    20)
        # 20. Finish preparting Ubuntu and download Rocketpool as non-root user
        prepare_as_non-root_user
        ;;
    30)
        # 30. Install and config Rocketpool as non-root user
        install_rocketpool
        install_grafana
        ;;
    35)
        # 35. Start Rocketpool after first installation
        start_rocketpool
        ;;
    37)
        # 37. Install and config Hyperdrive
        install_hyperdrive
        ;;
    40)
        # 40. Wait for eth1 to sync

        # Restore if available
        RESTORE_ETH1_FROM_DROPBOX=false
        RESTORE_ETH1_FROM_BACKUP=false
        if [ -d "$DROPBOX_DEST_DIR" ]; then
            answer=
            echo "Restore ETH1 from $DROPBOX_DEST_DIR (y/n)?"
            read -r answer
            if [[ $answer == 'y' ]]; then
                RESTORE_ETH1_FROM_DROPBOX=true
            fi
        else
            if [ -d "$HOME/backup" ]; then
# TODO: determine if we lost connection while paused and auto enable 2FA
                answer=
                echo "Restore ETH1 from $HOME/backup (y/n)?"
                read -r answer
                if [[ $answer == 'y' ]]; then
                    RESTORE_ETH1_FROM_BACKUP=true
                fi
            else
                answer=
                echo 'Pause 2FA so rsync can run (y/n)?'
                read -r answer
                if [[ $answer == 'y' ]]; then
                    pause2fa
                    RESTORE_ETH1_FROM_BACKUP=true
                fi
            fi
        fi

        if [[ $RESTORE_ETH1_FROM_DROPBOX == true ]]; then
            echo 'Restore from Dropbox'
            stop_rocketpool
            restore_eth1_backup_from_dropbox
            rocketpool node sync
        fi

        if [[ $RESTORE_ETH1_FROM_BACKUP == true ]]; then
            echo 'Restore from local/rsync backup'
            stop_rocketpool
            restore_eth1_backup_from_other_server
            rocketpool node sync
        fi

        # We still have to wait even if restored to get latest
        wait_for_eth1_sync
        ;;
    44)
        # 44. Create Rocketpool Wallet

        RESTORE_WALLET=false
        answer=
        echo 'Recover existing wallet (y/n)?'
        read -r answer
        if [[ $answer == 'y' ]]; then
            RESTORE_WALLET=true
        fi

        if [[ $RESTORE_WALLET == true ]]; then
            recover_rocketpool
        else
            create_rocketpool_wallet
        fi
        ;;
    46)
        # 46. Wait for eth2 to sync
        wait_for_eth2_sync
        ;;
    50)
        # 50. Finish Rocketpool installation as non-root user
        finish_rocketpool_installation
        ;;
    60)
        # 60. Optional - Recover Rocketpool as non-root user
        ;;
    100)
        # 100. Node is active
        install_nodeset
        active_node
        ;;
    *)
        # UNKNOWN STEP
        echo '  ****** ERROR: WAS NOT ABLE TO DETERMINE STATUS OF INSTALLATION. EXIT.'
        log_fail 'WAS NOT ABLE TO DETERMINE STATUS OF INSTALLATION. EXIT.'
        return
        ;;
esac

Cleanup $step

return
