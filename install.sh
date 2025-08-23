#!/bin/bash
# Script principal de instalación - Sistema Ultra-Minimalista bspwm
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

# Paso 1: Sistema base
echo -e "${YELLOW}📦 Paso 1/3: Instalando sistema base ultra-mínimo...${NC}"
chmod +x install/01-base.sh
./install/01-base.sh "$DISK" "$USERNAME"

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Error en la instalación del sistema base${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Sistema base instalado${NC}"
echo ""

# Preguntar si continuar con los pasos adicionales
echo -e "${YELLOW}🤔 ¿Deseas continuar con la instalación completa?${NC}"
echo -e "${BLUE}Opciones:${NC}"
echo -e "  1. Solo sistema base (recomendado para espacio limitado)"
echo -e "  2. Continuar después del reinicio (mejor opción)"
echo -e "  3. Intentar continuar ahora (puede fallar por espacio)"
echo ""
read -p "Selecciona una opción (1/2/3): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[1]$ ]]; then
    # Solo sistema base
    echo -e "${GREEN}✅ Instalación completada (solo sistema base)${NC}"
    COMPLETE_INSTALLATION=false
    
elif [[ $REPLY =~ ^[2]$ ]]; then
    # Continuar después del reinicio (recomendado)
    echo -e "${BLUE}📋 Configurando instalación post-reinicio...${NC}"
    
    # Copiar repositorio al sistema instalado
    echo -e "${YELLOW}📁 Copiando repositorio al sistema...${NC}"
    mkdir -p /mnt/home/$USERNAME
    cp -r . /mnt/home/$USERNAME/sistema-install/
    # Crear script de auto-instalación mejorado
    cat > /mnt/home/$USERNAME/auto-install.sh << 'EOF'
#!/bin/bash
# Script de auto-instalación post-reinicio mejorado

set -e
DIR="sistema-install/install"
cd "$DIR"

echo "🚀 Continuando instalación post-reinicio..."
echo ""

# Verificar espacio disponible
AVAILABLE_SPACE=$(df / | awk 'NR==2 {print $4}')
echo "💾 Espacio disponible: $((AVAILABLE_SPACE / 1024))MB"

if [ "$AVAILABLE_SPACE" -lt 500000 ]; then
    echo "⚠️ Advertencia: Espacio limitado detectado"
    echo "   Se usará instalación ultra-minimalista"
fi

# Ejecutar X11 y bspwm con script optimizado
echo "🖥️ Configurando X11 y bspwm..."
chmod +x 02-x11-bspwm
sudo ./02-x11-bspwm.sh

if [ $? -ne 0 ]; then
    echo "❌ Error en la configuración de X11 y bspwm"
    echo "💡 Puedes intentar manualmente más tarde"
    exit 1
fi

echo "✅ X11 y bspwm configurados"
echo ""

# Preguntar si instalar herramientas
echo "🤔 ¿Deseas instalar herramientas esenciales (Neovim, etc.)?"
echo "💡 Esto requiere espacio adicional (~60MB)"
read -p "¿Continuar? (s/N): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Ss]$ ]]; then
    echo "🛠️ Instalando herramientas esenciales..."
    chmod +x 03-tools.sh
    sudo ./03-tools.sh
    
    if [ $? -ne 0 ]; then
        echo "❌ Error en la instalación de herramientas"
        echo "💡 Puedes instalar manualmente más tarde"
    else
        echo "✅ Herramientas esenciales instaladas"
    fi
    echo ""
fi

# Limpiar archivos de instalación
echo "🧹 Limpiando archivos de instalación..."
rm -rf ~/sistema-install

echo "🎉 ¡Instalación completada!"
echo "🚀 El sistema está listo para usar."
echo ""
echo "🎯 Para iniciar el entorno gráfico:"
echo "   - Reiniciar y usar ly display manager"
echo "   - O ejecutar 'startx' manualmente"
EOF
    
    # Configurar auto-ejecución en el primer login
    cat >> /mnt/home/$USERNAME/.bashrc << 'EOF'

# Auto-instalación post-reinicio
if [ -f ~/auto-install.sh ]; then
    echo ""
    echo "🚀 Se detectó script de auto-instalación"
    echo "💡 Este script instalará X11 + bspwm + herramientas"
    echo "¿Ejecutar ahora? (s/N): "
    read -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        ~/auto-install.sh
    else
        echo "💡 Puedes ejecutar '~/auto-install.sh' más tarde"
    fi
fi
EOF

    echo -e "${GREEN}✅ Configuración post-reinicio completada${NC}"
    echo -e "${YELLOW}📝 Después del reinicio, el sistema te preguntará si continuar${NC}"
    COMPLETE_INSTALLATION=false
    
elif [[ $REPLY =~ ^[3]$ ]]; then
    # Intentar continuar ahora (puede fallar)
    echo -e "${YELLOW}⚠️ Intentando instalación completa ahora...${NC}"
    echo -e "${YELLOW}⚠️ Esto puede fallar si no hay suficiente espacio${NC}"
    
    # Verificar espacio disponible
    AVAILABLE_SPACE=$(df /mnt | awk 'NR==2 {print $4}')
    if [ "$AVAILABLE_SPACE" -lt 500000 ]; then
        echo -e "${RED}❌ Error: Espacio insuficiente para instalación completa${NC}"
        echo -e "${YELLOW}💡 Recomendamos usar la opción 2 (post-reinicio)${NC}"
        exit 1
    fi
    
    echo -e "${YELLOW}🖥️ Paso 2/3: Configurando X11 y bspwm ...${NC}"
    chmod +x install/02-x11-bspwm-setup.sh
    ./install/02-x11-bspwm.sh

    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Error en la configuración de X11 y bspwm ${NC}"
        exit 1
    fi

    echo -e "${GREEN}✅ X11 y bspwm  configurados${NC}"
    echo ""

    echo -e "${YELLOW}🛠️ Paso 3/3: Instalando herramientas esenciales...${NC}"
    chmod +x install/03-tools.sh
    ./install/03-tools.sh

    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Error en la instalación de herramientas${NC}"
        exit 1
    fi

    echo -e "${GREEN}✅ Herramientas esenciales instaladas${NC}"
    echo ""
    
    COMPLETE_INSTALLATION=true
    
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
    echo -e "  X11 + bspwm: ~66MB"
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
    echo -e "${BLUE}🎯 Atajos de bspwm :${NC}"
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
        echo -e "  3. El sistema te preguntará si continuar con X11 + bspwm + herramientas"
        echo -e "  4. Después podrás elegir instalar herramientas adicionales"
    fi
    echo -e "  5. ¡Disfrutar del máximo rendimiento!"
    echo ""
    echo -e "${GREEN}🎯 ¡Sistema base ultra-minimalista listo!${NC}"
    echo -e "${GREEN}🚀 GRUB bootloader configurado - El sistema iniciará automáticamente${NC}"
fi
