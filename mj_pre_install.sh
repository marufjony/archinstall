#!/bin/bash

# Prompt for user input
read -p "Enter the hostname: " hostname
read -p "Enter your username: " username
read -sp "Enter your user password: " user_password
echo
read -sp "Confirm your user password: " user_password_confirm
echo
read -p "Enter your locale (e.g., en_US.UTF-8): " locale
read -p "Enter your timezone (e.g., Asia/Dhaka): " timezone

# Verify that the user password matches the confirmation
if [ "$user_password" != "$user_password_confirm" ]; then
    echo "Passwords do not match. Exiting."
    exit 1
fi

# Partitioning

# Prompt the user for the root partition device (e.g., /dev/sdXY).
read -p "Enter the root partition device (e.g., /dev/sdXY): " ROOT_PARTITION

# Prompt the user for the swap partition device (e.g., /dev/sdXZ).
read -p "Enter the swap partition device (e.g., /dev/sdXZ): " SWAP_PARTITION

# Create root partition and format it as ext4.
echo "Creating and formatting root partition as ext4..."
mkfs.ext4 "$ROOT_PARTITION"

# Mount the root partition to /mnt.
echo "Mounting root partition to /mnt..."
mount "$ROOT_PARTITION" /mnt

# Create swap on the specified partition.
echo "Setting up swap partition..."
mkswap "$SWAP_PARTITION"
swapon "$SWAP_PARTITION"


# Install essential packages and generate an fstab file
pacstrap /mnt base base-devel amd-ucode linux linux-firmware linux-lts linux-headers

# Generate an fstab file
genfstab -U /mnt >> /mnt/etc/fstab
