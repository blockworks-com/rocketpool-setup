#!/bin/bash

if [[ -f "common-rpl.sh" ]]; then source common-rpl.sh; else source ../Common/common-rpl.sh; fi
if [[ -f "common-rpl-maintenance.sh" ]]; then source common-rpl-maintenance.sh; else source ../Common/common-rpl-maintenance.sh; fi

#Define the string value
exportEth1='n'
disk='sda3'
BACKUP_DEST_DIR=$HOME/backup
destDir="$DROPBOX_DEST_DIR" # default to Dropbox

#####################################################################################################################
# Main
#####################################################################################################################
Initialize

seconds=0

echo ""
echo "*** Check disk space"
df -h

#ask if we should perform export-eth1
answer=
echo ""
echo "Perform export-eth1 (y/n)?"
read -r answer
if [[ $answer == 'y' ]]; then
  exportEth1=$answer
  #ask if we should export-eth1 to Dropbox
  if [ ! -d "$DROPBOX_DEST_DIR" ]; then
    echo "Using local backup since Dropbox directory does not exist."
    destDir="$BACKUP_DEST_DIR"
  fi
  answer=
  echo ""
  echo "Export-eth1 to $destDir (y/n)?"
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

# backup geth
if [[ $exportEth1 == 'y' ]]; then
  if [ ! -d "$destDir" ]; then
    mkdir -p "$destDir";
  fi
  # func (c *Client) RunEcMigrator(container string, volume string, targetDir string, mode string, image string) error {
	# cmd := fmt.Sprintf("docker run --rm --name %s -v %s:/ethclient -v %s:/mnt/external -e EC_MIGRATE_MODE='%s' %s", container, volume, targetDir, mode, image)
# docker run --rm --name $container -v $volume:/ethclient -v $targetDir:/mnt/external -e EC_MIGRATE_MODE='$mode' $image", container, volume, targetDir, "export", image
  echo "*** Performing export-eth1"
  rocketpool service export-eth1-data "$destDir"
else
  echo "not exporting eth1"
fi

# rm backup.tar.gz && sudo tar -c -f backup.tar.gz $HOME/backup

duration=$seconds
echo "$((duration / 60)) minutes and $((duration % 60)) seconds elapsed."

Cleanup