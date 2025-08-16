#!/bin/bash
set -e

# Parámetros del script
NEW_USER="$1"
DISK="$2"

if [ -z "$NEW_USER" ] || [ -z "$DISK" ]; then
    echo "Error: Uso: $0 <usuario> <disco>"
    exit 1
fi

echo "[INFO] Configurando sistema para usuario: $NEW_USER"
echo "[INFO] Disco: $DISK"

# Zona horaria y reloj
echo "[INFO] Configurando zona horaria..."
ln -sf /usr/share/zoneinfo/{{TIMEZONE}} /etc/localtime
hwclock --systohc

# Locale
echo "[INFO] Configurando idioma y teclado..."
echo "{{LOCALE}} UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG={{LOCALE}}" > /etc/locale.conf
echo "KEYMAP={{KEYMAP}}" > /etc/vconsole.conf

# Hostname
echo "[INFO] Configurando hostname..."
echo "{{HOSTNAME}}" > /etc/hostname
cat > /etc/hosts <<EOH
127.0.0.1   localhost
::1         localhost
127.0.1.1   {{HOSTNAME}}.localdomain {{HOSTNAME}}
EOH

# ZRAM
echo "[INFO] Configurando ZRAM..."
mkdir -p /etc/systemd/zram-generator.conf.d
cat > /etc/systemd/zram-generator.conf <<EOZ
[zram0]
zram-size = {{ZRAM_SIZE}}
compression-algorithm = {{ZRAM_ALGORITHM}}
EOZ
systemctl enable systemd-zram-setup@zram0

# Optimizar compilación
echo "[INFO] Optimizando configuración de compilación..."
sed -i "s|^#MAKEFLAGS=.*|MAKEFLAGS=\"-j$(nproc)\"|" /etc/makepkg.conf
sed -i 's|^CFLAGS=.*|CFLAGS="-march=native -O2 -pipe -fstack-protector-strong -fno-plt"|' /etc/makepkg.conf
sed -i 's|^CXXFLAGS=.*|CXXFLAGS="${CFLAGS}"|' /etc/makepkg.conf

# Network
echo "[INFO] Habilitando NetworkManager..."
systemctl enable NetworkManager

# Root password
echo "[INFO] Configurando contraseña de root..."
echo "root:root" | chpasswd

# Usuario
echo "[INFO] Creando usuario $NEW_USER..."
useradd -m -G wheel -s /bin/bash "$NEW_USER"
echo "$NEW_USER:$NEW_USER" | chpasswd

# Configurar sudo
echo "[INFO] Configurando sudo para wheel..."
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

# Copiar configuración de tmux
echo "[INFO] Instalando configuración de tmux..."
install -Dm644 /root/tmux.conf /home/$NEW_USER/.tmux.conf

# Copiar configuración de Neovim
echo "[INFO] Instalando configuración de Neovim..."
install -d -m 755 /home/$NEW_USER/.config/nvim
install -Dm644 /root/init.vim /home/$NEW_USER/.config/nvim/init.vim

# Crear directorio para plantillas de Neovim
mkdir -p /home/$NEW_USER/.config/nvim/templates

# Crear plantillas para archivos C
cat > /home/$NEW_USER/.config/nvim/templates/template.c << 'EOF'
#include <stdio.h>
#include <stdlib.h>

int main() {
    printf("Hello, World!\n");
    return 0;
}
EOF

# Crear plantillas para archivos C++
cat > /home/$NEW_USER/.config/nvim/templates/template.cpp << 'EOF'
#include <iostream>
#include <vector>
#include <string>

using namespace std;

int main() {
    cout << "Hello, World!" << endl;
    return 0;
}
EOF

# Crear plantilla para Python
cat > /home/$NEW_USER/.config/nvim/templates/template.py << 'EOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-

def main():
    print("Hello, World!")

if __name__ == "__main__":
    main()
EOF

# Crear plantilla para Makefile
cat > /home/$NEW_USER/.config/nvim/templates/template.mk << 'EOF'
# Makefile básico

CC = gcc
CXX = g++
CFLAGS = -Wall -Wextra -std=c99 -g
CXXFLAGS = -Wall -Wextra -std=c++17 -g
TARGET = main
SOURCES = $(wildcard *.c *.cpp)
OBJECTS = $(SOURCES:.c=.o)
OBJECTS := $(OBJECTS:.cpp=.o)

all: $(TARGET)

$(TARGET): $(OBJECTS)
	$(if $(filter %.cpp,$(SOURCES)),$(CXX),$(CC)) $(OBJECTS) -o $(TARGET)

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

%.o: %.cpp
	$(CXX) $(CXXFLAGS) -c $< -o $@

clean:
	rm -f $(OBJECTS) $(TARGET)

run: $(TARGET)
	./$(TARGET)

debug: CFLAGS += -DDEBUG
debug: CXXFLAGS += -DDEBUG
debug: $(TARGET)

.PHONY: all clean run debug
EOF

# Configurar Neovim para el usuario root también
echo "[INFO] Configurando Neovim para root..."
install -d -m 755 /root/.config/nvim
cp /root/init.vim /root/.config/nvim/init.vim
cp -r /home/$NEW_USER/.config/nvim/templates /root/.config/nvim/

# Cambiar permisos para el usuario
echo "[INFO] Ajustando permisos de archivos de usuario..."
chown -R $NEW_USER:$NEW_USER /home/$NEW_USER/.tmux.conf /home/$NEW_USER/.config

# Crear alias útiles para el usuario
echo "[INFO] Creando aliases útiles..."
cat >> /home/$NEW_USER/.bashrc << 'EOF'

# Aliases personalizados para desarrollo
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# Aliases para desarrollo
alias cc='gcc -Wall -Wextra -g'
alias cpp='g++ -Wall -Wextra -std=c++17 -g'
alias py='python3'
alias v='nvim'
alias vim='nvim'
alias t='tmux'
alias ta='tmux attach'
alias tl='tmux list-sessions'

# Funciones útiles
mkcd() { mkdir -p "$1" && cd "$1"; }
backup() { cp "$1" "$1.bak"; }

# Prompt colorido
PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '

# Historia mejorada
export HISTSIZE=10000
export HISTFILESIZE=20000
export HISTCONTROL=ignoreboth
shopt -s histappend

# Editor por defecto
export EDITOR=nvim
export VISUAL=nvim
EOF

# Configurar .vimrc como enlace simbólico para compatibilidad
ln -sf /home/$NEW_USER/.config/nvim/init.vim /home/$NEW_USER/.vimrc

# Bootloader
echo "[INFO] Instalando bootloader..."
if [ -d /sys/firmware/efi ]; then
    echo "[INFO] Instalando systemd-boot para UEFI..."
    bootctl install
    
    # Obtener PARTUUID de la partición root
    PARTUUID=$(blkid -s PARTUUID -o value $(findmnt -n -o SOURCE /))
    
    # Crear configuración del bootloader
    mkdir -p /boot/loader/entries
    
    cat > /boot/loader/loader.conf << EOB
default arch.conf
timeout 3
console-mode max
editor no
EOB
    
    cat > /boot/loader/entries/arch.conf << EOE
title   Arch Linux
linux   /vmlinuz-linux
initrd  /initramfs-linux.img
options root=PARTUUID=${PARTUUID} rw quiet loglevel=3 rd.systemd.show_status=auto rd.udev.log-level=3
EOE

    # Crear entrada de recuperación
    cat > /boot/loader/entries/arch-fallback.conf << EOF
title   Arch Linux (fallback initramfs)
linux   /vmlinuz-linux
initrd  /initramfs-linux-fallback.img
options root=PARTUUID=${PARTUUID} rw
EOF

else
    echo "[INFO] Instalando GRUB para BIOS..."
    grub-install --target=i386-pc "$DISK"
    
    # Configurar GRUB
    sed -i 's/GRUB_TIMEOUT=5/GRUB_TIMEOUT=3/' /etc/default/grub
    sed -i 's/#GRUB_DISABLE_SUBMENU=y/GRUB_DISABLE_SUBMENU=y/' /etc/default/grub
    
    # Habilitar os-prober para detectar otros sistemas operativos
    echo "GRUB_DISABLE_OS_PROBER=false" >> /etc/default/grub
    
    grub-mkconfig -o /boot/grub/grub.cfg
fi

# Configurar mkinitcpio para optimizar initramfs
echo "[INFO] Optimizando initramfs..."
sed -i 's/^HOOKS=.*/HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block filesystems fsck)/' /etc/mkinitcpio.conf

# Regenerar initramfs
mkinitcpio -P

# Configurar servicios del sistema
echo "[INFO] Configurando servicios del sistema..."

# Habilitar servicios esenciales
systemctl enable NetworkManager
systemctl enable systemd-timesyncd

# Configurar journald para limitar el uso de espacio
mkdir -p /etc/systemd/journald.conf.d
cat > /etc/systemd/journald.conf.d/00-journal-size.conf << EOF
[Journal]
SystemMaxUse=100M
RuntimeMaxUse=50M
EOF

# Configurar límites del sistema
echo "[INFO] Configurando límites del sistema..."
cat > /etc/security/limits.d/99-custom.conf << EOF
# Límites personalizados para desarrollo
* soft nofile 65536
* hard nofile 65536
* soft nproc 4096
* hard nproc 8192
EOF

# Configurar swappiness si no hay ZRAM
if ! systemctl is-enabled systemd-zram-setup@zram0 &>/dev/null; then
    echo 'vm.swappiness=10' > /etc/sysctl.d/99-swappiness.conf
fi

# Configurar tmpfs para /tmp si hay suficiente RAM
TOTAL_RAM=$(grep MemTotal /proc/meminfo | awk '{print $2}')
if [ $TOTAL_RAM -gt 2097152 ]; then  # Si hay más de 2GB de RAM
    echo 'tmpfs /tmp tmpfs defaults,noatime,mode=1777,size=1G 0 0' >> /etc/fstab
fi

# Crear script de bienvenida
cat > /home/$NEW_USER/.welcome.sh << 'EOF'
#!/bin/bash

# Script de bienvenida para nuevos usuarios
echo "============================================"
echo "  ¡Bienvenido a tu sistema Arch Linux!"
echo "============================================"
echo
echo "Comandos útiles para desarrollo:"
echo "  • nvim archivo.c     # Editor Neovim"
echo "  • F5 en nvim         # Compilar y ejecutar C"
echo "  • F6 en nvim         # Compilar y ejecutar C++"
echo "  • F7 en nvim         # Ejecutar Python"
echo "  • tmux               # Multiplexor de terminal"
echo "  • htop               # Monitor de recursos"
echo "  • cc archivo.c       # Compilar C (con flags)"
echo "  • cpp archivo.cpp    # Compilar C++ (con flags)"
echo
echo "Configuración personalizada aplicada:"
echo "  ✓ Neovim con plantillas para C/C++/Python"
echo "  ✓ tmux configurado para desarrollo"
echo "  ✓ Aliases útiles (ll, la, v, vim, etc.)"
echo "  ✓ ZRAM activado para mejor rendimiento"
echo "  ✓ Compilación optimizada"
echo
echo "Para no ver este mensaje de nuevo: rm ~/.welcome.sh"
echo "============================================"
echo
EOF

chmod +x /home/$NEW_USER/.welcome.sh
chown $NEW_USER:$NEW_USER /home/$NEW_USER/.welcome.sh

# Añadir script de bienvenida al .bashrc
echo "" >> /home/$NEW_USER/.bashrc
echo "# Mostrar mensaje de bienvenida en el primer login" >> /home/$NEW_USER/.bashrc
echo "if [ -f ~/.welcome.sh ]; then" >> /home/$NEW_USER/.bashrc
echo "    ~/.welcome.sh" >> /home/$NEW_USER/.bashrc
echo "fi" >> /home/$NEW_USER/.bashrc

# Configurar Git con configuración básica
echo "[INFO] Configurando Git..."
cat > /home/$NEW_USER/.gitconfig << EOF
[user]
    name = $NEW_USER
    email = $NEW_USER@localhost

[init]
    defaultBranch = main

[core]
    editor = nvim
    autocrlf = input

[alias]
    st = status
    co = checkout
    br = branch
    ci = commit
    df = diff
    lg = log --oneline --graph --all
    last = log -1 HEAD
    unstage = reset HEAD --

[color]
    ui = auto

[push]
    default = simple

[pull]
    rebase = false
EOF

chown $NEW_USER:$NEW_USER /home/$NEW_USER/.gitconfig

# Configurar un directorio de proyectos
echo "[INFO] Creando estructura de directorios para desarrollo..."
mkdir -p /home/$NEW_USER/{Proyectos,Documentos,Descargas}
mkdir -p /home/$NEW_USER/Proyectos/{C,CPP,Python,Scripts}

# Crear un proyecto de ejemplo
cat > /home/$NEW_USER/Proyectos/C/hola.c << 'EOF'
#include <stdio.h>

int main() {
    printf("¡Hola desde Arch Linux!\n");
    printf("Este es tu primer programa en C.\n");
    return 0;
}
EOF

cat > /home/$NEW_USER/Proyectos/CPP/hola.cpp << 'EOF'
#include <iostream>
#include <string>

int main() {
    std::string mensaje = "¡Hola desde Arch Linux!";
    std::cout << mensaje << std::endl;
    std::cout << "Este es tu primer programa en C++." << std::endl;
    return 0;
}
EOF

cat > /home/$NEW_USER/Proyectos/Python/hola.py << 'EOF'
#!/usr/bin/env python3

def main():
    print("¡Hola desde Arch Linux!")
    print("Este es tu primer programa en Python.")
    
    # Ejemplo de uso de variables
    nombre = input("¿Cuál es tu nombre? ")
    print(f"¡Hola, {nombre}! Bienvenido a la programación en Python.")

if __name__ == "__main__":
    main()
EOF

chmod +x /home/$NEW_USER/Proyectos/Python/hola.py

# Ajustar permisos finales
chown -R $NEW_USER:$NEW_USER /home/$NEW_USER/Proyectos

echo "[INFO] Configuración del sistema completada exitosamente."
echo "[INFO] Usuario creado: $NEW_USER"
echo "[INFO] Contraseña temporal: $NEW_USER (¡Cámbiala después del primer login!)"
echo "[INFO] El sistema está listo para usar."