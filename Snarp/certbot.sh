#!/bin/bash

# Creador: Yona
# Snarp con Certbot Automatizacion y renovacion de certificados
# Descripción: Script para configurar Certbot con un dominio y correo proporcionados por el usuario.

echo -e "\nCREADOR JHONATAN: AlmaLinux"

# Solicitar el dominio y el correo electrónico
read -p "Por favor, ingrese el nombre del dominio: " DOMAIN
read -p "Por favor, ingrese su correo electrónico: " EMAIL

# Verificar si se ejecuta como root
if [ "$(id -u)" -ne 0 ]; then
  echo "Por favor, ejecuta este script como root o con sudo."
  exit 1
fi

# Función para verificar el estado de firewalld
verificar_firewalld() {
  echo "Verificando el estado de firewalld..."
  if ! systemctl is-active --quiet firewalld; then
    echo "firewalld no está activo. Intentando activarlo..."
    systemctl enable --now firewalld
    if [ $? -ne 0 ]; then
      echo "Error: No se pudo activar firewalld. Verifica manualmente."
      exit 1
    fi
    echo "firewalld activado correctamente."
  else
    echo "firewalld está activo."
  fi
}

# Función para habilitar el puerto 80
habilitar_puerto_80() {
  echo "Habilitando el puerto 80 en el firewall..."
  if ! firewall-cmd --permanent --add-service=http; then
    echo "Error: No se pudo habilitar el puerto 80. Verifica manualmente."
    exit 1
  fi
  firewall-cmd --reload
  echo "Puerto 80 habilitado."
}

# Función para cerrar el puerto 80
cerrar_puerto_80() {
  echo "Cerrando el puerto 80 en el firewall..."
  if ! firewall-cmd --permanent --remove-service=http; then
    echo "Error: No se pudo cerrar el puerto 80. Verifica manualmente."
    exit 1
  fi
  firewall-cmd --reload
  echo "Puerto 80 cerrado."
}

# Función para verificar la instalación de un paquete
verificar_instalacion() {
  local paquete=$1
  if ! rpm -q "$paquete" > /dev/null 2>&1; then
    echo "Error: El paquete $paquete no se instaló correctamente. Verifica manualmente."
    exit 1
  fi
}

echo "Configurando snap y Certbot para el dominio: $DOMAIN"

# Instalar EPEL release
echo "Instalando EPEL release..."
dnf install -y epel-release || { echo "Error instalando epel-release. Verifica manualmente."; exit 1; }

# Actualizar el sistema
echo "Actualizando el sistema..."
dnf upgrade -y || { echo "Error actualizando el sistema. Verifica manualmente."; exit 1; }

# Instalar snapd
echo "Instalando snapd..."
dnf install -y snapd || { echo "Error instalando snapd. Verifica manualmente."; exit 1; }
verificar_instalacion snapd

# Habilitar y arrancar snapd.socket
echo "Habilitando snapd.socket..."
systemctl enable --now snapd.socket || { echo "Error habilitando snapd.socket. Verifica manualmente."; exit 1; }

# Crear enlace simbólico para snap
if [ ! -L /snap ]; then
  echo "Creando enlace simbólico para /snap..."
  ln -s /var/lib/snapd/snap /snap || { echo "Error creando el enlace simbólico para /snap. Verifica manualmente."; exit 1; }
fi

# Verificar versión de snap
snap version || { echo "Error verificando la instalación de snap. Verifica manualmente."; exit 1; }

echo "Instalación de snap completa."

# Eliminar cualquier versión previa de Certbot
echo "Eliminando versiones previas de Certbot si existen..."
dnf remove -y certbot || true
yum remove -y certbot || true
apt-get remove -y certbot || true

# Instalar Certbot con snapd
echo "Instalando Certbot con snapd..."
snap install --classic certbot || { echo "Error instalando Certbot con snapd. Verifica manualmente."; exit 1; }

# Crear enlace simbólico para certbot
if [ ! -L /usr/bin/certbot ]; then
  ln -s /snap/bin/certbot /usr/bin/certbot || { echo "Error creando el enlace simbólico para Certbot. Verifica manualmente."; exit 1; }
fi

echo "Certbot instalado con éxito."

# Verificar firewalld y habilitar el puerto 80
verificar_firewalld
habilitar_puerto_80

# Validar dominio y obtener certificado
echo "Asegúrate de que el tráfico del dominio redirija a esta máquina."
echo "Ejecutando Certbot para el dominio $DOMAIN..."

certbot certonly --standalone -d "$DOMAIN" --non-interactive --agree-tos --email "$EMAIL"

if [ $? -eq 0 ]; then
  echo "Certificado generado con éxito."
else
  echo "Error al generar el certificado. Verifica los pasos manualmente."
  cerrar_puerto_80
  exit 1
fi

# Probar renovación automática
echo "Probando la renovación automática..."
certbot renew --dry-run

if [ $? -eq 0 ]; then
  echo "Renovación automática configurada correctamente."
else
  echo "Error en la prueba de renovación automática. Verifica manualmente."
fi

# Cerrar puerto 80
cerrar_puerto_80

# Salida estilizada con la ruta de los certificados
echo ""
echo "========================================================"
echo "         Certificado generado con éxito                "
echo "========================================================"
echo "Ruta del certificado: /etc/letsencrypt/live/$DOMAIN/fullchain.pem"
echo "Ruta de la clave privada: /etc/letsencrypt/live/$DOMAIN/privkey.pem"
echo "========================================================"
echo ""
echo "Si necesitas verificar la renovación automática, ejecuta:"
echo "  sudo certbot renew --dry-run"
echo "========================================================"

echo "Script completado. Certbot configurado para el dominio: $DOMAIN con el correo: $EMAIL"