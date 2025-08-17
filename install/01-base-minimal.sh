#!/bin/bash
# Instalación base ultra-mínima para Celeron 4GB
# Uso: ./01-base-minimal.sh /dev/sda username

set -e

# Variables
DISK=${1:-/dev/sda}
USERNAME=${2:-user}
MOUNT_POINT="/mnt"

echo "🚀 Instalación base ultra-mínima para Celeron 4GB"
echo "Disco: $DISK"
echo "Usuario: $USERNAME"

# Solicitar contraseñas al inicio
echo ""
echo "🔐 Configuración de contraseñas:"
echo "================================"

# Contraseña para root
echo -n "Ingresa la contraseña para root: "
read -s ROOT_PASSWORD
echo ""

# Confirmar contraseña de root
echo -n "Confirma la contraseña para root: "
read -s ROOT_PASSWORD_CONFIRM
echo ""

# Verificar que coincidan
if [ "$ROOT_PASSWORD" != "$ROOT_PASSWORD_CONFIRM" ]; then
    echo "❌ Error: Las contraseñas de root no coinciden"
    exit 1
fi

# Contraseña para usuario
echo -n "Ingresa la contraseña para $USERNAME: "
read -s USER_PASSWORD
echo ""

# Confirmar contraseña de usuario
echo -n "Confirma la contraseña para $USERNAME: "
read -s USER_PASSWORD_CONFIRM
echo ""

# Verificar que coincidan
if [ "$USER_PASSWORD" != "$USER_PASSWORD_CONFIRM" ]; then
    echo "❌ Error: Las contraseñas de usuario no coinciden"
    exit 1
fi

echo "✅ Contraseñas configuradas correctamente"
echo ""

# Verificar que estamos en modo UEFI o BIOS
if [ -d /sys/firmware/efi/efivars ]; then
    echo "✅ Modo UEFI detectado"
    EFI_PARTITION="${DISK}1"
    ROOT_PARTITION="${DISK}2"
else
    echo "✅ Modo BIOS detectado"
    ROOT_PARTITION="${DISK}1"
fi

# Crear particiones
echo "📦 Creando particiones..."
if [ -d /sys/firmware/efi/efivars ]; then
    # UEFI
    parted -s $DISK mklabel gpt
    parted -s $DISK mkpart ESP fat32 1MiB 513MiB
    parted -s $DISK set 1 esp on
    parted -s $DISK mkpart primary ext4 513MiB 100%
    
    mkfs.fat -F32 $EFI_PARTITION
    mkfs.ext4 $ROOT_PARTITION
    
    mount $ROOT_PARTITION $MOUNT_POINT
    mkdir -p $MOUNT_POINT/boot/efi
    mount $EFI_PARTITION $MOUNT_POINT/boot/efi
else
    # BIOS
    parted -s $DISK mklabel msdos
    parted -s $DISK mkpart primary ext4 1MiB 100%
    
    mkfs.ext4 $ROOT_PARTITION
    mount $ROOT_PARTITION $MOUNT_POINT
fi

# Paquetes críticos solamente
BASE_PACKAGES=(
    base 
    linux-lts 
    linux-lts-headers 
    linux-firmware
    networkmanager
    sudo
    gcc 
    make 
    git 
    neovim 
    tmux
    bash-completion
)

echo ">> Instalando paquetes base..."
# Configurar pacman para no extraer documentación
mkdir -p $MOUNT_POINT/etc
echo '[options]' > $MOUNT_POINT/etc/pacman.conf
echo 'NoExtract = usr/share/man/* usr/share/doc/*' >> $MOUNT_POINT/etc/pacman.conf

# Configurar pacman para ser más tolerante con conexiones lentas
echo 'ParallelDownloads = 1' >> $MOUNT_POINT/etc/pacman.conf
echo 'Timeout = 300' >> $MOUNT_POINT/etc/pacman.conf
echo 'ConnectTimeout = 60' >> $MOUNT_POINT/etc/pacman.conf

# Función para instalar paquetes con reintentos
install_packages_with_retry() {
    local max_attempts=5
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        echo ">> Intento $attempt de $max_attempts - Instalando paquetes base..."
        
        if pacstrap --needed $MOUNT_POINT "${BASE_PACKAGES[@]}"; then
            echo "✅ Paquetes instalados exitosamente en el intento $attempt"
            return 0
        else
            echo "❌ Error en el intento $attempt"
            if [ $attempt -lt $max_attempts ]; then
                echo "🔄 Esperando 30 segundos antes del siguiente intento..."
                sleep 30
                echo "🔄 Limpiando cache de pacman..."
                pacman -Sc --noconfirm || true
            fi
        fi
        attempt=$((attempt + 1))
    done
    
    echo "❌ Error: No se pudieron instalar los paquetes después de $max_attempts intentos"
    return 1
}

# Instalar paquetes con reintentos
if ! install_packages_with_retry; then
    echo "⚠️ Instalación masiva falló, intentando instalar paquetes individualmente..."
    
    # Función para instalar paquetes individuales con reintentos
    install_single_package() {
        local package=$1
        local max_attempts=3
        local attempt=1
        
        while [ $attempt -le $max_attempts ]; do
            echo ">> Instalando $package (intento $attempt/$max_attempts)..."
            
            if pacstrap --needed $MOUNT_POINT "$package"; then
                echo "✅ $package instalado exitosamente"
                return 0
            else
                echo "❌ Error instalando $package (intento $attempt)"
                if [ $attempt -lt $max_attempts ]; then
                    echo "🔄 Esperando 20 segundos..."
                    sleep 20
                fi
            fi
            attempt=$((attempt + 1))
        done
        
        echo "❌ Error: No se pudo instalar $package después de $max_attempts intentos"
        return 1
    }
    
    # Instalar paquetes críticos uno por uno
    critical_packages=("base" "linux-lts" "linux-firmware" "networkmanager")
    
    for package in "${critical_packages[@]}"; do
        if ! install_single_package "$package"; then
            echo "❌ Error crítico: No se pudo instalar $package"
            echo "💡 Sugerencia: Verifica tu conexión a internet y ejecuta el script nuevamente"
            exit 1
        fi
    done
    
    # Instalar paquetes no críticos
    non_critical_packages=("linux-lts-headers" "sudo" "gcc" "make" "git" "neovim" "tmux" "bash-completion")
    
    for package in "${non_critical_packages[@]}"; do
        install_single_package "$package" || echo "⚠️ Advertencia: $package no se pudo instalar, continuando..."
    done
fi

# Configuración mínima del sistema
echo "⚙️ Configurando sistema base..."

# Locale
echo "en_US.UTF-8 UTF-8" > $MOUNT_POINT/etc/locale.gen
arch-chroot $MOUNT_POINT locale-gen
echo "LANG=en_US.UTF-8" > $MOUNT_POINT/etc/locale.conf
echo "KEYMAP=us" > $MOUNT_POINT/etc/vconsole.conf

# Hostname
echo "celeron-minimal" > $MOUNT_POINT/etc/hostname

# Fstab
genfstab -U $MOUNT_POINT >> $MOUNT_POINT/etc/fstab

# Usuario
arch-chroot $MOUNT_POINT useradd -m -G wheel -s /bin/bash $USERNAME
echo "🔐 Configurando contraseñas..."
echo "root:$ROOT_PASSWORD" | arch-chroot $MOUNT_POINT chpasswd
echo "$USERNAME:$USER_PASSWORD" | arch-chroot $MOUNT_POINT chpasswd
echo "$USERNAME ALL=(ALL) ALL" >> $MOUNT_POINT/etc/sudoers

# ZRAM inmediato
echo "💾 Configurando ZRAM..."
cat > $MOUNT_POINT/etc/systemd/zram-generator.conf << EOF
[zram0]
zram-size = 1024
compression-algorithm = lz4
EOF

# Optimizaciones kernel
echo "⚡ Configurando optimizaciones kernel..."
cat > $MOUNT_POINT/etc/sysctl.d/99-performance.conf << EOF
# Memoria
vm.swappiness=5
vm.vfs_cache_pressure=50
vm.dirty_background_ratio=5
vm.dirty_ratio=10

# CPU scheduler 
kernel.sched_migration_cost_ns=500000
kernel.sched_autogroup_enabled=0

# Red
net.core.netdev_max_backlog=1000
EOF

# Configuración makepkg optimizada (en el sistema instalado)
echo "🔧 Configurando makepkg..."
cat > $MOUNT_POINT/etc/makepkg.conf << EOF
# Optimizaciones para Celeron
CFLAGS="-O2 -march=native -mtune=native -pipe"
CXXFLAGS="\$CFLAGS"
MAKEFLAGS="-j2"
COMPRESSGZ=(gzip -c -f -n)
COMPRESSBZ2=(bzip2 -c -f)
COMPRESSXZ=(xz -c -z -)
COMPRESSZST=(zstd -c -z -q -)
COMPRESSLZ=(lzip -c -f)
COMPRESSLRZ=(lrzip -q)
COMPRESSLZO=(lzop -q)
COMPRESSZ=(compress -c -f)
COMPRESSLZ4=(lz4 -q)
COMPRESSLZMA=(lzma -c -q)
COMPRESSZSTD=(zstd -c -q)
EOF

# Deshabilitar servicios no críticos
echo "🚫 Deshabilitando servicios no críticos..."
arch-chroot $MOUNT_POINT systemctl disable systemd-resolved
arch-chroot $MOUNT_POINT systemctl disable systemd-timesyncd

# Habilitar servicios críticos
echo ">> Habilitando servicios críticos..."
echo "DEBUG: Variables actuales:"
echo "DISK=$DISK"
echo "USERNAME=$USERNAME" 
echo "MOUNT_POINT=$MOUNT_POINT"

echo "Presiona ENTER para continuar con NetworkManager..."
read

# Habilitar NetworkManager
arch-chroot $MOUNT_POINT systemctl enable NetworkManager

echo "Presiona ENTER para continuar con ZRAM..."
read
# Habilitar ZRAM
arch-chroot $MOUNT_POINT systemctl enable systemd-zram-setup@zram0

# Configuración bash optimizada
echo "🐚 Configurando bash..."
cat > $MOUNT_POINT/home/$USERNAME/.bashrc << EOF
# Aliases ultra-rápidos
alias c='gcc -O2 -march=native'
alias cpp='g++ -O2 -march=native -std=c++17'
alias v='nvim'
alias l='ls -la'
alias ..='cd ..'

# Función compilar y ejecutar
cr() { gcc -O2 "\$1" -o "\${1%.*}" && ./"\${1%.*}"; }

# Prompt minimalista
PS1='[\u@\h \W]\$ '

# Historial optimizado
HISTSIZE=1000
HISTFILESIZE=2000
HISTCONTROL=ignoreboth
EOF

# Permisos
chown $USERNAME:$USERNAME $MOUNT_POINT/home/$USERNAME/.bashrc

echo "✅ Instalación base completada!"
echo "📋 Próximos pasos:"
echo "   1. Ejecutar: ./02-x11-dwm-setup.sh"
echo "   2. Ejecutar: ./03-essential-tools.sh"
echo "   3. Reiniciar y disfrutar del rendimiento máximo!"
echo ""
echo "🔐 Información de acceso:"
echo "   Usuario: $USERNAME"
echo "   Contraseña: [La que ingresaste]"
echo "   Root: [La contraseña que ingresaste]"