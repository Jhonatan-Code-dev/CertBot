#!/bin/bash

# Autor: Jhonatan
# Descripción: Automatización y renovación de certificados con Certbot en AlmaLinux.

echo -e "\nCREADOR: Jhonatan - AlmaLinux"

# Solicitar dominio y correo electrónico
read -p "Por favor, ingrese el nombre del dominio: " DOMAIN
read -p "Por favor, ingrese su correo electrónico: " EMAIL

# Verificar si el script se ejecuta como root
if [ "$(id -u)" -ne 0 ]; then
  echo "Por favor, ejecuta este script como root o con sudo."
  exit 1
fi

# Función para gestionar el firewall y puertos
gestionar_firewall() {
  local action=$1
  local service=$2
  echo "${action^} el servicio ${service} en el firewall..."
  firewall-cmd --permanent --"${action}"-service="${service}" && firewall-cmd --reload || { echo "Error: No se pudo ${action} el servicio ${service}. Verifica manualmente."; exit 1; }
  echo "Servicio ${service} ${action} correctamente."
}

# Función para instalar y verificar paquetes
instalar_paquete() {
  local paquete=$1
  echo "Instalando ${paquete}..."
  dnf install -y "${paquete}" || { echo "Error instalando ${paquete}. Verifica manualmente."; exit 1; }
  rpm -q "${paquete}" > /dev/null 2>&1 || { echo "Error: El paquete ${paquete} no se instaló correctamente. Verifica manualmente."; exit 1; }
}

# Función para gestionar servicios
gestionar_servicio() {
  local service=$1
  local action=$2
  if systemctl is-active --quiet "${service}"; then
    systemctl "${action}" "${service}"
    echo "${service^} ${action}."
  fi
}

echo "Configurando snap y Certbot para el dominio: ${DOMAIN}"

# Instalar y habilitar dependencias necesarias
instalar_paquete epel-release
dnf upgrade -y
instalar_paquete snapd

echo "Habilitando y verificando snapd..."
systemctl enable --now snapd.socket || { echo "Error habilitando snapd.socket. Verifica manualmente."; exit 1; }
ln -s /var/lib/snapd/snap /snap || true
snap version || { echo "Error verificando la instalación de snap. Verifica manualmente."; exit 1; }

# Eliminar versiones previas de Certbot e instalar la nueva con snapd
echo "Eliminando versiones previas de Certbot si existen..."
dnf remove -y certbot || true
snap install --classic certbot || { echo "Error instalando Certbot con snapd. Verifica manualmente."; exit 1; }
ln -s /snap/bin/certbot /usr/bin/certbot || true

# Verificar y gestionar el firewall
gestionar_firewall "add" "http"

# Detener servicios antes de ejecutar Certbot
gestionar_servicio nginx stop
gestionar_servicio httpd stop

# Detener cualquier proceso de Certbot en ejecución
sudo killall -9 certbot || true

# Ejecutar Certbot
echo "Asegúrate de que el tráfico del dominio redirija a esta máquina."
if ! certbot certonly --standalone -d "${DOMAIN}" --non-interactive --agree-tos --email "${EMAIL}"; then
  echo "Error al generar el certificado. Verifica manualmente."
  gestionar_servicio nginx start
  gestionar_servicio httpd start
  exit 1
fi

# Probar renovación automática
if ! certbot renew --dry-run; then
  echo "Error en la prueba de renovación automática. Verifica manualmente."
  exit 1
fi

# Iniciar servicios después de completar el proceso
gestionar_servicio nginx start
gestionar_servicio httpd start

# Mostrar información del certificado generado
echo -e "\n========================================================"
echo -e "         Certificado generado con éxito                "
echo -e "========================================================"
echo -e "Ruta del certificado: /etc/letsencrypt/live/${DOMAIN}/fullchain.pem"
echo -e "Ruta de la clave privada: /etc/letsencrypt/live/${DOMAIN}/privkey.pem"
echo -e "========================================================\n"
echo "Si necesitas verificar la renovación automática, ejecuta:"
echo "  sudo certbot renew --dry-run"
echo -e "========================================================\n"
echo "Script completado. Certbot configurado para el dominio: ${DOMAIN} con el correo: ${EMAIL}"