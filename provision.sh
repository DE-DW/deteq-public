#!/bin/bash

# make sure we are running with sudo
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit -1
fi

ser_num=$(cat /sys/firmware/devicetree/base/serial-number | cut -c9-16)

apt update

echo "Enabling SPI via raspi-config"
raspi-config nonint do_spi 0

echo "Enabling I2C via raspi-config"
raspi-config nonint do_i2c 0

echo "Enabling Serial Port via raspi-config"
raspi-config nonint do_serial_hw 0

echo "Disabling Serial Console via raspi-config"
raspi-config nonint do_serial_cons 1

echo "Set hostname to deteq-${ser_num}"
raspi-config nonint do_hostname deteq-${ser_num}

echo "Enabling WiFi"
rfkill unblock wifi
ifconfig wlan0 up

nmcli radio wifi on

sleep 5

echo "Enable WiFi Access Point"
nmcli device wifi hotspot ssid deteq_ap-${ser_num} password ${ser_num} ifname wlan0

# Set the hotspot to autoconnect with high priority
nmcli connection modify Hotspot connection.autoconnect yes connection.autoconnect-priority 100

# create /mnt/usb directory if it doesn't exist
if [ ! -d "/mnt/usb" ]; then
  mkdir -p /mnt/usb
fi

# change the owner of the /mnt/usb directory to pi
chown pi:pi /mnt/usb

# add a line to /etc/fstab to mount the USB drive at /mnt/usb
# we will use /dev/sda1 as the device, but this may need to be changed depending on the system
if ! grep -q "/dev/sda1" /etc/fstab; then
  echo "/dev/sda1 /mnt/usb auto defaults,uid=pi,gid=pi,nofail 0 0" >> /etc/fstab
fi

# set gpio pins to output and high if not already set in /boot/firmware/config.txt
if ! grep -q "gpio=19=op,dh" /boot/firmware/config.txt; then
  echo "gpio=19=op,dh" >> /boot/firmware/config.txt
fi

if ! grep -q "gpio=16=op,dh" /boot/firmware/config.txt; then
  echo "gpio=16=op,dh" >> /boot/firmware/config.txt
fi

if ! grep -q "gpio=26=op,dh" /boot/firmware/config.txt; then
  echo "gpio=26=op,dh" >> /boot/firmware/config.txt
fi

if ! grep -q "gpio=20=op,dh" /boot/firmware/config.txt; then
  echo "gpio=20=op,dh" >> /boot/firmware/config.txt
fi

# clean up the provisioning files
# delete the parent folder of this script
script_dir=$(dirname "$(realpath "$0")")
rm -rf "$script_dir"

echo "Rebooting to apply changes"
reboot
