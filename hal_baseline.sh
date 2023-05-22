#!/bin/bash
###################################################
# Baseline the  system for a new run of
# the hal_first_run.sh script
##################################################
rm -f /etc/hal/work/*
echo "" > /etc/hal/env/station.env
echo "HAL_VERSION=1" > /etc/hal/env/setup.env
rm -f /root/kisstnc1 /root/kisstnc2

