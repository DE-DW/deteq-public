#!/bin/bash

# make sure we are running with sudo
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit -1
fi

apt update

raspi-config nonint do_spi 0
raspi-config nonint do_i2c 0
raspi-config nonint do_serial_hw 0
raspi-config nonint do_serial_cons 1

ser_num=$(cat /sys/firmware/devicetree/base/serial-number | cut -c9-16)
nmcli device wifi hotspot ssid deteq_ap-${ser_num} password ${ser_num} ifname wlan0

reboot
