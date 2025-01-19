#!/bin/bash

answer=
echo "Enter new hostname"
read -r answer
if [[ ! -z $answer ]]; then
    hostnamectl set-hostname $answer
fi
