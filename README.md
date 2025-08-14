# Arch Linux Auto-Installer

Script automatizado para instalar Arch Linux con una configuración básica optimizada para desarrollo en C/C++. Configuracion para que funcione en un celeron, 4gb de ram ddr3 y una memoria de hdd. 

## Características

- Instalación automatizada de Arch Linux
- Soporte para UEFI y BIOS legacy
- Particionado automático del disco
- Configuración de ZRAM para mejor rendimiento
- Optimizaciones de compilación
- Configuración pre-establecida para:
  - Neovim con soporte para C/C++
  - tmux con atajos personalizados
  - Teclado en español (latinoamericano)

## Uso

1. Bootear desde USB con Arch Linux

2. Descargar el script:
```bash
git clone https://github.com/umbraflare-code/sistema
chmod +x arch-install-auto.sh
```
O 
```bash
curl -O https://raw.githubusercontent.com/umbraflare-code/sistema/master/arch-install-auto.sh
chmod +x arch-install-auto.sh
```

3. Ejecutar el instalador:
```bash 
./arch-install-auto.sh /dev/sdX usuario
```

### Parámetros
- `/dev/sdX`: Disco donde instalar (ej: /dev/sda, /dev/nvme0n1)

## Configuración

Puedes personalizar la instalación modificando las variables al inicio del script:

| Variable | Descripción | Valor por defecto |
|----------|-------------|-------------------|
| HOSTNAME | Nombre del equipo | archtty |
| TIMEZONE | Zona horaria | America/Lima |
| KEYMAP | Distribución del teclado | la-latin1 |
| LOCALE | Idioma del sistema | es_ES.UTF-8 |
| SWAP_SIZE | Tamaño de SWAP en GB | 4 |
| ROOT_SIZE | Tamaño de / en GB | 20 |
| HOME_SIZE | Tamaño de /home en GB | resto |
| ZRAM_SIZE | Tamaño de ZRAM en MB | 1024 |
| ZRAM_ALGORITHM | Algoritmo compresión ZRAM | zstd |
| EXTRA_PACKAGES | Paquetes adicionales | firefox libreoffice |

Ejemplo de personalización:

```bash
# Editar las variables antes de ejecutar
CONFIG[HOSTNAME]="mipc"
CONFIG[TIMEZONE]="America/Mexico_City"
CONFIG[EXTRA_PACKAGES]="vim firefox"
./arch-install-auto.sh /dev/sda usuario
```

## Post-instalación

El sistema quedará configurado con:

| Componente | Configuración |
|------------|---------------|
| Usuario | Creado con privilegios sudo |
| Contraseñas | Iguales al nombre de usuario |
| Neovim | Configurado para C/C++ (F5/F6 para compilar) |
| tmux | Prefijo Ctrl+a y atajos Alt+flechas |
| Red | NetworkManager habilitado |
| ZRAM | Activado para mejor rendimiento |

## Archivos de configuración

| Archivo | Descripción |
|---------|-------------|
| `init.vim` | Configuración de Neovim |
| `tmux.conf` | Configuración de tmux |
| `configure_system.sh` | Script de configuración del sistema |
| `arch-install-auto.sh` | Script principal de instalación |

## Advertencia

Este script borrará **TODO** el contenido del disco especificado. Úsalo con precaución y asegúrate de tener respaldos.

## Licencia