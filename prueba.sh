#!/bin/bash

# Verifica que se pase el nombre de la máquina virtual como argumento
if [ "$#" -ne 1 ]; then
    echo "Uso: $0 <nombre_maquina_virtual>"
    exit 1
fi

NOMBRE_MAQUINA=$1

# Obtiene la dirección MAC de la máquina virtual
MAC=$(virsh domiflist "$NOMBRE_MAQUINA" | grep -i 'vnet' | awk '{print $5}')

if [ -z "$MAC" ]; then
    echo "No se pudo obtener la dirección MAC para $NOMBRE_MAQUINA."
    exit 1
fi

# Busca la IP en la tabla ARP
IP=$(ip neigh show | grep "$MAC" | awk '{print $1}')

if [ -n "$IP" ]; then
    echo "La dirección IP de la máquina virtual $NOMBRE_MAQUINA es: $IP"
else
    echo "No se encontró la dirección IP asociada a la máquina virtual $NOMBRE_MAQUINA."
fi