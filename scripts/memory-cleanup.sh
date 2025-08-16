#!/bin/bash
# Limpieza de memoria para Celeron 4GB

echo "🧹 Limpiando memoria..."

# Limpiar caché
echo 1 > /proc/sys/vm/drop_caches
echo 2 > /proc/sys/vm/drop_caches
echo 3 > /proc/sys/vm/drop_caches

# Limpiar buffers
sync

# Mostrar estado de memoria
echo "📊 Estado de memoria:"
free -h

echo "✅ Memoria limpiada!"
