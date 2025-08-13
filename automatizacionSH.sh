#!/bin/bash
set -e

# Uso: ./arch-install-auto.sh /dev/sdX
# Ejemplo: ./arch-install-auto.sh /dev/sda

# === CONFIGURACIÓN PREVIA ===
if [ -z "$1" ]; then
    echo "Uso: $0 /dev/sdX"
    exit 1
fi

DISK="$1"
ROOT_PARTITION="${DISK}1"
HOME_PARTITION="${DISK}2"

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

# Confirmación
warn "ADVERTENCIA: Se borrará TODO en $DISK"
echo "Partición raíz: 20GB ext4"
echo "Partición home: resto del espacio"
read -p "Presiona Enter para continuar o Ctrl+C para cancelar..."

log "Iniciando instalación automatizada de Arch Linux..."

# === PASOS DE INSTALACIÓN ===
log "Configurando teclado y NTP..."
loadkeys la-latin1
timedatectl set-ntp true

log "Particionando disco..."
wipefs -af "$DISK"
sgdisk --zap-all "$DISK"
sgdisk -n 1:0:+20G -t 1:8300 "$DISK"  # root
sgdisk -n 2:0:0 -t 2:8300 "$DISK"     # home
partprobe "$DISK"
sleep 2

# Ajustar para NVMe
if [[ "$DISK" == *"nvme"* ]]; then
    ROOT_PARTITION="${DISK}p1"
    HOME_PARTITION="${DISK}p2"
fi

log "Formateando..."
mkfs.ext4 -F "$ROOT_PARTITION"
mkfs.ext4 -F "$HOME_PARTITION"

log "Montando..."
mount "$ROOT_PARTITION" /mnt
mkdir -p /mnt/home
mount "$HOME_PARTITION" /mnt/home

log "Instalando base..."
pacstrap /mnt base linux linux-firmware \
    base-devel git neovim tmux w3m imagemagick \
    zram-generator ttf-monofur-nerd chafa htop wget curl \
    make gcc gdb cmake pkgconf networkmanager

log "Generando fstab..."
genfstab -U /mnt >> /mnt/etc/fstab

log "Configurando sistema..."
cat > /mnt/configure_system.sh << 'EOF'
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
sed -i 's/^CXXFLAGS=.*/CXXFLAGS="${CFLAGS}"/' /etc/makepkg.conf

# Network
systemctl enable NetworkManager

# Root password
echo "Configurando contraseña de root..."
echo "root:root" | chpasswd
echo "ADVERTENCIA: La contraseña de root es 'root'. Cámbiala después del primer arranque."

# Crear usuario normal
echo "Creando usuario normal..."
read -p "Nombre del usuario: " NEW_USER
if [ -n "$NEW_USER" ]; then
    useradd -m -G wheel -s /bin/bash "$NEW_USER"
    echo "Establece contraseña para $NEW_USER:"
    passwd "$NEW_USER"
    
    # Configurar sudo
    pacman -S --noconfirm sudo
    sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
    echo "Usuario $NEW_USER creado con permisos sudo."
else
    echo "No se creó usuario adicional. Usa 'root' para el primer arranque."
fi

# Bootloader systemd-boot
bootctl install
PARTUUID=$(blkid -s PARTUUID -o value $(findmnt -n -o SOURCE /))

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
options root=PARTUUID=${PARTUUID} rw
ENTRY_EOF

EOF

arch-chroot /mnt bash /configure_system.sh
rm /mnt/configure_system.sh

log "Desmontando..."
umount -R /mnt

log "¡Instalación completada!"
echo
echo "Resumen de la instalación:"
echo "- Disco usado: $DISK"
echo "- Partición raíz: $ROOT_PARTITION (20GB)"
echo "- Partición home: $HOME_PARTITION (resto del espacio)"
echo "- Hostname: archtty"
echo "- Zona horaria: America/Lima"
echo "- Locale: es_ES.UTF-8"
echo "- Bootloader: systemd-boot"
echo "- NetworkManager habilitado"
echo "- Nerd Font instalada: ttf-monofur-nerd (para tmux y terminal gráfica)"
echo
warn "IMPORTANTE:"
echo "1. La contraseña de root es 'root' - cámbiala inmediatamente"
echo "2. El sistema está listo para reiniciar"
echo
read -p "¿Reiniciar ahora? (y/N) " r
[[ $r =~ ^[Yy]$ ]] && reboot
