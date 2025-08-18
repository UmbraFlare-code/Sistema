#!/bin/bash
# Activar modo rendimiento máximo para Celeron 4GB

echo "🚀 Activando modo rendimiento máximo..."

# CPU governor performance
echo performance > /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

# Limpiar caché
echo 3 > /proc/sys/vm/drop_caches

# Optimizar I/O
echo 0 > /proc/sys/vm/laptop_mode
echo 1 > /proc/sys/vm/drop_caches

# Deshabilitar servicios no críticos temporalmente
systemctl stop systemd-resolved 2>/dev/null || true
systemctl stop systemd-timesyncd 2>/dev/null || true

echo "✅ Modo rendimiento activado!"
echo "📊 CPU Governor: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)"
echo "💾 Memoria libre: $(free -h | awk 'NR==2{print $7}')"
