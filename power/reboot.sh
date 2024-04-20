#!/bin/bash
#
# reboot system

ts=`date +'%Y-%m-%d_%H%M%S'`

echo "initiating forced reboot at ${ts}"
sudo shutdown -r now