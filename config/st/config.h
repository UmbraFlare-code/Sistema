/* st ultra-minimal para máximo rendimiento */
char *font = "Monofur Nerd Font Mono:pixelsize=12:antialias=false"; // Sin antialiasing
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
