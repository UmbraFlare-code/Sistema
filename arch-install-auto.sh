#!/bin/bash
set -e

# Configuración global
declare -A CONFIG=(
    # Sistema
    [HOSTNAME]="archtty"                      # Nombre del equipo
    [TIMEZONE]="America/Lima"                 # Zona horaria
    [KEYMAP]="la-latin1"                      # Distribución del teclado
    [LOCALE]="es_ES.UTF-8"                   # Idioma del sistema
    
    # Particiones (en GB, usar 0 para espacio restante)
    [SWAP_SIZE]=4                            # Tamaño de SWAP
    [ROOT_SIZE]=20                           # Tamaño de /
    [HOME_SIZE]=0                            # Tamaño de /home (0 = resto del disco)
    
    # ZRAM
    [ZRAM_SIZE]=1024                         # Tamaño de ZRAM en MB
    [ZRAM_ALGORITHM]="zstd"                  # Algoritmo de compresión
    
    # Paquetes adicionales (separados por espacios)
    [EXTRA_PACKAGES]="git"   # Paquetes extra a instalar
)

# Configuración del repositorio
REPO_URL="https://raw.githubusercontent.com/umbraflare-code/sistema/master"
REQUIRED_FILES=("configure_system.sh" "init.vim" "tmux.conf")

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Funciones de logging
log()   { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }
info()  { echo -e "${BLUE}[INFO]${NC} $1"; }

# Función para mostrar ayuda
show_help() {
    cat << EOF
Uso: $0 [OPCIONES] DISCO [USUARIO]

ARGUMENTOS:
    DISCO      Dispositivo de destino (ej: /dev/sda, /dev/nvme0n1)
    USUARIO    Nombre del usuario a crear (opcional, se preguntará si no se proporciona)

OPCIONES:
    -h, --help     Mostrar esta ayuda
    -c, --check    Verificar requisitos sin instalar
    -v, --verbose  Modo verboso

EJEMPLOS:
    $0 /dev/sda usuario
    $0 --check /dev/nvme0n1
    
CONFIGURACIÓN:
    Edita el array CONFIG al inicio del script para personalizar la instalación.
EOF
}

# Verificar requisitos del sistema
check_requirements() {
    local errors=0
    
    info "Verificando requisitos del sistema..."
    
    # Verificar que estamos en Arch Linux live
    if [ ! -f /etc/arch-release ]; then
        error "Debes estar ejecutando desde el live USB de Arch Linux"
        ((errors++))
    fi
    
    # Verificar conexión a internet
    if ! ping -c 1 google.com &>/dev/null; then
        error "No hay conexión a internet"
        ((errors++))
    fi
    
    # Verificar herramientas necesarias
    local tools=("sgdisk" "pacstrap" "genfstab" "arch-chroot" "curl" "wipefs" "partprobe")
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &>/dev/null; then
            error "Herramienta requerida no encontrada: $tool"
            ((errors++))
        fi
    done
    
    # Verificar que no haya instalaciones previas montadas
    if mountpoint -q /mnt 2>/dev/null; then
        error "/mnt está montado. Desmonta antes de continuar:"
        error "  umount -R /mnt"
        ((errors++))
    fi
    
    return $errors
}

# Función para desmontar todas las particiones de un disco
unmount_disk() {
    local disk="$1"
    local mounted_partitions=()
    
    # Buscar todas las particiones montadas del disco
    while IFS= read -r line; do
        if [[ "$line" =~ ^($disk[p]?[0-9]+) ]]; then
            mounted_partitions+=("${BASH_REMATCH[1]}")
        fi
    done < <(mount | grep "^$disk")
    
    # Si hay particiones montadas, desmontarlas
    if [ ${#mounted_partitions[@]} -gt 0 ]; then
        warn "Encontradas particiones montadas del disco $disk:"
        for partition in "${mounted_partitions[@]}"; do
            warn "  - $partition"
        done
        
        read -p "¿Desmontar automáticamente? (Y/n): " -r
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            log "Desmontando particiones..."
            for partition in "${mounted_partitions[@]}"; do
                log "Desmontando $partition..."
                if ! umount "$partition" 2>/dev/null; then
                    warn "No se pudo desmontar $partition, intentando desmontaje forzado..."
                    if ! umount -f "$partition" 2>/dev/null; then
                        error "No se pudo desmontar $partition"
                        error "Cierra todas las aplicaciones que puedan estar usando esta partición"
                        return 1
                    fi
                fi
            done
            log "Todas las particiones desmontadas correctamente"
        else
            error "No se puede continuar con particiones montadas"
            return 1
        fi
    fi
    
    return 0
}

# Función para validar el disco
validate_disk() {
    local disk="$1"
    
    if [ -z "$disk" ]; then
        error "No se especificó el disco"
        return 1
    fi
    
    if [ ! -b "$disk" ]; then
        error "El disco $disk no existe o no es un dispositivo de bloque"
        return 1
    fi
    
    # Verificar si el disco o sus particiones están montadas
    if mount | grep -q "^$disk"; then
        if ! unmount_disk "$disk"; then
            return 1
        fi
    fi
    
    # Verificar si hay procesos usando el disco
    if command -v lsof &>/dev/null; then
        local processes
        processes=$(lsof "$disk"* 2>/dev/null || true)
        if [ -n "$processes" ]; then
            error "Hay procesos usando el disco $disk:"
            echo "$processes"
            error "Cierra todas las aplicaciones antes de continuar"
            return 1
        fi
    fi
    
    return 0
}

# Función para obtener nombre de usuario
get_username() {
    local username="$1"
    
    while [ -z "$username" ]; do
        read -p "Ingresa el nombre del usuario: " username
        if [ -z "$username" ]; then
            error "El nombre de usuario no puede estar vacío"
        elif [[ ! "$username" =~ ^[a-z][a-z0-9_-]*$ ]]; then
            error "Nombre de usuario inválido. Debe comenzar con letra minúscula y contener solo letras, números, _ o -"
            username=""
        fi
    done
    
    echo "$username"
}

# Función para descargar archivos de configuración
download_config_files() {
    info "Verificando archivos de configuración..."
    
    if [ ! -d "config" ]; then
        log "Creando directorio config y descargando archivos..."
        mkdir -p config
        
        for file in "${REQUIRED_FILES[@]}"; do
            log "Descargando $file..."
            local url="${REPO_URL}/config/$file"
            
            if ! curl -fsSL -o "config/$file" "$url"; then
                error "No se pudo descargar $file desde $url"
                error "Verifica tu conexión a internet y que el repositorio sea accesible"
                rm -rf config
                return 1
            fi
        done
        
        chmod +x config/configure_system.sh
        log "Archivos de configuración descargados correctamente"
    else
        log "Usando archivos de configuración existentes"
        
        # Verificar que todos los archivos existan
        for file in "${REQUIRED_FILES[@]}"; do
            if [ ! -f "config/$file" ]; then
                error "Archivo config/$file no encontrado"
                error "La carpeta config está incompleta. Elimínala y ejecuta nuevamente el script"
                return 1
            fi
        done
    fi
    
    return 0
}

# Función para mostrar información del disco
show_disk_info() {
    local disk="$1"
    
    info "Información del disco $disk:"
    echo "================================"
    
    # Mostrar información básica del disco
    if command -v lsblk &>/dev/null; then
        lsblk "$disk" 2>/dev/null || true
    fi
    
    echo
    
    # Mostrar tamaño del disco
    if [ -f "/sys/block/$(basename "$disk")/size" ]; then
        local sectors=$(cat "/sys/block/$(basename "$disk")/size")
        local size_gb=$((sectors * 512 / 1024 / 1024 / 1024))
        echo "Tamaño total: ${size_gb}GB"
    fi
    
    # Mostrar particiones existentes
    if command -v sgdisk &>/dev/null; then
        if sgdisk -p "$disk" 2>/dev/null | grep -q "Number"; then
            warn "Particiones existentes que serán ELIMINADAS:"
            sgdisk -p "$disk" 2>/dev/null | grep -A20 "Number"
        fi
    fi
    
    echo "================================"
    echo
}

# Función para mostrar configuración
show_configuration() {
    info "Configuración actual:"
    echo "======================"
    echo "Hostname: ${CONFIG[HOSTNAME]}"
    echo "Zona horaria: ${CONFIG[TIMEZONE]}"
    echo "Teclado: ${CONFIG[KEYMAP]}"
    echo "Idioma: ${CONFIG[LOCALE]}"
    echo "SWAP: ${CONFIG[SWAP_SIZE]}GB"
    echo "Root: ${CONFIG[ROOT_SIZE]}GB"
    echo "Home: ${CONFIG[HOME_SIZE]}GB (0 = resto del disco)"
    echo "ZRAM: ${CONFIG[ZRAM_SIZE]}MB (${CONFIG[ZRAM_ALGORITHM]})"
    echo "Paquetes extra: ${CONFIG[EXTRA_PACKAGES]}"
    echo "======================"
    echo
}

# Función para particionar el disco
partition_disk() {
    local disk="$1"
    
    log "Particionando disco $disk..."
    
    # Asegurarse de que no hay procesos usando el disco
    sync
    sleep 1
    
    # Limpiar el disco completamente
    log "Limpiando tabla de particiones..."
    wipefs -af "$disk" 2>/dev/null || true
    sgdisk --zap-all "$disk" 2>/dev/null || true
    
    # Esperar a que los cambios se apliquen
    partprobe "$disk" 2>/dev/null || true
    sleep 2
    
    # Crear nuevas particiones según el tipo de sistema
    if [ -d /sys/firmware/efi ]; then
        log "Sistema UEFI detectado - Creando particiones UEFI"
        sgdisk -n 1:0:+512M -t 1:ef00 -c 1:"EFI System" "$disk"
        sgdisk -n 2:0:+${CONFIG[ROOT_SIZE]}G -t 2:8300 -c 2:"Linux Root" "$disk"
        sgdisk -n 3:0:0 -t 3:8300 -c 3:"Linux Home" "$disk"
    else
        log "Sistema BIOS detectado - Creando particiones MBR"
        sgdisk -n 1:0:+${CONFIG[ROOT_SIZE]}G -t 1:8300 -c 1:"Linux Root" "$disk"
        sgdisk -n 2:0:0 -t 2:8300 -c 2:"Linux Home" "$disk"
    fi
    
    # Actualizar tabla de particiones
    partprobe "$disk" 2>/dev/null || true
    sleep 3
    
    # Definir variables de particiones
    if [[ "$disk" == *"nvme"* ]] || [[ "$disk" == *"mmcblk"* ]]; then
        if [ -d /sys/firmware/efi ]; then
            EFI="${disk}p1"
            ROOT="${disk}p2"
            HOME="${disk}p3"
        else
            ROOT="${disk}p1"
            HOME="${disk}p2"
        fi
    else
        if [ -d /sys/firmware/efi ]; then
            EFI="${disk}1"
            ROOT="${disk}2"
            HOME="${disk}3"
        else
            ROOT="${disk}1"
            HOME="${disk}2"
        fi
    fi
    
    # Verificar que las particiones se crearon correctamente
    local max_attempts=10
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if [ -b "$ROOT" ] && [ -b "$HOME" ] && ([ -z "$EFI" ] || [ -b "$EFI" ]); then
            log "Particiones creadas correctamente"
            break
        fi
        
        warn "Intento $attempt/$max_attempts: Esperando que aparezcan las particiones..."
        sleep 2
        partprobe "$disk" 2>/dev/null || true
        ((attempt++))
        
        if [ $attempt -gt $max_attempts ]; then
            error "No se pudieron crear las particiones después de $max_attempts intentos"
            return 1
        fi
    done
}

# Función para formatear particiones
format_partitions() {
    log "Formateando particiones..."
    
    # Formatear EFI si existe
    if [ -n "$EFI" ] && [ -d /sys/firmware/efi ]; then
        log "Formateando partición EFI: $EFI"
        mkfs.fat -F32 "$EFI"
    fi
    
    # Formatear Root
    log "Formateando partición root: $ROOT"
    mkfs.ext4 -F "$ROOT"
    
    # Formatear Home
    log "Formateando partición home: $HOME"
    mkfs.ext4 -F "$HOME"
}

# Función para montar particiones
mount_partitions() {
    log "Montando particiones..."
    
    # Montar root
    mount "$ROOT" /mnt
    
    # Crear y montar home
    mkdir -p /mnt/home
    mount "$HOME" /mnt/home
    
    # Montar EFI si existe
    if [ -n "$EFI" ] && [ -d /sys/firmware/efi ]; then
        mkdir -p /mnt/boot
        mount "$EFI" /mnt/boot
    fi
}

# Función para instalar sistema base
install_base_system() {
    log "Instalando sistema base..."
    
    local base_packages=(
        base linux linux-firmware
        base-devel git neovim tmux w3m imagemagick
        zram-generator ttf-monofur-nerd chafa htop wget curl
        make gcc gdb cmake pkgconf networkmanager sudo grub
    )
    
    # Añadir efibootmgr si es sistema UEFI
    if [ -d /sys/firmware/efi ]; then
        base_packages+=(efibootmgr)
    fi
    
    # Añadir os-prober
    base_packages+=(os-prober)
    
    pacstrap /mnt "${base_packages[@]}"
    
    # Instalar paquetes adicionales si están especificados
    if [ -n "${CONFIG[EXTRA_PACKAGES]}" ]; then
        log "Instalando paquetes adicionales: ${CONFIG[EXTRA_PACKAGES]}"
        pacstrap /mnt ${CONFIG[EXTRA_PACKAGES]}
    fi
}

# Función para configurar el sistema
configure_system() {
    local username="$1"
    local disk="$2"
    
    log "Configurando sistema..."
    
    # Generar fstab
    genfstab -U /mnt >> /mnt/etc/fstab
    
    # Copiar archivos de configuración
    install -Dm755 config/configure_system.sh "/mnt/root/configure_system.sh"
    install -Dm644 config/tmux.conf "/mnt/root/tmux.conf"
    install -Dm644 config/init.vim "/mnt/root/init.vim"
    
    # Aplicar configuraciones personalizadas al script de configuración
    log "Aplicando configuraciones personalizadas..."
    sed -i "s/archtty/${CONFIG[HOSTNAME]}/g" /mnt/root/configure_system.sh
    sed -i "s|America/Lima|${CONFIG[TIMEZONE]}|g" /mnt/root/configure_system.sh
    sed -i "s/es_ES.UTF-8/${CONFIG[LOCALE]}/g" /mnt/root/configure_system.sh
    sed -i "s/la-latin1/${CONFIG[KEYMAP]}/g" /mnt/root/configure_system.sh
    sed -i "s/zram-size = 1024/zram-size = ${CONFIG[ZRAM_SIZE]}/g" /mnt/root/configure_system.sh
    sed -i "s/compression-algorithm = zstd/compression-algorithm = ${CONFIG[ZRAM_ALGORITHM]}/g" /mnt/root/configure_system.sh
    
    # Ejecutar configuración dentro de chroot
    log "Ejecutando configuración del sistema..."
    arch-chroot /mnt bash /root/configure_system.sh "$username" "$disk"
}

# Función para limpiar en caso de error
cleanup() {
    local exit_code=$?
    
    log "Realizando limpieza..."
    
    # Desmontar /mnt si está montado
    if mountpoint -q /mnt 2>/dev/null; then
        log "Desmontando sistema de archivos..."
        if ! umount -R /mnt 2>/dev/null; then
            warn "Desmontaje normal falló, intentando desmontaje forzado..."
            umount -Rf /mnt 2>/dev/null || true
        fi
    fi
    
    # Cerrar dispositivos dm-crypt si existen
    if command -v cryptsetup &>/dev/null; then
        for mapper in /dev/mapper/*; do
            if [[ "$mapper" != "/dev/mapper/control" ]] && [ -b "$mapper" ]; then
                local name=$(basename "$mapper")
                if cryptsetup status "$name" &>/dev/null; then
                    log "Cerrando dispositivo cifrado: $name"
                    cryptsetup close "$name" 2>/dev/null || true
                fi
            fi
        done
    fi
    
    # Desactivar RAID si existe
    if command -v mdadm &>/dev/null; then
        for md in /dev/md*; do
            if [ -b "$md" ]; then
                log "Desactivando RAID: $md"
                mdadm --stop "$md" 2>/dev/null || true
            fi
        done
    fi
    
    # Desactivar LVM si existe
    if command -v vgchange &>/dev/null; then
        log "Desactivando volúmenes LVM..."
        vgchange -an 2>/dev/null || true
    fi
    
    if [ $exit_code -ne 0 ]; then
        error "Script terminado con errores. Limpieza completada."
    fi
    
    exit $exit_code
}

# Función principal
main() {
    local disk="/dev/sda"
    local username="tmuxuser" 
    local check_only=false
    local verbose=false
    
    # Procesar argumentos
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -c|--check)
                check_only=true
                shift
                ;;
            -v|--verbose)
                verbose=true
                set -x
                shift
                ;;
            -*)
                error "Opción desconocida: $1"
                echo "Usa -h para ver la ayuda"
                exit 1
                ;;
            *)
                if [ -z "$disk" ]; then
                    disk="$1"
                elif [ -z "$username" ]; then
                    username="$1"
                else
                    error "Demasiados argumentos"
                    show_help
                    exit 1
                fi
                shift
                ;;
        esac
    done
    
    # Verificar argumentos mínimos
    if [ -z "$disk" ]; then
        error "Debes especificar un disco"
        show_help
        exit 1
    fi
    
    # Verificar requisitos
    if ! check_requirements; then
        error "Faltan requisitos del sistema"
        exit 1
    fi
    
    # Si solo queremos verificar, salir aquí
    if [ "$check_only" = true ]; then
        log "Verificación completada exitosamente"
        exit 0
    fi
    
    # Validar disco
    if ! validate_disk "$disk"; then
        exit 1
    fi
    
    # Obtener nombre de usuario
    username=$(get_username "$username")
    
    # Configurar teclado y hora
    loadkeys "${CONFIG[KEYMAP]}"
    timedatectl set-ntp true
    
    # Mostrar información del disco y configuración
    show_disk_info "$disk"
    show_configuration
    
    warn "ADVERTENCIA: Se borrará TODO el contenido de $disk"
    warn "Usuario a crear: $username"
    echo
    read -p "¿Continuar con la instalación? (escriba 'SI' para confirmar): " -r
    if [[ "$REPLY" != "SI" ]]; then
        log "Instalación cancelada por el usuario"
        exit 0
    fi
    
    # Configurar trap para limpiar en caso de error o interrupción
    trap cleanup EXIT INT TERM
    
    
    # Proceso de instalación
    partition_disk "$disk"
    format_partitions
    mount_partitions
    install_base_system
    configure_system "$username" "$disk"
    
    # Limpiar
    umount -R /mnt
    
    log "¡Instalación de Arch Linux completada exitosamente!"
    log "Puedes reiniciar el sistema ahora"
    
    # Desactivar trap
    trap - EXIT
}

# Ejecutar función principal con todos los argumentos
main "$@"