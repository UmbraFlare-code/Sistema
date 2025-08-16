#!/bin/bash
# Script principal de instalación - Sistema Ultra-Minimalista dwm
# Uso: ./install.sh /dev/sda username

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables
DISK=${1:-/dev/sda}
USERNAME=${2:-user}

echo -e "${BLUE}🎯 Sistema Ultra-Minimalista dwm para Celeron 4GB${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""
echo -e "${YELLOW}Especificaciones objetivo:${NC}"
echo -e "  CPU: Intel Celeron (cualquier gen)"
echo -e "  RAM: 4GB DDR3"
echo -e "  Storage: 8GB HDD/SSD"
echo -e "  GPU: Intel HD Graphics integrada"
echo ""
echo -e "${YELLOW}Meta de consumo:${NC}"
echo -e "  Sistema completo: ~416MB"
echo -e "  RAM libre: ~3.5GB (87.5%)"
echo -e "  CPU idle: <3%"
echo ""

# Verificar parámetros
if [ -z "$DISK" ] || [ -z "$USERNAME" ]; then
    echo -e "${RED}❌ Uso: $0 <disco> <usuario>${NC}"
    echo -e "${YELLOW}Ejemplo: $0 /dev/sda usuario${NC}"
    exit 1
fi

# Verificar que el disco existe
if [ ! -b "$DISK" ]; then
    echo -e "${RED}❌ Error: El disco $DISK no existe${NC}"
    exit 1
fi

# Confirmar instalación
echo -e "${YELLOW}⚠️  ADVERTENCIA:${NC}"
echo -e "  Este script instalará Arch Linux en $DISK"
echo -e "  TODOS LOS DATOS EN $DISK SERÁN ELIMINADOS"
echo ""
read -p "¿Continuar? (s/N): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    echo -e "${RED}❌ Instalación cancelada${NC}"
    exit 1
fi

# Verificar que estamos en Arch Linux live
if [ ! -f /etc/arch-release ]; then
    echo -e "${RED}❌ Error: Este script debe ejecutarse desde Arch Linux live${NC}"
    exit 1
fi

# Verificar conexión a internet
if ! ping -c 1 archlinux.org >/dev/null 2>&1; then
    echo -e "${RED}❌ Error: No hay conexión a internet${NC}"
    echo -e "${YELLOW}Conecta a internet antes de continuar${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Verificaciones completadas${NC}"
echo ""

# Ejecutar scripts de instalación
echo -e "${BLUE}🚀 Iniciando instalación...${NC}"
echo ""

# Paso 1: Sistema base
echo -e "${YELLOW}📦 Paso 1/3: Instalando sistema base ultra-mínimo...${NC}"
chmod +x install/01-base-minimal.sh
./install/01-base-minimal.sh "$DISK" "$USERNAME"

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Error en la instalación del sistema base${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Sistema base instalado${NC}"
echo ""

# Paso 2: X11 y dwm
echo -e "${YELLOW}🖥️ Paso 2/3: Configurando X11 y dwm...${NC}"
chmod +x install/02-x11-dwm-setup.sh
./install/02-x11-dwm-setup.sh

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Error en la configuración de X11 y dwm${NC}"
    exit 1
fi

echo -e "${GREEN}✅ X11 y dwm configurados${NC}"
echo ""

# Paso 3: Herramientas esenciales
echo -e "${YELLOW}🛠️ Paso 3/3: Instalando herramientas esenciales...${NC}"
chmod +x install/03-essential-tools.sh
./install/03-essential-tools.sh

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Error en la instalación de herramientas${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Herramientas esenciales instaladas${NC}"
echo ""

# Instalación completada
echo -e "${GREEN}🎉 ¡INSTALACIÓN COMPLETADA!${NC}"
echo ""
echo -e "${BLUE}📊 Resumen del sistema:${NC}"
echo -e "  Sistema Base: ~290MB"
echo -e "  X11 + dwm: ~66MB"
echo -e "  Neovim + nvim-tree: ~60MB"
echo -e "  Total estimado: ~416MB"
echo -e "  RAM libre: ~3.5GB (87.5%)"
echo ""
echo -e "${BLUE}🚀 Comandos útiles:${NC}"
echo -e "  perf - Activar modo rendimiento"
echo -e "  clean - Limpiar memoria"
echo -e "  v - Abrir Neovim"
echo -e "  tmux - Iniciar sesión tmux"
echo ""
echo -e "${BLUE}🎯 Atajos de dwm:${NC}"
echo -e "  Super + Enter - Abrir terminal"
echo -e "  Super + q - Cerrar ventana"
echo -e "  Super + j/k - Cambiar ventana"
echo -e "  Super + h/l - Redimensionar"
echo -e "  Super + Space - Cambiar layout"
echo ""
echo -e "${BLUE>📝 Próximos pasos:${NC}"
echo -e "  1. Reiniciar el sistema"
echo -e "  2. Iniciar sesión con usuario: $USERNAME"
echo -e "  3. Ejecutar 'perf' para activar modo rendimiento"
echo -e "  4. ¡Disfrutar del máximo rendimiento!"
echo ""
echo -e "${GREEN}🎯 ¡Sistema ultra-minimalista listo para tu Celeron 4GB!${NC}"
