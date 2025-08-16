#!/bin/bash
set -e

# Configuración global
declare -A CONFIG=(
    # Sistema
    [HOSTNAME]="0xterminal"                      # Nombre del equipo
    [TIMEZONE]="America/Lima"                 # Zona horaria
    [KEYMAP]="la-latin1"                      # Distribución del teclado
    [LOCALE]="es_ES.UTF-8"                   # Idioma del sistema
    
    # Particiones (en GB, usar 0 para espacio restante)
    [SWAP_SIZE]=4                            # Tamaño de SWAP
    [ROOT_SIZE]=20                           # Tamaño de /
    [HOME_SIZE]=0                            # Tamaño de /home
    
    # ZRAM
    [ZRAM_SIZE]=1024                         # Tamaño de ZRAM en MB
    [ZRAM_ALGORITHM]="zstd"                  # Algoritmo de compresión
    
    # Paquetes adicionales (separados por espacios)
    [EXTRA_PACKAGES]="git"   # Paquetes extra a instalar
)

# Configuración del repositorio
REPO_URL="https://raw.githubusercontent.com/umbraflare-code/sistema/master"
REQUIRED_FILES=("configure_system.sh" "init.vim" "tmux.conf")

# Colores
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[1;33m"
NC="\033[0m"

# Variables globales para particiones
EFI=""
ROOT=""

# Funciones de utilidad
log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Verificar carpeta config
if [ ! -d "config" ]; then
    log "Carpeta config no encontrada, descargando archivos..."
    mkdir -p config
    
    for file in "${REQUIRED_FILES[@]}"; do
        log "Descargando $file..."
        if ! curl -o "config/$file" "${REPO_URL}/config/$file"; then
            error "No se pudo descargar $file"
            error "Verifica tu conexión a internet o el repositorio:"
            error "${REPO_URL}/config/$file"
            rm -rf config
            exit 1
        fi
    done
    
    chmod +x config/configure_system.sh
    log "Archivos de configuración descargados correctamente"
else
    log "Usando archivos de configuración existentes"
    for file in "${REQUIRED_FILES[@]}"; do
        if [ ! -f "config/$file" ]; then
            error "Archivo config/$file no encontrado"
            error "La carpeta config está incompleta"
            exit 1
        fi
    done
fi

# Función principal
main() {
    local disk=$1
    local username=$2

    # Validar parámetros
    if [ -z "$disk" ] || [ -z "$username" ]; then
        error "Uso: $0 /dev/sdX usuario"
        exit 1
    fi

    # Configurar trap para limpieza
    trap cleanup EXIT

    # Verificar modo UEFI
    if [ -d "/sys/firmware/efi" ]; then
        log "Modo UEFI detectado"
        UEFI=1
    else
        log "Modo BIOS detectado"
        UEFI=0
    fi

    # Instalación base
    log "Instalando base..."
    pacstrap /mnt base linux linux-firmware

    # Generar fstab
    genfstab -U /mnt >> /mnt/etc/fstab

    # Copiar scripts de configuración
    install -Dm755 config/configure_system.sh "/mnt/root/configure_system.sh"
    install -Dm644 config/tmux.conf "/mnt/root/tmux.conf"
    install -Dm644 config/init.vim "/mnt/root/init.vim"

    # Aplicar configuraciones personalizadas
    log "Aplicando configuraciones personalizadas..."
    sed -i "s/archtty/${CONFIG[HOSTNAME]}/g" /mnt/root/configure_system.sh
    sed -i "s|America/Lima|${CONFIG[TIMEZONE]}|g" /mnt/root/configure_system.sh
    sed -i "s/es_ES.UTF-8/${CONFIG[LOCALE]}/g" /mnt/root/configure_system.sh
    sed -i "s/la-latin1/${CONFIG[KEYMAP]}/g" /mnt/root/configure_system.sh
    sed -i "s/zram-size = 1024/zram-size = ${CONFIG[ZRAM_SIZE]}/g" /mnt/root/configure_system.sh
    sed -i "s/compression-algorithm = zstd/compression-algorithm = ${CONFIG[ZRAM_ALGORITHM]}/g" /mnt/root/configure_system.sh

    # Instalar paquetes adicionales
    if [ -n "${CONFIG[EXTRA_PACKAGES]}" ]; then
        log "Instalando paquetes adicionales..."
        pacstrap /mnt ${CONFIG[EXTRA_PACKAGES]}
    fi

    # Ejecutar configuración dentro de chroot
    arch-chroot /mnt bash /root/configure_system.sh "$username" "$disk"

    # Desactivar trap antes de los mensajes finales
    trap - EXIT
    
    # Mensaje de finalización
    echo
    echo -e "${GREEN}"
    echo "=============================================="
    echo "    ¡INSTALACIÓN COMPLETADA EXITOSAMENTE!    "
    echo "=============================================="
    echo -e "${NC}"
    echo
    log "Configuración del sistema:"
    log "  • Usuario: $username (contraseña: $username)"
    log "  • Root: contraseña 'root'"
    log "  • Hostname: ${CONFIG[HOSTNAME]}"
    log "  • Entorno: tmux + Neovim configurado para programación"
    log "  • ZRAM activado (${CONFIG[ZRAM_SIZE]}MB)"
    log "  • Bootloader instalado"
    echo
    log "Para continuar:"
    log "  1. Retira el USB de instalación"
    log "  2. Reinicia el sistema: reboot"
    log "  3. Inicia sesión con tu usuario"
    echo
    log "Comandos útiles para desarrollo:"
    log "  • nvim archivo.c    # Editor con plantillas"
    log "  • F5 en nvim        # Compilar y ejecutar C"
    log "  • F6 en nvim        # Compilar y ejecutar C++"
    log "  • tmux              # Multiplexor de terminal"
    log "  • htop              # Monitor de recursos"
    echo
    warn "RECORDATORIO: Cambia las contraseñas por defecto después del primer inicio"
    
    return 0
}

# Función para limpiar en caso de error
cleanup() {
    local exit_code=$?
    
    # Solo ejecutar limpieza si hubo error
    if [ $exit_code -ne 0 ]; then
        log "Realizando limpieza..."
        
        # Desmontar /mnt si está montado
        if mountpoint -q /mnt 2>/dev/null; then
            log "Desmontando sistema de archivos..."
            if ! umount -R /mnt 2>/dev/null; then
                warn "Desmontaje normal falló, intentando desmontaje forzado..."
                umount -Rf /mnt 2>/dev/null || true
            fi
        fi
        
        error "La instalación falló. Revisa los mensajes de error anteriores."
        error "Para reintentar:"
        error "  1. Ejecuta 'umount -R /mnt' si es necesario"
        error "  2. Ejecuta el script nuevamente"
    fi
    
    exit $exit_code
}

# Ejecutar script principal
main "$@"