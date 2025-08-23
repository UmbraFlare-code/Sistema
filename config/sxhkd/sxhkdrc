# sxhkdrc - Configuración ultra-minimal de sxhkd para Celeron 4GB
# Atajos optimizados para desarrollo en hardware modesto

#
# APLICACIONES BÁSICAS
#

# Terminal (optimizado para st)
super + Return
    st

# Terminal alternativo (si st no está disponible)
super + shift + Return
    xterm

# Launcher minimalista
super + d
    dmenu_run -fn 'fixed-8' -nb '#222222' -nf '#bbbbbb' -sb '#005577' -sf '#ffffff'

# Editor de texto (Neovim)
super + v
    st -e nvim

# Explorador de archivos básico
super + e
    st -e ranger

# Navegador web (si está instalado)
super + w
    firefox || chromium || qutebrowser

#
# CONTROL DE VENTANAS
#

# Cerrar ventana actual
super + q
    bspc node -c

# Matar ventana forzadamente
super + shift + q
    bspc node -k

# Alternar entre tiled y fullscreen
super + f
    bspc node -t ~fullscreen

# Alternar entre tiled y floating
super + space
    bspc node -t ~floating

# Alternar entre tiled y pseudo_tiled
super + shift + space
    bspc node -t ~pseudo_tiled

#
# NAVEGACIÓN DE VENTANAS
#

# Enfocar la ventana en la dirección dada
super + {h,j,k,l}
    bspc node -f {west,south,north,east}

# Enfocar ventana siguiente/anterior en el escritorio local
super + {_,shift + }c
    bspc node -f {next,prev}.local.!hidden.window

# Enfocar la última ventana/escritorio
super + {grave,Tab}
    bspc {node,desktop} -f last

# Enfocar la ventana más antigua o más nueva en el historial de focus
super + {o,i}
    bspc wm -h off; \
    bspc node {older,newer} -f; \
    bspc wm -h on

#
# MOVIMIENTO DE VENTANAS
#

# Intercambiar la ventana actual con la ventana en la dirección dada
super + shift + {h,j,k,l}
    bspc node -s {west,south,north,east}

# Mover ventana flotante
super + {Left,Down,Up,Right}
    bspc node -v {-20 0,0 20,0 -20,20 0}

#
# PRESELECCIÓN
#

# Preseleccionar la dirección
super + ctrl + {h,j,k,l}
    bspc node -p {west,south,north,east}

# Preseleccionar el ratio
super + ctrl + {1-9}
    bspc node -o 0.{1-9}

# Cancelar la preselección para la ventana enfocada
super + ctrl + space
    bspc node -p cancel

# Cancelar la preselección para el escritorio enfocado
super + ctrl + shift + space
    bspc query -N -d | xargs -I id -n 1 bspc node id -p cancel

#
# REDIMENSIONAR VENTANAS
#

# Expandir una ventana moviéndola hacia la dirección dada
super + alt + {h,j,k,l}
    bspc node -z {left -20 0,bottom 0 20,top 0 -20,right 20 0}

# Contraer una ventana moviéndola hacia la dirección dada
super + alt + shift + {h,j,k,l}
    bspc node -z {right -20 0,top 0 20,bottom 0 -20,left 20 0}

#
# CONTROL DE ESCRITORIOS
#

# Enfocar el escritorio dado
super + {1-9,0}
    bspc desktop -f '^{1-9,10}'

# Enviar la ventana al escritorio dado
super + shift + {1-9,0}
    bspc node -d '^{1-9,10}'

# Alternar entre el escritorio actual y el último
super + BackSpace
    bspc desktop -f last

# Ciclar entre escritorios
super + bracket{left,right}
    bspc desktop -f {prev,next}.local

#
# LAYOUTS
#

# Alternar entre los layouts tiled y monocle
super + m
    bspc desktop -l next

# Rotar el árbol de ventanas 90 grados
super + shift + r
    bspc node @/ -R 90

# Voltear el árbol de ventanas
super + shift + {h,v}
    bspc node @/ -F {horizontal,vertical}

# Balancear el árbol de ventanas
super + shift + b
    bspc node @/ -B

#
# CONTROL DEL SISTEMA
#

# Salir/reiniciar bspwm
super + alt + {q,r}
    bspc {quit,wm -r}

# Recargar configuración de sxhkd
super + Escape
    pkill -USR1 -x sxhkd

# Bloquear pantalla (si está instalado i3lock)
super + ctrl + l
    i3lock -c 000000 || xlock

#
# APLICACIONES ESPECÍFICAS PARA DESARROLLO
#

# Compilar proyecto actual (C)
super + F5
    st -e sh -c 'gcc -O2 -march=native *.c -o main && ./main; read'

# Compilar proyecto actual (C++)
super + F6
    st -e sh -c 'g++ -O2 -march=native -std=c++17 *.cpp -o main && ./main; read'

# Ejecutar Python
super + F7
    st -e sh -c 'python3 *.py; read'

# Abrir tmux para desarrollo
super + t
    st -e tmux

# Monitor del sistema
super + shift + h
    st -e htop

# Explorador de archivos gráfico (si está instalado)
super + shift + e
    thunar || pcmanfm || nautilus

#
# CONTROL DE AUDIO (si está disponible)
#

# Volumen
XF86Audio{RaiseVolume,LowerVolume,Mute}
    amixer {-q sset Master 5%+,-q sset Master 5%-,set Master toggle}

#
# CONTROL DE BRILLO (para laptops)
#

# Brillo de pantalla
XF86MonBrightness{Up,Down}
    xbacklight {+10,-10}

#
# ATAJOS RÁPIDOS PARA OPTIMIZACIÓN
#

# Limpiar memoria
super + shift + c
    /usr/local/bin/clean.sh

# Activar modo rendimiento
super + shift + p
    /usr/local/bin/perf.sh

# Mostrar información del sistema
super + shift + i
    st -e sh -c 'echo "=== INFORMACIÓN DEL SISTEMA ==="; \
    echo "CPU: $(grep "model name" /proc/cpuinfo | head -1 | cut -d: -f2)"; \
    echo "RAM: $(free -h | grep Mem)"; \
    echo "Espacio: $(df -h / | tail -1)"; \
    echo "Uptime: $(uptime)"; \
    echo "Procesos: $(ps aux | wc -l)"; \
    echo ""; echo "Presiona Enter para continuar..."; read'

#
# GESTIÓN DE SESIONES
#

# Apagar sistema
super + shift + alt + q
    systemctl poweroff

# Reiniciar sistema
super + shift + alt + r
    systemctl reboot

# Suspender sistema
super + shift + alt + s
    systemctl suspend

#
# ATAJOS PARA MÚLTIPLES MONITORES (si aplica)
#

# Enfocar el monitor dado
super + {comma,period}
    bspc monitor -f {prev,next}

# Enviar ventana al monitor dado
super + shift + {comma,period}
    bspc node -m {prev,next} --follow

#
# DESARROLLO WEB (opcional)
#

# Servidor HTTP simple para desarrollo
super + shift + w
    st -e sh -c 'python3 -m http.server 8000; read'

# Git status rápido
super + g
    st -e sh -c 'git status; echo ""; echo "Presiona Enter para continuar..."; read'

#
# CAPTURAS DE PANTALLA (si está instalado scrot)
#

# Captura de pantalla completa
Print
    scrot ~/screenshot-%Y%m%d-%H%M%S.png

# Captura de ventana activa
shift + Print
    scrot -u ~/screenshot-window-%Y%m%d-%H%M%S.png

# Captura de área seleccionada
ctrl + Print
    scrot -s ~/screenshot-area-%Y%m%d-%H%M%S.png

#
# CONFIGURACIÓN ESPECÍFICA PARA CELERON
#

# Cerrar todas las ventanas excepto la enfocada (para liberar memoria)
super + shift + alt + c
    bspc node @/ -c; \
    for node in $(bspc query -N -n .!focused); do bspc node $node -c; done

# Cambiar a layout monocle en el escritorio actual (maximizar rendimiento)
super + shift + m
    bspc desktop -l monocle

# Reset completo del escritorio (en caso de problemas)
super + shift + alt + BackSpace
    bspc desktop -R