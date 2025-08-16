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
