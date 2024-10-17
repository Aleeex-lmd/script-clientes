#!/bin/bash

# Verifica que se pasen los argumentos necesarios
if [ "$#" -ne 4 ]; then
    echo "Uso: $0 <nombre_maquina> <tamano_volumen> <tipo_red> <nombre_red>"
    echo "<tipo_red>: 'puente' o 'red'"
    exit 2
fi

# Asignación de argumentos a variables
NOMBRE_MAQUINA=$1
TAMANO_VOLUMEN=$2
TIPO_RED=$3
NOMBRE_RED=$4

# Variables
TEMPLATE="plantilla-cliente.qcow2"
VOLUMEN="${NOMBRE_MAQUINA}.qcow2"
RUTA_IMAGEN="/var/lib/libvirt/images/${VOLUMEN}"
USUARIO="debian"  # Usuario para acceso SSH
USUARIO_LOCAL="alex"  # Usuario local
SSH_DIR="/home/${USUARIO}/.ssh"
SSH_KEY="${SSH_DIR}/id_rsa"
CLAVE_PUBLICA="/home/alex/.ssh/id_rsa.pub"
CLAVE_PUBLICA_CONTENIDO=$(cat "${CLAVE_PUBLICA}")

# Verificar si el volumen ya existe
if virsh vol-list default | grep -q "${VOLUMEN}"; then
    echo "El volumen ${VOLUMEN} ya existe. Por favor elige otro nombre."
    exit 1
fi

# Crea el volumen a partir de la plantilla
echo "Creando volumen ${VOLUMEN} de tamaño ${TAMANO_VOLUMEN}..."
virsh vol-create-as default "${VOLUMEN}" "${TAMANO_VOLUMEN}" --format qcow2 --backing-vol "${TEMPLATE}" --backing-vol-format qcow2

# Crea la máquina virtual a partir del nuevo volumen
echo "Creando la máquina virtual ${NOMBRE_MAQUINA}..."
virt-clone --connect=qemu:///system --original plantilla-cliente --name "${NOMBRE_MAQUINA}" --file "${RUTA_IMAGEN}" --preserve-data

# Redimensionar el sistema de archivos
echo "Redimensionando el sistema de archivos del volumen..."
TEMP_FILE="/home/${USUARIO_LOCAL}/temp_${NOMBRE_MAQUINA}.qcow2"
sudo cp "${RUTA_IMAGEN}" "${TEMP_FILE}"
sudo virt-resize --expand /dev/sda1 "${RUTA_IMAGEN}" "${TEMP_FILE}"
sudo mv "${TEMP_FILE}" "${RUTA_IMAGEN}"

# Personaliza la máquina virtual
echo "Personalizando la máquina virtual..."
sudo virt-customize -a "${RUTA_IMAGEN}" \
    --hostname "${NOMBRE_MAQUINA}" \
    --run-command "if [ ! -d '/home/${USUARIO}/.ssh' ]; then mkdir -p '/home/${USUARIO}/.ssh'; fi" \
    --run-command "echo '${CLAVE_PUBLICA_CONTENIDO}' >> /home/${USUARIO}/.ssh/authorized_keys" \
    --run-command "ssh-keygen -t rsa -b 2048 -f '/home/${USUARIO}/.ssh/id_rsa' -N ''" \

# Conecta la máquina a la red especificada
if [ "$TIPO_RED" == "puente" ]; then
    echo "Conectando la máquina ${NOMBRE_MAQUINA} a la red de puente ${NOMBRE_RED}..."
    virsh attach-interface "${NOMBRE_MAQUINA}" --type bridge --source "${NOMBRE_RED}" --model virtio --persistent
elif [ "$TIPO_RED" == "red" ]; then
    echo "Conectando la máquina ${NOMBRE_MAQUINA} a la red ${NOMBRE_RED}..."
    virsh attach-interface "${NOMBRE_MAQUINA}" --type network --source "${NOMBRE_RED}" --model virtio --persistent
else
    echo "Tipo de red no válido. Debe ser 'puente' o 'red'."
    exit 1
fi

# Inicia la máquina virtual
echo "Iniciando la máquina virtual ${NOMBRE_MAQUINA}..."
virsh start "${NOMBRE_MAQUINA}"

echo "La máquina ${NOMBRE_MAQUINA} ha sido creada y está en funcionamiento."

# Espera a que la máquina esté en estado "running"
echo "Esperando a que la máquina ${NOMBRE_MAQUINA} esté en funcionamiento..."
sleep 15

# Obtener la dirección IP de la máquina virtual
IP=$(virsh domifaddr "${NOMBRE_MAQUINA}" | grep -oP '(\d{1,3}\.){3}\d{1,3}')

if [ -n "$IP" ]; then
    echo "La máquina ${NOMBRE_MAQUINA} está en funcionamiento y tiene la IP: ${IP}"
else
    echo "No se pudo obtener la IP de la máquina ${NOMBRE_MAQUINA}. Verifica que la máquina esté conectada a la red correctamente."
fi

ssh debian@"$IP"
