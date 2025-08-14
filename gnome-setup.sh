#!/bin/bash
set -e

# Variables
USERNAME="${USERNAME:-$(whoami)}"

echo "=== Updating system packages ==="
sudo pacman -Syu --noconfirm

echo "=== Installing extra GNOME utilities and tweaks ==="
sudo pacman -S --noconfirm \
    gnome-tweaks \
    gnome-shell-extensions \
    gnome-control-center \
    gnome-system-monitor \
    gnome-keyring \
    dconf-editor \
    xdg-user-dirs \
    xdg-utils

echo "=== Creating default user directories ==="
sudo -u "$USERNAME" xdg-user-dirs-update

echo "=== Setting up GNOME shell extensions ==="
# Enable some useful extensions
gnome-extensions enable user-theme@gnome-shell-extensions.gcampax.github.com || true
gnome-extensions enable dash-to-dock@micxgx.gmail.com || true

echo "=== Enabling graphical target ==="
sudo systemctl set-default graphical.target

echo "=== Enabling GDM (GNOME Display Manager) ==="
sudo systemctl enable gdm
sudo systemctl start gdm

echo "=== Setting GTK and GNOME shell theme ==="
gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'
gsettings set org.gnome.shell.extensions.user-theme name 'Adwaita-dark'

echo "=== Setting favorite apps ==="
gsettings set org.gnome.shell favorite-apps "['firefox.desktop', 'org.gnome.Terminal.desktop', 'org.gnome.Nautilus.desktop', 'org.gnome.Software.desktop']"

echo "=== Desktop setup complete! ==="
