# Certbot Automation Script
![Certbot Logo](https://certbot.eff.org/assets/certbot-logo-1A-6d3526936bd519275528105555f03904956c040da2be6ee981ef4777389a4cd2.svg)
## Descripción

Este script está diseñado para automatizar la configuración, instalación y renovación de certificados SSL utilizando **Certbot** en servidores basados en AlmaLinux. El script también se asegura de que el firewall esté configurado correctamente y permite la renovación automática de los certificados SSL. Actualmente está configurado para funcionar en **AlmaLinux**, pero está diseñado para ser adaptable a otros sistemas operativos Linux.

## Requisitos

1. **Acceso de root**: Este script debe ejecutarse como usuario root o con privilegios de `sudo`.
2. **Conexión a Internet**: Necesita acceso a Internet para instalar paquetes y obtener el certificado SSL de Let's Encrypt.
3. **Dominio y correo electrónico**: Se solicitarán durante la ejecución del script.

## Características

- **Instalación de dependencias**: El script instala todas las dependencias necesarias, incluyendo **EPEL**, **snapd** y **Certbot**.
- **Configuración de firewall**: Asegura que el puerto 80 esté habilitado en el firewall para que Certbot pueda validar el dominio.
- **Instalación de Certbot con snapd**: Certbot se instala utilizando el paquete **snap** para asegurar que se utilice la versión más actual.
- **Generación de certificado SSL**: Una vez configurado todo, el script ejecuta Certbot para obtener un certificado SSL para el dominio proporcionado.
- **Renovación automática**: El script prueba la renovación automática del certificado para garantizar que la renovación no falle cuando sea necesario.
- **Cierre del puerto 80**: Después de generar el certificado, el script cierra automáticamente el puerto 80 para mayor seguridad.

## Cómo usar el script

1. **Clona o descarga este repositorio en tu servidor**.

2. **Ejecuta el script**:
   Asegúrate de tener acceso root y de que tu dominio esté correctamente configurado para apuntar a la máquina donde ejecutarás el script.

   Puedes iniciar el script con privilegios ejecutando el siguiente comando:

   ```bash
   [ -f /home/opc/certbot.sh ] && chmod +x /home/opc/certbot.sh && sudo /home/opc/certbot.sh
