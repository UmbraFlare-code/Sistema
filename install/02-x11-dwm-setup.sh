#!/bin/bash
# X11 y dwm ultra-básicos para Celeron 4GB
# Uso: ./02-x11-dwm-setup.sh

set -e

echo "🖥️ Configurando X11 y dwm ultra-minimalista..."

# X11 mínimo funcional
X11_PACKAGES=(
    xorg-server
    xorg-xinit
    xf86-video-intel
    xf86-input-libinput
    xorg-xset
    xorg-xsetroot
)

echo "📦 Instalando X11 mínimo..."
pacman -S --noconfirm "${X11_PACKAGES[@]}"

# Compilar dwm desde source
echo "🔨 Compilando dwm ultra-minimalista..."
cd /tmp
git clone --depth=1 https://git.suckless.org/dwm
cd dwm

# Aplicar configuración ultra-minimalista
cat > config.h << 'EOF'
/* dwm ultra-minimal para Celeron 4GB */
static const unsigned int borderpx  = 0;        // Sin bordes (ahorra pixels/CPU)
static const unsigned int snap      = 32;       // Snap distance
static const unsigned int gappx     = 0;        // Sin gaps (ahorra memoria)
static const int showbar            = 0;        // Sin barra (ahorra ~2MB)
static const int topbar             = 1;        // Top bar si se activa
static const char *fonts[]          = { "fixed:size=8" }; // Font del sistema
static const char dmenufont[]       = "fixed:size=8";

/* No colors fancy - solo básicos */
static const char col_gray1[]       = "#222222";
static const char col_gray2[]       = "#444444"; 
static const char col_gray3[]       = "#bbbbbb";
static const char col_gray4[]       = "#eeeeee";
static const char col_cyan[]        = "#005577";

/* Sin systray para ahorrar memoria */
static const unsigned int systraypinning = 0;
static const unsigned int systrayspacing = 0;
static const int showsystray             = 0;

/* Configuración mínima de ventanas */
static const Rule rules[] = {
    /* class      instance    title       tags mask     isfloating   monitor */
    { "st",       NULL,       NULL,       0,            0,           -1 },
};

/* Layouts básicos solo */
static const Layout layouts[] = {
    /* symbol     arrange function */
    { "[]=",      tile },    // Tiling básico
    { "><>",      NULL },    // Floating básico
    { "[M]",      monocle }, // Monocle básico
};

/* Key bindings mínimos */
#define MODKEY Mod4Mask  // Super key
static Key keys[] = {
    /* modifier                     key        function        argument */
    { MODKEY,                       XK_Return, spawn,          {.v = termcmd } },
    { MODKEY,                       XK_q,      killclient,     {0} },
    { MODKEY|ShiftMask,             XK_q,      quit,           {0} },
    { MODKEY,                       XK_j,      focusstack,     {.i = +1 } },
    { MODKEY,                       XK_k,      focusstack,     {.i = -1 } },
    { MODKEY,                       XK_h,      setmfact,       {.f = -0.05} },
    { MODKEY,                       XK_l,      setmfact,       {.f = +0.05} },
    { MODKEY,                       XK_space,  setlayout,      {0} },
    { MODKEY,                       XK_f,      setlayout,      {.v = &layouts[1]} },
    { MODKEY,                       XK_m,      setlayout,      {.v = &layouts[2]} },
};

/* Mouse bindings mínimos */
static Button buttons[] = {
    /* click                event mask      button          function        argument */
    { ClkClientWin,         MODKEY,         Button1,        movemouse,      {0} },
    { ClkClientWin,         MODKEY,         Button3,        resizemouse,    {0} },
};
EOF

# Compilar dwm optimizado
make clean
make -j2
make install

# Compilar st (terminal) desde source
echo "🔨 Compilando st ultra-ligero..."
cd /tmp
git clone --depth=1 https://git.suckless.org/st
cd st

# Aplicar configuración ultra-minimalista
cat > config.h << 'EOF'
/* st ultra-minimal para máximo rendimiento */
char *font = "fixed:pixelsize=12:antialias=false"; // Sin antialiasing
static int borderpx = 0;                           // Sin bordes
static char *shell = "/bin/bash";                  // Shell directo

/* Sin transparency ni efectos */
float alpha = 1.0;
float alphaOffset = 0.0;

/* Colores básicos del sistema */
static const char *colorname[] = {
    "#000000", "#cd0000", "#00cd00", "#cdcd00",
    "#0000ee", "#cd00cd", "#00cdcd", "#e5e5e5",
    "#7f7f7f", "#ff0000", "#00ff00", "#ffff00", 
    "#5c5cff", "#ff00ff", "#00ffff", "#ffffff",
};

/* Sin scrollback para ahorrar memoria */
static unsigned int histsize = 0;

/* Configuración mínima de teclado */
static unsigned int defaultfg = 15;
static unsigned int defaultbg = 0;
static unsigned int defaultcs = 256;
static unsigned int defaultrcs = 257;
EOF

# Compilar st optimizado
make clean
make -j2
make install

# ly display manager (TUI)
echo "🔐 Instalando ly display manager..."
pacman -S --noconfirm ly
systemctl enable ly

# Configuración X11 mínima
echo "⚙️ Configurando X11 mínimo..."
mkdir -p /home/$USER/.config
cat > /home/$USER/.xinitrc << 'EOF'
#!/bin/sh
# Sin compositor ni extras
xset r rate 300 50        # Teclado rápido
xset s off -dpms         # Sin screensaver
xsetroot -solid black    # Fondo negro (menos memoria que imagen)

# Sin picom ni efectos
# Sin xrandr automático (configurar manual si necesario)

exec dwm
EOF

chmod +x /home/$USER/.xinitrc
chown $USER:$USER /home/$USER/.xinitrc

# Configuración X11 optimizada
cat > /etc/X11/xorg.conf.d/10-performance.conf << 'EOF'
Section "Device"
    Identifier "Intel"
    Driver "intel"
    Option "AccelMethod" "sna"
    Option "TearFree" "true"
    Option "DRI" "3"
EndSection

Section "Monitor"
    Identifier "Monitor0"
    Option "DPMS" "false"
EndSection

Section "ServerLayout"
    Identifier "Layout0"
    Screen 0 "Screen0"
EndSection

Section "Screen"
    Identifier "Screen0"
    Device "Intel"
    Monitor "Monitor0"
    DefaultDepth 24
    SubSection "Display"
        Depth 24
        Modes "1024x768" "800x600"
    EndSubSection
EndSection
EOF

echo "✅ X11 y dwm configurados!"
echo "📋 Próximos pasos:"
echo "   1. Ejecutar: ./03-essential-tools.sh"
echo "   2. Reiniciar y disfrutar del escritorio minimalista!"
