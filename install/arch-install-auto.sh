#!/bin/bash
# Instalador automático de Arch Linux optimizado para laptop vieja (Celeron + 4GB RAM DDR3 + HDD)
# Uso: bash 01-arch-install-auto.sh <dispositivo_disco> (ej: /dev/sda)

set -euo pipefail

DISK="${1:-/dev/sda}"

echo "==> Iniciando instalación automática en $DISK"
timedatectl set-ntp true

echo "==> Borrando particiones antiguas en $DISK"
wipefs -a "$DISK"

echo "==> Creando tabla de particiones"
parted -s "$DISK" mklabel gpt
parted -s "$DISK" mkpart ESP fat32 1MiB 513MiB
parted -s "$DISK" set 1 boot on
parted -s "$DISK" mkpart primary ext4 513MiB 100%

BOOT="${DISK}1"
ROOT="${DISK}2"

echo "==> Formateando particiones"
mkfs.fat -F32 "$BOOT"
mkfs.ext4 "$ROOT"

echo "==> Montando particiones"
mount "$ROOT" /mnt
mkdir -p /mnt/boot
mount "$BOOT" /mnt/boot

echo "==> Configurando mirrors rápidos"
reflector --latest 10 --sort rate --save /etc/pacman.d/mirrorlist

echo "==> Instalando sistema base"
pacstrap /mnt base linux linux-firmware vim sudo man-db man-pages less reflector git curl

echo "==> Generando fstab"
genfstab -U /mnt >> /mnt/etc/fstab

echo "==> Configuración básica dentro del sistema"
arch-chroot /mnt /bin/bash <<EOF
ln -sf /usr/share/zoneinfo/UTC /etc/localtime
hwclock --systohc
echo "es_ES.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=es_ES.UTF-8" > /etc/locale.conf
echo "archceleron" > /etc/hostname

cat <<EON > /etc/hosts
127.0.0.1   localhost
::1         localhost
127.0.1.1   archceleron.localdomain archceleron
EON

echo "==> Creando usuario"
echo "root:root" | chpasswd
useradd -m -G wheel -s /bin/bash dev
echo "dev:dev" | chpasswd
echo "%wheel ALL=(ALL:ALL) ALL" >> /etc/sudoers

echo "==> Instalando gestor de arranque systemd-boot"
bootctl install
cat <<EON > /boot/loader/entries/arch.conf
title   Arch Linux
linux   /vmlinuz-linux
initrd  /initramfs-linux.img
options root=$ROOT rw
EON
EOF

echo ""
echo "==> Instalación base completada ✅"
echo ""

read -p "¿Quieres ejecutar la configuración avanzada (sistema + tmux + vim)? [s/n]: " RESP
if [[ "\$RESP" =~ ^[sS]$ ]]; then
    echo "==> Descargando y ejecutando configure..."
    arch-chroot /mnt /bin/bash -c "curl -fsSL https://mi-servidor.com/arch/02-configure-system.sh | bash"
else
    echo "==> Finalizando instalación. Puedes reiniciar y acceder a tu nuevo sistema."
fi
