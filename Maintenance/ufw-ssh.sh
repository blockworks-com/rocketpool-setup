if [[ -f "common-rpl.sh" ]]; then source common-rpl.sh; elif [[ -f "../Common/common-rpl.sh" ]]; then source ../Common/common-rpl.sh; elif [[ -f "../common-rpl.sh" ]]; then source ../common-rpl.sh; else echo "Failed to load common-rpl.sh"; return 0; fi

#Define the string value
# DEBUG=true
prompt=true
allow=

# handle command line options
# check for verbose first so it is used with the other parameters
if [[ $1 == "-v" || $1 == "--verbose" ||
    $2 == "-v" || $2 == "--verbose" ||
    $3 == "-v" || $3 == "--verbose" ||
    $4 == "-v" || $4 == "--verbose" ]]; then
    echo "verbose on"
    verbose=true
fi

# Set variables from config file if defaults override was not passed
echo "reading config file"
setVariablesFromConfigFile "new-install.yml"
prompt=false

if [[ $1 == "-a" || $1 == "--allow" ||
    $2 == "-a" || $2 == "--allow" ||
    $3 == "-a" || $3 == "--allow" ||
    $4 == "-a" || $4 == "--allow" ]]; then
    allow=true
fi
if [[ $1 == "-b" || $1 == "--block" ||
    $2 == "-b" || $2 == "--block" ||
    $3 == "-b" || $3 == "--block" ||
    $4 == "-b" || $4 == "--block" ]]; then
    allow=false
fi
if [[ $1 == "-h" || $1 == "--help" || 
    $2 == "-h" || $2 == "--help" || 
    $3 == "-h" || $3 == "--help" || 
    $4 == "-h" || $4 == "--help" ]]; then
    cat << EOF
Usage: ufw-ssh [OPTIONS]...
Allows or blocks SSH port.

    Option                     Meaning
    -a|--allow                 Allow SSH traffic
    -b|--block                 Block SSH traffic
    -h|--help                  Displays this help and exit
    -p|--prompt                Prompt for each option instead of using defaults
    -v|--verbose               Displays verbose output
EOF
    return
fi

if [[ ! $allow == true && ! $allow == false ]]; then
    echo 'You must specify either --allow or --block. EXIT.'
    return
fi

if [[ $prompt == true || -z $SSH_PORT ]]; then
    answer=
    echo 'Enter ssh port number'
    read -r answer
    if [[ -z $answer ]]; then
        echo 'ssh port is required. EXIT.'
        return
    else
        SSH_PORT=$answer
    fi
fi

if [[ ! -z $SSH_PORT ]]; then
    if [[ $allow == true ]]; then
        echo "Allow ssh on port $SSH_PORT"
        sudo ufw allow "$SSH_PORT/tcp" comment 'Allow ssh on custom port'
    elif [[ $allow == false ]]; then
        echo "Block ssh on port $SSH_PORT"
        sudo ufw delete allow "$SSH_PORT/tcp"
    fi
    echo "Reloading ufw and restarting ssh"
    sudo ufw reload
    sudo service ssh restart
    sudo ufw status verbose
fi