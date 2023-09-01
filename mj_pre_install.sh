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
# You can include your partitioning commands here, similar to what you provided earlier.

# Formatting and mounting partitions
#!/bin/bash

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

# Prompt for the EFI partition device and mount point
read -p "Enter the EFI partition device (e.g., /dev/sda1): " EFI_PARTITION
read -p "Enter the mount point for the EFI partition (e.g., /mnt/efi): " EFI_MOUNT_POINT

# Create an EFI mount point and mount the EFI partition.
echo "Creating EFI mount point and mounting EFI partition..."
mkdir "$EFI_MOUNT_POINT"
mount "$EFI_PARTITION" "$EFI_MOUNT_POINT"

# Create swap on the specified partition.
echo "Setting up swap partition..."
mkswap "$SWAP_PARTITION"
swapon "$SWAP_PARTITION"


# Install essential packages and generate an fstab file
pacstrap /mnt base base-devel amd-ucode linux linux-firmware linux-lts linux-headers

# Generate an fstab file
genfstab -U /mnt >> /mnt/etc/fstab

# Chroot into the new system
arch-chroot /mnt

# Set the hostname
echo "$hostname" > /etc/hostname

# Set the system clock
ln -sf /usr/share/zoneinfo/$timezone /etc/localtime
hwclock --systohc

# Localization
echo "LANG=en_US.UTF-8" > /etc/locale.conf
locale-gen

# Network configuration (you can modify this based on your needs)
echo "127.0.0.1    localhost" >> /etc/hosts
echo "::1          localhost" >> /etc/hosts
echo "127.0.1.1    $hostname.localdomain $hostname" >> /etc/hosts

# Set the root password
echo "Setting root password..."
passwd

# Create a new user
useradd -m -g users -G wheel $username

# Check if the user was created successfully
if [ $? -eq 0 ]; then
    echo "User '$username' created successfully."
else
    echo "Failed to create user '$username'. Exiting."
    exit 1
fi


# Set a password for the user
echo "Setting password for $username..."
passwd "$username"

# Grant sudo access
echo "Granting sudo access to $username..."
echo "$username ALL=(ALL) ALL" | sudo tee -a /etc/sudoers.d/"$username"

# Check if sudo access was granted successfully
if [ $? -eq 0 ]; then
    echo "Sudo access granted to '$username'."
else
    echo "Failed to grant sudo access to '$username'. Please add manually."
fi


# Install and configure bootloader

# First necessary packages installation:
pacman -S grub efibootmgr osprober networkmanger vim sudo

# GRUB Installation and configuring:
grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

# Exit chroot and unmount partitions
exit
umount -R /mnt
