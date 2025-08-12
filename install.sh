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

echo "=== Partitioning Disk ==="
parted -s $DISK mklabel msdos
parted -s $DISK mkpart primary ext4 1MiB 100%

echo "=== Formatting ==="
mkfs.ext4 ${DISK}1

echo "=== Mounting ==="
mount ${DISK}1 /mnt

echo "=== Installing Base System ==="
pacstrap /mnt base linux linux-firmware sudo nano networkmanager grub xorg plasma kde-applications sddm virtualbox-guest-utils

echo "=== Generating fstab ==="
genfstab -U /mnt >> /mnt/etc/fstab

echo "=== Chroot Config ==="
arch-chroot /mnt /bin/bash -c "
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
    sed -i 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers
    systemctl enable NetworkManager
    systemctl enable sddm
    systemctl enable vboxservice
    grub-install --target=i386-pc $DISK
    grub-mkconfig -o /boot/grub/grub.cfg
"

umount -R /mnt
echo "=== Installation Complete! Reboot ==="
