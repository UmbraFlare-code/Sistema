#!/bin/bash
set -e

NEW_USER="$1"
DISK="$2"

# Zona horaria y reloj
ln -sf /usr/share/zoneinfo/America/Lima /etc/localtime
hwclock --systohc

# Locale
echo "es_ES.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=es_ES.UTF-8" > /etc/locale.conf
echo "KEYMAP=la-latin1" > /etc/vconsole.conf

# Hostname
echo "archtty" > /etc/hostname
cat > /etc/hosts <<EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   archtty.localdomain archtty
EOF

# ZRAM
mkdir -p /etc/systemd/zram-generator.conf.d
cat > /etc/systemd/zram-generator.conf <<EOF
[zram0]
zram-size = 1024
compression-algorithm = zstd
EOF
systemctl enable systemd-zram-setup@zram0

# Optimizar compilación
sed -i "s|^#MAKEFLAGS=.*|MAKEFLAGS=\"-j$(nproc)\"|" /etc/makepkg.conf
sed -i 's|^CFLAGS=.*|CFLAGS="-march=native -O2 -pipe -fstack-protector-strong -fno-plt"|' /etc/makepkg.conf
sed -i 's|^CXXFLAGS=.*|CXXFLAGS="${CFLAGS}"|' /etc/makepkg.conf

# Network
systemctl enable NetworkManager

# Root password
echo "root:root" | chpasswd

# Usuario
useradd -m -G wheel -s /bin/bash "$NEW_USER"
echo "$NEW_USER:$NEW_USER" | chpasswd
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

# Copiar configuración de tmux
install -Dm644 /root/tmux.conf /home/$NEW_USER/.tmux.conf

# Copiar configuración de Neovim
install -d -m 755 /home/$NEW_USER/.config/nvim
install -Dm644 /root/init.vim /home/$NEW_USER/.config/nvim/init.vim

# Cambiar permisos para el usuario
chown -R $NEW_USER:$NEW_USER /home/$NEW_USER/.tmux.conf /home/$NEW_USER/.config

# Bootloader
if [ -d /sys/firmware/efi ]; then
    bootctl install
    PARTUUID=$(blkid -s PARTUUID -o value $(findmnt -n -o SOURCE /))
    mkdir -p /boot/loader/entries
    cat > /boot/loader/loader.conf <<EOF
default arch.conf
timeout 3
console-mode max
editor no
EOF
    cat > /boot/loader/entries/arch.conf <<EOF
title   Arch Linux
linux   /vmlinuz-linux
initrd  /initramfs-linux.img
options root=PARTUUID=${PARTUUID} rw
EOF
else
    grub-install --target=i386-pc "$DISK"
    grub-mkconfig -o /boot/grub/grub.cfg
fi
