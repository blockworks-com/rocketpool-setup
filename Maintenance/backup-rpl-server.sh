#!/bin/bash

if [[ -f "common-rpl.sh" ]]; then source common-rpl.sh; else source ../Common/common-rpl.sh; fi
if [[ -f "common-rpl-maintenance.sh" ]]; then source common-rpl-maintenance.sh; else source ../Common/common-rpl-maintenance.sh; fi

#Define the string value
exportEth1='n'
disk='sda3'
BACKUP_DEST_DIR=$HOME/backup
destDir="$DROPBOX_DEST_DIR" # default to Dropbox
exportEth1=false
defaults=true

# handle command line options
if [[ $1 == "-e" || $1 == "--export-eth1" ||
    $2 == "-e" || $2 == "--export-eth1" || 
    $3 == "-e" || $3 == "--export-eth1" || 
    $4 == "-e" || $4 == "--export-eth1" ]]; then
    echo "Export Eth1"
    exportEth1=true
fi
if [[ $1 == "-p" || $1 == "--prompt" || 
    $2 == "-p" || $2 == "--prompt" || 
    $3 == "-p" || $3 == "--prompt" || 
    $4 == "-p" || $4 == "--prompt" ]]; then
    echo "Prompt for values and options"
    defaults=false
fi
if [[ $1 == "-v" || $1 == "--verbose" ||
    $2 == "-v" || $2 == "--verbose" ||
    $3 == "-v" || $3 == "--verbose" ||
    $4 == "-v" || $4 == "--verbose" ]]; then
    echo "Verbose on"
    verbose=true
fi
if [[ $1 == "-h" || $1 == "--help" || 
    $2 == "-h" || $2 == "--help" || 
    $3 == "-h" || $3 == "--help" || 
    $4 == "-h" || $4 == "--help" ]]; then
    cat << EOF
Usage: backup-rpl-server [OPTIONS]...
Copies eth1 directory, and grafana dashboard configuration to backup directory.

    Option                     Meaning
    -e|--export-eth1           Export Eth1 to local disk before backing up
    -h|--help                  Displays this help and exit
    -p|--prompt                Prompt for each option instead of using defaults
    -v|--verbose               Displays verbose output
EOF
    return
fi

#####################################################################################################################
# Main
#####################################################################################################################
Initialize

seconds=0

echo ""
echo "*** Check disk space"
df -h

# Use local backup directory if Dropbox not installed
if [ ! -d "$DROPBOX_DEST_DIR" ]; then
  # echo "Using local backup since Dropbox directory does not exist."
  destDir="$BACKUP_DEST_DIR"
fi
echo "Backup directory: $destDir"

if [[ "$defaults" == false ]]; then
  #ask if we should perform export-eth1
  exportEth1=false
  answer=
  echo ""
  echo "Perform export-eth1 (y/n)?"
  read -r answer
  if [[ $answer == 'y' ]]; then
    exportEth1=$answer
  fi
fi

echo ""
echo "*** Check disk space"
availSpace=0
availSpace=$(df -h /dev/"$disk" | tail -n+2 | while read -r fs size used avail rest ; do echo "$avail"; done;)
echo "Available space $availSpace"

# backup grafana
if [ ! -d "$destDir" ]; then
  mkdir -p "$destDir";
fi
if [ ! -d "$destDir/grafana" ]; then
  mkdir -p "$destDir/grafana";
fi
sudo cp -r '/var/lib/docker/volumes/rocketpool_grafana-storage' "$destDir/grafana"

# backup eth1
if [[ $exportEth1 == 'y' ]]; then
  # func (c *Client) RunEcMigrator(container string, volume string, targetDir string, mode string, image string) error {
	# cmd := fmt.Sprintf("docker run --rm --name %s -v %s:/ethclient -v %s:/mnt/external -e EC_MIGRATE_MODE='%s' %s", container, volume, targetDir, mode, image)
# docker run --rm --name $container -v $volume:/ethclient -v $targetDir:/mnt/external -e EC_MIGRATE_MODE='$mode' $image", container, volume, targetDir, "export", image
  echo "*** Performing export-eth1"
  rocketpool service export-eth1-data "$destDir"
  echo "Done export-eth1."
else
  echo "Not exporting eth1"
fi

# rm backup.tar.gz && sudo tar -c -f backup.tar.gz $HOME/backup

duration=$seconds
echo "$((duration / 60)) minutes and $((duration % 60)) seconds elapsed."

Cleanup