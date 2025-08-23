#!/bin/bash
# X11 y bspwm con configuración de repositorios
# Uso: ./02-x11-bspwm.sh

set -e

echo "🖥️ Configurando X11 y bspwm con repositorios..."

# Verificar que estamos en Arch Linux
if [ ! -f /etc/arch-release ]; then
    echo "❌ Error: Este script está diseñado para Arch Linux"
    exit 1
fi

# Verificar si estamos como root
if [ "$EUID" -ne 0 ]; then
    echo "❌ Error: Este script debe ejecutarse como root (sudo)"
    exit 1
fi

# Configurar repositorios de Arch Linux
echo "📦 Configurando repositorios de Arch Linux..."

# Crear configuración de pacman si no existe
if [ ! -f /etc/pacman.conf ]; then
    echo "⚙️ Creando configuración de pacman..."
    cat > /etc/pacman.conf << 'EOF'
#
# /etc/pacman.conf
#
# See the pacman.conf(5) manpage for option and repository directives

#
# GENERAL OPTIONS
#
[options]
# The following paths are commented out with their default values listed.
# If you wish to use different paths, uncomment and update the paths.
#RootDir     = /
#DBPath      = /var/lib/pacman/
#CacheDir    = /var/cache/pacman/pkg/
#LogFile     = /var/log/pacman.log
#GPGDir      = /etc/pacman.d/gnupg/
#HookDir     = /etc/pacman.d/hooks/
HoldPkg     = pacman glibc
#XferCommand = /usr/bin/curl -L -C - -f -o %o %u
#XferCommand = /usr/bin/wget --passive-ftp -c -O %o %u
#CleanMethod = KeepInstalled
Architecture = auto

# Pacman won't upgrade packages listed in IgnorePkg and members of IgnoreGroup
#IgnorePkg   =
#IgnoreGroup =

#NoUpgrade   =
#NoExtract   =

# Misc options
#UseSyslog
#Color
#NoProgressBar
CheckSpace
#VerbosePkgLists
ParallelDownloads = 5

# By default, pacman accepts packages signed by keys that its local keyring
# trusts (see pacman-key and its man page), as well as unsigned packages.
SigLevel    = Never
LocalFileSigLevel = Never
#RemoteFileSigLevel = Required

# NOTE: You must run `pacman-key --init` before first using pacman; the local
# keyring can then be populated with the keys of all official Arch Linux
# packagers with `pacman-key --populate archlinux`.

#
# REPOSITORIES
#   - can be defined here or included from another file
#   - pacman will search repositories in the order defined here
#   - local/custom mirrors can be added here or in separate files
#   - repositories listed first will take precedence when packages
#     have identical names, regardless of version number
#   - URLs will have $repo replaced by the name of the current repo
#   - URLs will have $arch replaced by the name of the architecture

# Repository entries are of the format:
#       [repo-name]
#       Server = ServerName
#       Include = IncludePath

# The testing repositories are disabled by default. To enable, uncomment the
# repo name header and Include lines. You can add preferred servers immediately
# after the header, and they will be used before the default mirrors.

#[testing]
#Include = /etc/pacman.d/mirrorlist

[core]
Include = /etc/pacman.d/mirrorlist

[extra]
Include = /etc/pacman.d/mirrorlist

#[community-testing]
#Include = /etc/pacman.d/mirrorlist

[community]
Include = /etc/pacman.d/mirrorlist

# If you want to run 32 bit applications on your x86_64 system,
# enable the multilib repositories as required here.

#[multilib-testing]
#Include = /etc/pacman.d/mirrorlist

[multilib]
Include = /etc/pacman.d/mirrorlist

# An example of a custom package repository.  See the pacman manpage for
# tips on creating your own repositories.
#[custom]
#SigLevel = Optional TrustAll
#Server = file:///home/custompkgs
EOF
    echo "✅ Configuración de pacman creada"
fi

# Crear mirrorlist si no existe
if [ ! -f /etc/pacman.d/mirrorlist ]; then
    echo "🌐 Creando mirrorlist..."
    mkdir -p /etc/pacman.d
    cat > /etc/pacman.d/mirrorlist << 'EOF'
## Arch Linux repository mirrorlist
## Generated on 2024-01-01

## Global
Server = https://mirrors.kernel.org/archlinux/$repo/os/$arch
Server = https://mirror.rackspace.com/archlinux/$repo/os/$arch
Server = https://mirror.umd.edu/archlinux/$repo/os/$arch
Server = https://mirrors.edge.kernel.org/archlinux/$repo/os/$arch
Server = https://mirror.csclub.uwaterloo.ca/archlinux/$repo/os/$arch
Server = https://mirror.pkgbuild.com/$repo/os/$arch
EOF
    echo "✅ Mirrorlist creado"
fi

# Inicializar base de datos de pacman si no existe
if [ ! -d /var/lib/pacman ]; then
    echo "🗄️ Inicializando base de datos de pacman..."
    mkdir -p /var/lib/pacman
    pacman -Sy
    echo "✅ Base de datos inicializada"
fi

# Actualizar repositorios
echo "📦 Actualizando repositorios..."
pacman -Sy

# Verificar conexión a internet
echo "🌐 Verificando conexión a internet..."
if ! ping -c 1 archlinux.org >/dev/null 2>&1; then
    echo "❌ Error: No hay conexión a internet"
    echo "💡 Conecta a internet antes de continuar"
    exit 1
fi

# Función para instalar paquetes con verificación
install_package_safe() {
    local package=$1
    local max_attempts=3
    local attempt=1
    
    echo "📦 Instalando: $package"
    
    while [ $attempt -le $max_attempts ]; do
        echo "   Intento $attempt/$max_attempts..."
        
        # Verificar espacio antes de instalar
        AVAILABLE_SPACE=$(df / | awk 'NR==2 {print $4}')
        if [ "$AVAILABLE_SPACE" -lt 100000 ]; then  # 100MB mínimo
            echo "   ⚠️ Espacio insuficiente, limpiando cache..."
            pacman -Sc --noconfirm || true
            rm -rf /tmp/* || true
        fi
        
        if pacman -S --noconfirm "$package"; then
            echo "   ✅ $package instalado exitosamente"
            return 0
        else
            echo "   ❌ Error en intento $attempt"
            if [ $attempt -lt $max_attempts ]; then
                echo "   🔄 Esperando 10 segundos..."
                sleep 10
                echo "   📦 Actualizando repositorios..."
                pacman -Sy || true
            fi
        fi
        attempt=$((attempt + 1))
    done
    
    echo "   ❌ Error: No se pudo instalar $package"
    return 1
}

# Instalar X11 mínimo
echo "🖥️ Instalando X11 mínimo..."

X11_PACKAGES=(
    "xorg-server"
    "xorg-xinit"
    "xf86-video-intel"
    "xf86-input-libinput"
    "xorg-xset"
    "xorg-xsetroot"
    "libx11"
    "libxft"
    "libxinerama"
    "freetype2"
    "ttf-monofur-nerd"
)

for package in "${X11_PACKAGES[@]}"; do
    if ! pacman -Q "$package" >/dev/null 2>&1; then
        if ! install_package_safe "$package"; then
            echo "⚠️ Advertencia: $package no se pudo instalar, continuando..."
        fi
    else
        echo "✅ $package ya está instalado"
    fi
done

# Instalar bspwm y sxhkd
echo "🏗️ Instalando bspwm y sxhkd..."

BSPWM_PACKAGES=(
    "bspwm"
    "sxhkd"
)

for package in "${BSPWM_PACKAGES[@]}"; do
    if ! pacman -Q "$package" >/dev/null 2>&1; then
        if ! install_package_safe "$package"; then
            echo "⚠️ Advertencia: $package no se pudo instalar"
        fi
    else
        echo "✅ $package ya está instalado"
    fi
done

# Instalar terminal st (compilado desde source)
echo "🔨 Compilando st ligero..."

if ! command -v st >/dev/null 2>&1; then
    # Instalar dependencias de compilación primero
    BUILD_DEPS=("base-devel" "git" "fontconfig")
    
    for dep in "${BUILD_DEPS[@]}"; do
        if ! pacman -Q "$dep" >/dev/null 2>&1; then
            if ! install_package_safe "$dep"; then
                echo "⚠️ Advertencia: $dep no se pudo instalar"
            fi
        fi
    done
    
    cd /tmp
    if [ -d "st" ]; then
        rm -rf st
    fi
    
    # Clonar st
    if git clone --depth=1 https://git.suckless.org/st; then
        cd st

        # Compilar con optimizaciones
        make clean
        make install
        
        # Limpiar archivos de compilación
        cd /
        rm -rf /tmp/st
        
        echo "✅ st compilado e instalado"
    else
        echo "❌ Error: No se pudo clonar st"
        echo "⚠️ Instalando xterm como alternativa..."
        install_package_safe "xterm"
    fi
else
    echo "✅ st ya está instalado"
fi

# Instalar ly display manager
echo "🔐 Instalando ly display manager..."
if ! command -v ly >/dev/null 2>&1; then
    if install_package_safe "ly"; then
        systemctl enable ly
        echo "✅ ly instalado y habilitado"
    else
        echo "⚠️ ly no disponible, continuando sin display manager"
    fi
else
    echo "✅ ly ya está instalado"
fi

# Configuración X11 mínima
echo "⚙️ Configurando X11 mínimo..."

# Obtener el usuario actual (no root)
CURRENT_USER=$(logname 2>/dev/null || echo $SUDO_USER)
if [ -z "$CURRENT_USER" ]; then
    echo "❌ Error: No se pudo determinar el usuario actual"
    exit 1
fi

# Crear directorio de configuración
mkdir -p /home/$CURRENT_USER/.config

# Copiar configuraciones del sistema si existen
if [ -d "/home/$CURRENT_USER/sistema-install/config" ]; then
    echo "📁 Copiando configuraciones del sistema..."
    
    # Copiar configuración de bspwm
    if [ -d "/home/$CURRENT_USER/sistema-install/config/bspwm" ]; then
        cp -r /home/$CURRENT_USER/sistema-install/config/bspwm /home/$CURRENT_USER/.config/
        chmod +x /home/$CURRENT_USER/.config/bspwm/bspwmrc
        echo "✅ Configuración bspwm copiada"
    fi
    
    # Copiar configuración de sxhkd
    if [ -d "/home/$CURRENT_USER/sistema-install/config/sxhkd" ]; then
        cp -r /home/$CURRENT_USER/sistema-install/config/sxhkd /home/$CURRENT_USER/.config/
        echo "✅ Configuración sxhkd copiada"
    fi
    
    # Copiar configuración de st
    if [ -d "/home/$CURRENT_USER/sistema-install/config/st" ]; then
        cp -r /home/$CURRENT_USER/sistema-install/config/st /home/$CURRENT_USER/.config/
        echo "✅ Configuración st copiada"
    fi
    
    # Copiar scripts de rendimiento
    if [ -d "/home/$CURRENT_USER/sistema-install/scripts" ]; then
        mkdir -p /usr/local/bin
        cp /home/$CURRENT_USER/sistema-install/scripts/*.sh /usr/local/bin/
        chmod +x /usr/local/bin/*.sh
        echo "✅ Scripts de rendimiento copiados"
    fi
fi

# Configuración de bspwm
if [ ! -d "/home/$CURRENT_USER/.config/bspwm" ]; then
    mkdir -p /home/$CURRENT_USER/.config/bspwm
    cp /usr/share/doc/bspwm/examples/bspwmrc /home/$CURRENT_USER/.config/bspwm/bspwmrc
    chmod +x /home/$CURRENT_USER/.config/bspwm/bspwmrc
    echo "✅ bspwmrc copiado desde ejemplos"
fi

# Configuración de sxhkd
if [ ! -d "/home/$CURRENT_USER/.config/sxhkd" ]; then
    mkdir -p /home/$CURRENT_USER/.config/sxhkd
    cp /usr/share/doc/bspwm/examples/sxhkdrc /home/$CURRENT_USER/.config/sxhkd/sxhkdrc
    echo "✅ sxhkdrc copiado desde ejemplos"
fi

# Configurar .xinitrc
if [ ! -f /home/$CURRENT_USER/.xinitrc ]; then
    cat > /home/$CURRENT_USER/.xinitrc << 'EOF'
#!/bin/sh
# X11 ultra-minimal con bspwm
xset r rate 300 50        # Teclado rápido

sxhkd &
exec bspwm
EOF

    chmod +x /home/$CURRENT_USER/.xinitrc
    echo "✅ .xinitrc configurado"
else
    echo "✅ .xinitrc ya existe"
fi

# Configurar permisos de los archivos
chown -R $CURRENT_USER:$CURRENT_USER /home/$CURRENT_USER/.config/bspwm
chown -R $CURRENT_USER:$CURRENT_USER /home/$CURRENT_USER/.config/sxhkd
chown $CURRENT_USER:$CURRENT_USER /home/$CURRENT_USER/.xinitrc

# Configuración X11 optimizada
# mkdir -p /etc/X11/xorg.conf.d
# cat > /etc/X11/xorg.conf.d/10-performance.conf << 'EOF'
# Section "Device"
#     Identifier "Intel"
#     Driver "intel"
#     Option "AccelMethod" "sna"
#     Option "TearFree" "true"
#     Option "DRI" "3"
# EndSection

# Section "Monitor"
#     Identifier "Monitor0"
#     Option "DPMS" "false"
# EndSection
# 
# Section "ServerLayout"
#     Identifier "Layout0"
#     Screen 0 "Screen0"
# EndSection
# 
# Section "Screen"
#     Identifier "Screen0"
#     Device "Intel"
#     Monitor "Monitor0"
#     DefaultDepth 24
#     SubSection "Display"
#         Depth 24
#         Modes "1024x768" "800x600"
#     EndSubSection
# EndSection
# EOF

# Limpiar archivos temporales
echo "🧹 Limpiando archivos temporales..."
pacman -Sc --noconfirm || true
rm -rf /tmp/* /var/tmp/* || true

echo "✅ X11 y bspwm configurados!"
echo ""
echo "📊 Información del sistema:"
echo "   Usuario actual: $CURRENT_USER"
echo "   bspwm instalado: $(command -v bspwm >/dev/null 2>&1 && echo "Sí" || echo "No")"
echo "   sxhkd instalado: $(command -v sxhkd >/dev/null 2>&1 && echo "Sí" || echo "No")"
echo "   st instalado: $(command -v st >/dev/null 2>&1 && echo "Sí" || echo "No")"
echo "   ly instalado: $(command -v ly >/dev/null 2>&1 && echo "Sí" || echo "No")"
echo "   Espacio restante: $((AVAILABLE_SPACE / 1024))MB"

echo ""
echo "📋 Próximos pasos:"
echo "   1. Reiniciar el sistema"
echo "   2. Iniciar sesión con ly (o ejecutar 'startx' manualmente)"
echo "   3. ¡Disfrutar del escritorio ultra-minimalista con bspwm!"

echo ""
echo "🎯 Atajos de bspwm:"
echo "   Super + Enter - Abrir terminal"
echo "   Super + d - Abrir dmenu"
echo "   Super + q - Cerrar ventana"
echo "   Super + m - Alternar monocle/tiled"
echo "   Super + j/k - Navegar ventanas"
echo "   Super + 1-5 - Cambiar escritorio"
echo "   Super + f - Fullscreen"