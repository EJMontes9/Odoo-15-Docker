# Odoo 15 + PostgreSQL Docker Setup

Este proyecto configura un entorno Odoo 15 con PostgreSQL mediante Docker, proporcionando una solución completa para desarrollo y despliegue.

This project sets up an Odoo 15 environment with PostgreSQL using Docker, providing a complete solution for development and deployment.

## Documentación / Documentation

La documentación completa del proyecto está organizada en los siguientes archivos:

The complete project documentation is organized in the following files:

- [Instalación y Configuración / Installation and Setup](docs/installation.md)
- [Gestión de Base de Datos / Database Management](docs/database-management.md)
- [Solución para Problemas de Generación de PDF / PDF Generation Troubleshooting](docs/pdf-generation.md)
- [Solución para Problemas del Filestore / Filestore Troubleshooting](docs/filestore.md)

## Inicio Rápido / Quick Start

1. Asegúrate de tener Docker y Docker Compose instalados / Make sure you have Docker and Docker Compose installed
2. Clona este repositorio / Clone this repository
3. Levanta los servicios / Start the services:
   ```bash
   docker-compose up -d
   ```
4. Configura la base de datos / Configure the database:
   ```bash
   # Linux/Mac
   ./scripts/shell/setup_db_from_host.sh
   ```

   ```bash
   # Windows (PowerShell)
   .\scripts\shell\setup_db_from_host.ps1
   ```
5. Accede a Odoo en tu navegador / Access Odoo in your browser:
   [http://localhost:8069](http://localhost:8069)

## Estructura del Proyecto / Project Structure

- **`./addons`**: Módulos personalizados / Custom modules
- **`./backups`**: Backups de base de datos / Database backups
- **`./config`**: Archivos de configuración / Configuration files
- **`./docs`**: Documentación / Documentation
- **`./scripts`**: Scripts de utilidad / Utility scripts

## Comandos Útiles / Useful Commands

```bash
# Verificar contenedores en ejecución / Check running containers
docker ps

# Ver logs de Odoo / View Odoo logs
docker logs -f odoo-app

# Entrar al contenedor de Odoo / Enter Odoo container
docker exec -it odoo-app bash

# Detener los servicios / Stop services
docker-compose down
```

## Notas Importantes / Important Notes

- Asegúrate de que el archivo `entrypoint.sh` tenga formato de línea LF en vez de CRLF o CR / Make sure the `entrypoint.sh` file has LF line format instead of CRLF or CR
- Para más detalles, consulta la documentación completa en la carpeta `docs` / For more details, see the complete documentation in the `docs` folder
