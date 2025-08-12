#!/bin/bash
set -e

DISK=/dev/sda
HOSTNAME=arch-vm

# Prompt for username
read -rp "Enter the username to create: " USERNAME

# Prompt for password silently
while true; do
    read -rsp "Enter password for user $USERNAME: " PASSWORD
    echo
    read -rsp "Confirm password: " PASSWORD2
    echo
    [ "$PASSWORD" = "$PASSWORD2" ] && break
    echo "Passwords do not match. Try again."
done

# Verify disk exists
if [ ! -b "$DISK" ]; then
    echo "Error: Disk $DISK not found!"
    echo "Available disks:"
    lsblk
    exit 1
fi

echo "=== Partitioning Disk ==="
parted -s $DISK mklabel msdos
parted -s $DISK mkpart primary ext4 1MiB 100%

echo "=== Formatting ==="
mkfs.ext4 -F ${DISK}1

echo "=== Mounting ==="
mount ${DISK}1 /mnt

echo "=== Installing Base System ==="
pacstrap /mnt base linux linux-firmware sudo nano networkmanager grub xorg plasma kde-applications sddm virtualbox-guest-utils

echo "=== Generating fstab ==="
genfstab -U /mnt >> /mnt/etc/fstab

echo "=== Chroot Config ==="
# Create a script to run inside chroot to avoid variable expansion issues
cat > /mnt/setup.sh << EOF
#!/bin/bash
ln -sf /usr/share/zoneinfo/Europe/London /etc/localtime
hwclock --systohc
echo 'en_US.UTF-8 UTF-8' >> /etc/locale.gen
locale-gen
echo 'LANG=en_US.UTF-8' > /etc/locale.conf
echo '$HOSTNAME' > /etc/hostname
echo '127.0.0.1 localhost' >> /etc/hosts
echo '::1       localhost' >> /etc/hosts
echo '127.0.1.1 $HOSTNAME.localdomain $HOSTNAME' >> /etc/hosts
echo root:$PASSWORD | chpasswd
useradd -m -G wheel,vboxsf -s /bin/bash $USERNAME
echo $USERNAME:$PASSWORD | chpasswd
# Enable sudo for wheel group - more robust approach
sed -i 's/^# *%wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers
# Alternative: uncomment any wheel sudo line
sed -i 's/^# *%wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
systemctl enable NetworkManager
systemctl enable sddm
systemctl enable vboxservice
grub-install --target=i386-pc $DISK
grub-mkconfig -o /boot/grub/grub.cfg
EOF

chmod +x /mnt/setup.sh
arch-chroot /mnt ./setup.sh
rm /mnt/setup.sh

umount -R /mnt
echo "=== Installation Complete! Reboot and remove installation media ==="
