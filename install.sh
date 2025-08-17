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
COMPLETE_INSTALLATION=false

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

# Preguntar si continuar con los pasos adicionales
echo -e "${YELLOW}🤔 ¿Deseas continuar con la instalación completa?${NC}"
echo -e "${BLUE}Opciones:${NC}"
echo -e "  1. Continuar ahora (ejecutar X11 + dwm + herramientas)"
echo -e "  2. Continuar después del reinicio (recomendado)"
echo -e "  3. Solo sistema base (sin entorno gráfico)"
echo ""
read -p "Selecciona una opción (1/2/3): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[1]$ ]]; then
    # Continuar ahora
    echo -e "${YELLOW}🖥️ Paso 2/3: Configurando X11 y dwm...${NC}"
    chmod +x install/02-x11-dwm-setup.sh
    ./install/02-x11-dwm-setup.sh

    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Error en la configuración de X11 y dwm${NC}"
        exit 1
    fi

    echo -e "${GREEN}✅ X11 y dwm configurados${NC}"
    echo ""

    echo -e "${YELLOW}🛠️ Paso 3/3: Instalando herramientas esenciales...${NC}"
    chmod +x install/03-essential-tools.sh
    ./install/03-essential-tools.sh

    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Error en la instalación de herramientas${NC}"
        exit 1
    fi

    echo -e "${GREEN}✅ Herramientas esenciales instaladas${NC}"
    echo ""
    
    COMPLETE_INSTALLATION=true
    
elif [[ $REPLY =~ ^[2]$ ]]; then
    # Continuar después del reinicio
    echo -e "${BLUE}📋 Configurando instalación post-reinicio...${NC}"
    
    # Copiar repositorio al sistema instalado
    echo -e "${YELLOW}📁 Copiando repositorio al sistema...${NC}"
    cp -r . /mnt/home/$USERNAME/sistema-install/
    chown -R $USERNAME:$USERNAME /mnt/home/$USERNAME/sistema-install/
    
    # Crear script de auto-instalación
    cat > /mnt/home/$USERNAME/auto-install.sh << 'EOF'
#!/bin/bash
# Script de auto-instalación post-reinicio

set -e

cd ~/sistema-install

echo "🚀 Continuando instalación post-reinicio..."
echo ""

# Ejecutar X11 y dwm
echo "🖥️ Configurando X11 y dwm..."
chmod +x install/02-x11-dwm-setup.sh
./install/02-x11-dwm-setup.sh

if [ $? -ne 0 ]; then
    echo "❌ Error en la configuración de X11 y dwm"
    exit 1
fi

echo "✅ X11 y dwm configurados"
echo ""

# Preguntar si instalar herramientas
echo "🤔 ¿Deseas instalar herramientas esenciales (Neovim, etc.)?"
read -p "¿Continuar? (s/N): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Ss]$ ]]; then
    echo "🛠️ Instalando herramientas esenciales..."
    chmod +x install/03-essential-tools.sh
    ./install/03-essential-tools.sh
    
    if [ $? -ne 0 ]; then
        echo "❌ Error en la instalación de herramientas"
        exit 1
    fi
    
    echo "✅ Herramientas esenciales instaladas"
    echo ""
fi

# Limpiar archivos de instalación
echo "🧹 Limpiando archivos de instalación..."
rm -rf ~/sistema-install

echo "🎉 ¡Instalación completada!"
echo "🚀 El sistema está listo para usar."
EOF

    chmod +x /mnt/home/$USERNAME/auto-install.sh
    chown $USERNAME:$USERNAME /mnt/home/$USERNAME/auto-install.sh
    
    # Configurar auto-ejecución en el primer login
    cat >> /mnt/home/$USERNAME/.bashrc << 'EOF'

# Auto-instalación post-reinicio
if [ -f ~/auto-install.sh ]; then
    echo "🚀 Se detectó script de auto-instalación"
    echo "¿Ejecutar ahora? (s/N): "
    read -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        ~/auto-install.sh
    fi
fi
EOF

    echo -e "${GREEN}✅ Configuración post-reinicio completada${NC}"
    echo -e "${YELLOW}📝 Después del reinicio, el sistema te preguntará si continuar${NC}"
    COMPLETE_INSTALLATION=false
    
else
    # Solo sistema base
    echo -e "${GREEN}✅ Instalación completada (solo sistema base)${NC}"
    COMPLETE_INSTALLATION=false
fi

# Instalación completada
if [ "$COMPLETE_INSTALLATION" = true ]; then
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
    echo -e "${BLUE}📝 Próximos pasos:${NC}"
    echo -e "  1. Reiniciar el sistema (ya puede iniciar automáticamente)"
    echo -e "  2. Iniciar sesión con usuario: $USERNAME"
    echo -e "  3. Ejecutar 'perf' para activar modo rendimiento"
    echo -e "  4. ¡Disfrutar del máximo rendimiento!"
    echo ""
    echo -e "${GREEN}🎯 ¡Sistema ultra-minimalista listo para tu Celeron 4GB!${NC}"
    echo -e "${GREEN}🚀 GRUB bootloader configurado - El sistema iniciará automáticamente${NC}"
    
else
    echo -e "${GREEN}🎉 ¡SISTEMA BASE INSTALADO!${NC}"
    echo ""
    echo -e "${BLUE}📊 Resumen del sistema base:${NC}"
    echo -e "  Sistema Base: ~290MB"
    echo -e "  RAM libre: ~3.7GB (92.5%)"
    echo -e "  CPU idle: <2%"
    echo ""
    echo -e "${BLUE}🚀 Comandos útiles:${NC}"
    echo -e "  perf - Activar modo rendimiento"
    echo -e "  clean - Limpiar memoria"
    echo ""
    echo -e "${BLUE}📝 Próximos pasos:${NC}"
    echo -e "  1. Reiniciar el sistema"
    echo -e "  2. Iniciar sesión con usuario: $USERNAME"
    if [ -f "/mnt/home/$USERNAME/auto-install.sh" ]; then
        echo -e "  3. El sistema te preguntará si continuar con X11 + dwm"
        echo -e "  4. Después podrás elegir instalar herramientas adicionales"
    fi
    echo -e "  5. ¡Disfrutar del máximo rendimiento!"
    echo ""
    echo -e "${GREEN}🎯 ¡Sistema base ultra-minimalista listo!${NC}"
    echo -e "${GREEN}🚀 GRUB bootloader configurado - El sistema iniciará automáticamente${NC}"
fi
