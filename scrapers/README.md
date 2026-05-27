# Scrapers / Motor de Datos - FarmaCompare

Esta carpeta contiene el entorno Node.js que se encarga de subir datos a tu base de datos Supabase.

## Requisitos Previos

1. Asegúrate de tener tu archivo `.env` configurado.
2. Debes tener tu **SERVICE ROLE KEY** (no la clave pública anónima). Esta clave permite saltarse las reglas de seguridad para poder escribir/insertar datos masivamente desde este backend.

Puedes encontrar la Service Role Key en la misma página donde sacaste la URL de Supabase:
`Supabase > Settings > API > service_role (secret)`

Copia ese secreto y pégalo en el archivo `.env` en `SUPABASE_SERVICE_KEY=...`

## Scripts Disponibles

### 1. Sembrar la Base de Datos (Para probar tu app de inmediato)
Este script inyectará unos 6 productos de prueba realistas directamente en tu Supabase en la nube, para que cuando uses tu app de Flutter, veas cómo lee los datos reales.
```bash
node seed_database.js
```

### 2. Plantilla de Scraper
Esta es una plantilla que muestra cómo deberías hacer el web scraping real para conectarte a Farmatodo.
```bash
node farmatodo_scraper.js "Aspirina"
```
