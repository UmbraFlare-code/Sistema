#!/bin/sh
# bspwmrc - Configuración ultra-minimal de bspwm para Celeron 4GB

# Monitor y escritorios optimizados
bspc monitor -d I II III IV V

# Configuración de ventanas ultra-minimal
bspc config border_width         0          # Sin bordes para ahorrar píxeles
bspc config window_gap           0          # Sin gaps para maximizar espacio
bspc config split_ratio          0.50       # División equilibrada
bspc config borderless_monocle   true       # Sin bordes en monocle
bspc config gapless_monocle      true       # Sin gaps en monocle

# Comportamiento del focus optimizado
bspc config focus_follows_pointer true      # Focus sigue al mouse
bspc config pointer_follows_focus false     # Mouse no sigue focus
bspc config pointer_follows_monitor false   # Optimización para un monitor

# Colores minimalistas (solo si se necesitan bordes)
bspc config normal_border_color "#222222"
bspc config active_border_color "#444444"
bspc config focused_border_color "#005577"
bspc config presel_feedback_color "#005577"

# Configuración de inserción de nodos
bspc config initial_polarity second_child
bspc config automatic_scheme alternate
bspc config removal_adjustment true

# Configuración de monocle
bspc config single_monocle false
bspc config click_to_focus none

# Configuración avanzada para rendimiento
bspc config merge_overlapping_monitors true
bspc config ignore_ewmh_focus false
bspc config ignore_ewmh_fullscreen none
bspc config honor_size_hints false

# Reglas de aplicaciones (minimalista)
bspc rule -a "*" state=tiled                    # Todo en modo tiled por defecto

# Reglas específicas para optimización
bspc rule -a "st" state=tiled                   # Terminal siempre tiled
bspc rule -a "xterm" state=tiled                # Xterm siempre tiled
bspc rule -a "nvim" state=tiled                 # Neovim siempre tiled

# Reglas para aplicaciones que podrían necesitar floating
bspc rule -a "feh" state=floating
bspc rule -a "mpv" state=floating
bspc rule -a "Gimp" state=floating desktop='^5'

# Autostart ultra-minimal
echo "🚀 Iniciando bspwm ultra-minimal..."

# Iniciar hotkey daemon (OBLIGATORIO)
pgrep -x sxhkd > /dev/null || sxhkd &

# Configurar cursor (opcional, consume poca memoria)
xsetroot -cursor_name left_ptr &

# Configurar wallpaper minimalista (color sólido para ahorrar memoria)
xsetroot -solid "#222222" &

# Optimizaciones de teclado y mouse
xset r rate 300 50          # Repetición de teclado rápida
xset s off -dpms           # Deshabilitar screensaver y power management

# Configuración de red (si NetworkManager está instalado)
if command -v nm-applet >/dev/null 2>&1; then
    nm-applet --sm-disable &
fi

# Script de optimización al iniciar (si existe)
if [ -x "/usr/local/bin/perf.sh" ]; then
    /usr/local/bin/perf.sh &
fi

echo "✅ bspwm iniciado correctamente"

# Configuración adicional para desarrollo
# Crear workspace de desarrollo predeterminado
bspc desktop I -l monocle

# Configurar escritorios específicos
bspc desktop II -l tiled    # Escritorio para múltiples ventanas
bspc desktop III -l tiled   # Escritorio para navegador/documentos
bspc desktop IV -l tiled    # Escritorio para herramientas
bspc desktop V -l tiled     # Escritorio libre/multimedia

# Establecer escritorio inicial
bspc desktop -f I

# Funciones útiles para desarrollo (opcional)
# Función para crear layout de desarrollo
setup_dev_layout() {
    # Abrir terminal en escritorio I
    bspc desktop -f I
    st &
    sleep 1
    
    # Dividir horizontalmente para editor
    bspc node -p east
    st -e nvim &
    
    # Ir al escritorio II para compilación
    bspc desktop -f II
    st &
}

# Bind para setup rápido (Super + Alt + d)
# setup_dev_layout &

# Configuración de polybar minimalista (si está instalado)
if command -v polybar >/dev/null 2>&1; then
    # Matar instancias previas
    killall -q polybar
    # Iniciar polybar minimalista
    polybar minimal &
fi

# Log de inicio (para debugging)
echo "$(date): bspwm iniciado con PID $$" >> ~/.bspwm.log

# Final del archivo
echo "🎯 bspwm configurado para máximo rendimiento en Celeron 4GB"