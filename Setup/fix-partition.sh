#!/bin/bash

df 
# (Note the drive: /dev/mapper/ubuntu--vg-ubuntu--lv)

# Escalate privilages into lvm:
sudo lvm

# Run LV Extend:
lvextend -l +100%FREE /dev/ubuntu-vg/ubuntu-lv
# exit

# Run resize:
sudo resize2fs /dev/ubuntu-vg/ubuntu-lv

# Free space visualized:
df -h