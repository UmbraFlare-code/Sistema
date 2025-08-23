#!/bin/bash
# Instalación base ultra-mínima para Celeron 4GB - Compatible con bspwm
# Uso: ./01-base.sh /dev/sda username

set -e

# Variables
DISK=${1:-/dev/sda}
USERNAME=${2:-user}
MOUNT_POINT="/mnt"

# Solicitar contraseñas al inicio
echo ""
echo "🔐 Configuración de contraseñas:"
echo "================================"

# Contraseña para root
echo -n "Ingresa la contraseña para root: "
read -s ROOT_PASSWORD

# Confirmar contraseña de root
echo -n "Confirma la contraseña para root: "
read -s ROOT_PASSWORD_CONFIRM

# Verificar que coincidan
if [ "$ROOT_PASSWORD" != "$ROOT_PASSWORD_CONFIRM" ]; then
    echo "❌ Error: Las contraseñas de root no coinciden"
    exit 1
fi

# Contraseña para usuario
echo -n "Ingresa la contraseña para $USERNAME: "
read -s USER_PASSWORD

# Confirmar contraseña de usuario
echo -n "Confirma la contraseña para $USERNAME: "
read -s USER_PASSWORD_CONFIRM

# Verificar que coincidan
if [ "$USER_PASSWORD" != "$USER_PASSWORD_CONFIRM" ]; then
    echo "❌ Error: Las contraseñas de usuario no coinciden"
    exit 1
fi

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

# Configurar pacman para no extraer documentación y optimizar para bspwm
mkdir -p $MOUNT_POINT/etc

cat > $MOUNT_POINT/etc/pacman.conf << 'EOF'
[options]
Architecture = auto
CheckSpace
Color
ParallelDownloads = 5
SigLevel = Required DatabaseOptional
LocalFileSigLevel = Optional
NoExtract = usr/share/man/* usr/share/doc/* usr/share/gtk-doc/* usr/share/help/*

[core]
Include = /etc/pacman.d/mirrorlist

[extra]
Include = /etc/pacman.d/mirrorlist

[community]
Include = /etc/pacman.d/mirrorlist

[multilib]
Include = /etc/pacman.d/mirrorlist
EOF

# Crear mirrorlist optimizado
mkdir -p $MOUNT_POINT/etc/pacman.d
echo "🌐 Configurando mirrorlist optimizada..."
cat > $MOUNT_POINT/etc/pacman.d/mirrorlist << 'EOF'
## Arch Linux repository mirrorlist
## Generated for optimal performance

## Global mirrors - fastest and most reliable
Server = https://mirrors.kernel.org/archlinux/$repo/os/$arch
Server = https://mirror.rackspace.com/archlinux/$repo/os/$arch
Server = https://mirror.umd.edu/archlinux/$repo/os/$arch
Server = https://mirrors.edge.kernel.org/archlinux/$repo/os/$arch
Server = https://mirror.csclub.uwaterloo.ca/archlinux/$repo/os/$arch
Server = https://archlinux.uk.mirror.allworldit.com/archlinux/$repo/os/$arch
Server = https://mirror.pkgbuild.com/$repo/os/$arch
EOF

# Función para instalar un paquete individual con reintentos
install_package_with_retry() {
    local package=$1
    local max_attempts=5
    local attempt=1
    
    echo "📦 Instalando: $package"
    
    while [ $attempt -le $max_attempts ]; do
        echo "   Intento $attempt/$max_attempts..."
        
        if pacstrap $MOUNT_POINT "$package"; then
            echo "   ✅ $package instalado exitosamente"
            return 0
        else
            echo "   ❌ Error en intento $attempt"
            if [ $attempt -lt $max_attempts ]; then
                echo "   🔄 Esperando 15 segundos antes del siguiente intento..."
                sleep 15
                echo "   🧹 Limpiando cache..."
                pacman -Sc --noconfirm || true
            fi
        fi
        attempt=$((attempt + 1))
    done
    
    echo "   ❌ Error: No se pudo instalar $package después de $max_attempts intentos"
    return 1
}

echo "🚀 Iniciando instalación recursiva de paquetes..."

# =========================
# Paquetes críticos (obligatorios)
# =========================
critical_packages=("base" "linux-lts" "linux-firmware" "networkmanager")
echo "📋 Paquetes críticos: ${critical_packages[*]}"

for package in "${critical_packages[@]}"; do
    if ! install_package_with_retry "$package"; then
        echo "❌ Error crítico: No se pudo instalar $package"
        echo "💡 El sistema no puede funcionar sin este paquete"
        exit 1
    fi
done

# =========================
# Paquetes importantes (continuar aunque fallen algunos)
# =========================
important_packages=("linux-lts-headers" "sudo" "gcc" "make" "base-devel" "git")
echo "📋 Paquetes importantes: ${important_packages[*]}"

for package in "${important_packages[@]}"; do
    if ! install_package_with_retry "$package"; then
        echo "⚠️ Advertencia: $package no se pudo instalar, continuando..."
    fi
done

# =========================
# Paquetes opcionales para entorno de desarrollo
# =========================
optional_packages=("neovim" "bash-completion" "wget" "curl" "tree" "htop" "unzip" "zip")
echo "📋 Paquetes opcionales para desarrollo: ${optional_packages[*]}"

for package in "${optional_packages[@]}"; do
    if ! install_package_with_retry "$package"; then
        echo "⚠️ Advertencia: $package no se pudo instalar, continuando..."
    fi
done

# =========================
# Paquetes para Laravel (PHP + DB + Composer)
# =========================
laravel_packages=("php" "php-gd" "php-pgsql" "php-sqlite" "php-mysql" "php-curl" "php-xml" "php-zip" "composer" "mariadb" "sqlite")
echo "📋 Paquetes para Laravel: ${laravel_packages[*]}"

for package in "${laravel_packages[@]}"; do
    if ! install_package_with_retry "$package"; then
        echo "⚠️ Advertencia: $package no se pudo instalar, Laravel puede no funcionar correctamente..."
    fi
done

# =========================
# Paquetes para React (Node.js + gestores de paquetes)
# =========================
react_packages=("nodejs" "npm" "pnpm")
echo "📋 Paquetes para React: ${react_packages[*]}"

for package in "${react_packages[@]}"; do
    if ! install_package_with_retry "$package"; then
        echo "⚠️ Advertencia: $package no se pudo instalar, React puede no funcionar correctamente..."
    fi
done

# =========================
# Paquetes extra para mejorar Neovim / NvChad
# =========================
neovim_extras=("tree-sitter" "ripgrep" "fd")
echo "📋 Paquetes extra para Neovim: ${neovim_extras[*]}"

for package in "${neovim_extras[@]}"; do
    if ! install_package_with_retry "$package"; then
        echo "⚠️ Advertencia: $package no se pudo instalar, algunas funciones de Neovim pueden fallar..."
    fi
done

echo "✅ Instalación de paquetes completada"

# Configuración mínima del sistema
echo "⚙️ Configurando sistema base..."

# Locale
echo "en_US.UTF-8 UTF-8" > $MOUNT_POINT/etc/locale.gen
arch-chroot $MOUNT_POINT locale-gen
echo "LANG=en_US.UTF-8" > $MOUNT_POINT/etc/locale.conf
echo "KEYMAP=la-latin1" > $MOUNT_POINT/etc/vconsole.conf

# Hostname
echo "0xTerminal" > $MOUNT_POINT/etc/hostname

# Configurar hosts
cat > $MOUNT_POINT/etc/hosts << 'EOF'
127.0.0.1   localhost
::1         localhost
127.0.1.1   0xTerminal.localdomain 0xTerminal
EOF

# Fstab
genfstab -U $MOUNT_POINT >> $MOUNT_POINT/etc/fstab

# Usuario
echo "👤 Creando usuario: $USERNAME"
arch-chroot $MOUNT_POINT useradd -m -G wheel -s /bin/bash $USERNAME
if [ $? -eq 0 ]; then
    echo "✅ Usuario $USERNAME creado exitosamente"
else
    echo "❌ Error: No se pudo crear el usuario $USERNAME"
    exit 1
fi

echo "🔐 Configurando contraseñas..."
echo "root:$ROOT_PASSWORD" | arch-chroot $MOUNT_POINT chpasswd
echo "$USERNAME:$USER_PASSWORD" | arch-chroot $MOUNT_POINT chpasswd

# Configurar sudoers para bspwm
echo "🔧 Configurando sudoers..."
cat > $MOUNT_POINT/etc/sudoers << 'EOF'
##
## Sudoers minimal para Arch + bspwm
##

# Usuario root
root ALL=(ALL) ALL

# Permitir a los usuarios del grupo wheel ejecutar cualquier comando con sudo
%wheel ALL=(ALL) ALL

# (Opcional) Descomentar para permitir sudo sin contraseña:
# %wheel ALL=(ALL) NOPASSWD: ALL

# Incluir configuraciones adicionales en /etc/sudoers.d
#includedir /etc/sudoers.d
EOF

# ZRAM inmediato
echo "💾 Configurando ZRAM..."
cat > $MOUNT_POINT/etc/systemd/zram-generator.conf << EOF
[zram0]
zram-size = 1024
compression-algorithm = lz4
EOF

# Optimizaciones kernel específicas para bspwm
echo "⚡ Configurando optimizaciones kernel para bspwm..."
cat > $MOUNT_POINT/etc/sysctl.d/99-performance.conf << EOF
# Memoria optimizada para bspwm
vm.swappiness=5
vm.vfs_cache_pressure=50
vm.dirty_background_ratio=5
vm.dirty_ratio=10
vm.dirty_expire_centisecs=1500

# CPU scheduler optimizado para desktop
kernel.sched_migration_cost_ns=500000
kernel.sched_autogroup_enabled=1
kernel.sched_wakeup_granularity_ns=2000000

# Red optimizada
net.core.netdev_max_backlog=1000
net.core.rmem_max=16777216
net.core.wmem_max=16777216

# Filesystem optimizado para SSD/HDD
vm.dirty_writeback_centisecs=1500
vm.page-cluster=0

# X11/bspwm optimizations
kernel.sched_latency_ns=6000000
kernel.sched_min_granularity_ns=750000
EOF

# Deshabilitar servicios no críticos
echo "🚫 Deshabilitando servicios no críticos..."
arch-chroot $MOUNT_POINT systemctl mask systemd-resolved
arch-chroot $MOUNT_POINT systemctl disable systemd-timesyncd
arch-chroot $MOUNT_POINT systemctl disable systemd-networkd

# Habilitar servicios críticos
echo "✅ Habilitando servicios críticos..."

# Habilitar NetworkManager
echo "🌐 Habilitando NetworkManager..."
arch-chroot $MOUNT_POINT systemctl enable NetworkManager

# Habilitar ZRAM si está disponible
echo "💾 Configurando ZRAM..."
if arch-chroot $MOUNT_POINT systemctl enable systemd-zram-setup@zram0.service 2>/dev/null; then
    echo "✅ ZRAM habilitado correctamente"
else
    echo "⚠️ ZRAM no disponible en esta versión, intentando método alternativo..."
    # Crear servicio ZRAM manual si no existe systemd-zram-setup
    cat > $MOUNT_POINT/etc/systemd/system/zram.service << 'EOF'
[Unit]
Description=Swap with zram
After=multi-user.target

[Service]
Type=oneshot  
RemainAfterExit=true
ExecStartPre=/sbin/modprobe zram num_devices=1
ExecStart=/bin/sh -c 'echo lz4 > /sys/block/zram0/comp_algorithm'
ExecStart=/bin/sh -c 'echo 1G > /sys/block/zram0/disksize'
ExecStart=/sbin/mkswap --label zram0 /dev/zram0
ExecStart=/sbin/swapon --priority 100 /dev/zram0
ExecStop=/sbin/swapoff /dev/zram0
ExecStop=/bin/sh -c 'echo 1 > /sys/block/zram0/reset'

[Install]
WantedBy=multi-user.target
EOF
    arch-chroot $MOUNT_POINT systemctl enable zram.service
    echo "✅ ZRAM manual configurado"
fi

# Configuración bash optimizada para bspwm
echo "🐚 Configurando bash para desarrollo con bspwm..."
cat > $MOUNT_POINT/home/$USERNAME/.bashrc << EOF
# .bashrc optimizado para desarrollo en bspwm

# Si no es interactivo, salir inmediatamente
case \$- in
    *i*) ;;
      *) return;;
esac

# Historial optimizado
HISTCONTROL=ignoreboth
HISTSIZE=1000
HISTFILESIZE=2000
shopt -s histappend

# Verificar tamaño de ventana después de cada comando
shopt -s checkwinsize

# Hacer que less sea más amigable para archivos no-texto
[ -x /usr/bin/lesspipe ] && eval "\$(SHELL=/bin/sh lesspipe)"

# Configurar prompt
if [ "\$EUID" -eq 0 ]; then
    PS1='\[\033[01;31m\]\h\[\033[01;34m\] \W \$\[\033[00m\] '
else
    PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
fi

# Habilitar completado de comandos
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# Aliases ultra-rápidos para desarrollo
alias ls='ls --color=auto'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# Aliases para desarrollo optimizado
alias c='gcc -O2 -march=native -Wall'
alias cpp='g++ -O2 -march=native -Wall -std=c++17'
alias py='python3'
alias v='nvim'

# Funciones útiles para desarrollo
cr() {
    if [ -z "\$1" ]; then
        echo "Uso: cr archivo.c [argumentos...]"
        return 1
    fi
    gcc -O2 -march=native -Wall "\$1" -o "\${1%.*}" && .//"\${1%.*}" "\${@:2}"
}

cpprun() {
    if [ -z "\$1" ]; then
        echo "Uso: cpprun archivo.cpp [argumentos...]"
        return 1
    fi
    g++ -O2 -march=native -Wall -std=c++17 "\$1" -o "\${1%.*}" && ./"\${1%.*}" "\${@:2}"
}

# Función para performance rápido
perf_mode() {
    sudo sh -c 'echo performance > /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor' 2>/dev/null || echo "Governor no disponible"
    sudo sh -c 'echo 3 > /proc/sys/vm/drop_caches'
    echo "Modo performance activado"
}

# Función para limpiar compilaciones
cleanc() {
    find . -name "*.o" -delete
    find . -name "a.out" -delete
    find . -type f -executable -not -name "*.sh" -not -name "*.py" -delete 2>/dev/null || true
    echo "Archivos de compilación limpiados"
}

# Configuración específica para bspwm
export EDITOR=nvim
export VISUAL=nvim
export BROWSER=firefox
export TERMINAL=st

# Optimización de PATH para herramientas de desarrollo
export PATH="\$HOME/.local/bin:/usr/local/bin:\$PATH"
EOF

# Permisos
arch-chroot $MOUNT_POINT chown $USERNAME:$USERNAME /home/$USERNAME/.bashrc

# Instalar y configurar GRUB (bootloader)
echo "🔧 Instalando GRUB bootloader..."
if ! install_package_with_retry "grub"; then
    echo "❌ Error: No se pudo instalar GRUB"
    echo "💡 El sistema no podrá iniciar sin un bootloader"
    exit 1
fi

# Instalar efibootmgr para UEFI si es necesario
if [ -d /sys/firmware/efi/efivars ]; then
    echo "🔧 Instalando efibootmgr para UEFI..."
    if ! install_package_with_retry "efibootmgr"; then
        echo "⚠️ Advertencia: efibootmgr no disponible, continuando..."
    fi
fi

# Configurar GRUB
echo "⚙️ Configurando GRUB..."
if [ -d /sys/firmware/efi/efivars ]; then
    # UEFI
    arch-chroot $MOUNT_POINT grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
else
    # BIOS
    arch-chroot $MOUNT_POINT grub-install --target=i386-pc $DISK
fi

# Generar configuración GRUB optimizada para bspwm
echo "📝 Generando configuración GRUB optimizada..."
cat > $MOUNT_POINT/etc/default/grub << EOF
# Configuración GRUB optimizada para bspwm
GRUB_DEFAULT=0
GRUB_TIMEOUT=1
GRUB_DISTRIBUTOR="Arch"
GRUB_CMDLINE_LINUX_DEFAULT="quiet loglevel=3 rd.systemd.show_status=false rd.udev.log_priority=3 transparent_hugepage=never"
GRUB_CMDLINE_LINUX=""
GRUB_DISABLE_OS_PROBER=true
GRUB_DISABLE_SUBMENU=true
GRUB_TERMINAL_OUTPUT=console
GRUB_DISABLE_RECOVERY=true
EOF

# Generar grub.cfg
arch-chroot $MOUNT_POINT grub-mkconfig -o /boot/grub/grub.cfg
echo "✅ GRUB instalado y configurado correctamente!"

# Configurar timezone
echo "🕐 Configurando timezone..."
arch-chroot $MOUNT_POINT ln -sf /usr/share/zoneinfo/America/Lima /etc/localtime
arch-chroot $MOUNT_POINT hwclock --systohc

echo "💡 Comandos útiles después del reinicio:"
echo "   perf_mode - Activar modo rendimiento"
echo "   cleanc - Limpiar archivos de compilación"
echo "   cr archivo.c - Compilar y ejecutar C"
echo "   cpprun archivo.cpp - Compilar y ejecutar C++"