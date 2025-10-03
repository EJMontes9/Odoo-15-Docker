# Solución: Pantalla en Blanco en Odoo después del Login

## 🚨 Problema Identificado

**Síntomas:**
- La página de login carga correctamente
- Después de iniciar sesión, aparece una pantalla en blanco
- En la consola del navegador aparecen errores 404 como:
  ```
  GET http://localhost:8069/web/assets/54466-f970e4c/web.assets_common.min.css 404 (NOT FOUND)
  GET http://localhost:8069/web/assets/54467-0775dd5/web.assets_backend.min.css 404 (NOT FOUND)
  GET http://localhost:8069/web/assets/54468-f970e4c/web.assets_common.min.js 404 (NOT FOUND)
  ```

**Causa del Problema:**
- Los assets (CSS/JS) del tema se corrompieron en la base de datos
- Esto sucedió después de modificar elementos del tema (logos, colores, archivos CSS)
- La base de datos tiene referencias a archivos de assets que no existen físicamente

## 🔍 Diagnóstico

### 1. Verificar el Estado del Problema

**En Docker:**
```bash
# Ver logs en tiempo real para detectar errores de assets
docker-compose logs odoo --tail=50 -f

# Verificar si el módulo del tema está instalado
docker-compose exec db psql -U odoo -d odoo -c "SELECT name, state FROM ir_module_module WHERE name = 'aeroportuaria_theme';"
```

**En Ubuntu (instalación nativa):**
```bash
# Ver logs de Odoo
sudo tail -f /var/log/odoo/odoo-server.log

# Verificar módulo del tema (conectar a PostgreSQL)
sudo -u postgres psql odoo -c "SELECT name, state FROM ir_module_module WHERE name = 'aeroportuaria_theme';"
```

### 2. Verificar Assets Corruptos en la Base de Datos

**En Docker:**
```bash
# Verificar assets corruptos
docker-compose exec db psql -U odoo -d odoo -c "SELECT id, name, url FROM ir_attachment WHERE url LIKE '%/web/assets/%' LIMIT 10;"
```

**En Ubuntu:**
```bash
# Verificar assets corruptos
sudo -u postgres psql odoo -c "SELECT id, name, url FROM ir_attachment WHERE url LIKE '%/web/assets/%' LIMIT 10;"
```

## 🛠️ Soluciones

### 🥇 Solución 1: Desinstalar y Reinstalar el Tema (MÁS FÁCIL)

**Desde la Interfaz Web:**
1. Ir a `Aplicaciones`
2. Buscar `aeroportuaria_theme` o `aeroportuaria`
3. Clic en **Desinstalar**
4. Esperar a que termine
5. Clic en **Instalar**
6. Reiniciar navegador y limpiar caché (Ctrl + Shift + R)

### 🥈 Solución 2: Comandos desde Terminal

#### Para Docker:

**Paso 1: Limpiar Assets Corruptos**
```bash
# Eliminar todos los assets corruptos de la base de datos
docker-compose exec db psql -U odoo -d odoo -c "DELETE FROM ir_attachment WHERE url LIKE '%/web/assets/%' OR name LIKE '%assets%' OR store_fname LIKE '%css%' OR store_fname LIKE '%js%';"

# Resetear configuración de sidebar del usuario admin
docker-compose exec db psql -U odoo -d odoo -c "UPDATE res_users SET sidebar_type = 'large' WHERE id = 1;"
```

**Paso 2: Desinstalar el Tema**
```bash
# Marcar tema como desinstalado
docker-compose exec db psql -U odoo -d odoo -c "UPDATE ir_module_module SET state = 'uninstalled' WHERE name = 'aeroportuaria_theme';"
```

**Paso 3: Reinstalar el Tema**
```bash
# Reinstalar el tema aeroportuaria
docker-compose exec odoo bash -c "python3.10 /opt/odoo/odoo-bin -c /etc/odoo/odoo.conf -d odoo -i aeroportuaria_theme --stop-after-init"

# Reiniciar Odoo
docker-compose restart odoo
```

#### Para Ubuntu (Instalación Nativa):

**Paso 1: Limpiar Assets Corruptos**
```bash
# Eliminar assets corruptos
sudo -u postgres psql odoo -c "DELETE FROM ir_attachment WHERE url LIKE '%/web/assets/%' OR name LIKE '%assets%' OR store_fname LIKE '%css%' OR store_fname LIKE '%js%';"

# Resetear configuración de usuario
sudo -u postgres psql odoo -c "UPDATE res_users SET sidebar_type = 'large' WHERE id = 1;"
```

**Paso 2: Desinstalar el Tema**
```bash
# Marcar tema como desinstalado
sudo -u postgres psql odoo -c "UPDATE ir_module_module SET state = 'uninstalled' WHERE name = 'aeroportuaria_theme';"
```

**Paso 3: Reinstalar el Tema**
```bash
# Detener Odoo
sudo systemctl stop odoo

# Reinstalar tema (ajustar rutas según tu instalación)
sudo -u odoo /opt/odoo/odoo-bin -c /etc/odoo/odoo.conf -d odoo -i aeroportuaria_theme --stop-after-init

# Iniciar Odoo
sudo systemctl start odoo
```

### 🥉 Solución 3: Regeneración Completa de Assets

#### Para Docker:

```bash
# Parar Odoo
docker-compose stop odoo

# Limpiar TODOS los assets
docker-compose exec db psql -U odoo -d odoo -c "DELETE FROM ir_attachment WHERE res_model = 'ir.ui.view' OR name LIKE '%assets%';"

# Limpiar filestore del contenedor
docker-compose exec odoo rm -rf /var/lib/odoo/filestore/odoo/*

# Actualizar solo el tema
docker-compose exec odoo bash -c "python3.10 /opt/odoo/odoo-bin -c /etc/odoo/odoo.conf -d odoo -u aeroportuaria_theme --stop-after-init"

# Reiniciar completamente
docker-compose restart odoo
```

#### Para Ubuntu:

```bash
# Parar Odoo
sudo systemctl stop odoo

# Limpiar assets
sudo -u postgres psql odoo -c "DELETE FROM ir_attachment WHERE res_model = 'ir.ui.view' OR name LIKE '%assets%';"

# Limpiar filestore (ajustar ruta según tu configuración)
sudo rm -rf /var/lib/odoo/filestore/odoo/*

# Actualizar tema
sudo -u odoo /opt/odoo/odoo-bin -c /etc/odoo/odoo.conf -d odoo -u aeroportuaria_theme --stop-after-init

# Iniciar Odoo
sudo systemctl start odoo
```

## 🔄 Verificación Post-Solución

### 1. Verificar que el Tema Está Instalado

**Docker:**
```bash
docker-compose exec db psql -U odoo -d odoo -c "SELECT name, state FROM ir_module_module WHERE name = 'aeroportuaria_theme';"
```

**Ubuntu:**
```bash
sudo -u postgres psql odoo -c "SELECT name, state FROM ir_module_module WHERE name = 'aeroportuaria_theme';"
```

### 2. Verificar Assets Regenerados

**Docker:**
```bash
docker-compose exec db psql -U odoo -d odoo -c "SELECT COUNT(*) as assets_count FROM ir_attachment WHERE url LIKE '%/web/assets/%';"
```

**Ubuntu:**
```bash
sudo -u postgres psql odoo -c "SELECT COUNT(*) as assets_count FROM ir_attachment WHERE url LIKE '%/web/assets/%';"
```

### 3. Verificar en el Navegador

1. **Abrir navegador en modo incógnito** o **limpiar caché** (Ctrl + Shift + R)
2. **Ir a** `http://localhost:8069`
3. **Iniciar sesión**
4. **Verificar que se vea** el tema aeroportuaria con colores azules y logo correcto

## 🚀 Comandos de Limpieza de Navegador

```bash
# En Windows (Chrome)
# Presionar: Ctrl + Shift + Del
# Seleccionar: "Imágenes y archivos almacenados en caché"

# En Linux (Chrome/Firefox)
# Presionar: Ctrl + Shift + R (recarga forzada)
# O: Ctrl + F5

# En macOS
# Presionar: Cmd + Shift + R
```

## 📋 Checklist de Resolución

- [ ] **Verificar logs** para confirmar errores 404 de assets
- [ ] **Limpiar assets corruptos** de la base de datos
- [ ] **Desinstalar tema** aeroportuaria
- [ ] **Reinstalar tema** aeroportuaria
- [ ] **Reiniciar Odoo**
- [ ] **Limpiar caché del navegador**
- [ ] **Verificar funcionamiento** con login
- [ ] **Confirmar tema aplicado** (colores azules, logo correcto)

## ⚠️ Prevención para el Futuro

**Cuando modifiques assets del tema (logos, colores, CSS):**

1. **Hacer backup** de la base de datos antes de cambios
2. **Testear cambios** en ambiente de desarrollo primero
3. **Si aparecen problemas** después de cambios en tema:
   - Ir inmediatamente a `Aplicaciones`
   - Desinstalar y reinstalar el tema
   - Esto evita problemas mayores

## 📝 Notas Importantes

- **El problema NO es de Docker** - puede pasar en cualquier instalación de Odoo
- **La causa** son assets corruptos en la base de datos
- **La solución más simple** es desinstalar/reinstalar el tema desde la interfaz
- **Siempre limpiar caché del navegador** después de la solución

**Creado:** 27 de septiembre de 2025
**Problema resuelto:** ✅ Desinstalar y reinstalar tema aeroportuaria
**Tiempo de solución:** ~5 minutos