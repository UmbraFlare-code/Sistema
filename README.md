# Sistema Ultra-Minimalista dwm para Celeron 4GB

 **OBJETIVO: M�XIMO RENDIMIENTO EN HARDWARE M�NIMO**

##  Especificaciones
- **CPU**: Intel Celeron (cualquier gen)
- **RAM**: 4GB DDR3
- **Storage**: 8GB HDD/SSD m�nimo
- **GPU**: Intel HD Graphics integrada

##  Consumo de Recursos
- **Sistema completo**: ~416MB
- **RAM libre**: ~3.5GB (87.5%)
- **CPU idle**: <3%

##  Estructura Simplificada

`
sistema/
 install/
    01-base.sh          # Sistema base
    02-x11.sh           # X11 + dwm
    03-tools.sh         # Herramientas
 config/
    dwm/                # Configuraci�n dwm
    st/                 # Configuraci�n st
    nvim/               # Configuraci�n Neovim
    system/             # Configuraciones del sistema
    x11/                # Configuraciones X11
    tmux.conf           # Configuraci�n tmux
 scripts/
    clean.sh            # Limpieza memoria
    perf.sh             # Modo rendimiento
 packages/
    base.txt            # Paquetes base
 install.sh              # Script principal
`

##  Instalaci�n

### Instalaci�n Completa
`ash
sudo ./install.sh /dev/sda tu-usuario
`

### Instalaci�n por Pasos
`ash
# 1. Sistema base
sudo ./install/01-base.sh /dev/sda tu-usuario

# 2. X11 + dwm
sudo ./install/02-x11.sh

# 3. Herramientas
sudo ./install/03-tools.sh
`

##  Comandos �tiles
`ash
# Activar modo rendimiento
perf

# Limpiar memoria
clean

# Abrir Neovim
v

# Iniciar tmux
tmux

# Iniciar entorno gr�fico
startx
`

##  Atajos de dwm
- **Super + Enter**: Abrir terminal
- **Super + q**: Cerrar ventana
- **Super + j/k**: Cambiar ventana
- **Super + h/l**: Redimensionar
- **Super + Space**: Cambiar layout

##  Paquetes Principales
- **Base**: linux-lts, networkmanager, sudo
- **X11**: xorg-server, xorg-xinit, dwm, st
- **Herramientas**: neovim, tmux, git, gcc

##  �M�ximo rendimiento para tu Celeron 4GB!
