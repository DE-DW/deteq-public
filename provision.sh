#!/bin/bash

# make sure we are running with sudo
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit -1
fi

apt update

echo "Enabling SPI via raspi-config"
raspi-config nonint do_spi 0

echo "Enabling I2C via raspi-config"
raspi-config nonint do_i2c 0

echo "Enabling Serial Port via raspi-config"
raspi-config nonint do_serial_hw 0

echo "Disabling Serial Console via raspi-config"
raspi-config nonint do_serial_cons 1

echo "Enabling WiFi"
rfkill unblock wifi
ifconfig wlan0 up

nmcli radio wifi on

sleep 5

echo "Enable WiFi Access Point"
ser_num=$(cat /sys/firmware/devicetree/base/serial-number | cut -c9-16)
nmcli device wifi hotspot ssid deteq_ap-${ser_num} password ${ser_num} ifname wlan0

# Set the hotspot to autoconnect with high priority
nmcli connection modify Hotspot connection.autoconnect yes connection.autoconnect-priority 100

# clean up the provisioning files
# delete the parent folder of this script
script_dir=$(dirname "$(realpath "$0")")
rm -rf "$script_dir"

echo "Rebooting to apply changes"
reboot
