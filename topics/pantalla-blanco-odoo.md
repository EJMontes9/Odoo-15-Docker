# Solucion: Pantalla en Blanco en Odoo despues del Login

## Problema Identificado

**Sintomas:**
- La pagina de login carga correctamente
- Despues de iniciar sesion, aparece una pantalla en blanco
- En la consola del navegador aparecen errores 404 como:
  ```
  GET http://localhost:8069/web/assets/54466-f970e4c/web.assets_common.min.css 404 (NOT FOUND)
  GET http://localhost:8069/web/assets/54467-0775dd5/web.assets_backend.min.css 404 (NOT FOUND)
  GET http://localhost:8069/web/assets/54468-f970e4c/web.assets_common.min.js 404 (NOT FOUND)
  ```

**Causa del Problema:**
- Los assets (CSS/JS) del tema se corrompieron en la base de datos
- Esto sucedio despues de modificar elementos del tema (logos, colores, archivos CSS)
- La base de datos tiene referencias a archivos de assets que no existen fisicamente

## Diagnostico

### Verificar el Estado del Problema

**En Docker:**
```bash
# Ver logs en tiempo real para detectar errores de assets
docker-compose logs odoo --tail=50 -f

# Verificar si el modulo del tema esta instalado
docker-compose exec db psql -U odoo -d odoo -c "SELECT name, state FROM ir_module_module WHERE name = 'aeroportuaria_theme';"
```

**En Ubuntu (instalacion nativa):**
```bash
# Ver logs de Odoo
sudo tail -f /var/log/odoo/odoo-server.log

# Verificar modulo del tema (conectar a PostgreSQL)
sudo -u postgres psql odoo -c "SELECT name, state FROM ir_module_module WHERE name = 'aeroportuaria_theme';"
```

### Verificar Assets Corruptos en la Base de Datos

**En Docker:**

<code-block lang="bash" ignore-vars="true">
# Verificar assets corruptos
docker-compose exec db psql -U odoo -d odoo -c "SELECT id, name, url FROM ir_attachment WHERE url LIKE '%/web/assets/%' LIMIT 10;"
</code-block>

**En Ubuntu:**

<code-block lang="bash" ignore-vars="true">
# Verificar assets corruptos
sudo -u postgres psql odoo -c "SELECT id, name, url FROM ir_attachment WHERE url LIKE '%/web/assets/%' LIMIT 10;"
</code-block>

## Soluciones

### Solucion 1: Desinstalar y Reinstalar el Tema (MAS FACIL)

**Desde la Interfaz Web:**
1. Ir a `Aplicaciones`
2. Buscar `aeroportuaria_theme` o `aeroportuaria`
3. Clic en **Desinstalar**
4. Esperar a que termine
5. Clic en **Instalar**
6. Reiniciar navegador y limpiar cache (Ctrl + Shift + R)

### Solucion 2: Comandos desde Terminal

**Docker - Paso 1: Limpiar Assets Corruptos**

<code-block lang="bash" ignore-vars="true">
# Eliminar todos los assets corruptos de la base de datos
docker-compose exec db psql -U odoo -d odoo -c "DELETE FROM ir_attachment WHERE url LIKE '%/web/assets/%' OR name LIKE '%assets%' OR store_fname LIKE '%css%' OR store_fname LIKE '%js%';"

# Resetear configuracion de sidebar del usuario admin
docker-compose exec db psql -U odoo -d odoo -c "UPDATE res_users SET sidebar_type = 'large' WHERE id = 1;"
</code-block>

**Docker - Paso 2: Desinstalar el Tema**
```bash
# Marcar tema como desinstalado
docker-compose exec db psql -U odoo -d odoo -c "UPDATE ir_module_module SET state = 'uninstalled' WHERE name = 'aeroportuaria_theme';"
```

**Docker - Paso 3: Reinstalar el Tema**
```bash
# Reinstalar el tema aeroportuaria
docker-compose exec odoo bash -c "python3.10 /opt/odoo/odoo-bin -c /etc/odoo/odoo.conf -d odoo -i aeroportuaria_theme --stop-after-init"

# Reiniciar Odoo
docker-compose restart odoo
```

**Ubuntu - Paso 1: Limpiar Assets Corruptos**

<code-block lang="bash" ignore-vars="true">
# Eliminar assets corruptos
sudo -u postgres psql odoo -c "DELETE FROM ir_attachment WHERE url LIKE '%/web/assets/%' OR name LIKE '%assets%' OR store_fname LIKE '%css%' OR store_fname LIKE '%js%';"

# Resetear configuracion de usuario
sudo -u postgres psql odoo -c "UPDATE res_users SET sidebar_type = 'large' WHERE id = 1;"
</code-block>

**Ubuntu - Paso 2: Desinstalar el Tema**
```bash
# Marcar tema como desinstalado
sudo -u postgres psql odoo -c "UPDATE ir_module_module SET state = 'uninstalled' WHERE name = 'aeroportuaria_theme';"
```

**Ubuntu - Paso 3: Reinstalar el Tema**
```bash
# Detener Odoo
sudo systemctl stop odoo

# Reinstalar tema (ajustar rutas segun tu instalacion)
sudo -u odoo /opt/odoo/odoo-bin -c /etc/odoo/odoo.conf -d odoo -i aeroportuaria_theme --stop-after-init

# Iniciar Odoo
sudo systemctl start odoo
```

### Solucion 3: Regeneracion Completa de Assets

**Docker:**

<code-block lang="bash" ignore-vars="true">
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
</code-block>

**Ubuntu:**

<code-block lang="bash" ignore-vars="true">
# Parar Odoo
sudo systemctl stop odoo

# Limpiar assets
sudo -u postgres psql odoo -c "DELETE FROM ir_attachment WHERE res_model = 'ir.ui.view' OR name LIKE '%assets%';"

# Limpiar filestore (ajustar ruta segun tu configuracion)
sudo rm -rf /var/lib/odoo/filestore/odoo/*

# Actualizar tema
sudo -u odoo /opt/odoo/odoo-bin -c /etc/odoo/odoo.conf -d odoo -u aeroportuaria_theme --stop-after-init

# Iniciar Odoo
sudo systemctl start odoo
</code-block>

## Verificacion Post-Solucion

### Verificar que el Tema Esta Instalado

**Docker:**
```bash
docker-compose exec db psql -U odoo -d odoo -c "SELECT name, state FROM ir_module_module WHERE name = 'aeroportuaria_theme';"
```

**Ubuntu:**
```bash
sudo -u postgres psql odoo -c "SELECT name, state FROM ir_module_module WHERE name = 'aeroportuaria_theme';"
```

### Verificar Assets Regenerados

**Docker:**

<code-block lang="bash" ignore-vars="true">
docker-compose exec db psql -U odoo -d odoo -c "SELECT COUNT(*) as assets_count FROM ir_attachment WHERE url LIKE '%/web/assets/%';"
</code-block>

**Ubuntu:**

<code-block lang="bash" ignore-vars="true">
sudo -u postgres psql odoo -c "SELECT COUNT(*) as assets_count FROM ir_attachment WHERE url LIKE '%/web/assets/%';"
</code-block>

### Verificar en el Navegador

1. **Abrir navegador en modo incognito** o **limpiar cache** (Ctrl + Shift + R)
2. **Ir a** `http://localhost:8069`
3. **Iniciar sesion**
4. **Verificar que se vea** el tema aeroportuaria con colores azules y logo correcto

## Comandos de Limpieza de Navegador

```
En Windows (Chrome): Ctrl + Shift + Del -> "Imagenes y archivos almacenados en cache"
En Linux (Chrome/Firefox): Ctrl + Shift + R (recarga forzada) o Ctrl + F5
En macOS: Cmd + Shift + R
```

## Checklist de Resolucion

- [ ] Verificar logs para confirmar errores 404 de assets
- [ ] Limpiar assets corruptos de la base de datos
- [ ] Desinstalar tema aeroportuaria
- [ ] Reinstalar tema aeroportuaria
- [ ] Reiniciar Odoo
- [ ] Limpiar cache del navegador
- [ ] Verificar funcionamiento con login
- [ ] Confirmar tema aplicado (colores azules, logo correcto)

## Prevencion para el Futuro

**Cuando modifiques assets del tema (logos, colores, CSS):**

1. **Hacer backup** de la base de datos antes de cambios
2. **Testear cambios** en ambiente de desarrollo primero
3. **Si aparecen problemas** despues de cambios en tema:
   - Ir inmediatamente a `Aplicaciones`
   - Desinstalar y reinstalar el tema
   - Esto evita problemas mayores

## Notas Importantes

- **El problema NO es de Docker** - puede pasar en cualquier instalacion de Odoo
- **La causa** son assets corruptos en la base de datos
- **La solucion mas simple** es desinstalar/reinstalar el tema desde la interfaz
- **Siempre limpiar cache del navegador** despues de la solucion
