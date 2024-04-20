#!/bin/bash
#
# shutdown system

ts=`date +'%Y-%m-%d_%H%M%S'`

echo "initiating forced shutdown at ${ts}"
sudo shutdown -h now