#!/bin/bash
set -e

# Uso: ./arch-install-auto.sh /dev/sdX usuario
# Ejemplo: ./arch-install-auto.sh /dev/sda pepe

if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Uso: $0 /dev/sdX nombre_usuario"
    exit 1
fi

DISK="$1"
NEW_USER="$2"

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()   { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Confirmar entorno live Arch
[ -f /etc/arch-release ] || { error "Debes estar en el live de Arch Linux"; exit 1; }

# Confirmar disco
[ -b "$DISK" ] || { error "El disco $DISK no existe"; exit 1; }

warn "ADVERTENCIA: Se borrará TODO en $DISK"
if [ -d /sys/firmware/efi ]; then
    echo "Modo detectado: UEFI"
    echo "Partición EFI: 512MB FAT32"
else
    echo "Modo detectado: BIOS Legacy"
fi
echo "Partición raíz: 20GB ext4"
echo "Partición home: resto del espacio"
read -p "Presiona Enter para continuar o Ctrl+C para cancelar..."

log "Configurando teclado y NTP..."
loadkeys la-latin1
timedatectl set-ntp true

# === PARTICIONES ===
log "Particionando disco..."
wipefs -af "$DISK"
sgdisk --zap-all "$DISK"

if [ -d /sys/firmware/efi ]; then
    # UEFI
    sgdisk -n 1:0:+512M -t 1:ef00 "$DISK"   # EFI
    sgdisk -n 2:0:+20G  -t 2:8300 "$DISK"   # root
    sgdisk -n 3:0:0     -t 3:8300 "$DISK"   # home
else
    # BIOS Legacy
    sgdisk -n 1:0:+20G  -t 1:8300 "$DISK"   # root
    sgdisk -n 2:0:0     -t 2:8300 "$DISK"   # home
fi

partprobe "$DISK"
sleep 2

if [[ "$DISK" == *"nvme"* ]]; then
    ROOT_PARTITION="${DISK}p2"
    HOME_PARTITION="${DISK}p3"
    EFI_PART="${DISK}p1"
    if [ ! -d /sys/firmware/efi ]; then
        ROOT_PARTITION="${DISK}p1"
        HOME_PARTITION="${DISK}p2"
    fi
else
    ROOT_PARTITION="${DISK}2"
    HOME_PARTITION="${DISK}3"
    EFI_PART="${DISK}1"
    if [ ! -d /sys/firmware/efi ]; then
        ROOT_PARTITION="${DISK}1"
        HOME_PARTITION="${DISK}2"
    fi
fi

# === FORMATEO ===
log "Formateando..."
if [ -d /sys/firmware/efi ]; then
    mkfs.fat -F32 "$EFI_PART"
fi
mkfs.ext4 -F "$ROOT_PARTITION"
mkfs.ext4 -F "$HOME_PARTITION"

# === MONTAJES ===
log "Montando..."
mount "$ROOT_PARTITION" /mnt
mkdir -p /mnt/home
mount "$HOME_PARTITION" /mnt/home
if [ -d /sys/firmware/efi ]; then
    mkdir -p /mnt/boot
    mount "$EFI_PART" /mnt/boot
fi

# === INSTALACIÓN BASE ===
log "Instalando base..."
pacstrap /mnt base linux linux-firmware \
    base-devel git neovim tmux w3m imagemagick \
    zram-generator ttf-monofur-nerd chafa htop wget curl \
    make gcc gdb cmake pkgconf networkmanager sudo grub efibootmgr os-prober

log "Generando fstab..."
genfstab -U /mnt >> /mnt/etc/fstab

# === CONFIGURAR SISTEMA ===
log "Creando script de configuración dentro del sistema..."
cat > /mnt/configure_system.sh << EOF
#!/bin/bash
set -e

ln -sf /usr/share/zoneinfo/America/Lima /etc/localtime
hwclock --systohc

# Locale
echo "es_ES.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=es_ES.UTF-8" > /etc/locale.conf
echo "KEYMAP=la-latin1" > /etc/vconsole.conf

# Hostname
echo "archtty" > /etc/hostname
cat > /etc/hosts << 'HOSTS_EOF'
127.0.0.1   localhost
::1         localhost
127.0.1.1   archtty.localdomain archtty
HOSTS_EOF

# ZRAM
mkdir -p /etc/systemd/zram-generator.conf.d
cat > /etc/systemd/zram-generator.conf << 'ZRAM_EOF'
[zram0]
zram-size = 1024
compression-algorithm = zstd
ZRAM_EOF
systemctl enable systemd-zram-setup@zram0

# Compilación optimizada
sed -i 's/^#MAKEFLAGS=.*/MAKEFLAGS="-j$(nproc)"/' /etc/makepkg.conf
sed -i 's/^CFLAGS=.*/CFLAGS="-march=native -O2 -pipe -fstack-protector-strong -fno-plt"/' /etc/makepkg.conf
sed -i 's/^CXXFLAGS=.*/CXXFLAGS="\${CFLAGS}"/' /etc/makepkg.conf

# Network
systemctl enable NetworkManager

# Root password
echo "root:root" | chpasswd

# Crear usuario
useradd -m -G wheel -s /bin/bash "$NEW_USER"
echo "$NEW_USER:$NEW_USER" | chpasswd
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

# Gestor de arranque
if [ -d /sys/firmware/efi ]; then
    # UEFI
    bootctl install
    PARTUUID=\$(blkid -s PARTUUID -o value \$(findmnt -n -o SOURCE /))
    mkdir -p /boot/loader/entries
    cat > /boot/loader/loader.conf << 'LOADER_EOF'
default arch.conf
timeout 3
console-mode max
editor no
LOADER_EOF
    cat > /boot/loader/entries/arch.conf << ENTRY_EOF
title   Arch Linux
linux   /vmlinuz-linux
initrd  /initramfs-linux.img
options root=PARTUUID=\${PARTUUID} rw
ENTRY_EOF
else
    # BIOS Legacy
    grub-install --target=i386-pc "$DISK"
    grub-mkconfig -o /boot/grub/grub.cfg
fi
EOF

arch-chroot /mnt bash /configure_system.sh
rm /mnt/configure_system.sh

log "Desmontando..."
umount -R /mnt

log "¡Instalación completada!"
echo "Usuario creado: $NEW_USER / contraseña: $NEW_USER"
echo "Root contraseña: root"
read -p "¿Reiniciar ahora? (y/N) " r
[[ \$r =~ ^[Yy]\$ ]] && reboot
