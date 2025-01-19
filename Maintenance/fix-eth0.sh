#!/bin/bash

ip link set eth0 down
ip link set eth0 up
dhclient eth0
echo 'restart docker rocketpool_eth2 will take a few minutes'
docker restart rocketpool_eth2
